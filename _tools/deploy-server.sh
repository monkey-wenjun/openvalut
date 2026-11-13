#!/usr/bin/env bash
# 一键部署/更新 openvalut-server (Rust) 到生产服务器 openvalut-server.example.com。
#
# 用法：
#   ./_tools/deploy-server.sh
#
# 一次完成：本机 musl 静态编译 -> scp 上传二进制与 service -> 远端以
# sudo 身份执行幂等初始化/安装 -> 重启服务 -> 健康检查 + sha256 校验。
#
# 服务器 SSH 账号通过 ~/.ssh/config 中 openvalut-server.example.com 别名决定（现为 deploy，
# 已禁用 root 登录）。若 SSH 用户非 root，远端通过 sudo 提权，sudo 密码从
# 本地文件读取（默认 ~/.config/openvalut/sudo.pass，可用 OPENVALUT_SUDO_PASS
# 覆盖），遗留路径 ~/.config/openvalut/sudo.pass 仍可作为后备。绝不写入命令行。
# 脚本幂等，可重复执行；任一步失败以非零状态退出。
set -euo pipefail
cd "$(dirname "$0")/.."

HOST="openvalut-server.example.com"
LOCAL_SERVICE="crates/openvalut-server/deploy/openvalut-server.service"
SUDO_PASS_FILE="${OPENVALUT_SUDO_PASS:-${HOME}/.config/openvalut/sudo.pass}"
if [[ ! -f "$SUDO_PASS_FILE" && -f "${HOME}/.config/openvalut/sudo.pass" ]]; then
  SUDO_PASS_FILE="${HOME}/.config/openvalut/sudo.pass"
fi

# 传输通道：默认 BatchMode=yes（纯公钥）。若目标机已启用两步验证
# （密码+TOTP），BatchMode 无法自动应答，可通过 OPENVALUT_SSH_SOCKET 指定
# 一个已认证的 control master socket（如 `ssh -MN -S /tmp/rs master`），
# 所有 ssh/scp 命令复用该连接，不再需要输入密码与验证码。
SSH_SOCKET="${OPENVALUT_SSH_SOCKET:-}"
if [[ -n "$SSH_SOCKET" ]]; then
  SSH_CMD=(ssh -S "$SSH_SOCKET")
else
  SSH_CMD=(ssh -o BatchMode=yes)
fi

NO_ROOT_TMP="/tmp/openvalut-server.$$.$RANDOM"
REMOTE_BIN_TMP="${NO_ROOT_TMP}.bin"
REMOTE_SVC_TMP="${NO_ROOT_TMP}.service"
REMOTE_SCRIPT="${NO_ROOT_TMP}.sh"

echo "==> 构建 openvalut-server (静态 musl, linux/amd64)"
TARGET="x86_64-unknown-linux-musl"
if ! rustup target list --installed 2>/dev/null | grep -qx "$TARGET"; then
  echo "==> 安装 Rust target $TARGET"
  rustup target add "$TARGET"
fi
if ! command -v musl-gcc >/dev/null 2>&1; then
  echo "ERROR: 缺少 musl-gcc，请先安装 musl-tools" >&2
  exit 1
fi
CC_x86_64_unknown_linux_musl=musl-gcc \
  cargo build -p openvalut-server --release --target "$TARGET"

cp "target/$TARGET/release/openvalut-server" /tmp/openvalut-server
LOCAL_SHA="$(sha256sum /tmp/openvalut-server | awk '{print $1}')"
echo "==> 本地构建 sha256: $LOCAL_SHA (commit $(git rev-parse --short HEAD))"

echo "==> [$HOST] 上传二进制与 systemd service"
"${SSH_CMD[@]}" "$HOST" "cat > '$REMOTE_BIN_TMP'" < /tmp/openvalut-server
"${SSH_CMD[@]}" "$HOST" "cat > '$REMOTE_SVC_TMP'" < "$LOCAL_SERVICE"

# 把远端安装脚本写过去（以登录用户身份写 /tmp，无需 root）。
echo "==> [$HOST] 写入远端安装脚本"
"${SSH_CMD[@]}" "$HOST" "cat > $REMOTE_SCRIPT" <<'REMOTE'
set -euo pipefail

REMOTE_BIN="/opt/openvalut-server/openvalut-server"
REMOTE_SERVICE="/etc/systemd/system/openvalut-server.service"
BIN_TMP="${1:?binary tmp path required}"
SVC_TMP="${2:?service tmp path required}"

# 1) 服务专用用户（不存在则创建）
if ! id openvalut >/dev/null 2>&1; then
  useradd --system --home /opt/openvalut-server --shell /usr/sbin/nologin openvalut
