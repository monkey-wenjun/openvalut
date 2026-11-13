#!/usr/bin/env bash
# Trigger a GitHub Actions release build without pushing a tag.
#
# The version is read from debian/DEBIAN/control. If a release (or local tag)
# with that version already exists, the patch version is automatically bumped,
# committed, and pushed before triggering the workflow.
#
# Usage: ./_tools/release.sh
set -euo pipefail
cd "$(dirname "$0")/.."

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
  echo "[dry-run] No changes will be made."
fi

if ! git diff --quiet HEAD; then
  echo "Error: working tree has uncommitted changes. Commit or stash them first." >&2
  exit 1
fi

# Read current version from debian control file.
VERSION="$(grep '^Version:' debian/DEBIAN/control | awk '{print $2}')"
TAG="v${VERSION}"

# If the tag or release already exists, bump the patch version.
if git rev-parse "${TAG}" >/dev/null 2>&1 || gh release view "${TAG}" --repo your-org/openvalut >/dev/null 2>&1; then
  echo "Release ${TAG} already exists, bumping patch version..."
  MAJOR="$(echo "${VERSION}" | cut -d. -f1)"
  MINOR="$(echo "${VERSION}" | cut -d. -f2)"
  PATCH="$(echo "${VERSION}" | cut -d. -f3)"
  PATCH=$((PATCH + 1))
  VERSION="${MAJOR}.${MINOR}.${PATCH}"
  TAG="v${VERSION}"
  if [ "$DRY_RUN" = true ]; then
    echo "[dry-run] Would update debian/DEBIAN/control to Version: ${VERSION}"
    echo "[dry-run] Would commit and push the version bump."
  else
    sed -i "s/^Version: .*/Version: ${VERSION}/" debian/DEBIAN/control
    git add debian/DEBIAN/control
    git commit -m "chore(release): bump version to ${VERSION}"
    git push
  fi
fi

if [ "$DRY_RUN" = true ]; then
  echo "[dry-run] Would trigger workflow build-all.yml with version=${VERSION}, create_release=true"
else
  echo "Triggering release build for ${TAG}..."
  gh workflow run build-all.yml \
    --repo your-org/openvalut \
    --ref master \
    -f version="${VERSION}" \
    -f create_release=true
fi

REPO_PATH="$(git remote get-url origin | sed -E 's#.*github.com[:/]##' | sed 's/\.git$//')"
echo ""
echo "Release ${TAG} build triggered."
echo "Watch the build at: https://github.com/${REPO_PATH}/actions"
