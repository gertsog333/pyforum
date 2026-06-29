#!/bin/bash
set -e

# ── Variables passed from Terraform templatefile() ──────────────────────────
JENKINS_DEPLOY_PUBKEY="${jenkins_deploy_pubkey}"
RDS_ENDPOINT="${rds_endpoint}"
AWS_REGION="${aws_region}"

# ── Install Docker CE ────────────────────────────────────────────────────────
# Amazon Linux 2023: use native docker package + compose plugin from GitHub
dnf install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user

# Install docker compose v2 plugin
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# ── Add Jenkins deploy public key to authorized_keys ────────────────────────
mkdir -p /home/ec2-user/.ssh
chmod 700 /home/ec2-user/.ssh
echo "$JENKINS_DEPLOY_PUBKEY" >> /home/ec2-user/.ssh/authorized_keys
chmod 600 /home/ec2-user/.ssh/authorized_keys
chown -R ec2-user:ec2-user /home/ec2-user/.ssh

# ── Fetch Cloudflare origin certificate and key from Secrets Manager ─────────
mkdir -p /opt/pyforum/certs
chmod 700 /opt/pyforum/certs

aws secretsmanager get-secret-value \
  --region "$AWS_REGION" \
  --secret-id pyforum/cloudflare-cert \
  --query SecretString \
  --output text > /opt/pyforum/certs/origin.crt

aws secretsmanager get-secret-value \
  --region "$AWS_REGION" \
  --secret-id pyforum/cloudflare-key \
  --query SecretString \
  --output text > /opt/pyforum/certs/origin.key

chmod 644 /opt/pyforum/certs/origin.crt
chmod 600 /opt/pyforum/certs/origin.key

# ── Clone application repository ─────────────────────────────────────────────
git clone https://github.com/gertsog333/pyforum.git /home/ec2-user/pyforum
chown -R ec2-user:ec2-user /home/ec2-user/pyforum

# ── Write .env.aws (non-secret config only — secrets read by entrypoint.aws.sh)
# Strip port from RDS endpoint (AWS returns host:port)
DB_HOST=$(echo "$RDS_ENDPOINT" | cut -d: -f1)

cat > /home/ec2-user/pyforum/docker/.env.aws << EOF
DB_HOST=$DB_HOST
DB_PORT=5432
CORS_ORIGIN_WHITELIST=https://pyforum-demo.win
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=1
EMAIL_HOST_USER=noreply@pyforum-demo.win
EMAIL_HOST_PASSWORD=placeholder
AWS_DEFAULT_REGION=$AWS_REGION
EOF

chown ec2-user:ec2-user /home/ec2-user/pyforum/docker/.env.aws
chmod 600 /home/ec2-user/pyforum/docker/.env.aws

# ── Start application ─────────────────────────────────────────────────────────
cd /home/ec2-user/pyforum/docker
sudo -u ec2-user docker compose --env-file .env.aws -f docker-compose.aws.yml up --build -d

echo "App EC2 user_data completed successfully"