fi

# 2) 数据目录
install -d -m 0755 /opt/openvalut-server
install -d -m 0700 -o openvalut -g openvalut /opt/openvalut-server/keys

# 3) 复用老 Go 服务的服务器密钥，保证 /api/server-key 不漂移
if [ ! -f /opt/openvalut-server/keys/server_key.bin ] &&
   [ -f /opt/openvalut-server/keys/server_key.bin ]; then
  cp /opt/openvalut-server/keys/server_key.bin /opt/openvalut-server/keys/server_key.bin
  chown openvalut:openvalut /opt/openvalut-server/keys/server_key.bin
  chmod 0600 /opt/openvalut-server/keys/server_key.bin
fi

# 4) 环境变量文件：从老 openvalut 配置迁移 DSN / PUBLISH_KEY
if [ ! -f /etc/default/openvalut-server ]; then
  : > /etc/default/openvalut-server
  if [ -f /etc/openvalut-server.env ]; then
    sed -n 's/^openvalut_MYSQL_DSN=/OPENVALUT_DSN=/p' /etc/openvalut-server.env \
      >> /etc/default/openvalut-server
  fi
  if [ -f /etc/systemd/system/openvalut-server.service ]; then
    sed -n 's/.*Environment="PUBLISH_KEY=\(.*\)".*/PUBLISH_KEY=\1/p' \
      /etc/systemd/system/openvalut-server.service >> /etc/default/openvalut-server
  fi
  chmod 0600 /etc/default/openvalut-server
fi
if ! grep -q '^OPENVALUT_DSN=' /etc/default/openvalut-server; then
  echo "ERROR: OPENVALUT_DSN 缺失于 /etc/default/openvalut-server" >&2
  exit 1
fi

# 5) 停掉老的 Go openvalut-server，释放 18080 端口（幂等）
if [ -f /etc/systemd/system/openvalut-server.service ]; then
  systemctl stop openvalut-server.service 2>/dev/null || true
  systemctl disable openvalut-server.service 2>/dev/null || true
fi

# 6) 安装二进制与服务
install -m 0755 "$BIN_TMP" "$REMOTE_BIN"
install -m 0644 "$SVC_TMP" "$REMOTE_SERVICE"
systemctl daemon-reload
systemctl enable openvalut-server
systemctl restart openvalut-server
sleep 2
systemctl is-active openvalut-server
REMOTE

REMOTE_USER="$("${SSH_CMD[@]}" "$HOST" 'id -un')"
if [[ "$REMOTE_USER" == "root" ]]; then
  echo "==> [$HOST] 以 root 执行安装"
  "${SSH_CMD[@]}" "$HOST" "bash $REMOTE_SCRIPT '$REMOTE_BIN_TMP' '$REMOTE_SVC_TMP'"
else
  echo "==> [$HOST] 以 sudo($REMOTE_USER) 执行安装"
  if [[ ! -f "$SUDO_PASS_FILE" ]]; then
    echo "ERROR: sudo 密码文件不存在: $SUDO_PASS_FILE" >&2
    exit 1
  fi
  # sudo 密码从 stdin 读取（不写入命令行），脚本作为文件参数传给 sudo bash。
  "${SSH_CMD[@]}" "$HOST" \
    "sudo -S bash $REMOTE_SCRIPT '$REMOTE_BIN_TMP' '$REMOTE_SVC_TMP'" < "$SUDO_PASS_FILE"
fi

echo "==> [$HOST] 健康检查"
if ! "${SSH_CMD[@]}" "$HOST" 'curl -fsS http://127.0.0.1:18080/healthz'; then
  echo "ERROR: [$HOST] 健康检查失败" >&2
  echo "==> 查看最近日志：ssh $HOST 'journalctl -u openvalut-server -n 40'" >&2
  exit 1
fi
echo

REMOTE_SHA="$("${SSH_CMD[@]}" "$HOST" "sha256sum /opt/openvalut-server/openvalut-server | awk '{print \$1}'")"
if [[ "$REMOTE_SHA" != "$LOCAL_SHA" ]]; then
  echo "ERROR: [$HOST] sha256 不一致: $REMOTE_SHA" >&2
  exit 1
fi
echo "==> 部署完成，sha256 一致: $REMOTE_SHA"

# 清理本次上传的临时文件（均为登录用户所有，安全）。
"${SSH_CMD[@]}" "$HOST" \
  "rm -f '$REMOTE_SCRIPT' '$REMOTE_BIN_TMP' '$REMOTE_SVC_TMP'" || true
