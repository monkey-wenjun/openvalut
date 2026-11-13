# openvalut 凭据服务（openvalut-cli）

给程序/脚本一个访问密码库的入口：用户名、密码、两步验证码（TOTP），
不需要把凭据复制到别处。类似 1Password 的 `op` 命令。

有两种模式：
- **socket 模式（默认）**：读取运行中且已解锁 App 的本地凭据服务（只读）；
- **独立模式（`--db` / `--cloud`）**：直接打开本地 KDBX 文件或 openvalut Cloud
  密码库，支持查询与增删改查，不需要 App 运行。

## 架构

密码库解锁期间，App 启动一个本地凭据服务（回环 TCP，新行分隔 JSON），并通过
0600 的 Unix socket（`<App 数据目录>/openvalut.sock`）暴露。`openvalut-cli`
读取同目录下的令牌（`openvalut.token`）和端口（`openvalut.port`）文件后连接。
锁定/关闭/退出后服务、socket、令牌文件全部删除。

```
脚本/程序 → openvalut-cli → 127.0.0.1:<随机端口>（JSON + 令牌）
                                │
                         已解锁的密码库（只读）
```

## 使用

```bash
# 列出条目（可带关键词过滤）
openvalut-cli list
openvalut-cli list github

# 取密码（默认输出密码）
openvalut-cli get github

# 取用户名 / 完整 JSON
openvalut-cli get github --field username
openvalut-cli get github --field json

# 两步验证码
openvalut-cli totp github
openvalut-cli totp github --field json   # {code, period, remainingSeconds}
```

查询按标题或用户名精确/包含匹配；无匹配时退出码 1。

### 允许读取（默认禁止读取全部条目）

出于安全考虑，CLI 的读取接口是**默认禁止**的：只有你明确允许的分组和条目
才会出现在 `list` / `get` 结果中，其他条目对 CLI 与脚本不可见、不可读取
（`resolve` 秘密引用同样只对允许的条目生效）。

允许方式（在 OpenValut App 中操作，标记随 KDBX 一起保存）：

- **条目详情页**有一个“允许 CLI/脚本读取”开关；
- **分组菜单**（长按分组）可以一键允许/禁止该分组（含子分组）下的全部条目。

底层实现是条目上一个隐藏字段 `openvalut.read-allowed=1`，因此也随
OpenValut Cloud 行同步在设备间保存。新条目默认都是禁止读取的。
“允许分组”会一次标记该分组（含子分组）下已有的全部条目；之后新增的条目
仍默认禁止，需要再次允许该条目（或在分组菜单再点一次“允许”）。

socket 模式 `list` 的 JSON 中每个条目带 `allowed` 字段；
`get --field allowed` 也可返回该状态（当前只读接口只返回已允许条目，
因此实际值恒为 `true`）。socket 的 `export` 同样只导出允许读取的条目
（App 菜单里的 CSV 导出不受影响，仍导出完整密码库）。

独立模式（`--db` / `--cloud`）也可以直接用命令维护允许列表：

```bash
openvalut-cli --db vault.kdbx --password '主密码' item allow github
openvalut-cli --db vault.kdbx --password '主密码' item deny github
```

## 独立模式（本地 KDBX）

直接解锁本地 `.kdbx` 文件（KDBX 3.x / 4.x，支持主密码和密钥文件），
不需要 App 运行，支持只读命令与条目增删改查：

```bash
# 只读查询（主密码可用 --password / --password-stdin /
# openvalut_MASTER_PASSWORD 环境变量，或交互输入）
openvalut-cli --db vault.kdbx --password '主密码' list
openvalut-cli --db vault.kdbx --password '主密码' get github
openvalut-cli --db vault.kdbx --password '主密码' totp github

# 创建新密码库
openvalut-cli --db new.kdbx --password '主密码' vault create 我的密码库

# 增删改查
openvalut-cli --db vault.kdbx --password '主密码' item add GitHub \
  --username alice --password-field s3cret --url https://github.com
openvalut-cli --db vault.kdbx --password '主密码' item edit GitHub \
  --password-field 新密码 --group Work
openvalut-cli --db vault.kdbx --password '主密码' item delete GitHub
```

修改会写回原文件（临时文件 + 原子替换），App 可以正常打开。

## 独立模式（openvalut Cloud）

直接用 邮箱 + Secret Key（注册时保存的账号 UUID）+ 主密码 登录云服务，
下载并解密密码库后查询/增删改查，修改后再加密上传：

```bash
# 创建云密码库（vault id 同时作为外层加密盐）
openvalut-cli --cloud --email you@example.com --secret-key <UUID> \
  --password '主密码' vault create 我的密码库

# 查询与增删改查
openvalut-cli --cloud --email you@example.com --secret-key <UUID> \
  --password '主密码' list
openvalut-cli --cloud --email you@example.com --secret-key <UUID> \
  --password '主密码' item add GitHub --username alice --password-field s3cret

# 自定义服务器
openvalut-cli --cloud --server https://openvalut.example.com --email ... --secret-key ... list
```

加密参数与 App 完全一致：外层 Argon2id（64 MiB / 3 轮 / 4 路，salt = vault id）
+ AES-256-GCM；内层为标准 KDBX 4.x。主密码只在本机使用，从不发送到服务器。

## 长期解锁（终端 / SSH / App 互通）

