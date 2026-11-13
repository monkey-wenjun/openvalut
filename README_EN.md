# OpenValut

> Open-source, self-hosted, end-to-end encrypted password manager. The server is written in Rust.

OpenValut gives you full control over your passwords: the master password is only used on
your device, and the server stores nothing but encrypted vaults it cannot decrypt. It speaks
the standard KeePass format (KDBX 3.x / 4.x), imports data from 1Password and other managers,
and can share entries end-to-end encrypted with family members.

The project is released under [GPL-3.0-or-later](LICENSE). Client, server, CLI, browser
extension and native host are all open source and auditable.

---

## Table of Contents

- [Core Features](#core-features)
- [Security Design](#security-design)
- [Technology Stack](#technology-stack)
- [Project Layout](#project-layout)
- [Build & Run](#build--run)
- [Server Configuration](#server-configuration)
- [Deployment](#deployment)
- [Android Signing](#android-signing)
- [Pre-Publish Checks](#pre-publish-checks)
- [Documentation](#documentation)
- [License](#license)

---

## Core Features

- **End-to-end encryption**: Argon2id key derivation and AES-256-GCM vault encryption;
  the master password and derived keys never leave the device.
- **Self-hosted sync**: Rust server with SQLite by default, MySQL / PostgreSQL optional;
  it only ever stores ciphertext.
- **Cross-platform clients**: Flutter (Android / iOS / Windows / macOS / Linux) plus a
  Tauri desktop app.
- **KeePass compatible**: Native KDBX 3.x / 4.x read and write, so KeePass vaults migrate directly.
- **Autofill**: Android autofill service, Chrome / Chromium extension, and an iOS credential
  provider (Face ID / Touch ID).
- **Passkeys**: The browser extension creates and uses ES256 passkeys; private keys stay in
  the local KDBX vault.
- **Secure sharing**: Entries are encrypted with a random share key, which is wrapped with the
  recipient's X25519 public key.
- **SSH Agent**: A 1Password-style in-memory SSH agent supporting ed25519 and RSA.
- **Local credential service**: Scripts read usernames, passwords and TOTP codes over a
  loopback service without writing secrets to environment variables or files.
- **Linux sudo 2FA**: TOTP plus `openvalut-sudo-askpass`, or an optional PAM module.

---

## Security Design

The core assumption is that **the server is untrusted**. If it is compromised, an attacker
gets ciphertext only.

### End-to-end Encryption

| Item | Implementation |
|---|---|
| Key derivation (KDF) | Argon2id, 64 MiB memory, 3 iterations, 4 lanes, 32-byte output |
| Symmetric encryption | AES-256-GCM with a random 12-byte nonce |
| Vault format | Standard KDBX 3.x / 4.x, encrypted and decrypted on the client |
| Extra cloud layer | Argon2id + AES-256-GCM on top of KDBX, salted with the vault id |

- The master password is only used in local memory. It is never sent over the network or
  written to the server or disk.
- The server database stores only `nonce + ciphertext` and holds no keys.
- Metadata such as vault and group names is encrypted before upload.

### Transport & Authentication

- **Envelope encryption**: X25519 ECDH on native clients (P-256 in browsers); request and
  response bodies are encrypted separately.
- **Request signing**: Every request carries an HMAC signature and timestamp to prevent
  tampering and replay.
- **Authentication**: Account plus Secret Key login, 30-day Bearer token, automatic refresh
  on 401.

### Sharing

- The client generates a random share key and encrypts a copy of the entry with it.
- The share key is wrapped with the recipient's X25519 public key before upload.
- The server only stores the wrapped key and ciphertext, so it cannot read shared entries.

### Local Security

| Scenario | Measure |
|---|---|
| Vault unlock | Master password lives in memory only and is zeroed on lock |
| Biometrics / quick unlock | Transformed key stored in the system Keychain / Keystore |
| SSH Agent | Keys live in memory only while unlocked; the agent stops and its socket is removed on lock or exit |
| Local credential service | Listens on `127.0.0.1` with 0600 socket / token files |
| Browser extension | KDBX decryption happens in a separate native host process; keys are cleared on screen lock or browser exit |
| Passkeys | Private keys are generated and stored in the local vault; signing happens inside the native host |
| Autofill | Only real visible inputs are filled; already-filled fields are skipped |

### Server

- Performs authentication, ciphertext storage and forwarding only; it holds no decryption keys.
- Production MySQL runs with `innodb_flush_log_at_trx_commit=1`, `sync_binlog=1`,
  doublewrite and binlog, so acknowledged writes survive a crash.
- Vault deletion cascades transactionally over entries and shares.
- Release artifacts live in private object storage; clients fetch a short-lived signed URL
  and verify SHA-256.
- Domains, database passwords and object-storage keys are injected via environment variables
  and never committed.

---

## Technology Stack

| Component | Technology |
|---|---|
| Server | Rust · axum · tokio · sqlx (SQLite / MySQL / PostgreSQL) |
| Crypto & KDBX | Rust · argon2 · aes-gcm · x25519-dalek · keepass |
| CLI / native host | Rust |
| Desktop | Tauri 2 + React (`crates/openvalut-desktop/ui`) |
| Mobile / cross-platform app | Flutter + Dart |
| Browser extension | Chrome Manifest V3 (plain JS) |

---

## Project Layout

```text
.
├── crates/
│   ├── openvalut-core/      # Crypto primitives, KDBX read/write, shared models
│   ├── openvalut-server/    # Self-hosted sync/share server (axum + sqlx)
│   ├── openvalut-cli/       # CLI, SSH agent, local credential service
│   ├── openvalut-host/      # Chrome native messaging host
│   ├── openvalut-desktop/   # Tauri 2 desktop app (Rust + React UI)
│   ├── openvalut-mobile/    # Rust FFI bridge for Flutter
│   └── openvalut-ui/        # Shared Rust UI components
├── openvalut/               # Flutter app (Android / iOS / Linux / macOS / Windows)
├── chrome_extension/        # Chrome / Chromium extension
├── autofill_module/         # Android / iOS autofill modules
├── autofill_shared/         # Domain / package matching logic (Dart)
├── linux/                   # PAM module and sudo askpass helper
├── docs/                    # Usage and development docs
├── _tools/                  # Build, packaging and deployment scripts
└── vendor/keepass/          # Locally patched keepass crate
```

---

## Build & Run

Requirements: Rust 1.80+, Node.js 20+ (desktop UI), Flutter 3.x (mobile).

### Server

```bash
cargo build --release -p openvalut-server

./target/release/openvalut-server \
  -addr 127.0.0.1:18080 \
  -db sqlite \
  -dsn openvalut.db
```

On first start the server generates an X25519 transport key (default
`/opt/openvalut-server/keys/server_key.bin`, mode 0600). Health check:

```bash
curl -fsS http://127.0.0.1:18080/healthz
```

### CLI

```bash
cargo build --release -p openvalut-cli

./target/release/openvalut-cli list
./target/release/openvalut-cli get github
./target/release/openvalut-cli totp github
./target/release/openvalut-cli agent add my-ssh
```

See [docs/credential-server.md](docs/credential-server.md) for more.

### Chrome Native Host

```bash
cargo build --release -p openvalut-host
```

Load the extension from `chrome://extensions/` with Developer mode enabled and
"Load unpacked" pointing at `chrome_extension/`. The deb build registers the native host
automatically via `_tools/build-deb.sh`; for manual registration, point the native-messaging
JSON `path` at `target/release/openvalut-host`.

### Desktop (Tauri)

```bash
cd crates/openvalut-desktop/ui
npm ci
npm run build
cd ../..

cargo build --release -p openvalut-desktop --features tauri/custom-protocol
```

Do not drop `tauri/custom-protocol`: a bare `cargo build` runs in dev mode, points
`WebviewUrl::App` at `http://localhost:5173`, and does not embed `ui/dist`. Verify with
`grep -oa 'assets/index-' <binary>`.

### Flutter App

```bash
cd openvalut
flutter pub get
flutter build apk --release --flavor sideload -t lib/env/custom_sideload.dart
```

### Linux deb

```bash
./_tools/build-deb.sh 0.1.0
sudo dpkg -i openvalut_0.1.0_amd64.deb
```

---

## Server Configuration

### Command-line Options

| Option | Description | Environment variable | Default |
|---|---|---|---|
| `-addr` | Listen address | `OPENVALUT_ADDR` | `0.0.0.0:8080` |
| `-db` | `sqlite` / `mysql` / `postgres` | — | `sqlite` |
| `-dsn` | Database DSN | `OPENVALUT_DSN` | `openvalut.db` |
| `-key-file` | X25519 transport key file | `SERVER_KEY_FILE` | `/opt/openvalut-server/keys/server_key.bin` |
| `-publish-key` | Key required to publish releases | `PUBLISH_KEY` | none |

### Object Storage (Optional)

Used when publishing APK / deb artifacts. All values come from the environment:

```bash
export OSS_ACCESS_KEY_ID='...'
export OSS_ACCESS_KEY_SECRET='...'
export OSS_BUCKET='...'
export OSS_ENDPOINT='...'
```

Never commit real values; `.env` is already in `.gitignore`.

### DSN Examples

```text
mysql://openvalut:<db-password>@127.0.0.1:3306/openvalut?ssl-mode=verify-identity
```

Non-loopback hosts must use `ssl-mode=required` or stronger (`verify-ca` /
`verify-identity`); otherwise the server refuses to start.

```text
postgres://openvalut:<db-password>@127.0.0.1:5432/openvalut
```

---

## Deployment

`crates/openvalut-server/deploy/` contains a minimal production setup:

| File | Purpose |
|---|---|
| `deploy.sh` | Install the binary, create the database, write systemd and nginx config |
| `openvalut.conf` | nginx reverse-proxy template |
| `openvalut-server.service` | systemd unit |

Templates use `openvalut.example.com` / `example.com` placeholders. Replace them with your
own domain and certificate paths before deploying:

```bash
cd crates/openvalut-server/deploy
sudo bash deploy.sh
```

The script assumes the `openvalut-server` binary and deployment files are in the current
directory and that nginx is installed. To reuse an existing MySQL instance, set
`OPENVALUT_MYSQL_ROOT_PW`; override `OPENVALUT_DB_NAME`, `OPENVALUT_DB_USER` and
`OPENVALUT_DB_PASS` as needed.

A lighter single-host setup can use systemd directly:

```bash
install -d -m 700 /opt/openvalut-server/keys
install -m 755 target/release/openvalut-server /opt/openvalut-server/
install -m 644 crates/openvalut-server/deploy/openvalut-server.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now openvalut-server
```

---

## Android Signing

No signing keys are shipped in this repository. Generate your own keystore before a release build:

```bash
keytool -genkeypair -v \
  -keystore my-release.keystore \
  -alias openvalut \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Inject it via environment variables (or a gitignored `openvalut/android/.env`):

```bash
export ANDROID_KEYSTORE_PATH=/absolute/path/to/my-release.keystore
export ANDROID_KEY_ALIAS=openvalut
export ANDROID_KEYSTORE_PASSWORD='...'
export ANDROID_KEY_PASSWORD='...'
```

`*.keystore` and `*.jks` are gitignored; never commit them.

---

## Pre-Publish Checks

Run before publishing the repository:

```bash
./_tools/check-public.sh
```

The script prints only `file:line:rule` and never echoes matched values. It checks for
private IPs, cloud AccessKeys, GitHub / OpenAI / Slack tokens, private-key blocks,
`*.keystore` / `*.jks` / `*.pem` files, and obviously real long values in `.env` files.

Only generic rules are built in. Put your own domains, usernames and hostnames in
`.public-deny` (gitignored), one `rule-name|extended-regexp` per line; see
`.public-deny.example`:

```bash
cp .public-deny.example .public-deny
$EDITOR .public-deny
./_tools/check-public.sh
```

Enable the pre-commit hook:

```bash
git config core.hooksPath .githooks
```

The hook scans staged content only (`--staged`) and blocks the commit on any finding.

---

## Documentation

- [SSH Agent](docs/ssh-agent.md)
- [Credential Service & CLI](docs/credential-server.md)
- [Linux sudo TOTP](docs/linux-totp.md)
- [Apple Signing](docs/apple-signing.md)
- [Autofill](docs/autofill/)

---

## License

[GPL-3.0-or-later](LICENSE).

---

> **Security note**: OpenValut never asks for your master password. Losing your master
> password or Secret Key means the data cannot be recovered, so keep an offline backup.
