#!/bin/bash
# =============================================================================
# pyforum-provision-appserver.sh
# Provision script for PyForum App server (Django + Gunicorn)
# OS: Oracle Linux 9
# Run as: root (sudo)
# NOTE: dbserver must be running before executing this script!
# =============================================================================

set -e  # остановить скрипт при любой ошибке

# =============================================================================
# Переменные
# =============================================================================
PROJECT_DIR="/home/vagrant/pyforum"
DB_HOST="192.168.56.20"
DB_PORT="5432"
DB_NAME="forum"
DB_USER="pyforum_user"
DB_PASSWORD="pyforum_pass"
APP_USER="vagrant"
DB_CHECK_ATTEMPTS=3
DB_CHECK_INTERVAL=5  # секунд между попытками

# =============================================================================
# Проверка запуска от root
# =============================================================================
if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] This script must be run as root. Use: sudo $0"
  exit 1
fi

echo "============================================"
echo "  PyForum App Server Provisioning"
echo "  Host: $(hostname)"
echo "============================================"

# =============================================================================
# Проверка что папка проекта существует (монтируется Vagrant'ом)
# =============================================================================
echo ""
echo "==> [APP] Checking project directory..."
if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "[ERROR] Project directory '$PROJECT_DIR' does not exist."
  echo "[ERROR] Make sure Vagrant has mounted the shared folder."
  exit 1
fi
echo "==> [APP] Project directory found: $PROJECT_DIR"

# =============================================================================
# Обновление системы
# =============================================================================
echo ""
echo "==> [APP] Updating system..."
dnf update -y -q
echo "==> [APP] System updated."

# =============================================================================
# Установка зависимостей (включая postgresql для pg_isready)
# =============================================================================
echo ""
echo "==> [APP] Installing dependencies..."
dnf install -y python3 python3-pip python3-devel \
               postgresql-devel gcc make git postgresql
echo "==> [APP] Dependencies installed."

# =============================================================================
# Предупреждение: dbserver должен быть запущен заранее
# =============================================================================
echo ""
echo "[INFO] IMPORTANT: dbserver ($DB_HOST:$DB_PORT) must be running before"
echo "[INFO] this script proceeds. Checking availability..."

# =============================================================================
# Проверка доступности БД (3 попытки)
# =============================================================================
attempt=1
db_ready=0

while [[ $attempt -le $DB_CHECK_ATTEMPTS ]]; do
  echo ""
  echo "==> [APP] Attempt $attempt/$DB_CHECK_ATTEMPTS: checking database at $DB_HOST:$DB_PORT..."
  if pg_isready -h "$DB_HOST" -p "$DB_PORT" -q 2>/dev/null; then
    echo "==> [APP] Database is available."
    db_ready=1
    break
  else
    echo "==> [APP] Database not available yet."
    if [[ $attempt -lt $DB_CHECK_ATTEMPTS ]]; then
      echo "==> [APP] Retrying in $DB_CHECK_INTERVAL seconds..."
      sleep $DB_CHECK_INTERVAL
    fi
  fi
  attempt=$((attempt + 1))
done

if [[ $db_ready -eq 0 ]]; then
  echo ""
  echo "[ERROR] Database at $DB_HOST:$DB_PORT is not available after $DB_CHECK_ATTEMPTS attempts."
  echo "[ERROR] Please make sure dbserver is running and try again."
  exit 1
fi

# =============================================================================
# Установка Python-зависимостей проекта
# =============================================================================
echo ""
echo "==> [APP] Installing Python dependencies..."
cd "$PROJECT_DIR"
pip3 install -r requirements.txt
echo "==> [APP] Python dependencies installed."

# =============================================================================
# Создание .env файла
# =============================================================================
echo ""
echo "==> [APP] Creating .env file..."
cat > "$PROJECT_DIR/.env" <<EOF
SECRET_KEY=dev-secret-key-change-in-production
PG_DB=$DB_NAME
PG_USER=$DB_USER
PG_PASSWORD=$DB_PASSWORD
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_PORT_OUT=55432
PGADMIN_EMAIL=admin@admin.com
PGADMIN_PASSWORD=admin
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
EMAIL_HOST=localhost
EMAIL_PORT=587
EMAIL_USE_TLS=1
EMAIL_HOST_USER=test@test.com
EMAIL_HOST_PASSWORD=password
CORS_ORIGIN_WHITELIST=http://192.168.56.10
EOF
echo "==> [APP] .env file created."

# =============================================================================
# Создание папки для логов
# =============================================================================
echo ""
echo "==> [APP] Creating logs directory..."
mkdir -p "$PROJECT_DIR/logs"
echo "==> [APP] Logs directory created."

# =============================================================================
# Создание и применение миграций Django
# =============================================================================
echo ""
echo "==> [APP] Creating migrations..."
cd "$PROJECT_DIR"
python3 manage.py makemigrations authentication profiles administration

echo ""
echo "==> [APP] Applying migrations..."
python3 manage.py migrate
echo "==> [APP] Migrations applied."

# =============================================================================
# Сборка статики
# =============================================================================
echo ""
echo "==> [APP] Collecting static files..."
python3 manage.py collectstatic --noinput
echo "==> [APP] Static files collected."

# =============================================================================
# Создание systemd-сервиса для автозапуска через gunicorn
# =============================================================================
echo ""
echo "==> [APP] Creating systemd service for gunicorn..."
cat > /etc/systemd/system/pyforum.service <<EOF
[Unit]
Description=PyForum Django Application
After=network.target

[Service]
User=$APP_USER
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/local/bin/gunicorn forum-sandbox.wsgi:application --bind 0.0.0.0:8000 --workers 2
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now pyforum
echo "==> [APP] Gunicorn service started and enabled on boot."

# =============================================================================
# Итог
# =============================================================================
echo ""
echo "============================================"
echo "  [APP] Provisioning complete!"
echo "  Host:      $(hostname) ($(hostname -I | awk '{print $1}'))"
echo "  App:       http://192.168.56.10:8000"
echo "  DB:        $DB_HOST:$DB_PORT/$DB_NAME"
echo "  Project:   $PROJECT_DIR"
echo "============================================"
