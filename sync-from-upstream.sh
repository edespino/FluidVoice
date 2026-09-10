#!/bin/bash
# Fast-forward fork main from upstream, rebase local/spoken-send-terminals onto it.
# Do not open a PR to altic-dev.
set -euo pipefail

PATCH_BRANCH="local/spoken-send-terminals"
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if ! git remote get-url upstream >/dev/null 2>&1; then
  echo "missing remote: upstream (expected https://github.com/altic-dev/FluidVoice.git)" >&2
  exit 1
fi
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "missing remote: origin (expected https://github.com/edespino/FluidVoice.git)" >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "working tree is dirty; commit or stash first" >&2
  git status -sb >&2
  exit 1
fi

git fetch upstream
git checkout main
git merge --ff-only upstream/main
git push origin main

git checkout "$PATCH_BRANCH"
if ! git rebase main; then
  echo "rebase conflict. Keep isSpokenSendBlockedApp returning false, then:" >&2
  echo "  git add Sources/Fluid/ContentView.swift" >&2
  echo "  git rebase --continue" >&2
  echo "  git push --force-with-lease origin $PATCH_BRANCH" >&2
  exit 1
fi

git push --force-with-lease origin "$PATCH_BRANCH"
echo "synced: origin/main <- upstream/main; $PATCH_BRANCH rebased onto main"
git status -sb
git log -1 --oneline
