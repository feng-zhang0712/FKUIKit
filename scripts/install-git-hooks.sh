#!/usr/bin/env bash
# Point this Git clone at .githooks/ so pre-push (and any future hooks) run automatically.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "error: not inside a Git work tree (expected a clone of FKKit at $ROOT)" >&2
  exit 1
fi

git config core.hooksPath .githooks
echo "Configured: core.hooksPath = $(git config --get core.hooksPath)"
echo "Active hooks live under: $ROOT/.githooks/"
echo "Pre-push runs: scripts/verify-podspec-versions.sh"
echo ""
echo "To disable for this clone only: git config --unset core.hooksPath"
