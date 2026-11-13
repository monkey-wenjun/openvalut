#!/usr/bin/env bash
# 构建 sideload APK 并安装到已连接的 Android 设备。
# 签名凭据从 OpenValut 读取（见 openvalut/_tools/build-sideload.sh），
# App 需已运行并解锁；否则回退到 openvalut/android/.env。
# 用法: ./_tools/install-android.sh
set -euo pipefail
cd "$(dirname "$0")/.."

if ! adb get-state >/dev/null 2>&1; then
  echo "ERROR: 未检测到 Android 设备（adb devices）" >&2
  exit 1
fi

start="$(date +%s)"
echo "==> 构建 sideload APK（openvalut/_tools/build-sideload.sh）"
openvalut/_tools/build-sideload.sh >/tmp/openvalut-apk-build.log 2>&1 || true
tail -5 /tmp/openvalut-apk-build.log

APK="openvalut/build/app/outputs/apk/sideload/release/app-sideload-release.apk"
if [[ ! -f "$APK" ]]; then
  APK="openvalut/build/app/outputs/flutter-apk/app-sideload-release.apk"
fi
if [[ ! -f "$APK" ]] || [[ "$(stat -c %Y "$APK")" -lt "$start" ]]; then
  echo "ERROR: APK 未生成，构建日志见 /tmp/openvalut-apk-build.log" >&2
  exit 1
fi

echo "==> 安装 APK: $APK"
adb install -r "$APK"
echo "==> 已安装完成"
