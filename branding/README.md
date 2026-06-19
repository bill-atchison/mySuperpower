# mySuperpower

A personal, HTML-native fork of [Superpowers](https://github.com/obra/superpowers)
by Jesse Vincent. Same brainstorm -> plan -> execute methodology, but the
brainstorming, writing-plans, executing-plans, and subagent-driven-development
skills produce **self-contained HTML** design docs, plans, and implementation
notes instead of markdown.

## How this fork is built

The git-tracked source stays **pristine upstream**. All mySuperpower-specific
branding and HTML behavior is applied by a build step into a generated `dist/`
directory, which the marketplace points at. This keeps upstream merges
conflict-free.

- Owned content lives in `branding/` (README, CLAUDE, manifest identity) and
  `overlays/` (per-skill HTML behavior).
- `scripts/build-mysuperpower.ps1` (or `.sh`) assembles `dist/`.
- `dist/` is git-ignored; build it locally before installing.

## Install (local plugin)

Build, then add the marketplace at the repo root and install:

```
pwsh -NoProfile -File scripts/build-mysuperpower.ps1
/plugin marketplace add C:\Projects\GitHub\mySuperpower
/plugin install my-superpower@my-superpower
```

The marketplace at the repo root loads the plugin from `./dist`. The technical
name/namespace is `my-superpower` (kebab-case, required by Claude Code); it shows
as **mySuperpower** in the `/plugin` picker via `displayName`.

After rebuilding, refresh the installed copy with `/plugin marketplace update`
(or quick-test directly with `claude --plugin-dir ./dist`).

## HTML workflow output

Skills write to `docs/mySuperpower/specs/` (designs), `docs/mySuperpower/plans/`
(plans), and `docs/mySuperpower/implementation-notes/` (implementation notes),
as distinctive, offline HTML documents.

## Updating from upstream

This repo tracks `obra/superpowers` as the `upstream` remote, with `main` kept as
a clean mirror of upstream and `mysuperpower` as the rolling customization branch:

```
git checkout main
git fetch upstream
git merge --ff-only upstream/main
git push origin main

git checkout mysuperpower
git merge main                 # pristine source -> clean merges
pwsh -NoProfile -File scripts/build-mysuperpower.ps1
/plugin marketplace update     # or reinstall from dist/
```

Because the tracked skills and manifests are pristine upstream, merges rarely
conflict. Branding and HTML behavior re-apply automatically at build time. The
root `.claude-plugin/marketplace.json` is marked `merge=ours` so upstream never
clobbers the fork's marketplace identity.

## Credit

Built on [Superpowers](https://github.com/obra/superpowers) (MIT) by Jesse Vincent.
See `LICENSE`.
