#!/usr/bin/env bash
# Check for files/directories whose names still contain "OpenVault" or "OpenVault".
# Excludes common build/dependency/VCS directories.

set -euo pipefail

ROOT="${1:-.}"

echo "Searching for filenames containing 'OpenVault' or 'OpenVault' under ${ROOT} ..."
echo "---"

find "${ROOT}" \
  -type d \( \
    -name '.git' -o \
    -name '.dart_tool' -o \
    -name 'build' -o \
    -name 'target' -o \
    -name 'node_modules' -o \
    -name '.idea' -o \
    -name '.vscode' -o \
    -name 'Pods' -o \
    -name '.symlinks' -o \
    -name 'DerivedData' -o \
    -name '.gradle' -o \
    -name '__pycache__' \
  \) -prune -o \
  -type f \( \
    -name '*OpenVault*' -o \
    -name '*OpenVault*' \
  \) -print -o \
  -type d \( \
    -name '*OpenVault*' -o \
    -name '*OpenVault*' \
  \) -print

echo "---"
echo "Done."
