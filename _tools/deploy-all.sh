#!/usr/bin/env bash
# 一键发布 OpenValut：PC deb（含桌面端、CLI、Chrome 原生消息宿主）+ Android APK
# （构建 + 上传阿里云 OSS + 可选 adb 安装）+ 服务端编译发布（openvalut-server.example.com）。
#
# 各部分可单独执行：
#   _tools/install-pc.sh        PC deb（桌面端 + openvalut-cli + Chrome host 注册）
#   _tools/publish-apk.sh       Android APK 构建 + 上传阿里云 OSS（可选 adb 安装）
#   _tools/deploy-server.sh     服务端 musl 编译 + 上传 + systemd 重启
#
# APK 版本号取环境变量 APK_VERSION（默认读 openvalut/pubspec.yaml 的 version），
# 更新说明用 CHANGELOG 传入，例如:
#   APK_VERSION=1.9.14+192 CHANGELOG="修复xxx" ./_tools/deploy-all.sh
#
# 用法:
#   ./_tools/deploy-all.sh                 # 全部执行
#   ./_tools/deploy-all.sh --no-apk        # 不构建/上传 APK
#   ./_tools/deploy-all.sh --no-server     # 不部署服务端
#   ./_tools/deploy-all.sh --no-deb        # 不构建/安装 PC deb
#   ./_tools/deploy-all.sh --no-install    # APK 上传 OSS，但不 adb 安装到设备
#   ./_tools/deploy-all.sh --no-oss        # APK 只构建+安装设备，不上传 OSS
set -euo pipefail
cd "$(dirname "$0")/.."

DO_DEB=true
DO_APK=true
DO_SERVER=true
DO_INSTALL=true
DO_OSS=true

while [ $# -gt 0 ]; do
  case "$1" in
    --no-deb) DO_DEB=false; shift ;;
    --no-apk) DO_APK=false; shift ;;
    --no-server) DO_SERVER=false; shift ;;
    --no-install) DO_INSTALL=false; shift ;;
    --no-oss) DO_OSS=false; shift ;;
    -h|--help) sed -n '1,18p' "$0"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done

echo "========== OpenValut 一键发布开始 =========="

if [ "$DO_DEB" = true ]; then
  echo "---- [1] PC deb：构建并安装（含 openvalut-cli、Chrome 原生消息宿主注册） ----"
  ./_tools/install-pc.sh
else
  echo "---- [1] PC deb：跳过 (--no-deb) ----"
fi

echo "---- [2] 校验 openvalut-cli ----"
if command -v openvalut-cli >/dev/null 2>&1; then
  echo "    openvalut-cli -> $(command -v openvalut-cli)"
else
  echo "    WARN: openvalut-cli 不在 PATH，请确认 deb 已安装" >&2
fi

echo "---- [3] 校验 Chrome 原生消息宿主 ----"
HOST_JSON="/etc/opt/chrome/native-messaging-hosts/design.codeux.openvalut.json"
if [ -f "$HOST_JSON" ]; then
  echo "    Chrome host 已注册: $HOST_JSON"
else
  echo "    WARN: 未找到 $HOST_JSON，Chrome 扩展将无法调用宿主" >&2
fi

if [ "$DO_APK" = true ]; then
  if [ "$DO_OSS" = true ]; then
    APK_VERSION="${APK_VERSION:-$(grep '^version:' openvalut/pubspec.yaml | awk '{print $2}')}"
    if [[ ! "$APK_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]]; then
      echo "ERROR: APK 版本号格式错误: $APK_VERSION（应为 1.9.14+192 形式）" >&2
      echo "  请用 APK_VERSION=1.9.14+192 ./_tools/deploy-all.sh 显式指定" >&2
      exit 1
    fi
    INSTALL_ARGS=""
    if [ "$DO_INSTALL" = true ]; then
      INSTALL_ARGS="--install"
    fi
    # shellcheck disable=SC2086
    echo "---- [4] Android APK：构建 + 上传阿里云 OSS${DO_INSTALL:+ + adb 安装} (${APK_VERSION}) ----"
    CHANGELOG="${CHANGELOG:-}" ./_tools/publish-apk.sh "$APK_VERSION" $INSTALL_ARGS
  elif [ "$DO_INSTALL" = false ]; then
    echo "ERROR: --no-oss 与 --no-install 同时指定时 APK 将无事可做" >&2
    exit 2
  else
    echo "---- [4] Android APK：构建并安装到已连接设备（--no-oss，不上传 OSS） ----"
    ./_tools/install-android.sh
  fi
else
  echo "---- [4] Android APK：跳过 (--no-apk) ----"
fi

if [ "$DO_SERVER" = true ]; then
  echo "---- [5] 服务端：编译并发布到 openvalut-server.example.com ----"
  ./_tools/deploy-server.sh
else
  echo "---- [5] 服务端：跳过 (--no-server) ----"
fi

echo "========== OpenValut 一键发布完成 =========="
