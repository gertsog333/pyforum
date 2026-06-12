#!/bin/bash
# =============================================================================
# pyforum-provision-vault.sh
# Provision script for HashiCorp Vault node (dev mode)
# OS: Oracle Linux 9
# Run as: root (via Vagrant shell provisioner)
# =============================================================================

set -e

echo "============================================"
echo "  PyForum Vault Node Provisioning"
echo "  Host: $(hostname)"
echo "============================================"

# =============================================================================
# Install HashiCorp Vault
# =============================================================================
echo ""
echo "==> [VAULT] Installing HashiCorp Vault..."
dnf install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf install -y vault
echo "==> [VAULT] Vault installed: $(vault version)"

# =============================================================================
# Create systemd service (dev mode, listens on all interfaces)
# Token is fixed to "root" for dev/demo purposes
# =============================================================================
echo ""
echo "==> [VAULT] Creating systemd service..."
cat > /etc/systemd/system/vault.service << 'SERVICE_EOF'
[Unit]
Description=HashiCorp Vault (dev mode)
After=network.target

[Service]
User=root
ExecStart=/usr/bin/vault server -dev -dev-root-token-id=root -dev-listen-address=0.0.0.0:8200
Restart=always
RestartSec=5
Environment=VAULT_DEV_ROOT_TOKEN_ID=root

[Install]
WantedBy=multi-user.target
SERVICE_EOF

systemctl daemon-reload
systemctl enable --now vault
echo "==> [VAULT] Vault service started."

# =============================================================================
# Wait for Vault to be ready
# =============================================================================
echo ""
echo "==> [VAULT] Waiting for Vault to accept connections..."
for i in $(seq 1 10); do
  if vault status --address=http://192.168.56.40:8200 > /dev/null 2>&1; then
    echo "==> [VAULT] Vault is ready (attempt $i)."
    break
  fi
  echo "==> [VAULT] Not ready yet, retrying in 2s... ($i/10)"
  sleep 2
done

# =============================================================================
# Write secrets to Vault
# Paths:
#   secret/pyforum/db  — DB credentials
#   secret/pyforum/app — App secrets
# =============================================================================
echo ""
echo "==> [VAULT] Writing secrets..."
export VAULT_ADDR="http://192.168.56.40:8200"
export VAULT_TOKEN="root"

vault kv put secret/pyforum/db \
  db_user="pyforum_user" \
  db_password="pyforum_pass"

vault kv put secret/pyforum/app \
  secret_key="dev-secret-key-change-in-production" \
  pgadmin_email="admin@admin.com" \
  pgadmin_password="admin" \
  email_host_user="test@test.com" \
  email_host_password="password"

# =============================================================================
# Verify
# =============================================================================
echo ""
echo "==> [VAULT] Verifying secrets..."
vault kv get secret/pyforum/db
vault kv get secret/pyforum/app

echo ""
echo "============================================"
echo "  [VAULT] Provisioning complete!"
echo "  Vault addr:  http://192.168.56.40:8200"
echo "  Token:       root"
echo "  Secrets:     secret/pyforum/db"
echo "               secret/pyforum/app"
echo "============================================"
