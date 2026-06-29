#!/bin/bash
set -e

# ── Variables passed from Terraform templatefile() ──────────────────────────
JENKINS_DEPLOY_PRIVKEY="${jenkins_deploy_privkey}"
JENKINS_DEPLOY_PUBKEY="${jenkins_deploy_pubkey}"

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

# ── Write Jenkins deploy private key ─────────────────────────────────────────
mkdir -p /home/ec2-user/.ssh
chmod 700 /home/ec2-user/.ssh

cat > /home/ec2-user/.ssh/jenkins_deploy << 'SSHEOF'
${jenkins_deploy_privkey}
SSHEOF

chmod 600 /home/ec2-user/.ssh/jenkins_deploy
chown -R ec2-user:ec2-user /home/ec2-user/.ssh

# ── Clone application repository ─────────────────────────────────────────────
git clone https://github.com/gertsog333/pyforum.git /home/ec2-user/pyforum
chown -R ec2-user:ec2-user /home/ec2-user/pyforum

# ── Write Jenkins .env.jenkins ───────────────────────────────────────────────
cat > /home/ec2-user/pyforum/jenkins-cicd/.env.jenkins << EOF
JENKINS_AGENT_SSH_PUBKEY=$JENKINS_DEPLOY_PUBKEY
EOF

chown ec2-user:ec2-user /home/ec2-user/pyforum/jenkins-cicd/.env.jenkins
chmod 600 /home/ec2-user/pyforum/jenkins-cicd/.env.jenkins

# ── Start Jenkins via Docker Compose ─────────────────────────────────────────
cd /home/ec2-user/pyforum/jenkins-cicd
sudo -u ec2-user docker compose --env-file .env.jenkins up -d --build

echo "Jenkins EC2 user_data completed successfully"
