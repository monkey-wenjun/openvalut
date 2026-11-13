#!/usr/bin/env bash
# Deploy openvalut-server (Rust) to this machine (Ubuntu/Debian).
#
# Run ON THE SERVER with sudo:
#   sudo bash deploy.sh
#
# Assumes: openvalut-server binary + this script are in the current directory,
# nginx is installed, and the wildcard cert for *.example.com exists at
# /etc/nginx/ssl/example.com/.
#
# If a MySQL-compatible server is already running (e.g. a Docker MySQL on
# 127.0.0.1:3306), it is reused — set OPENVALUT_MYSQL_ROOT_PW to its root
# password. Otherwise MariaDB is installed and configured for durability.
set -euo pipefail

if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx mysql || \
   mysqladmin ping -h127.0.0.1 --silent 2>/dev/null; then
  echo "==> Reusing an existing MySQL server"
  MYSQL_ROOT_PW="${OPENVALUT_MYSQL_ROOT_PW:-}"
  if [ -z "$MYSQL_ROOT_PW" ]; then
    echo "Set OPENVALUT_MYSQL_ROOT_PW to the existing MySQL root password."
    exit 1
  fi
  MYSQL_CMD="docker exec -i mysql mysql -uroot -p${MYSQL_ROOT_PW}" 2>/dev/null || true
  if ! echo "SELECT 1" | ${MYSQL_CMD} >/dev/null 2>&1; then
    MYSQL_CMD="mysql -uroot -p${MYSQL_ROOT_PW}"
  fi
else
  echo "==> Installing MariaDB server"
  apt-get update -qq
  apt-get install -y -qq mariadb-server

  echo "==> Configuring MySQL durability (dual-1 + doublewrite + binlog)"
  cat > /etc/mysql/mariadb.conf.d/99-openvalut-durability.cnf <<'EOF'
[mysqld]
# Durability (dual-1): flush the InnoDB redo log to disk on every commit and
# fsync the binlog on every commit, so a crash never loses acknowledged data.
innodb_flush_log_at_trx_commit = 1
sync_binlog = 1

# Doublewrite buffer: prevents torn-page writes so the redo log can always
# recover a page.
innodb_doublewrite = 1

# Binlog (server-side archive log) for recovery / future replication.
log_bin = /var/log/mysql/mariadb-bin
binlog_format = ROW
server_id = 1
EOF
  systemctl restart mariadb
  MYSQL_CMD="mysql -uroot"
fi

echo "==> Creating database and user"
DB_NAME="${OPENVALUT_DB_NAME:-openvalut}"
DB_USER="${OPENVALUT_DB_USER:-openvalut}"
DB_PASS="${OPENVALUT_DB_PASS:-$(openssl rand -hex 16)}"
${MYSQL_CMD} <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
SQL

echo "==> Installing binary"
install -d -m 755 /opt/openvalut-server
install -m 755 openvalut-server /opt/openvalut-server/openvalut-server

echo "==> Writing env file"
cat > /etc/default/openvalut-server <<EOF
OPENVALUT_DSN=${DB_USER}:${DB_PASS}@tcp(127.0.0.1:3306)/${DB_NAME}?parseTime=true
EOF
chmod 600 /etc/default/openvalut-server

echo "==> Installing systemd unit"
install -m 644 openvalut-server.service /etc/systemd/system/openvalut-server.service
systemctl daemon-reload
systemctl enable --now openvalut-server
systemctl status openvalut-server --no-pager | head -5

echo "==> Installing nginx site"
install -m 644 openvalut.conf /etc/nginx/sites-enabled/openvalut.conf
nginx -t
systemctl reload nginx

echo
echo "Deployed. Health check:"
curl -s http://127.0.0.1:18080/healthz
echo
echo "Remember to add the DNS record: openvalut.example.com -> your public IP"
