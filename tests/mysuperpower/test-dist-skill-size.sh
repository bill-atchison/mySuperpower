#!/usr/bin/env bash
# After a build, every shipped SKILL.md must stay under upstream's skill-size limit.
#
# Upstream's tests/skill-size checks only the pristine source, but the overlays
# append to SKILL.md at build time. Upstream's subagent-driven-development is
# already within a few hundred bytes of the limit, so fork text that is not in
# references/ will push it over -- and an upstream merge that grows the skill can
# do the same. This check is what makes either one visible.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DIST="${1:-$REPO_ROOT/dist}"
LIMIT=20000

[ -d "$DIST/skills" ] || { echo "no built skills at $DIST/skills -- run build-mysuperpower.ps1 first" >&2; exit 2; }

failed=0
for skill in "$DIST"/skills/*/SKILL.md; do
  size=$(wc -c <"$skill" | tr -d ' ')
  if ((size >= LIMIT)); then
    echo "FAIL: ${skill#"$DIST"/} is $size bytes (limit: under $LIMIT)" >&2
    failed=1
  fi
done

if ((failed)); then
  echo "Move overlay text into overlay-supplied references/ files (overlay.json \"files\")." >&2
  exit 1
fi
echo "dist skill-size check passed: every built SKILL.md is under $LIMIT bytes"
