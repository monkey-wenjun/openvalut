# OpenValut

> 开源、可自托管、端到端加密的跨平台密码管理器。服务端用 Rust 编写。

OpenValut 让你完全掌控自己的密码：主密码只在本机使用，服务端只保存加密后的
密码库，无法解密任何条目。支持标准 KeePass（KDBX 3.x / 4.x）格式，可从
1Password 等管理器导入数据，也可以把条目端到端加密后分享给家人。

项目以 [GPL-3.0-or-later](LICENSE) 发布，客户端、服务端、CLI、浏览器扩展与
native host 全部开源，可自行审计和二次开发。

本项目基于 CodeUX.design 的 OpenValut（<https://codeux.design/>，GPL-3.0）
继续开发，上游版权与改动范围见 [NOTICE](NOTICE)。

---

## 目录

- [核心特性](#核心特性)
- [安全设计](#安全设计)
- [技术栈](#技术栈)
- [项目结构](#项目结构)
- [构建与运行](#构建与运行)
- [服务端配置](#服务端配置)
- [部署](#部署)
- [Android 签名](#android-签名)
- [发布前自检](#发布前自检)
- [相关文档](#相关文档)
- [开源协议](#开源协议)

---

## 核心特性

- **端到端加密**：主密码经 Argon2id 派生密钥，密码库以 AES-256-GCM 加密；
  主密码与派生密钥不上传、不落盘。
- **自托管同步**：Rust 服务端，默认 SQLite，可选 MySQL / PostgreSQL；只存密文。
- **跨平台客户端**：Flutter（Android / iOS / Windows / macOS / Linux）+ Tauri 桌面端。
- **KeePass 兼容**：原生读写 KDBX 3.x / 4.x，可直接迁移 KeePass 数据。
- **自动填充**：Android 系统自动填充服务、Chrome / Chromium 扩展、
  iOS 凭证提供程序（Face ID / Touch ID）。
- **通行密钥（Passkey）**：浏览器扩展支持创建与使用 ES256 Passkey，私钥保存在本地 KDBX。
- **安全分享**：条目用随机分享密钥加密，分享密钥再用接收方 X25519 公钥包装。
- **SSH Agent**：1Password 风格的内存 SSH Agent，支持 ed25519 / RSA。
- **本地凭据服务**：脚本通过本机回环服务读取用户名、密码、TOTP，无需写入环境变量或文件。
- **Linux sudo 两步验证**：TOTP + `openvalut-sudo-askpass`，或可选的 PAM 模块。

---

## 安全设计

安全模型的核心假设是：**服务端不可信**。服务端被攻破时，攻击者只能拿到密文。

### 端到端加密

| 项目 | 实现 |
|---|---|
| 密钥派生（KDF） | Argon2id，64 MiB 内存，3 轮，4 并行，输出 32 字节 |
| 对称加密 | AES-256-GCM，随机 12 字节 nonce |
| 密码库格式 | 标准 KDBX 3.x / 4.x，客户端本地加解密 |
| 云端额外加密 | KDBX 之上再套一层 Argon2id + AES-256-GCM，salt 为 vault id |

- 主密码只在本机内存中使用，从不通过网络发送，也不写入服务端或磁盘。
- 服务端数据库只保存 `nonce + ciphertext`，不持有任何密钥。
- 元数据（密码库名称、分组名等）同样加密后上传。

### 传输与认证

- **信封加密**：X25519（浏览器端使用 P-256）ECDH 协商，请求体与响应体分别加密。
- **请求签名**：每个请求附带 HMAC 签名与时间戳，防篡改、防重放。
- **认证**：账号 + Secret Key 登录，Bearer token 30 天有效，401 自动刷新。

### 分享

- 客户端生成随机分享密钥加密条目副本。
- 分享密钥用接收方 X25519 公钥包装后上传。
- 服务端只保存包装后的密钥与密文，无法读取分享内容。

### 本地安全

| 场景 | 措施 |
|---|---|
| 密码库解锁 | 主密码仅在内存中使用，锁定时清零 |
| 生物识别 / 快速解锁 | 系统 Keychain / Keystore 保存转换后的密钥 |
| SSH Agent | 私钥仅在解锁后驻留内存；锁定或退出时停止 Agent 并删除 socket |
| 本地凭据服务 | 仅监听 `127.0.0.1`，配合 0600 权限的 socket / token 文件 |
| 浏览器扩展 | KDBX 解密在独立 native host 进程完成，锁屏或浏览器关闭后清除密钥 |
| 通行密钥 | 私钥仅在本地密码库生成与保存，签名在 native host 内完成 |
| 自动填充 | 只填充真实可见的输入框，已填字段不重复填充 |

### 服务端

- 只做身份校验、密文存储与转发，不持有解密密钥。
- 生产环境 MySQL 使用 `innodb_flush_log_at_trx_commit=1`、`sync_binlog=1`、
  doublewrite 与 binlog，崩溃不丢已确认写入。
- 删除密码库使用事务级联，条目与分享记录原子删除。
- 发布包存放在私有对象存储，客户端通过临时签名 URL 下载并校验 SHA-256。
- 域名、数据库密码、对象存储密钥等全部通过环境变量注入，不进入代码库。

---

## 技术栈

| 组件 | 技术 |
|---|---|
| 服务端 | Rust · axum · tokio · sqlx（SQLite / MySQL / PostgreSQL） |
| 核心加密与 KDBX | Rust · argon2 · aes-gcm · x25519-dalek · keepass |
| CLI / native host | Rust |
| 桌面端 | Tauri 2 + React（`crates/openvalut-desktop/ui`） |
| 移动端 / 跨平台 App | Flutter + Dart |
| 浏览器扩展 | Chrome Manifest V3（原生 JS） |

---

## 项目结构

```text
.
├── crates/
│   ├── openvalut-core/      # 加密原语、KDBX 读写、共享数据模型
│   ├── openvalut-server/    # 自托管同步/分享服务端（axum + sqlx）
│   ├── openvalut-cli/       # 命令行工具、SSH Agent、本地凭据服务
│   ├── openvalut-host/      # Chrome native messaging host
│   ├── openvalut-desktop/   # Tauri 2 桌面端（Rust 侧 + React UI）
│   ├── openvalut-mobile/    # Flutter 的 Rust FFI 桥
│   └── openvalut-ui/        # 共享 Rust UI 组件
├── openvalut/               # Flutter App（Android / iOS / Linux / macOS / Windows）
├── chrome_extension/        # Chrome / Chromium 扩展
├── autofill_module/         # Android / iOS 自动填充模块
├── autofill_shared/         # 域名/包名匹配逻辑（Dart）
├── linux/                   # PAM 模块与 sudo askpass
├── docs/                    # 使用与开发文档
├── _tools/                  # 构建、打包与部署脚本
└── vendor/keepass/          # 本地 patch 的 keepass crate
```

---

## 构建与运行

要求：Rust 1.87+、Node.js 20+（桌面端 UI）、Flutter 3.x（移动端）。

### 服务端

```bash
cargo build --release -p openvalut-server

./target/release/openvalut-server \
  -addr 127.0.0.1:18080 \
  -db sqlite \
  -dsn openvalut.db
```

首次启动会自动生成 X25519 传输密钥（默认
`/opt/openvalut-server/keys/server_key.bin`，权限 0600）。健康检查：

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

更多用法见 [docs/credential-server.md](docs/credential-server.md)。

### Chrome native host

```bash
cargo build --release -p openvalut-host
```

加载扩展：打开 `chrome://extensions/`，开启开发者模式，选择“加载已解压的扩展程序”，
指向 `chrome_extension/`。deb 安装会通过 `_tools/build-deb.sh` 自动注册 native host；
手动注册时，把 native-messaging JSON 的 `path` 指向 `target/release/openvalut-host`。

### 桌面端（Tauri）

```bash
cd crates/openvalut-desktop/ui
npm ci
npm run build
cd ../..

cargo build --release -p openvalut-desktop --features tauri/custom-protocol
```

`tauri/custom-protocol` 不能省略：裸 `cargo build` 会进入 dev 模式，把
`WebviewUrl::App` 指向 `http://localhost:5173`，产物不会内嵌 `ui/dist`。
可用 `grep -oa 'assets/index-' <binary>` 验证前端是否真的打进了二进制。

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

## 服务端配置

### 命令行参数

| 参数 | 说明 | 环境变量 | 默认值 |
|---|---|---|---|
| `-addr` | 监听地址 | `OPENVALUT_ADDR` | `0.0.0.0:8080` |
| `-db` | `sqlite` / `mysql` / `postgres` | — | `sqlite` |
| `-dsn` | 数据库连接串 | `OPENVALUT_DSN` | `openvalut.db` |
| `-key-file` | X25519 传输密钥文件 | `SERVER_KEY_FILE` | `/opt/openvalut-server/keys/server_key.bin` |
| `-publish-key` | 发布制品所需密钥 | `PUBLISH_KEY` | 无 |

### 对象存储（可选）

发布 APK / deb 时使用，全部通过环境变量注入：

```bash
export OSS_ACCESS_KEY_ID='...'
export OSS_ACCESS_KEY_SECRET='...'
export OSS_BUCKET='...'
export OSS_ENDPOINT='...'
```

不要把真实值写进仓库；`.env` 已在 `.gitignore` 中。

### MySQL DSN 示例

```text
mysql://openvalut:<db-password>@127.0.0.1:3306/openvalut?ssl-mode=verify-identity
```

非回环地址要求 `ssl-mode=required` 或更强（`verify-ca` / `verify-identity`），
否则启动会被拒绝。

### PostgreSQL DSN 示例

```text
postgres://openvalut:<db-password>@127.0.0.1:5432/openvalut
```

---

## 部署

`crates/openvalut-server/deploy/` 提供一套最小化生产部署：

| 文件 | 用途 |
|---|---|
| `deploy.sh` | 安装二进制、创建数据库、写入 systemd 与 nginx 配置 |
| `openvalut.conf` | nginx 反向代理模板 |
| `openvalut-server.service` | systemd 单元 |

模板中的域名统一使用 `openvalut.example.com` / `example.com` 占位。部署前替换为你自己的域名与证书路径：

```bash
cd crates/openvalut-server/deploy
sudo bash deploy.sh
```

脚本假设 `openvalut-server` 二进制与部署文件位于同一目录，并且 nginx 已安装。
已有 MySQL 时可通过 `OPENVALUT_MYSQL_ROOT_PW` 复用；数据库名、用户、密码可用
`OPENVALUT_DB_NAME`、`OPENVALUT_DB_USER`、`OPENVALUT_DB_PASS` 覆盖。

更轻量的单机部署也可以直接用 systemd 托管：

```bash
install -d -m 700 /opt/openvalut-server/keys
install -m 755 target/release/openvalut-server /opt/openvalut-server/
install -m 644 crates/openvalut-server/deploy/openvalut-server.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now openvalut-server
```

---

## Android 签名

仓库不包含任何签名密钥。发布构建前自行生成 keystore：

```bash
keytool -genkeypair -v \
  -keystore my-release.keystore \
  -alias openvalut \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

通过环境变量注入（或写入已被 gitignore 的 `openvalut/android/.env`）：

```bash
export ANDROID_KEYSTORE_PATH=/absolute/path/to/my-release.keystore
export ANDROID_KEY_ALIAS=openvalut
export ANDROID_KEYSTORE_PASSWORD='...'
export ANDROID_KEY_PASSWORD='...'
```

`*.keystore` 与 `*.jks` 已在 `.gitignore` 中，请勿提交。

---

## 发布前自检

公开仓库前运行：

```bash
./_tools/check-public.sh
```

脚本只输出 `文件:行号:规则`，不会回显匹配到的值。它会检查内网 IP、云厂商
AccessKey、GitHub / OpenAI / Slack 令牌、私钥块、`*.keystore` / `*.jks` /
`*.pem` 等文件，以及 `.env` 里明显的真实长随机值。

仓库本身只内置通用规则。个人域名、用户名、部署主机等标识请写入
`.public-deny`（已 gitignore），格式为每行 `规则名|扩展正则`，可参考
`.public-deny.example`：

```bash
cp .public-deny.example .public-deny
$EDITOR .public-deny
./_tools/check-public.sh
```

启用提交前检查：

```bash
git config core.hooksPath .githooks
```

hook 只扫描暂存内容（`--staged`），发现命中会直接阻止提交。

如果希望连 `git push` / `cargo publish` 一起拦住，可把
`_tools/codex-hook/public_repo_guard.py` 注册为 Codex 的 `PreToolUse` hook，
详见 [docs/public-repo-hook.md](docs/public-repo-hook.md)。

---

## 相关文档

- [SSH Agent](docs/ssh-agent.md)
- [凭据服务与 CLI](docs/credential-server.md)
- [Linux sudo TOTP](docs/linux-totp.md)
- [Apple 签名](docs/apple-signing.md)
- [自动填充](docs/autofill/)

---

## 开源协议

[GPL-3.0-or-later](LICENSE)。上游项目与第三方组件的版权声明见
[NOTICE](NOTICE)。

---

> **安全提示**：OpenValut 不会以任何形式索要主密码。主密码与 Secret Key
> 丢失后无法恢复数据，请自行做好离线备份。
