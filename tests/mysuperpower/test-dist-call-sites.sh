#!/usr/bin/env bash
# After a build, no shipped skill may point at a fork docs path that ends in .md.
#
# The rebrand cascade rewrites docs/superpowers/ to docs/mySuperpower/ and never
# touches the extension, so upstream's markdown examples ship with fork paths and
# markdown suffixes -- a path shape that cannot exist in this fork. The cascade
# will keep manufacturing these on every upstream merge; this check is what makes
# the next one visible.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DIST="${1:-$REPO_ROOT/dist}"

[ -d "$DIST/skills" ] || { echo "no built skills at $DIST/skills -- run build-mysuperpower.ps1 first" >&2; exit 2; }

hits=$(grep -rn -E 'docs/mySuperpower/[^ )`"<>]*\.md' "$DIST/skills" || true)

if [ -n "$hits" ]; then
  echo "FAIL: built skills reference fork doc paths that are still markdown:" >&2
  printf '%s\n' "$hits" >&2
  exit 1
fi
echo "dist call-site check passed: no docs/mySuperpower/*.md references"