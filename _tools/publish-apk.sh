#!/usr/bin/env bash
# 构建并发布 openvalut Android APK 到 openvalut-server（OSS 私有桶 + 版本记录）。
#
# 用法:
#   CHANGELOG="修复xxx" ./_tools/publish-apk.sh 1.9.13+191 [--install]
#
# 版本号格式必须是 <versionName>+<versionCode>，例如 1.9.13+191；
# 脚本会同步更新 pubspec.yaml 的 version，保证 App 自身版本与发布一致。
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:?用法: publish-apk.sh <versionName+versionCode> [--install]}"
INSTALL="${2:-}"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]]; then
  echo "版本号格式错误: $VERSION（应为 1.9.13+191 形式）" >&2
  exit 1
fi
VERSION_NAME="${VERSION%+*}"
VERSION_CODE="${VERSION#*+}"

# 读取私有配置（服务器地址等）
if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

# 发布密钥：本地文件优先，其次环境变量
PUBLISH_KEY=""
if [ -f "$HOME/.config/openvalut/publish.key" ]; then
  PUBLISH_KEY="$(cat "$HOME/.config/openvalut/publish.key")"
elif [ -n "${openvalut_PUBLISH_KEY:-}" ]; then
  PUBLISH_KEY="$openvalut_PUBLISH_KEY"
fi
if [ -z "$PUBLISH_KEY" ]; then
  echo "缺少发布密钥（~/.config/openvalut/publish.key 或 openvalut_PUBLISH_KEY）" >&2
  exit 1
fi

# 1. 同步 App 版本号
echo "==> 更新版本号为 $VERSION"
sed -i "s/^version: .*/version: ${VERSION}/" openvalut/pubspec.yaml

# 2. 构建 APK
echo "==> 构建 APK..."
cd openvalut
flutter build apk --release -t lib/env/custom_sideload.dart \
  --dart-define=openvalut_CLOUD_URI="${openvalut_CLOUD_URI:-}" 2>&1 | tail -3
APK="build/app/outputs/flutter-apk/app-sideload-release.apk"
if [ ! -f "$APK" ]; then
  APK="build/app/outputs/apk/sideload/release/app-sideload-release.apk"
fi
echo "==> APK: $APK ($(du -h "$APK" | cut -f1))"

# 3. 发布到 openvalut-server
echo "==> 发布 $VERSION ..."
RESPONSE="$(curl -sS --max-time 300 -X POST \
  "${openvalut_CLOUD_URI:-https://openvalut.example.com}/api/versions/publish" \
  -H "X-Publish-Key: $PUBLISH_KEY" \
  -F "platform=android" \
  -F "versionName=$VERSION_NAME" \
  -F "versionCode=$VERSION_CODE" \
  -F "changelog=${CHANGELOG:-}" \
  -F "file=@$APK")"
echo "==> 发布响应: $RESPONSE"

# 4. 可选：adb 安装到已连接设备
if [ "$INSTALL" == "--install" ]; then
  echo "==> adb 安装..."
  adb install -r "$APK"
fi

echo "==> 完成: $VERSION"
