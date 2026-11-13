#!/usr/bin/env bash
# 构建 PC 端 deb 并安装到本机（Deepin/Debian）。
# 用法: ./_tools/install-pc.sh [版本号]
#   版本号省略时自动取已安装版本 +1（如 1.9.49 -> 1.9.50）。
#
# sudo 密码从本地文件读取（不写进命令行）：默认
#   ~/.config/openvalut/sudo.pass
# 可用环境变量 OPENVALUT_SUDO_PASS 或 openvalut_SUDO_PASS 覆盖，
# 遗留路径 ~/.config/openvalut/sudo.pass 仍可作为后备。
set -euo pipefail
cd "$(dirname "$0")/.."

SUDO_PASS_FILE="${OPENVALUT_SUDO_PASS:-${openvalut_SUDO_PASS:-${HOME}/.config/openvalut/sudo.pass}}"
if [[ ! -f "$SUDO_PASS_FILE" && -f "${HOME}/.config/openvalut/sudo.pass" ]]; then
  SUDO_PASS_FILE="${HOME}/.config/openvalut/sudo.pass"
fi
if [[ ! -f "$SUDO_PASS_FILE" ]]; then
  echo "ERROR: sudo 密码文件不存在: $SUDO_PASS_FILE" >&2
  exit 1
fi

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  installed="$(dpkg-query -W -f='${Version}' openvalut 2>/dev/null || true)"
  if [[ "$installed" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.$((BASH_REMATCH[3] + 1))"
  else
    echo "ERROR: 无法自动推断版本，请显式传入，例如 ./_tools/install-pc.sh 1.9.50" >&2
    exit 1
  fi
fi

echo "==> 构建 deb openvalut_${VERSION}_amd64.deb"
./_tools/build-deb.sh "$VERSION"

echo "==> 安装 deb"
sudo -S dpkg -i "openvalut_${VERSION}_amd64.deb" < "$SUDO_PASS_FILE"

# build-deb.sh 会改写 debian/DEBIAN/control 的版本号，装完后还原。
git checkout -- debian/DEBIAN/control 2>/dev/null || true

dpkg -l | grep -E '^ii\s+openvalut'
echo "==> PC 端安装完成"
