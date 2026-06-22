# =============================================================================
# docker/Dockerfile — Multi-stage build for PyForum Django application
#
# Stage 1 (builder): installs build deps, creates venv, runs collectstatic
# Stage 2 (runtime): lean image with only what is needed to run the app
#
# Build context is the project root (..):
#   docker compose --env-file .env.docker up --build
# =============================================================================

# ---- Stage 1: Builder -------------------------------------------------------
FROM python:3.11-slim AS builder

# No gcc/libpq-dev needed — we use psycopg2-binary (pre-compiled wheel)

WORKDIR /build

# Install Python deps into an isolated virtual env.
# requirements.txt contains both psycopg2 (source) and psycopg2-binary (wheel).
# In Docker we skip the source package and use only the binary version.
COPY requirements.txt .
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir --upgrade pip \
    && grep -v '^psycopg2==' requirements.txt \
       | pip install --no-cache-dir -r /dev/stdin

# Copy the full source tree (.dockerignore excludes .vagrant/, .git/, etc.)
COPY . .

# Run collectstatic into a dedicated directory (staticfiles_src/).
# STATIC_ROOT is passed as env var — settings.py reads it via config().
# Nginx will serve /staticfiles_src/ content directly (faster than Whitenoise).
RUN mkdir -p staticfiles_src logs \
    && DJANGO_SETTINGS_MODULE=forum-sandbox.settings \
    STATIC_ROOT=/build/staticfiles_src \
    SECRET_KEY=dummy-build-key-not-for-production \
    PG_DB=dummy \
    PG_USER=dummy \
    PG_PASSWORD=dummy \
    DB_HOST=localhost \
    DB_PORT=5432 \
    CORS_ORIGIN_WHITELIST=http://localhost \
    EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend \
    EMAIL_HOST=localhost \
    EMAIL_PORT=587 \
    EMAIL_USE_TLS=1 \
    EMAIL_HOST_USER=dummy@example.com \
    EMAIL_HOST_PASSWORD=dummy \
    python manage.py collectstatic --noinput

# ---- Stage 2: Runtime -------------------------------------------------------
FROM python:3.11-slim AS runtime

# libpq5  — psycopg2 runtime shared library
# curl    — used in entrypoint.sh to call Vault HTTP API
RUN apt-get update && apt-get install -y \
    libpq5 \
    curl \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd --gid 1001 appuser \
    && useradd --uid 1001 --gid appuser --shell /bin/bash --create-home appuser

WORKDIR /app

# Virtual env from builder
COPY --from=builder /opt/venv /opt/venv

# Application source from builder
COPY --from=builder /build .

# Baked static files from builder (separate dir, not mixed with source code)
COPY --from=builder /build/staticfiles_src /app/staticfiles_src

# Ensure entrypoint is executable, logs dir exists,
# and /staticfiles is owned by appuser so the volume is writable at runtime.
RUN chmod +x /app/docker/entrypoint.sh \
    && chmod +x /app/docker/nginx.entrypoint.sh \
    && mkdir -p /app/logs \
    && chown -R appuser:appuser /app/logs \
    && mkdir -p /staticfiles \
    && chown appuser:appuser /staticfiles

USER appuser

ENV PATH="/opt/venv/bin:$PATH"
ENV DJANGO_SETTINGS_MODULE="forum-sandbox.settings"
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

EXPOSE 8000

ENTRYPOINT ["/app/docker/entrypoint.sh"]
