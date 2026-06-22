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

## Installing the plugin

Every harness installs the **same built plugin**; only the location of the
marketplace catalog differs. There are two repo installation options:

| Option | What it is | Best for |
|---|---|---|
| **GitHub `release` branch** | The built plugin and its marketplace catalogs sit at the root of the `release` branch — no local checkout required. | Normal use |
| **Local checkout** | Build `dist/` yourself and point the harness at this working copy. | Developing overlays / branding |

`main` (the default branch) is a pristine upstream mirror with **no** built
plugin, so every GitHub install must pin the `release` branch. The technical
name/namespace is `my-superpower` (kebab-case, required by the harnesses); it
shows as **mySuperpower** in the picker via `displayName`.

### Claude Code

From GitHub — pin the `release` branch with `#`:

```
/plugin marketplace add bill-atchison/mySuperpower#release
/plugin install my-superpower@my-superpower
```

From a local checkout — build first; the marketplace at the repo root loads the
plugin from `./dist`:

```
pwsh -NoProfile -File scripts/build-mysuperpower.ps1
/plugin marketplace add C:\Projects\GitHub\mySuperpower
/plugin install my-superpower@my-superpower
```

After rebuilding, refresh the installed copy with `/plugin marketplace update`
(or quick-test directly with `claude --plugin-dir ./dist`).

### Codex

Codex installs from the **`release` branch**, which also carries a Codex
marketplace catalog (`.agents/plugins/marketplace.json`) next to the Claude one.
Register the marketplace, then add the plugin (verified on `codex-cli 0.141.0`):

```
codex plugin marketplace add bill-atchison/mySuperpower --ref release
codex plugin add my-superpower@my-superpower
```

`codex plugin marketplace add` accepts an `owner/repo`, an HTTPS/SSH Git URL, or
a local path; `--ref release` pins the published branch. Both the marketplace
and the plugin are named `my-superpower`. Pull a newer build with
`codex plugin marketplace upgrade`.

> Codex must install from the GitHub `release` branch — the local `dist/` build
> does not contain the Codex catalog (`.agents/plugins/...`), which is emitted
> only when the `release` branch is published.

The plugin version follows `<upstream-base>+fork.<iteration>` (see `CHANGELOG.md`); a
marketplace refresh (`/plugin marketplace update`, or `codex plugin marketplace upgrade`)
pulls a new build only after the version is bumped on a release.

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

## Publishing a release to GitHub

The `release` branch is generated, not hand-edited. To cut a new release after
syncing upstream and/or changing overlays:

```
pwsh -NoProfile -File scripts/publish-mysuperpower.ps1 -Push
```

This builds `dist/`, mirrors it to the root of the `release` branch (via a throwaway
worktree), stamps the plugin version into both release marketplace catalogs — Claude
Code's `.claude-plugin/marketplace.json` and Codex's `.agents/plugins/marketplace.json` —
commits, and pushes `origin/release`. The `mysuperpower` branch stays free of generated
artifacts.

## Credit

Built on [Superpowers](https://github.com/obra/superpowers) (MIT) by Jesse Vincent.
See `LICENSE`.
