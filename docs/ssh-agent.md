# openvalut SSH Agent

openvalut 内置了一个 1Password 风格的 SSH Agent：SSH 密钥只保存在密码库条目里
（`ssh-private-key` 字段），**私钥永远不会写进磁盘**。密码库解锁期间，App 在
内存中持有密钥，开一个本地 SSH agent socket；`ssh` 把签名请求交给它，由 App
完成签名，ssh 服务端验证通过后即可登录。

## 架构

```
ssh / git / 其他程序
    │  (~/.ssh/config → IdentityAgent)
    ▼
<App 数据目录>/ssh-agent/agent.sock   ← Unix socket（0600）
    │  (openvalut-agent-bridge, C 桥接)
    ▼
127.0.0.1:<随机端口>                     ← SSH agent 协议（Dart 实现）
    ▼
解锁的密码库（密钥只存在于内存）
```

- 密码库全部关闭 / 锁定 / App 退出时，agent 和 socket 立即停止并删除；
- 私钥仅存在于 App 进程内存，磁盘上没有任何明文密钥文件；
- 支持 **ed25519** 和 **RSA**（rsa-sha2-256 / rsa-sha2-512）两种密钥。

## 生成密钥对

1. 打开密码库，进入任意分组（比如你建一个叫“SSH”的分组）；
2. 点 App 右上角 **钥匙图标（生成 SSH 密钥对）**；
3. 输入密钥名称（会同时作为 ssh 注释），确认；
4. 自动生成 ed25519 密钥对，条目保存在当前分组，字段为
   `ssh-private-key` / `ssh-public-key`（与 KeePassXC/1Password 约定一致）。

## 迁移本机已有密钥

设置 → 本地服务 → **导入本机 SSH 密钥**（或 App 右上角钥匙菜单里的“导入”）：

1. 扫描 `~/.ssh`，勾选要导入的私钥（ed25519 / RSA）；
2. 导入后条目自动标注本机：标题为 `id_ed25519 (主机名)`，并写入
   `ssh-machine` 字段（`用户@主机名`）；
3. 可勾选删除 `~/.ssh` 下的原始文件（会明确二次确认）；
4. 在设置里点 **“写入 ~/.ssh/config”**，一键追加 IdentityAgent 引用，
   本机只保留这一行引用，密钥全部在密码库里。

### 多台机器怎么区分

- 每台机器导入的密钥都会带上**本机标签**（`ssh-machine` 字段）；
- SSH Agent **只暴露当前机器的密钥**：A 机器导入的密钥在 B 机器上不会出现，
  也不会被误用；未打标签的密钥（例如在 App 里直接生成的）在所有机器可用；
- 密码库列表里标题带主机名，一眼就能看出密钥属于哪台机器。

## 让 ssh 使用它

编辑 `~/.ssh/config`，加上：

```
Host *
    IdentityAgent <App 数据目录>/ssh-agent/agent.sock
```

或者临时使用：

```bash
SSH_AUTH_SOCK=$(find ~/.openvalut/data ~/.config/openvalut/data -name agent.sock 2>/dev/null | head -1) ssh user@host
```

验证：

```bash
SSH_AUTH_SOCK=$(find ~/.openvalut/data ~/.config/openvalut/data -name agent.sock 2>/dev/null | head -1) ssh-add -l
# 256 SHA256:… user@host (ED25519)
```

然后把公钥（条目的 `ssh-public-key` 字段）加到服务器的
`~/.ssh/authorized_keys`，之后密码库解锁状态下即可直接登录。

## 安全说明

- 私钥**只在解锁期间存在于内存**；锁定/关闭/退出后 agent 停止、socket 删除；
- 签名在 App 进程内完成，任何程序都无法读取私钥原文；
- agent socket 权限为 0600，仅当前用户可访问；
- 密钥生成使用系统 `ssh-keygen`（权威实现），临时文件立即删除。

> 注意：App 数据目录随系统不同——优先 `~/.openvalut/data`，否则用 XDG 配置目录
> （Linux 通常是 `~/.config/openvalut/data`）。App 写入 ssh config 时会用解析后的
> **绝对路径**，无需手工指定；设置页的“SSH 配置”也会显示当前机器的真实路径。

## 平台支持

- **Linux**：完整支持（Unix socket 桥接随 deb 一起安装）；
- **macOS / Windows**：代码路径已具备，但 Unix socket 桥接尚未为这两个平台
  编译，待后续补充。

## 已知限制

- 不支持加密（带口令）的 OpenSSH 私钥——密码库本身就是加密层；
- agent 只支持身份列举和签名（`ssh-add -l/-L`、SSH 登录），不支持
  add/remove/lock 等管理消息（会返回 failure）。
