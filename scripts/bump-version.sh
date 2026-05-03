#!/usr/bin/env bash
# Bumps s.version in all root *.podspec files to the same SemVer.
# Usage: ./scripts/bump-version.sh 0.46.0
set -euo pipefail

new="${1:?Usage: $0 <semver> (e.g. 0.46.0)}"
if [[ ! "$new" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "error: version must look like 1.2.3 or 1.2.3-beta.1" >&2
  exit 1
fi

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

specs=(FKCoreKit.podspec FKEmptyStateCoreLite.podspec FKUIKit.podspec FKCompositeKit.podspec)
for f in "${specs[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "error: missing $f" >&2
    exit 1
  fi
done

for f in "${specs[@]}"; do
  if sed --version >/dev/null 2>&1; then
    sed -i "s/^  s\.version = '.*'/  s.version = '$new'/" "$f"
  else
    sed -i '' "s/^  s\.version = '.*'/  s.version = '$new'/" "$f"
  fi
done

echo "Updated s.version to '$new' in: ${specs[*]}"
echo ""
echo "Manual follow-up (not done by this script):"
echo "  1. Edit CHANGELOG.md — add ## [$new] - YYYY-MM-DD and move items from [Unreleased] as appropriate."
echo "  2. Update README.md SPM/CocoaPods examples that pin a version (from: / :tag =>) if you publish those literals."
echo "  3. Commit; create annotated tag matching the podspec version:"
echo "       git tag -a $new -m \"Release $new\""
echo "       git push origin \"$new\""
echo "  4. After the tag exists on the remote, run pod spec lint on each podspec (see README / docs/RELEASING.md)."
