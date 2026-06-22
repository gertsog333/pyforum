#!/bin/sh
# =============================================================================
# docker/nginx.entrypoint.sh
#
# 0. Install openssl (not included in nginx:alpine by default)
# 1. Generate self-signed TLS certificate (if missing)
# 2. Start Nginx in foreground
# =============================================================================
set -e

# ---------------------------------------------------------------------------
# 0. Install openssl if not present (nginx:alpine does not ship it)
# ---------------------------------------------------------------------------
if ! command -v openssl >/dev/null 2>&1; then
    echo "[nginx-init] Installing openssl..."
    apk add --no-cache openssl >/dev/null 2>&1
fi

CERT_DIR="/etc/nginx/certs"
CERT_FILE="${CERT_DIR}/nginx.crt"
KEY_FILE="${CERT_DIR}/nginx.key"

# ---------------------------------------------------------------------------
# 1. Generate self-signed certificate
# ---------------------------------------------------------------------------
mkdir -p "${CERT_DIR}"

if [ ! -f "${CERT_FILE}" ]; then
    echo "[nginx-init] Generating self-signed TLS certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "${KEY_FILE}" \
        -out "${CERT_FILE}" \
        -subj "/C=UA/ST=Kyiv/L=Kyiv/O=PyForum Dev/OU=DevOps/CN=localhost" \
        2>/dev/null
    echo "[nginx-init] Certificate generated: ${CERT_FILE}"
else
    echo "[nginx-init] Certificate already exists, skipping generation."
fi

# ---------------------------------------------------------------------------
# 2. Start Nginx (exec replaces shell so Nginx gets PID 1 and SIGTERM)
# ---------------------------------------------------------------------------
echo "[nginx-init] Starting Nginx..."
exec nginx -g "daemon off;"
