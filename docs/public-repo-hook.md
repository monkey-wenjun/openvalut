# 发布前拦截（Codex hook / pre-commit）

仓库带两层“别把私有部署信息推出去”的检查，二者共用同一个扫描器
`_tools/check-public.sh`：

| 层 | 触发时机 | 作用 |
|---|---|---|
| git pre-commit | `git commit` | 只扫描暂存内容，命中即拒绝提交 |
| Codex `PreToolUse` hook | `git push` / `gh release` / `cargo publish` 等 | 扫描已跟踪文件，命中即拒绝执行 |

扫描器只输出 `文件:行号:规则`，不会回显命中的文本，因此日志、录屏和模型上下文里
都不会出现密钥或域名本身。

## 1. 本地规则

通用规则（内网 IP、云厂商 AccessKey、GitHub / OpenAI / Slack 令牌、私钥块、
`*.keystore` / `*.pem` / `.env` 等）内置在脚本里。**个人域名、用户名、部署主机**
这类只对自己有效的规则放在 `.public-deny`（已被 `.gitignore` 忽略，不会发布）：

```bash
cp .public-deny.example .public-deny
$EDITOR .public-deny
./_tools/check-public.sh
```

格式为每行 `规则名|扩展正则`，例如：

```text
personal-domain|my-domain[.]example
personal-user|my-username
home-path|/home/my-username
```

## 2. git pre-commit

```bash
git config core.hooksPath .githooks
```

## 3. Codex hook

把 `_tools/codex-hook/public_repo_guard.py` 注册到 Codex 的 `PreToolUse`
（`~/.codex/hooks.json`）。它从命令里找出 `git -C` / `cd` 的目标仓库，
对该仓库运行 `./_tools/check-public.sh --tracked`；返回非零就 deny 这次发布命令。

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/usr/bin/python3 /absolute/path/to/_tools/codex-hook/public_repo_guard.py",
            "statusMessage": "public-repo-guard: checking publish contents",
            "timeout": 200
          }
        ]
      }
    ]
  }
}
```

该 hook 不依赖网络，也不读取仓库以外的文件；仓库没有 `_tools/check-public.sh`
时直接放行，所以可以安全地装在全局 Codex 配置里。

## 4. 已推送的历史怎么办

扫描器只看当前提交的内容。如果敏感信息曾经进入历史提交，改写历史（
`git filter-repo`）后需要 force push，并让所有协作者重新克隆；已经泄露的密钥
必须先轮换，不能只靠改历史。
