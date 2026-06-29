#!/bin/bash
# =============================================================================
# jenkins-cicd/provision.sh
#
# 1. Install Docker CE + Docker Compose plugin (Oracle Linux 9)
# 2. Generate SSH deploy key pair:
#      Private key: /home/vagrant/.ssh/jenkins_deploy  (stays on this VM)
#      Public key:  written to jenkins-cicd/jenkins_deploy.pub (shared folder)
#                   so pyforum-docker-host can add it to authorized_keys
# 3. Write jenkins-cicd/.env.jenkins with JENKINS_AGENT_SSH_PUBKEY
#    (jenkins/ssh-agent base image reads this to configure the agent)
# 4. Build and start Jenkins Master + Agent containers
#
# Security: private key never leaves this VM, never committed to git.
# =============================================================================
set -e

# ---------------------------------------------------------------------------
# 1. Install Docker CE
# ---------------------------------------------------------------------------
echo "[provision] Installing Docker CE..."
dnf -y install dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[provision] Starting Docker service..."
systemctl enable --now docker
usermod -aG docker vagrant

echo "[provision] Docker installed: $(docker --version)"

# ---------------------------------------------------------------------------
# 2. Generate SSH deploy key pair
# ---------------------------------------------------------------------------
KEY_FILE="/home/vagrant/.ssh/jenkins_deploy"
PUBKEY_SHARED="/home/vagrant/pyforum/jenkins-cicd/jenkins_deploy.pub"
ENV_FILE="/home/vagrant/pyforum/jenkins-cicd/.env.jenkins"

echo "[provision] Generating SSH deploy key pair..."
mkdir -p /home/vagrant/.ssh
chown vagrant:vagrant /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh

if [ ! -f "${KEY_FILE}" ]; then
    sudo -u vagrant ssh-keygen -t ed25519 \
        -C "jenkins@pyforum-deploy" \
        -f "${KEY_FILE}" \
        -N ""
    echo "[provision] SSH key pair generated."
else
    echo "[provision] SSH key pair already exists, skipping generation."
fi

chmod 600 "${KEY_FILE}"
chmod 644 "${KEY_FILE}.pub"
chown vagrant:vagrant "${KEY_FILE}" "${KEY_FILE}.pub"

# ---------------------------------------------------------------------------
# 3. Share public key via synced_folder so docker/ VM can pick it up
# ---------------------------------------------------------------------------
cp "${KEY_FILE}.pub" "${PUBKEY_SHARED}"
echo "[provision] Public key shared at: ${PUBKEY_SHARED}"

# ---------------------------------------------------------------------------
# 4. Write .env.jenkins for docker-compose
#    JENKINS_AGENT_SSH_PUBKEY is read by jenkins/ssh-agent base image
#    and added to /home/jenkins/.ssh/authorized_keys inside the container
# ---------------------------------------------------------------------------
echo "JENKINS_AGENT_SSH_PUBKEY=$(cat ${KEY_FILE}.pub)" > "${ENV_FILE}"
echo "[provision] .env.jenkins written."

# ---------------------------------------------------------------------------
# 5. Build and start Jenkins containers
# ---------------------------------------------------------------------------
echo "[provision] Starting Jenkins containers..."
cd /home/vagrant/pyforum/jenkins-cicd
docker compose --env-file .env.jenkins up -d --build

echo "[provision] ============================================"
echo "[provision] Jenkins containers started."
echo "[provision]"
echo "[provision] Wait ~60s for Jenkins to initialize, then:"
echo "[provision]   http://localhost:8080"
echo "[provision]"
echo "[provision] Initial admin password:"
echo "[provision]   vagrant ssh -c \"docker exec pyforum_jenkins_master \\"
echo "[provision]     cat /var/jenkins_home/secrets/initialAdminPassword\""
echo "[provision]"
echo "[provision] Deploy SSH private key (add to Jenkins Credentials):"
echo "[provision]   ${KEY_FILE}"
echo "[provision] ============================================"
