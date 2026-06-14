#!/bin/sh
# =============================================================================
# docker/vault-init.sh — Initialises Vault with PyForum secrets
#
# Runs once as the vault-init service (restart: no).
# Secrets are passed in via environment variables from .env.docker.
#
# Required env vars:
#   VAULT_ADDR, VAULT_TOKEN
#   VAULT_DB_NAME, VAULT_DB_USER, VAULT_DB_PASSWORD
#   VAULT_SECRET_KEY, VAULT_PGADMIN_EMAIL, VAULT_PGADMIN_PASSWORD
#   VAULT_EMAIL_HOST_USER, VAULT_EMAIL_HOST_PASSWORD
# =============================================================================
set -e

VAULT_ADDR="${VAULT_ADDR:-http://vault:8200}"
export VAULT_ADDR
export VAULT_TOKEN

# ---------------------------------------------------------------------------
# Wait for Vault to be ready
# ---------------------------------------------------------------------------
echo "[vault-init] Waiting for Vault at ${VAULT_ADDR}..."
until vault status > /dev/null 2>&1; do
    echo "[vault-init]   Vault not ready, retrying in 2s..."
    sleep 2
done
echo "[vault-init] Vault is ready."

# ---------------------------------------------------------------------------
# Enable KV v2 at secret/ (dev mode enables it automatically, so the
# command may fail with "path is already in use" — that is fine)
# ---------------------------------------------------------------------------
vault secrets enable -path=secret kv-v2 2>/dev/null \
    && echo "[vault-init] KV v2 enabled at secret/" \
    || echo "[vault-init] KV v2 already enabled at secret/ — continuing."

# ---------------------------------------------------------------------------
# Write DB secrets: secret/pyforum/db
# ---------------------------------------------------------------------------
echo "[vault-init] Writing DB secrets to secret/pyforum/db..."
vault kv put secret/pyforum/db \
    db_name="${VAULT_DB_NAME}" \
    db_user="${VAULT_DB_USER}" \
    db_password="${VAULT_DB_PASSWORD}"

# ---------------------------------------------------------------------------
# Write App secrets: secret/pyforum/app
# ---------------------------------------------------------------------------
echo "[vault-init] Writing App secrets to secret/pyforum/app..."
vault kv put secret/pyforum/app \
    secret_key="${VAULT_SECRET_KEY}" \
    pgadmin_email="${VAULT_PGADMIN_EMAIL}" \
    pgadmin_password="${VAULT_PGADMIN_PASSWORD}" \
    email_host_user="${VAULT_EMAIL_HOST_USER}" \
    email_host_password="${VAULT_EMAIL_HOST_PASSWORD}"

# ---------------------------------------------------------------------------
# Verify — print stored keys (values are hidden in real Vault, shown in dev)
# ---------------------------------------------------------------------------
echo "[vault-init] ✓ Secrets written successfully."
echo "[vault-init] Verifying secret/pyforum/db:"
vault kv get secret/pyforum/db
echo "[vault-init] Verifying secret/pyforum/app:"
vault kv get secret/pyforum/app
