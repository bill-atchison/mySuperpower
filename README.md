# mySuperpower

A personal, HTML-native fork of [Superpowers](https://github.com/obra/superpowers)
by Jesse Vincent. Same brainstorm → plan → execute methodology — but the
brainstorming, writing-plans, executing-plans, and subagent-driven-development
skills produce **self-contained HTML** design docs, plans, and implementation
notes instead of markdown.

## Install (local plugin)

```
/plugin marketplace add C:\Projects\GitHub\mySuperpower
/plugin install my-superpower@my-superpower
```

The plugin's technical name/namespace is `my-superpower` (kebab-case, required by
Claude Code); it shows as **mySuperpower** in the `/plugin` picker via `displayName`.

## HTML workflow output

Skills write to `docs/mySuperpower/specs/` (designs) and `docs/mySuperpower/plans/`
(plans), as distinctive, offline HTML documents. Implementation notes land in
`docs/mySuperpower/implementation-notes/`.

## Updating from upstream

This repo tracks `obra/superpowers` as the `upstream` remote:

```
git fetch upstream
git merge upstream/main
# resolve any content conflicts on the 4 forked skills, then:
pwsh -NoProfile -File scripts/apply-my-superpower-brand.ps1   # or the .sh
git add -u
git commit
```

The rebrand script (`scripts/apply-my-superpower-brand.*`) is idempotent and
re-applies the `my-superpower:` namespace cascade + manifest names. Run it only
after all merge conflicts are resolved (never on a tree with conflict markers).

## Credit

Built on [Superpowers](https://github.com/obra/superpowers) (MIT) by Jesse Vincent.
See `LICENSE`.
