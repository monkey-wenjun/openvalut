# Linux 两步验证码（TOTP）集成

openvalut 在 Linux 桌面端支持将当前计算机作为一条特殊条目管理，并为该条目配置两步验证码（TOTP）。

## 已完成功能

1. **普通「计算机」分组**
   - 「计算机」是一个普通分组，和其它分组一样：左侧选中 → 右侧列表展示条目 → 点条目进标准编辑页。
   - 条目内存储当前计算机的信息：
     - 用户名
     - 登录/管理员密码
     - 两步验证码（OTP）
     - 机器唯一标识符（`machine-id`）
   - 可通过设置「自动配置两步验证」一键录入，或手动在「计算机」分组新建/编辑。

2. **PC 端菜单统一**
   - 桌面端右上角重新显示三个点的溢出菜单。
   - 系统菜单栏（Linux/Windows/macOS）也加入了「打开另一个数据库」和「锁定文件」。
   - 移动端顶部的二维码扫描图标已移除，入口保留在三个点菜单中。

3. **程序/Agent 调用 sudo 密码**
   - 当 openvalut 正在运行且密码库已解锁时，本地会启动凭据服务。
   - `openvalut-cli sudo --totp <当前TOTP码>` 会验证 TOTP，成功后打印当前计算机的管理员密码。
   - 这样可以把 TOTP 码交给 Agent，Agent 拿到的是一次性验证码，验证通过后才能获取真实密码。

## sudo 免交互用法（Agent 场景）

1. 在 openvalut 侧边栏「计算机」中设置好：
   - 用户名
   - 密码（即 sudo 密码）
   - OTP（任意 TOTP 应用的密钥或 `otpauth://` URI）

2. 设置 sudo 使用 openvalut 询问密码：

   ```bash
   chmod +x /opt/openvalut/openvalut-sudo-askpass
   export SUDO_ASKPASS=/opt/openvalut/openvalut-sudo-askpass
   sudo -A <command>
   ```

   执行 `sudo -A` 时，会弹窗（或终端）要求输入当前 TOTP 码，验证通过后自动把真实密码交给 sudo。

3. 也可以直接在脚本里：

   ```bash
   PASS=$(openvalut-cli sudo --totp "$(zenity --entry --text='TOTP')")
   echo "$PASS" | sudo -S <command>
   ```

## 系统登录/sudo 原生 PAM 集成（实验性）

> **警告**：PAM 模块配置错误可能导致无法登录。测试时请务必保持 root shell，并先配置好备用登录方式。

`linux/pam_openvalut/` 是一个实验性 PAM 模块，可在 `pam_unix` 验证密码后额外要求输入 TOTP 码。

### 1. 生成加密的 TOTP 文件

```bash
openvalut-cli --db ~/密码库.kdbx pam-setup
```

成功后会在 `~/.openvalut/totp/<machine-id>.enc` 写入用机器 ID 加密的 TOTP 密钥，文件权限 0600。

### 2. 编译并安装 PAM 模块

```bash
cd /path/to/openvalut/linux/pam_openvalut
cargo build --release
sudo install -m 0644 target/release/libpam_openvalut.so /lib/x86_64-linux-gnu/security/pam_openvalut.so
```

### 3. 配置 PAM

以 sudo 为例，编辑 `/etc/pam.d/sudo`：

```text
auth       required   pam_unix.so
auth       required   pam_openvalut.so
```

桌面登录（GDM/SDDM/LightDM）类似，编辑对应的 `/etc/pam.d/...` 文件，在 `pam_unix` 之后加入 `pam_openvalut.so`。

### 4. 卸载

从 `/etc/pam.d/...` 中移除 `pam_openvalut.so` 行即可。

## 安全说明

- TOTP 验证码是时间相关的「一次性」码，适合交给 Agent/脚本临时使用。
- 真实密码只在验证 TOTP 后返回，且不会离开本地 openvalut 进程/CLI。
- PAM 集成为了能在登录时使用，必须把 TOTP 密钥以机器 ID 加密后落盘；请确保 `~/.openvalut/totp/` 目录权限为 0700，文件权限为 0600。

## 一键自动配置（Linux 桌面端）

在 openvalut 设置中开启「自动配置两步验证」后，App 会自动完成：

1. 在密码库「计算机」分组写入本机条目：当前用户名、sudo 密码、一次性验证码（TOTP）、机器标识。
2. 生成机器绑定的加密 TOTP 文件 `~/.openvalut/totp/<machine-id>.enc`，并备份到 `~/.config/openvalut/totp-backups/`。
3. 通过系统授权（`pkexec`）安装 `pam_openvalut` 模块与 `openvalut-sudo-askpass`，并在 `/etc/pam.d/sudo` 加入两步验证行。
4. 在 `/etc/pam.d/sudo` 的 **`account` 栈**（而非 `auth` 栈）加入 `pam_openvalut`，并清除任何强制“每次重新认证”的 sudoers 覆盖。

## 密码缓存但每次都要两步验证码

`sudo` 缓存的是 **`auth`（密码）** 栈的认证结果。同一终端里再次 `sudo` 会跳过 `auth` 栈（不再要密码），但 **`account`/`session` 栈每次都执行**。因此：

- 密码留在 `auth` 栈（`pam_unix`）——被 sudo 缓存，一段时间内不用重复输入。
- TOTP 校验放在 `account` 栈（`pam_openvalut`）——每次 `sudo` 都会执行，因此**验证码每次都要输入**。

`/etc/pam.d/sudo` 中的正确形式：

```text
@include common-auth        # auth：密码（被缓存）
@include common-account
account required /opt/openvalut/pam/pam_openvalut.so   # 每次执行的 TOTP 校验
```

> 注意：不要把 `pam_openvalut` 放在 `auth` 栈——那样它会被密码缓存一并跳过。

## 用密码库里的 TOTP 登录服务器（`ovssh`）

服务器侧 sshd 配成 `AuthenticationMethods publickey,keyboard-interactive` 时，第二因子是
PAM-OATH 动态码，提示词是：

```text
One-time password (OATH) for `user':
```

`~/.local/bin/ovssh`（配套 `ovscp` / `ovrsync`）把 `openvalut-cli run --env OTP=<引用>`
注入的码通过 `SSH_ASKPASS` 回给 ssh，主机↔引用的对应关系写在
`~/.config/ovssh/aliases`（每行 `<ssh 别名> <op://库/条目/totp>`）。

### 两个容易踩的坑

1. **引用要指向服务器上那个用户自己的 OATH 密钥**。把 root 的密钥用在
   `user` 上会得到 `Permission denied (keyboard-interactive)`，看上去像"工具坏了"——
   实际是码不对。排查时让 askpass 只记录**提示词**（不含值）即可确认服务器在问谁。
2. **动态码只在启动那一刻取一次**。TOTP 窗口 30 秒，若取码时已接近窗口末尾，码送到
   服务器时就过期了（实测窗口第 27~29 秒起连 100% 失败）。`ovssh` 现在会在带命令时
   等下一个窗口重取重试；其它消费者要么同样重试，要么参考下面的
   `remainingSeconds`。

### 凭据服务返回的 TOTP 结构

`resolve` 一个 `ov://<库>/<条目>/totp` 引用时，返回的不只是码：

```json
{"ok": true, "data": {"code": "123456", "period": 30, "remainingSeconds": 7}}
```

`remainingSeconds` 让调用方可以判断"这张码还来不来得及用"（例如小于 5 秒就等下一个
窗口再取）。`openvalut-cli run --env` 目前只注入 `code`，需要窗口判断的工具应直接查
凭据服务（见 [credential-server.md](credential-server.md)）。
