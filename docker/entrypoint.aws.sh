#!/bin/bash
# =============================================================================
# docker/entrypoint.aws.sh — AWS entrypoint for PyForum app
# Reads secrets from AWS Secrets Manager (boto3) instead of Vault
# EC2 IAM role provides credentials automatically via instance metadata
# =============================================================================
set -e

AWS_REGION="${AWS_DEFAULT_REGION:-eu-central-1}"

# ---------------------------------------------------------------------------
# 1. Read DB secrets: pyforum/db
# ---------------------------------------------------------------------------
echo "[entrypoint-aws] Reading DB secrets from Secrets Manager..."
DB_SECRETS=$(python3 - <<'PYEOF'
import boto3, json, os, sys
try:
    sm = boto3.client('secretsmanager', region_name=os.environ.get('AWS_DEFAULT_REGION', 'eu-central-1'))
    r = sm.get_secret_value(SecretId='pyforum/db')
    print(r['SecretString'])
except Exception as e:
    print(f"ERROR reading pyforum/db: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
)

export PG_DB=$(echo "${DB_SECRETS}" | python3 -c "import sys,json; print(json.load(sys.stdin)['db_name'])")
export PG_USER=$(echo "${DB_SECRETS}" | python3 -c "import sys,json; print(json.load(sys.stdin)['db_user'])")
export PG_PASSWORD=$(echo "${DB_SECRETS}" | python3 -c "import sys,json; print(json.load(sys.stdin)['db_password'])")

# ---------------------------------------------------------------------------
# 2. Read App secrets: pyforum/app
# ---------------------------------------------------------------------------
echo "[entrypoint-aws] Reading App secrets from Secrets Manager..."
APP_SECRETS=$(python3 - <<'PYEOF'
import boto3, json, os, sys
try:
    sm = boto3.client('secretsmanager', region_name=os.environ.get('AWS_DEFAULT_REGION', 'eu-central-1'))
    r = sm.get_secret_value(SecretId='pyforum/app')
    print(r['SecretString'])
except Exception as e:
    print(f"ERROR reading pyforum/app: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
)

export SECRET_KEY=$(echo "${APP_SECRETS}" | python3 -c "import sys,json; print(json.load(sys.stdin)['secret_key'])")

echo "[entrypoint-aws] Secrets loaded successfully."

# ---------------------------------------------------------------------------
# 3. Copy static files to shared volume
# ---------------------------------------------------------------------------
echo "[entrypoint-aws] Copying static files to /staticfiles/..."
cp -r /app/staticfiles_src/. /staticfiles/
echo "[entrypoint-aws] Static files ready."

# ---------------------------------------------------------------------------
# 4. Wait for PostgreSQL (RDS)
# ---------------------------------------------------------------------------
echo "[entrypoint-aws] Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT:-5432}..."
until python3 - <<PYEOF
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
PYEOF
do
    echo "[entrypoint-aws]   DB not ready, retrying in 3s..."
    sleep 3
done
echo "[entrypoint-aws] PostgreSQL is ready."

# ---------------------------------------------------------------------------
# 5. Run Django migrations (explicit order: contenttypes → authentication → rest)
# ---------------------------------------------------------------------------
echo "[entrypoint-aws] Running Django migrations..."
python manage.py migrate contenttypes --noinput
python manage.py migrate authentication --noinput
python manage.py migrate --noinput

# ---------------------------------------------------------------------------
# 6. Start Gunicorn (exec → PID 1 → proper SIGTERM handling)
# ---------------------------------------------------------------------------
echo "[entrypoint-aws] Starting Gunicorn..."
exec gunicorn "forum-sandbox.wsgi:application" \
    --bind 0.0.0.0:8000 \
    --workers 2 \
    --access-logfile - \
    --error-logfile -
