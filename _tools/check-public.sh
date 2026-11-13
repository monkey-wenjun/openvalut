#!/usr/bin/env bash
#
# Pre-publish leak check.
#
# Prints only "path:line:rule" and never echoes the matched text, so it is safe
# to run in a terminal that is being recorded or shared.
#
# Usage:
#   ./_tools/check-public.sh              # scan tracked + untracked files
#   ./_tools/check-public.sh --staged     # scan only what is staged for commit
#   ./_tools/check-public.sh --tracked    # scan only tracked files (what a push sends)
#   ./_tools/check-public.sh --deny FILE  # extra rules, one "rule|regex" per line
#
# Extra machine-specific rules can live in .public-deny (gitignored), which is
# read automatically when present. --deny may be repeated and is additive.
#
# Exit status is non-zero when at least one finding is reported.

set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT" || exit 2

MODE=worktree
DENY_FILES=()
while [ $# -gt 0 ]; do
  case "$1" in
    --staged) MODE=staged ;;
    --tracked) MODE=tracked ;;
    --deny)
      [ $# -ge 2 ] || { echo "usage: $0 [--staged] [--deny FILE]" >&2; exit 2; }
      DENY_FILES+=("$2")
      shift
      ;;
    *)
      echo "usage: $0 [--staged|--tracked] [--deny FILE]" >&2
      exit 2
      ;;
  esac
  shift
done

TMPDIR_RUN=$(mktemp -d "${TMPDIR:-/tmp}/check-public.XXXXXX") || exit 2
trap 'rm -rf "$TMPDIR_RUN"' EXIT

# rule|extended-regexp
# Generic patterns only. Character classes keep this file from containing a
# literal credential prefix. Machine-specific identifiers (usernames, domains,
# internal IPs) belong in .public-deny or a file passed with --deny, so this
# script can be published as-is.
cat >"$TMPDIR_RUN/rules" <<'RULES'
private-ip|192[.]168[.][0-9]{1,3}[.][0-9]{1,3}
aliyun-key|L[T]AI[0-9A-Za-z]{12,}
aws-key|A[K]IA[0-9A-Z]{16}
github-token|gh[pousr]_[A-Za-z0-9]{30,}
github-pat|github_pat_[A-Za-z0-9_]{30,}
openai-key|s[k]-[A-Za-z0-9]{20,}
slack-token|xox[baprs]-[A-Za-z0-9-]{10,}
RULES

if [ -f .public-deny ]; then
  cat .public-deny >>"$TMPDIR_RUN/rules"
fi
if [ "${#DENY_FILES[@]}" -gt 0 ]; then
  for deny in "${DENY_FILES[@]}"; do
    [ -f "$deny" ] || { echo "check-public: deny file not found: $deny" >&2; exit 2; }
    cat "$deny" >>"$TMPDIR_RUN/rules"
  done
fi

# Paths that must never be published, even if someone force-adds them.
check_path() {
  local path=$1
  shopt -s nocasematch
  case "$path" in
    *.keystore|*.jks|*.p12|*.pfx|*.pem|*.key)
      report "$path" 0 "credential-file" ;;
  esac
  case "$path" in
    .env|*/.env|.env.*|*/.env.*)
      case "$path" in
        *.example|*.sample|*.template) ;;
        *) report "$path" 0 "env-file" ;;
      esac
      ;;
  esac
  shopt -u nocasematch
}

report() {
  printf '%s:%s:%s\n' "$1" "$2" "$3" >>"$TMPDIR_RUN/findings"
}

# scan_file <display-name> <file>
scan_file() {
  local display=$1
  local src=$2

  check_path "$display"

  # Skip binaries and unreadable files.
  grep -Iq . "$src" 2>/dev/null || return 0

  awk -F'|' -v file="$display" '
    NR == FNR { rules[++n] = $1; pats[n] = $2; next }
    {
      if ($0 ~ /-----BEGIN [A-Z ]*PRIVATE KEY-----/) {
        in_key = 1
        header = FNR
        body = 0
      } else if ($0 ~ /-----END [A-Z ]*PRIVATE KEY-----/) {
        if (in_key && body) printf "%s:%d:%s\n", file, header, "private-key-block"
        in_key = 0
      } else if (in_key && $0 ~ /^[A-Za-z0-9+\/=]{20,}$/) {
        body++
      }
      for (i = 1; i <= n; i++) {
        if ($0 ~ pats[i]) {
          printf "%s:%d:%s\n", file, FNR, rules[i]
          break
        }
      }
    }
  ' "$TMPDIR_RUN/rules" "$src" >>"$TMPDIR_RUN/findings"

  # Long, non-placeholder values in committed env templates.
  case "$display" in
    *.env.example|*/.env.example|*.env.sample|*.env.template)
      awk -v file="$display" '
        /^[A-Za-z_][A-Za-z0-9_]*=/ {
          value = substr($0, index($0, "=") + 1)
          gsub(/^[ \t]+|[ \t]+$/, "", value)
          if (length(value) < 32) next
          if (value ~ /^["\047]?[$<{]/) next
          if (tolower(value) ~ /example|placeholder|changeme|your[-_]|replace|redacted|dummy|sample|xxx/) next
          printf "%s:%d:%s\n", file, FNR, "env-example-value"
        }
      ' "$src" >>"$TMPDIR_RUN/findings"
      ;;
  esac
}

should_skip() {
  case "$1" in
    .git/*|target/*|*/target/*|build/*|*/build/*)
      return 0 ;;
    node_modules/*|*/node_modules/*|.dart_tool/*|*/.dart_tool/*)
      return 0 ;;
    vendor/*|*/vendor/*|_docs/*|*/_docs/*)
      return 0 ;;
    metadata/android/*|*/metadata/android/*)
      return 0 ;;
    .public-deny)
      return 0 ;;
  esac
  return 1
}

if [ "$MODE" = staged ]; then
  n=0
  while IFS= read -r -d '' path; do
    should_skip "$path" && continue
    n=$((n + 1))
    if git show ":$path" >"$TMPDIR_RUN/f$n" 2>/dev/null; then
      scan_file "$path" "$TMPDIR_RUN/f$n"
    fi
  done < <(git diff --cached --name-only --diff-filter=ACMR -z)
elif [ "$MODE" = tracked ]; then
  while IFS= read -r -d '' path; do
    [ -f "$path" ] || continue
    should_skip "$path" && continue
    scan_file "$path" "$path"
  done < <(git ls-files -z --cached)
else
  if git rev-parse --git-dir >/dev/null 2>&1; then
    list_cmd=(git ls-files -z --cached --others --exclude-standard)
  else
    list_cmd=(rg --files --hidden -0)
  fi

  while IFS= read -r -d '' path; do
    [ -f "$path" ] || continue
    should_skip "$path" && continue
    scan_file "$path" "$path"
  done < <("${list_cmd[@]}")
fi

if [ -s "$TMPDIR_RUN/findings" ]; then
  sort -u "$TMPDIR_RUN/findings"
  findings=$(wc -l <"$TMPDIR_RUN/findings")
  echo "check-public: $findings finding(s)" >&2
  exit 1
fi

echo "check-public: clean" >&2
exit 0
