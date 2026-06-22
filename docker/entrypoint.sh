#!/bin/bash
# =============================================================================
# docker/entrypoint.sh — Container entrypoint for PyForum app
#
# Steps:
#   1. Wait for Vault to be healthy
#   2. Read DB + App secrets from Vault KV v2 via curl
#   3. Export secrets as environment variables
#   4. Copy baked static files into shared volume (for Nginx)
#   5. Wait for PostgreSQL to accept connections
#   6. Run Django migrations
#   7. exec Gunicorn (replaces this shell process)
#
# Required env vars (from docker-compose environment section):
#   VAULT_ADDR, VAULT_TOKEN, DB_HOST, DB_PORT
#   STATIC_ROOT, EMAIL_BACKEND, EMAIL_HOST, EMAIL_PORT, EMAIL_USE_TLS
#   CORS_ORIGIN_WHITELIST
# =============================================================================
set -e

VAULT_ADDR="${VAULT_ADDR:-http://vault:8200}"
VAULT_TOKEN="${VAULT_TOKEN:-root}"

# ---------------------------------------------------------------------------
# 1. Wait for Vault
# ---------------------------------------------------------------------------
echo "[entrypoint] Waiting for Vault at ${VAULT_ADDR}..."
until curl -sf "${VAULT_ADDR}/v1/sys/health?standbyok=true&sealedok=true" \
        -o /dev/null 2>&1; do
    echo "[entrypoint]   Vault not ready, retrying in 2s..."
    sleep 2
done
echo "[entrypoint] Vault is ready."

# ---------------------------------------------------------------------------
# 2. Read DB secrets from Vault KV v2
#    CLI path:  secret/pyforum/db
#    API path:  /v1/secret/data/pyforum/db
# ---------------------------------------------------------------------------
echo "[entrypoint] Reading DB secrets from Vault..."
DB_SECRETS=$(curl -sf \
    -H "X-Vault-Token: ${VAULT_TOKEN}" \
    "${VAULT_ADDR}/v1/secret/data/pyforum/db")

export PG_DB=$(echo "${DB_SECRETS}" | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['data']['data']['db_name'])")
export PG_USER=$(echo "${DB_SECRETS}" | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['data']['data']['db_user'])")
export PG_PASSWORD=$(echo "${DB_SECRETS}" | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['data']['data']['db_password'])")

# ---------------------------------------------------------------------------
# 3. Read App secrets from Vault KV v2
#    CLI path:  secret/pyforum/app
#    API path:  /v1/secret/data/pyforum/app
# ---------------------------------------------------------------------------
echo "[entrypoint] Reading App secrets from Vault..."
APP_SECRETS=$(curl -sf \
    -H "X-Vault-Token: ${VAULT_TOKEN}" \
    "${VAULT_ADDR}/v1/secret/data/pyforum/app")

export SECRET_KEY=$(echo "${APP_SECRETS}" | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['data']['data']['secret_key'])")
export PGADMIN_EMAIL=$(echo "${APP_SECRETS}" | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['data']['data']['pgadmin_email'])")
export PGADMIN_PASSWORD=$(echo "${APP_SECRETS}" | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['data']['data']['pgadmin_password'])")
export EMAIL_HOST_USER=$(echo "${APP_SECRETS}" | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['data']['data']['email_host_user'])")
export EMAIL_HOST_PASSWORD=$(echo "${APP_SECRETS}" | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['data']['data']['email_host_password'])")

echo "[entrypoint] Secrets loaded from Vault."

# ---------------------------------------------------------------------------
# 4. Copy static files into shared volume (read by Nginx at /staticfiles/)
#    /app/staticfiles_src/ is baked into the image by docker build.
#    /staticfiles/ is the Docker named volume shared with the nginx container.
# ---------------------------------------------------------------------------
echo "[entrypoint] Copying static files to shared volume /staticfiles/..."
cp -r /app/staticfiles_src/. /staticfiles/
echo "[entrypoint] Static files ready."

# ---------------------------------------------------------------------------
# 5. Wait for PostgreSQL
# ---------------------------------------------------------------------------
echo "[entrypoint] Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT}..."
until python3 - <<EOF
import os, sys
try:
    import psycopg2
    psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ["PG_DB"],
        user=os.environ["PG_USER"],
        password=os.environ["PG_PASSWORD"],
    ).close()
    sys.exit(0)
except Exception as e:
    sys.exit(1)
EOF
do
    echo "[entrypoint]   PostgreSQL not ready, retrying in 2s..."
    sleep 2
done
echo "[entrypoint] PostgreSQL is ready."

# ---------------------------------------------------------------------------
# 6. Run Django migrations
# ---------------------------------------------------------------------------
echo "[entrypoint] Running Django migrations..."
python manage.py migrate --noinput

# ---------------------------------------------------------------------------
# 7. Start Gunicorn (exec replaces shell — PID 1 gets SIGTERM properly)
# ---------------------------------------------------------------------------
echo "[entrypoint] Starting Gunicorn..."
exec gunicorn "forum-sandbox.wsgi:application" \
    --bind 0.0.0.0:8000 \
    --workers 2 \
    --access-logfile - \
    --error-logfile -
