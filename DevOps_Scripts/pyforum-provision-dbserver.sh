#!/bin/bash
# =============================================================================
# pyforum-provision-dbserver.sh
# Provision script for PyForum DB server (PostgreSQL)
# OS: Oracle Linux 9
# Run as: root (sudo)
# =============================================================================

set -e  # остановить скрипт при любой ошибке

# =============================================================================
# Переменные
# =============================================================================
DB_NAME="forum"
DB_USER="pyforum_user"
DB_PASSWORD="pyforum_pass"
APP_SERVER_IP="192.168.56.10"
PG_HBA="/var/lib/pgsql/data/pg_hba.conf"
PG_CONF="/var/lib/pgsql/data/postgresql.conf"

# =============================================================================
# Проверка запуска от root
# =============================================================================
if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] This script must be run as root. Use: sudo $0"
  exit 1
fi

echo "============================================"
echo "  PyForum DB Server Provisioning"
echo "  Host: $(hostname)"
echo "============================================"

# =============================================================================
# Обновление системы
# =============================================================================
echo ""
echo "==> [DB] Updating system..."
dnf update -y -q
echo "==> [DB] System updated."

# =============================================================================
# Установка PostgreSQL
# =============================================================================
echo ""
echo "==> [DB] Installing PostgreSQL..."
dnf install -y postgresql postgresql-server
echo "==> [DB] PostgreSQL installed."

# =============================================================================
# Инициализация PostgreSQL
# =============================================================================
echo ""
echo "==> [DB] Initializing PostgreSQL..."
postgresql-setup --initdb
echo "==> [DB] PostgreSQL initialized."

# =============================================================================
# Настройка аутентификации (md5 вместо ident)
# =============================================================================
echo ""
echo "==> [DB] Configuring authentication (md5)..."
sed -i 's/ident/md5/g' "$PG_HBA"
echo "==> [DB] Authentication configured."

# =============================================================================
# Разрешаем подключения с app-сервера
# PostgreSQL по умолчанию слушает только localhost — меняем на все интерфейсы
# =============================================================================
echo ""
echo "==> [DB] Allowing connections from app-server ($APP_SERVER_IP)..."
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"
echo "host    $DB_NAME    $DB_USER    $APP_SERVER_IP/32    md5" >> "$PG_HBA"
echo "==> [DB] Remote connections configured."

# =============================================================================
# Запуск PostgreSQL и добавление в автозагрузку
# =============================================================================
echo ""
echo "==> [DB] Starting PostgreSQL and enabling on boot..."
systemctl enable --now postgresql
echo "==> [DB] PostgreSQL is running."

# =============================================================================
# Создание пользователя и базы данных
# =============================================================================
echo ""
echo "==> [DB] Creating database user and database..."
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" 2>/dev/null || true
echo "==> [DB] Database and user created."

# =============================================================================
# Итог
# =============================================================================
echo ""
echo "============================================"
echo "  [DB] Provisioning complete!"
echo "  Host:     $(hostname) ($(hostname -I | awk '{print $1}'))"
echo "  Database: $DB_NAME"
echo "  User:     $DB_USER"
echo "  Listening on: 0.0.0.0:5432"
echo "  App server allowed: $APP_SERVER_IP"
echo "============================================"
