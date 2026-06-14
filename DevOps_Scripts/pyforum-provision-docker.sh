#!/bin/bash
# =============================================================================
# DevOps_Scripts/pyforum-provision-docker.sh
# Installs Docker CE + Docker Compose plugin on Oracle Linux 9
# Called by docker/Vagrantfile during vagrant up
# =============================================================================
set -e

echo "[provision-docker] Installing Docker CE..."
dnf -y install dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[provision-docker] Starting Docker service..."
systemctl enable --now docker

echo "[provision-docker] Adding vagrant user to docker group..."
usermod -aG docker vagrant

echo "[provision-docker] ----------------------------------------"
echo "[provision-docker] Docker installed:"
docker --version
docker compose version
echo "[provision-docker] ----------------------------------------"
echo "[provision-docker] Done!"
echo "[provision-docker]"
echo "[provision-docker] Next steps:"
echo "[provision-docker]   vagrant ssh"
echo "[provision-docker]   cd /home/vagrant/pyforum/docker"
echo "[provision-docker]   docker compose --env-file .env.docker up --build"
