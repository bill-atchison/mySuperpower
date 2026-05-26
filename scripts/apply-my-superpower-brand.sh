#!/usr/bin/env bash
# Re-apply the my-superpower brand. Idempotent. Run on a CLEAN index only.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"

# Transform 1: namespace cascade over skills/ and the session-start hook
while IFS= read -r -d '' f; do
  perl -pi -e 's/superpowers:/my-superpower:/g' "$f"
done < <(find "$root/skills" -type f -print0)
[ -f "$root/hooks/session-start" ] && perl -pi -e 's/superpowers:/my-superpower:/g' "$root/hooks/session-start"

# Transform 2: manifest name fields
for rel in .claude-plugin/plugin.json .claude-plugin/marketplace.json \
           .codex-plugin/plugin.json .cursor-plugin/plugin.json \
           gemini-extension.json package.json; do
  p="$root/$rel"
  [ -f "$p" ] || continue
  perl -pi -e 's/"name":\s*"superpowers-dev"/"name": "my-superpower"/g; s/"name":\s*"superpowers"/"name": "my-superpower"/g' "$p"
done
echo "apply-my-superpower-brand: done."
