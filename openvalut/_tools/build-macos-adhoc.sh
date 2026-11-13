#!/usr/bin/env bash
# Build OpenValut macOS DMG with ad-hoc signing.
# Usage: ./_tools/build-macos-adhoc.sh [--no-dmg]
#
# Prerequisites:
#   - Flutter SDK at ~/.local/lib/flutter/bin (set FLUTTER_ROOT to override)
#   - Xcode (with command-line tools)
#
# Output: ../OpenValut-<version>-<arch>.dmg

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_NUMBER="193"

# ---------- helpers ----------
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
info()  { printf '\033[36m==> %s\033[0m\n' "$*"; }

# ---------- resolve Flutter ----------
FLUTTER_BIN="${FLUTTER_ROOT:-$HOME/.local/lib/flutter/bin}/flutter"
if [ ! -x "$FLUTTER_BIN" ]; then
  red "Flutter not found at $FLUTTER_BIN"
  red "Set FLUTTER_ROOT env var to the Flutter SDK directory."
  exit 1
fi
info "Flutter: $("$FLUTTER_BIN" --version 2>&1 | head -1)"

# ---------- read version ----------
cd "$PROJECT_DIR"
VERSION=$("$FLUTTER_BIN" pub deps --json 2>/dev/null | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d['root']['version'])
" 2>/dev/null || echo "1.9.14")
APP_NAME="OpenValut"
ARCH="arm64"
DMG_NAME="${APP_NAME}-${VERSION}-${ARCH}"
ENTITLEMENTS_FILE="/tmp/ov-adhoc.entitlements"

info "Version: $VERSION  Build: $BUILD_NUMBER  Arch: $ARCH"

# ---------- create ad-hoc entitlements ----------
cat > "$ENTITLEMENTS_FILE" << 'ENTITLEMENTS'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.cs.allow-jit</key>
	<true/>
	<key>com.apple.security.files.downloads.read-write</key>
	<true/>
	<key>com.apple.security.files.user-selected.read-write</key>
	<true/>
	<key>com.apple.security.network.client</key>
	<true/>
	<key>com.apple.security.files.bookmarks.app-scope</key>
	<true/>
</dict>
</plist>
ENTITLEMENTS

# ---------- Flutter config ----------
info "Flutter build config-only..."
"$FLUTTER_BIN" build macos --release --config-only \
  -t lib/env/custom_desktop.dart \
  --build-name "$VERSION" \
  --build-number "$BUILD_NUMBER" \
  --dart-define=openvalut_CLOUD_URI=

# ---------- xcodebuild (ad-hoc) ----------
info "xcodebuild (ad-hoc signing)..."
xcodebuild -workspace macos/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath build/macos/DerivedData \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="" \
  PROVISIONING_PROFILE_SPECIFIER="" \
  CODE_SIGN_ENTITLEMENTS="$ENTITLEMENTS_FILE" \
  ENABLE_HARDENED_RUNTIME=NO \
  build

APP_BUNDLE="build/macos/DerivedData/Build/Products/Release/${APP_NAME}.app"
if [ ! -d "$APP_BUNDLE" ]; then
  red "Build failed: .app not found at $APP_BUNDLE"
  exit 1
fi
green "Build OK: $APP_BUNDLE"

# ---------- verify ----------
codesign -dv "$APP_BUNDLE" 2>&1 | grep -i "identifier\|signature" || true
info "App size: $(du -sh "$APP_BUNDLE" | cut -f1)"

# ---------- DMG ----------
if [ "${1:-}" = "--no-dmg" ]; then
  info "Skipping DMG (--no-dmg)."
  exit 0
fi

info "Creating DMG..."
DMG_TMP="build/${DMG_NAME}.tmp.dmg"
DMG_OUT="../${DMG_NAME}.dmg"
rm -f "$DMG_OUT" "$DMG_TMP"

mkdir -p build/dmg
cp -R "$APP_BUNDLE" "build/dmg/${APP_NAME}.app"
ln -sf /Applications "build/dmg/Applications"

hdiutil create -volname "$APP_NAME" \
  -srcfolder "build/dmg" \
  -ov -format UDRW "$DMG_TMP" >/dev/null

hdiutil convert "$DMG_TMP" \
  -format UDZO -imagekey zlib-level=9 \
  -o "$DMG_OUT" >/dev/null

rm -f "$DMG_TMP"
rm -rf build/dmg

hdiutil verify "$DMG_OUT" >/dev/null 2>&1
green "DMG: $(realpath "$DMG_OUT")  ($(du -sh "$DMG_OUT" | cut -f1))"