`openvalut-cli unlock` 会把主密码同时写进两处，之后**同一台机器的任意终端、
任意 SSH 登录都不再重新要主密码，直到重启**：

- **内核 user keyring（`@u`）**：同一 UID 的所有进程共享，只存在内核内存里，
  重启即消失，不落盘；纯 SSH（没有桌面会话 / DBus）也能读写；
- **系统钥匙串**（Secret Service / Keychain）：跨重启保留，桌面会话可用时写入。

桌面 App 与 CLI 共用这一份「已解锁」状态（key 名 `openvalut:master-password`）：

- App 解锁后会把主密码发布到 keyring，`openvalut-cli`（含 `--db` / `--cloud`
  独立模式）随后直接可用；
- `openvalut-cli unlock` 之后打开 App，App 会读取同一 key 自动解锁，不再要求输入；
- `openvalut-cli lock` 或 App 里的锁定 / 关闭密码库会清掉这份共享解锁。

只读场景（`list` / `run` / `get --field` / `pam-setup`）本就走运行中 App 的凭据
服务，App 解锁即 CLI 解锁，两者等价。

## 扫码登录 / 扫码解锁（手机 → PC，仅当面）

人在电脑旁但不方便输密码时，可以用手机 App 给 PC「授权」：

```bash
# 用手机扫码登录云账号，PC 上不用再输邮箱 + Secret Key
openvalut-cli auth login --scan

# 用手机把已解锁密码库的主密码推给 PC，PC 直接解锁
openvalut-cli unlock --scan
```

命令会在终端打印一个二维码（内容为 `openvalut://scan-login/<会话>`），
用手机 App 的「扫码授权登录」扫描并确认即可。协议要点：

- CLI 每次生成一次性 RSA-2048 密钥对，只把**公钥**登记到服务器（不在二维码里），
  私钥只留在本机内存；
- 手机取回公钥后用 RSA-OAEP/SHA-256 加密主密码再回传，服务器只中转密文、
  看不到明文；二维码里不含任何密钥或密码；
- 轮询携带只属于会话创建者的一次性密钥（`x-scan-secret`），所以只有出示
  二维码的那台 PC 能拿到登录令牌与账号 ID；
- 会话 2 分钟有效，过期或超时会提示重来。`auth login --scan` 会把账号 ID
  （即 Secret Key）写进钥匙串，之后 `--cloud` 命令照常复用。

> 依赖服务端在扫码确认后返回账号 ID（`userId`）。旧服务端只返回令牌，CLI 会
> 提示「请升级服务端后重试」。

## SSH agent 与 .env 导入

密码库条目的 `ssh-private-key` 字段（App 的 SSH 密钥条目，OpenSSH PEM 格式）
可以像 `ssh-add` 一样加载到系统 ssh-agent，私钥只进 agent 内存、不落盘：

```bash
# 加载条目私钥到 ssh-agent（需要已启动 agent，如 eval "$(ssh-agent -s)"）
openvalut-cli --db vault.kdbx --password '主密码' agent add my-ssh

# 查看 / 移除
openvalut-cli --db vault.kdbx --password '主密码' agent list
openvalut-cli --db vault.kdbx --password '主密码' agent remove my-ssh
openvalut-cli agent remove-all

# 通过 CLI 写入 SSH 私钥（App 也能直接创建此类条目）
openvalut-cli --db vault.kdbx --password '主密码' item add my-ssh \
  --ssh-private-key ~/.ssh/id_ed25519
```

`agent list` / `agent remove-all` 不需要密码库，只要求 `SSH_AUTH_SOCK`；
`agent add` / `agent remove` 需要 `--db` 或 `--cloud` 定位对应条目。

`.env` 文件可以一键导入密码库：每个 `KEY=VALUE` 变成一个条目（默认
`.env` 分组），值存入受保护的 Password 字段，重复导入只会更新不会产生
重复条目：

```bash
# 自动搜索：从当前目录向上找 .env / .env.local（后者覆盖前者）
openvalut-cli --db vault.kdbx --password '主密码' item import-env

# 指定路径 / 分组
openvalut-cli --db vault.kdbx --password '主密码' item import-env \
  /path/to/.env --group services
```

## 脚本示例

```bash
# 自动登录
openvalut-cli get my-server > /tmp/pw && sshpass -f /tmp/pw ssh user@host

# 取 TOTP 填入其它工具
code=$(openvalut-cli totp my-account)

# git 之类的程序可以从环境变量读取
export GITHUB_TOKEN=$(openvalut-cli get github --field json | jq -r .password)
```

## 安全

- 凭据只在**解锁期间**通过本地服务返回，磁盘上无明文；
- socket 与令牌/端口文件权限均为 0600；令牌防止其他本地用户直接连 TCP 端口；
- socket 模式服务只读，不支持写入/修改密码库；独立模式可直接修改并写回；
- 密码和 TOTP 只在请求时返回，`list` 不包含任何秘密。

## 平台

- Linux：完整支持（随 deb 安装 `openvalut-cli`）；
- macOS / Windows：服务端代码就绪，CLI 二进制待各自平台编译。

## 源码位置

- 服务：`openvalut/lib/credential_server/`
- CLI：`cli/`（独立 Rust 实现，`cargo build --release` 后产物为 `target/release/openvalut-cli`）
