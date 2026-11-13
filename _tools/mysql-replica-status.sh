#!/usr/bin/env bash
# 检查 MySQL 主从状态与两边数据一致性：
#   主库（可读写）: db-admin / 192.0.2.10（Docker MySQL 8.0）
#   从库（只读）  : root-server / 203.0.113.10（Docker MySQL 8.0，经
#                   SSH 反向隧道 127.0.0.1:13306 连主库复制）
#
# 用法: ./_tools/mysql-replica-status.sh
# 依赖: 局域网侧 mysql-replica-tunnel.service 正在运行。
set -euo pipefail
cd "$(dirname "$0")/.."

VAULT_ID="33132e9c50aa499bb8a1462f3cff9b11"

if command -v ovssh >/dev/null 2>&1; then
  ssh46() { ovssh 46 "$@"; }
else
  ssh46() { ssh deploy@192.0.2.10 "$@"; }
fi

lan_root_pw() {
  ssh46 \
    "docker inspect mysql --format '{{range .Config.Env}}{{println .}}{{end}}'" \
    < /dev/null | sed -n 's/^MYSQL_ROOT_PASSWORD=//p' | head -1
}

ali_root_pw() {
  ssh root-server \
    "docker inspect mysql --format '{{range .Config.Env}}{{println .}}{{end}}'" \
    < /dev/null | sed -n 's/^MYSQL_ROOT_PASSWORD=//p' | head -1
}

echo "==> 主库（192.0.2.10）"
LAN_PW="$(lan_root_pw)"
MASTER_SHA="$(ssh46 \
  "docker exec mysql mysql -uroot -p$LAN_PW -N -e \"SELECT SHA2(ciphertext,256) FROM openvalut.vaults WHERE id='$VAULT_ID'\"" \
  < /dev/null 2>/dev/null)"
echo "vault blob sha256: $MASTER_SHA"

echo "==> 从库（203.0.113.10，只读）"
ALI_PW="$(ali_root_pw)"
ssh root-server "docker exec mysql mysql -uroot -p$ALI_PW -e \"SHOW SLAVE STATUS\\G\" 2>/dev/null" \
  < /dev/null | grep -E "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master|Last_IO_Error|Last_SQL_Error"
SLAVE_SHA="$(ssh root-server \
  "docker exec mysql mysql -uroot -p$ALI_PW -N -e \"SELECT SHA2(ciphertext,256) FROM openvalut.vaults WHERE id='$VAULT_ID'\"" \
  < /dev/null 2>/dev/null)"
echo "vault blob sha256: $SLAVE_SHA"

if [[ "$MASTER_SHA" == "$SLAVE_SHA" ]]; then
  echo "==> 数据一致 OK"
else
  echo "ERROR: 主从 vault blob 不一致，请检查复制状态/延迟" >&2
  exit 1
fi

echo "==> 反向复制通道（阿里云应用库 -> 局域网，channel app_db_repl）"
ssh46 "docker exec mysql mysql -uroot -p$LAN_PW -e \"SHOW SLAVE STATUS FOR CHANNEL 'app_db_repl'\\G\" 2>/dev/null" \
  < /dev/null | grep -E "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master|Last_IO_Error|Last_SQL_Error"

echo "==> 应用库表数量对比"
APP_DBS="'ai_video_learning','bicycle','blog_api_db','clipvault_db','english_vocabulary','growth_app','melody_db','weread_payment'"
ALI_COUNTS="$(ssh root-server \
  "docker exec mysql mysql -uroot -p$ALI_PW -N -e \"SELECT table_schema, COUNT(*) FROM information_schema.tables WHERE table_schema IN ($APP_DBS) GROUP BY table_schema ORDER BY table_schema\"" \
  < /dev/null 2>/dev/null)"
LAN_COUNTS="$(ssh46 \
  "docker exec mysql mysql -uroot -p$LAN_PW -N -e \"SELECT table_schema, COUNT(*) FROM information_schema.tables WHERE table_schema IN ($APP_DBS) GROUP BY table_schema ORDER BY table_schema\"" \
  < /dev/null 2>/dev/null)"
if [[ "$ALI_COUNTS" == "$LAN_COUNTS" ]]; then
  echo "==> 应用库表数量一致 OK"
  echo "$ALI_COUNTS"
else
  echo "ERROR: 应用库表数量不一致" >&2
  echo "阿里云:"; echo "$ALI_COUNTS"
  echo "局域网:"; echo "$LAN_COUNTS"
  exit 1
fi
