# Changelog

mySuperpower is a personal fork of [obra/superpowers](https://github.com/obra/superpowers).

**Version scheme:** `<upstream-base>+fork.<iteration>` — the base is the upstream
superpowers release this build tracks; `fork.N` counts fork iterations since that sync,
resetting to `fork.1` on each upstream merge. Manage it with `scripts/bump-version.sh`
(`--fork-bump`, `--sync <base>`). Both Claude Code and Codex detect updates by comparing
the version **string**, so every release bumps it.

## 6.0.3+fork.4 — 2026-07-17

- **Unified Implementation Log in the notes template.** The implementation-notes template
  (both the `subagent-driven-development` and `executing-plans` copies) replaces the
  separate "Decisions & Deviations" section with a single **Implementation Log · By Task**:
  per-task `h3.tglabel` group headings, `dd-card` decision cards, and new `.cc`
  before→after code-change cards (dark `pre` blocks with red/green diff borders), appended
  at a `TASK_LOG` comment marker so each task's rationale and code stay co-located. Both
  overlays now instruct the controller/agent to append the full task group — heading,
  decision cards, and one code card per applied change. Structure proven live on the
  DTPOS-325 run (the two-section layout had to be restructured mid-session; the unified
  log then carried a full 5-task run to completion).

## 6.0.3+fork.3 — 2026-07-03

- **Repo-root-anchored doc paths.** The `brainstorming`, `writing-plans`, `executing-plans`,
  and `subagent-driven-development` overlays now anchor their `docs/mySuperpower/...` output
  paths to `$(git rev-parse --show-toplevel)` instead of a bare relative path, so specs,
  plans, and implementation notes always land at the repo root even if the agent's cwd has
  drifted mid-task.
- **Publish script cleanup.** Removed a stale hardcoded `Co-Authored-By: Oz <oz-agent@warp.dev>`
  trailer from `scripts/publish-mysuperpower.ps1` that misattributed every release commit.

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
