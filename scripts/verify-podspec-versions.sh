#!/usr/bin/env bash
# Ensures all root podspecs declare the same s.version (fails CI / pre-push if drifted).
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

specs=(FKCoreKit.podspec FKEmptyStateCoreLite.podspec FKUIKit.podspec FKCompositeKit.podspec)
versions=()
for f in "${specs[@]}"; do
  v="$(grep -E '^  s\.version = ' "$f" | head -1 | sed -E "s/^  s\.version = '([^']+)'.*/\1/")"
  if [[ -z "$v" ]]; then
    echo "error: could not parse s.version in $f" >&2
    exit 1
  fi
  versions+=("$v")
done

first="${versions[0]}"
for v in "${versions[@]}"; do
  if [[ "$v" != "$first" ]]; then
    echo "error: podspec s.version mismatch:" >&2
    for i in "${!specs[@]}"; do
      echo "  ${specs[$i]} -> ${versions[$i]}" >&2
    done
    exit 1
  fi
done

echo "OK: all podspecs s.version = '$first'"
