#!/usr/bin/env bash
# Builds a openvalut .deb for local installation on Debian/Ubuntu/Deepin.
#
# Requires the Flutter Linux desktop toolchain:
#   sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev \
#        libsecret-1-dev liblzma-dev
# and a Rust toolchain (cargo) for the standalone openvalut-cli.
#
# Usage: ./_tools/build-deb.sh [version]
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-1.0.0}"
ARCH="amd64"

# 从本地 .env 读取私有值（域名等），通过 --dart-define 注入，不硬编码进源码。
if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi
DART_DEFINES=""
if [ -n "${openvalut_CLOUD_URI:-}" ]; then
  DART_DEFINES="$DART_DEFINES --dart-define=openvalut_CLOUD_URI=$openvalut_CLOUD_URI"
fi
if [ -n "${openvalut_CONTACT_EMAIL:-}" ]; then
  DART_DEFINES="$DART_DEFINES --dart-define=openvalut_CONTACT_EMAIL=$openvalut_CONTACT_EMAIL"
fi
if [ -n "${openvalut_WEBSITE_URL:-}" ]; then
  DART_DEFINES="$DART_DEFINES --dart-define=openvalut_WEBSITE_URL=$openvalut_WEBSITE_URL"
fi

cd openvalut
# Build & bundle the Linux PAM module + sudo askpass into Flutter assets so
# the app can auto-configure computer two-step verification at runtime.
(cd ../linux/pam_openvalut && cargo build --release --quiet)
mkdir -p assets/linux
install -m 0644 ../linux/pam_openvalut/target/release/libpam_openvalut.so \
    assets/linux/pam_openvalut.so
install -m 0755 ../linux/openvalut-sudo-askpass assets/linux/openvalut-sudo-askpass

flutter build linux --release -t lib/env/custom_desktop.dart $DART_DEFINES
# The SSH agent bridge (Unix socket -> loopback TCP) ships next to the app.
cc -O2 -o build/linux/x64/release/bundle/openvalut-agent-bridge linux/agent_bridge.c
# The CLI reads usernames/passwords/TOTP from the unlocked vault.
(cd .. && cargo build -p openvalut-cli --release --quiet)
cp ../target/release/openvalut-cli build/linux/x64/release/bundle/openvalut-cli
# The Chrome native-messaging host reads unlocked vaults via the app bridge.
(cd .. && cargo build -p openvalut-host --release --quiet)
cp ../target/release/openvalut-host build/linux/x64/release/bundle/openvalut-host
cd ..

rm -rf debian/opt/openvalut debian/usr/lib/openvalut debian/lib/x86_64-linux-gnu/security
mkdir -p debian/opt/openvalut
cp -r openvalut/build/linux/x64/release/bundle/* debian/opt/openvalut/
cp packaging/openvalut-icon.png debian/opt/openvalut/icon.png

# Sudo askpass helper: agents can obtain the sudo password after TOTP.
# NOTE: `/usr/lib` may be a read-only overlay on Deepin, so install the helper
# under `/opt/openvalut` (writable) instead of `/usr/lib/openvalut`.
mkdir -p debian/opt/openvalut
install -m 0755 linux/openvalut-sudo-askpass debian/opt/openvalut/openvalut-sudo-askpass

# Experimental PAM module for login/sudo TOTP verification.
(cd linux/pam_openvalut && cargo build --release --quiet)
mkdir -p debian/lib/x86_64-linux-gnu/security
install -m 0644 linux/pam_openvalut/target/release/libpam_openvalut.so \
    debian/lib/x86_64-linux-gnu/security/pam_openvalut.so
# The app's auto-config (and /etc/pam.d/sudo) reference the module under
# /opt/openvalut/pam, so ship it there as well.
mkdir -p debian/opt/openvalut/pam
install -m 0644 linux/pam_openvalut/target/release/libpam_openvalut.so \
    debian/opt/openvalut/pam/pam_openvalut.so

# Chrome / Chromium native messaging host registration.
mkdir -p debian/etc/opt/chrome/native-messaging-hosts \
         debian/etc/chromium/native-messaging-hosts
cat > debian/etc/opt/chrome/native-messaging-hosts/design.codeux.openvalut.json <<'EOF'
{
  "name": "design.codeux.openvalut",
  "description": "openvalut native messaging host",
  "path": "/opt/openvalut/openvalut-host",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://hnjmpepmjglmnfifjhomiadmbdpdfkik/"]
}
EOF
cp debian/etc/opt/chrome/native-messaging-hosts/design.codeux.openvalut.json \
   debian/etc/chromium/native-messaging-hosts/design.codeux.openvalut.json

sed -i "s/^Version: .*/Version: ${VERSION}/" debian/DEBIAN/control
dpkg-deb --build --root-owner-group debian "openvalut_${VERSION}_${ARCH}.deb"

echo "DEB: openvalut_${VERSION}_${ARCH}.deb"
