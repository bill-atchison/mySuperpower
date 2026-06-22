# Changelog

mySuperpower is a personal fork of [obra/superpowers](https://github.com/obra/superpowers).

**Version scheme:** `<upstream-base>+fork.<iteration>` — the base is the upstream
superpowers release this build tracks; `fork.N` counts fork iterations since that sync,
resetting to `fork.1` on each upstream merge. Manage it with `scripts/bump-version.sh`
(`--fork-bump`, `--sync <base>`). Both Claude Code and Codex detect updates by comparing
the version **string**, so every release bumps it.

## 6.0.3+fork.2 — 2026-06-21

- **Live implementation-notes.** The `subagent-driven-development` and `executing-plans`
  overlays now drive the implementation-notes HTML as a live document: created and opened
  in the browser at execution start, updated as tasks run, finalized (auto-refresh
  stripped) at the end. The template is reused unchanged. (PR #2)
- **Fork version scheme.** Adopted `<upstream-base>+fork.<iteration>`. `bump-version.sh`
  gains `--fork-bump` and `--sync <base>`; the README/CLAUDE docs describe the scheme and
  the upstream-merge re-assert step.

## 6.0.3+fork.1 — prior fork work (recorded retroactively)

- **Release-branch distribution + Codex support.** Added the `release`-branch publish
  pipeline (`scripts/publish-mysuperpower.ps1`) serving a GitHub-hosted marketplace, with
  a Codex catalog (`.agents/plugins/marketplace.json`) and the plugin in a subdirectory so
  `codex plugin add` resolves it.
- **Install docs.** README install options for Claude Code and Codex from the `release`
  branch.

## 6.0.3 — upstream base

- Tracks upstream superpowers `6.0.3`. The HTML-native fork conversion (4 workflow skills
  emit self-contained HTML; `my-superpower:` namespace; per-harness manifests) predates
  this changelog.
