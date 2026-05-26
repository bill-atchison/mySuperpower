# mySuperpower — Project Notes

This repository is **mySuperpower**, a personal fork of
[obra/superpowers](https://github.com/obra/superpowers). It is installed as a
local Claude Code plugin named `my-superpower` (branded **mySuperpower**).

## What is different from upstream

The 4 workflow skills emit self-contained HTML instead of markdown:
`brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`.
They write to `docs/mySuperpower/specs/` and `docs/mySuperpower/plans/`. All other
skills are upstream's, namespaced `my-superpower:`.

## Taking changes from upstream

```
git fetch upstream
git merge upstream/main
# resolve conflicts on the 4 forked skills, then (on a clean index):
pwsh -NoProfile -File scripts/apply-my-superpower-brand.ps1
git add -u && git commit
```

`scripts/apply-my-superpower-brand.*` is idempotent and re-applies the
`my-superpower:` namespace cascade + manifest `name` fields. Run it only after all
conflicts are resolved.

## Out of scope

Upstream's `tests/` and the OpenCode harness files (`.opencode/`) are not
maintained in this fork.
