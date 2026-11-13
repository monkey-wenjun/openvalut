#!/usr/bin/env bash
# Build an arm64 macOS DMG with the local Apple Development identity.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FLUTTER_BIN="${FLUTTER_ROOT:-$HOME/.local/lib/flutter/bin}/flutter"
TEAM_ID="VCDMB9S3N2"
APP_NAME="OpenValut"
BUILD_NUMBER="193"

if [ ! -x "$FLUTTER_BIN" ]; then
  echo "Flutter not found at $FLUTTER_BIN" >&2
  exit 1
fi

cd "$PROJECT_DIR"
VERSION="$(
  sed -nE 's/^version:[[:space:]]*([^+[:space:]]+).*/\1/p' pubspec.yaml |
    head -1
)"
if [ -z "$VERSION" ]; then
  echo "Unable to read the application version from pubspec.yaml" >&2
  exit 1
fi
DERIVED_DATA="build/macos/DerivedData-signed"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Release/$APP_NAME.app"
DMG_NAME="$APP_NAME-$VERSION-arm64"
DMG_TMP="build/$DMG_NAME.tmp.dmg"
DMG_OUT="../$DMG_NAME.dmg"
DMG_STAGE="build/dmg-development"

"$FLUTTER_BIN" build macos --release --config-only \
  -t lib/env/custom_desktop.dart \
  --build-name "$VERSION" \
  --build-number "$BUILD_NUMBER" \
  --dart-define=openvalut_CLOUD_URI=

mkdir -p .tmp/xcode "$DERIVED_DATA"
TMPDIR="$PROJECT_DIR/.tmp/xcode/" xcodebuild \
  -workspace macos/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED_DATA" \
  -allowProvisioningUpdates \
  ONLY_ACTIVE_ARCH=YES \
  ARCHS=arm64 \
  EXCLUDED_ARCHS=x86_64 \
  build

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
signature_info="$(codesign -dv --verbose=4 "$APP_BUNDLE" 2>&1)"
grep -q "TeamIdentifier=$TEAM_ID" <<<"$signature_info" || {
  echo "Unexpected signing team:" >&2
  echo "$signature_info" >&2
  exit 1
}

entitlements="$(mktemp)"
trap 'rm -f "$entitlements"' EXIT
codesign -d --entitlements :- "$APP_BUNDLE" >"$entitlements" 2>/dev/null
plutil -extract keychain-access-groups xml1 -o - "$entitlements" |
  grep -q "$TEAM_ID.app.openvalut" || {
    echo "OpenValut Keychain access group is missing." >&2
    exit 1
  }
if [ "$(plutil -extract 'com\.apple\.security\.network\.server' raw -o - "$entitlements")" != "true" ]; then
  echo "The signed application cannot bind its single-instance socket." >&2
  exit 1
fi

rm -rf "$DMG_STAGE"
rm -f "$DMG_TMP" "$DMG_OUT"
mkdir -p "$DMG_STAGE"
ditto "$APP_BUNDLE" "$DMG_STAGE/$APP_NAME.app"
ln -s /Applications "$DMG_STAGE/Applications"
hdiutil create -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGE" -ov -format UDRW "$DMG_TMP" >/dev/null
hdiutil convert "$DMG_TMP" \
  -format UDZO -imagekey zlib-level=9 -o "$DMG_OUT" >/dev/null
hdiutil verify "$DMG_OUT" >/dev/null
rm -f "$DMG_TMP"
rm -rf "$DMG_STAGE"

echo "DMG: $(realpath "$DMG_OUT")"
shasum -a 256 "$DMG_OUT"
