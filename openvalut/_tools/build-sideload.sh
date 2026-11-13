#!/usr/bin/env bash
# Builds the sideload (direct APK) flavor for local installs.
#
# The env entrypoint must be passed explicitly: `flutter build` always forwards
# -Ptarget=lib/main.dart, which overrides any flavor-level
# `project.flutter.target` setting, and lib/main.dart intentionally throws
# ("Run some env/*.dart").
#
# Release signing credentials are read from the OpenValut vault so the key
# survives machine loss:
#
#   vault  我的密码库  (group 计算机)
#   entry  OpenValut Android 签名密钥
#     password -> ANDROID_KEYSTORE_PASSWORD / ANDROID_KEY_PASSWORD
#     username -> key alias (openvalut)
#     url      -> keystore path relative to android/ (app/openvalut-release-*.keystore)
#     notes    -> base64 of the keystore itself (recovery copy)
#
# The app must be running and unlocked (credential-server token present), or
# the build falls back to android/.env, which build.gradle still reads.
set -euo pipefail
cd "$(dirname "$0")/.."

# Flutter is often installed outside the default PATH (e.g. /usr/local/flutter
# with only FLUTTER_ROOT exported). Resolve it before the first invocation so
# both the vault-backed attempt and the android/.env fallback can run.
if ! command -v flutter >/dev/null 2>&1; then
  for flutterBin in \
    "${FLUTTER_ROOT:-}/bin" \
    /usr/local/flutter/bin \
    /opt/flutter/bin \
    "$HOME/flutter/bin" \
    "$HOME/.local/opt/flutter/bin"
  do
    if [[ -x "$flutterBin/flutter" ]]; then
      export PATH="$flutterBin:$PATH"
      break
    fi
  done
fi
if ! command -v flutter >/dev/null 2>&1; then
  echo "error: 找不到 flutter，请先安装或把 flutter/bin 加入 PATH" >&2
  exit 1
fi

VAULT="我的密码库"
ENTRY="OpenValut Android 签名密钥"
KS_REL="app/openvalut-release-2026.keystore"
KS_FILE="android/${KS_REL}"

# If the keystore file is missing, restore it from the vault notes (base64).
if [ ! -f "$KS_FILE" ]; then
  echo "==> keystore 缺失，从 OpenValut 恢复: $KS_FILE"
  openvalut-cli run \
    --env OV_KS_B64="op://${VAULT}/${ENTRY}/notes" \
    -- bash -c 'base64 -d <<<"$OV_KS_B64" > "$1"' _ "$KS_FILE"
fi

# Signing secrets must never hit argv; openvalut-cli run resolves the refs and
# injects them as environment variables only. Non-secret settings are exported
# here and inherited by the child.
export ANDROID_KEYSTORE_PATH="$KS_REL"
export ANDROID_KEY_ALIAS="openvalut"
if openvalut-cli run \
  --env ANDROID_KEYSTORE_PASSWORD="op://${VAULT}/${ENTRY}/password" \
  --env ANDROID_KEY_PASSWORD="op://${VAULT}/${ENTRY}/password" \
  -- flutter build apk --release --flavor sideload -t lib/env/custom_sideload.dart "$@"
then
  echo "APK: build/app/outputs/flutter-apk/app-sideload-release.apk"
else
  rc=$?
  echo "warning: 无法从 OpenValut 读取签名凭据（rc=$rc），回退到 android/.env" >&2
  flutter build apk --release --flavor sideload -t lib/env/custom_sideload.dart "$@"
  echo "APK: build/app/outputs/flutter-apk/app-sideload-release.apk"
fi
