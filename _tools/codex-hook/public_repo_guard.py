#!/usr/bin/env python3
"""Block publish commands when the repository still contains private data.

Install as a Codex ``PreToolUse`` hook (see ``docs/public-repo-hook.md``). It
only inspects the command string; when the command publishes something
(``git push``, ``gh release``, ``cargo publish``, ``npm publish`` ...), it runs
the repository's ``_tools/check-public.sh`` and denies the call if that script
reports findings.

Findings are printed as ``path:line:rule`` and never include the matched text,
so the hook itself cannot leak a secret into the transcript.

Repositories without ``_tools/check-public.sh`` are left alone.
"""

from __future__ import annotations

import json
import os
import re
import shlex
import subprocess
import sys

PUBLISH_RE = re.compile(
    r"(?:^|[;&|]\s*|\bthen\s+|\bdo\s+)"
    r"(?:sudo\s+)?(?:git\s+push|gh\s+release|gh\s+repo\s+create|cargo\s+publish"
    r"|npm\s+publish|pnpm\s+publish|yarn\s+publish|twine\s+upload|docker\s+push)\b"
)


def command_of(payload: dict) -> str:
    tool_input = payload.get("tool_input")
    if isinstance(tool_input, dict):
        value = tool_input.get("command", "")
    elif tool_input is not None:
        value = tool_input
    else:
        value = ""
    return value if isinstance(value, str) else ""


def candidate_dirs(command: str) -> list[str]:
    dirs = [os.getcwd()]
    try:
        tokens = shlex.split(command, posix=True)
    except ValueError:
        return dirs
    for i, token in enumerate(tokens):
        if token in ("cd", "-C") and i + 1 < len(tokens):
            path = os.path.expanduser(tokens[i + 1])
            if not os.path.isabs(path):
                path = os.path.join(os.getcwd(), path)
            dirs.append(path)
    return dirs


def repo_root(path: str) -> str | None:
    try:
        out = subprocess.run(
            ["git", "-C", path, "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            timeout=5,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    root = out.stdout.strip()
    return root or None


def scan(root: str) -> tuple[int, str]:
    script = os.path.join(root, "_tools", "check-public.sh")
    if not os.access(script, os.X_OK):
        return 0, ""
    try:
        out = subprocess.run(
            [script, "--tracked"],
            cwd=root,
            capture_output=True,
            text=True,
            timeout=180,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        return 0, f"check-public.sh could not run: {type(exc).__name__}"
    return out.returncode, (out.stdout or "") + (out.stderr or "")


def main() -> int:
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except json.JSONDecodeError:
        return 0
    if not isinstance(payload, dict):
        return 0

    command = command_of(payload)
    if not PUBLISH_RE.search(command):
        return 0

    seen: set[str] = set()
    for path in candidate_dirs(command):
        root = repo_root(path)
        if not root or root in seen:
            continue
        seen.add(root)
        code, output = scan(root)
        if code == 0:
            continue
        detail = output.strip().splitlines()[:20]
        reason = (
            "public-repo-guard: publish blocked, the leak check failed.\n"
            f"repository: {root}\n"
            + ("\n".join(detail) if detail else "(no output)")
            + "\nRun ./_tools/check-public.sh and fix the findings first."
        )
        print(
            json.dumps(
                {
                    "systemMessage": "public-repo-guard blocked a publish",
                    "hookSpecificOutput": {
                        "hookEventName": "PreToolUse",
                        "permissionDecision": "deny",
                        "permissionDecisionReason": reason,
                    },
                },
                ensure_ascii=False,
            )
        )
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
