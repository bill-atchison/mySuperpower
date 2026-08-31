# Changelog

mySuperpower is a personal fork of [obra/superpowers](https://github.com/obra/superpowers).

**Version scheme:** `<upstream-base>+fork.<iteration>` — the base is the upstream
superpowers release this build tracks; `fork.N` counts fork iterations since that sync,
resetting to `fork.1` on each upstream merge. Manage it with `scripts/bump-version.sh`
(`--fork-bump`, `--sync <base>`). Both Claude Code and Codex detect updates by comparing
the version **string**, so every release bumps it.

## 6.3.0+fork.2 — 2026-08-30

- **HTML task briefs for subagent-driven-development.** The fork's `writing-plans` skill
  emits plans as self-contained HTML, but upstream's `task-brief` selects a task with awk
  on a markdown heading — it matched nothing in a fork plan, wrote a zero-byte file and
  exited 3, a hard stop before the first implementer was ever dispatched. A new fork-owned
  `scripts/task-brief-html` reads them properly. Upstream's `task-brief`, `sdd-workspace`
  and `review-package` are untouched.
  - Same argument order, same default output location and same exit codes as upstream, so
    the controller's only branch is on the plan's file extension.
  - Selection keys on structure: the Nth `<section class="task">`, cross-checked against
    its first heading, with a heading-only fallback for plans that have no task sections.
    Task identity in fork plans is **positional** — the 2026-05-25 plan numbers no heading
    at all — so position governs, a heading that disagrees is a hard error rather than a
    guess, and an out-of-range task never falls through to the heading search.
  - Entities are decoded, so an implementer receives `<meta>` rather than `&lt;meta&gt;`.
    `&amp;` is decoded last, so a double-escaped `&amp;lt;` stays `&lt;`.
  - Code fences are sized to outrun the longest backtick run in the payload. Plan code
    blocks really do contain their own fences; a fixed ``` wrapper would be closed by the
    first inner one, silently demoting the rest of the requirements to prose.
  - Every failure between the temp file and the rename runs through one cleanup point, so
    a failed extraction never leaves a previously good brief looking current. A caller's
    explicit `OUTFILE` is never deleted.
  - `--plan` renders the whole plan body for setup — not a summary, because the pre-flight
    conflict scan needs every task's full text.
- **Overlays can ship files.** `overlay.json` gains a third verb beside `replaces` and
  `append`: `files: [{ from, to, exec }]`, copying a fork-owned file into
  `dist/skills/<skill>/`. Every schema rule fails the build loudly and names the offending
  entry — an unvalidated copy step is a file-write primitive pointed at the build output.
  The build then asserts every declared file actually landed.
- **Publish maps fork-owned executables to their published paths.** A fork file's source
  lives under `overlays/`, which is excluded from `dist/`, so the index-derived chmod list
  missed it entirely and it published `100644` — the same "Permission denied" failure
  6.2.0+fork.2 fixed, arriving through a new door. The executable bit is now *declared*
  (`exec: true`) rather than sniffed, so a source committed `100644` by accident fails the
  release instead of shipping a broken plugin.
- **Extensionless skill scripts are pinned to LF.** `*.sh` never reached them, so their
  released blobs were LF only because `core.autocrlf` happened to normalize them inside the
  publish worktree. A publishing machine with `core.autocrlf=false` would have shipped a
  CR-terminated shebang.
- **Two stale markdown call sites migrated.** The rebrand cascade rewrites
  `docs/superpowers/` to `docs/mySuperpower/` and never touches the extension, so upstream's
  examples shipped with fork paths and markdown suffixes — a path shape that cannot exist
  in this fork. Fixed in the SDD worked example and the `requesting-code-review` dispatch
  example, with a build-time assertion that scans the whole built tree for the next one.

## 6.3.0+fork.1 — 2026-08-28

- **Synced to upstream superpowers 6.3.0** (from base 6.2.0). Merged 2 upstream commits
  (40 files). Notable upstream changes now in the fork:
  - **Brainstorming scales its ceremony** — requests are classified as *spike*, *bounded*,
    or *architectural*; only the architectural path writes a spec and hands off to
    writing-plans. Every path still stops for an explicit approval before implementation.
  - **SDD circuit-breaker and cost fixes** — controllers rule on non-catastrophic plan
    conflicts instead of stalling, the pre-dispatch conflict scan records its checks in the
    ledger, small same-shape tasks batch into one dispatch, and implementers/reviewers may
    no longer spawn their own subagents.
  - **Plans carry a `Spec:` pointer** so SDD resolves plan conflicts against the design.
  - **`finishing-a-development-branch` no longer force-removes worktrees** holding
    uncommitted work — it stops, names the files, and asks.
  - **New harness manifests** — `.devin-plugin/plugin.json` and `.hermes-plugin/`
    (`plugin.yaml` + `__init__.py`), both registered in `.version-bump.json`.
  - **Codex** — event-driven subagent waits, explicit model/effort pinning on spawn.
  - Fixes: `writing-skills/render-graphs.js` works on Windows; Copilot CLI backgrounding
    guidance corrected.
- **Merge conflicts resolved.** The version field in all nine declared manifests (resolved to
  the fork scheme), `.gitignore` (fork's `/dist/` + `/.baseline-skills/` kept alongside
  upstream's Python ignores), and `scripts/bump-version.sh` — where upstream's YAML manifest
  support (`read_manifest_field`/`write_manifest_field`, `preflight_manifests`, yq) met the
  fork's `get_current_version` helper. `get_current_version` now reads through
  `read_manifest_field`, so `--check`/`--audit`/`--fork-bump`/`--sync` see the Hermes YAML
  manifest too.
- **`declared_files()` strips CR** from Windows jq's CRLF output. A trailing CR on every
  field name was harmless to jq (which treats CR as whitespace) but broke yq's `strenv()`
  lookup outright — `--check` failed with `Error: no matches found` on the first YAML
  manifest. `scripts/bump-version.sh` now requires **yq** in addition to jq.
- **Brainstorming overlay scoped to the architectural path.** The HTML-spec instructions and
  the two gates (Codex review, browser acceptance) now say explicitly that they apply only
  where upstream writes a spec; spike and bounded work stays in chat. Both required overlay
  anchors survived the upstream rewrite, and the plan template's `Spec` meta-card row
  already satisfies upstream's new "spec travels with the plan" rule — no other fork edits
  were needed.
- **Cut with the 6.2.0+fork.2 publish fix in place** — the release branch is republished
  with the executable bits re-asserted from the source index (see the entry below).

## 6.2.0+fork.2 — 2026-08-12

- **Fixed: published releases lost the executable bit**, so hooks and skill scripts in the
  installed plugin failed with `Permission denied` (exit 126) on macOS and Linux:

  ```
  sh: .../my-superpower/6.0.3-fork.3/hooks/run-hook.cmd: Permission denied
  ```

  The source tree was always correct (`hooks/run-hook.cmd` is committed `100755`) — the bit
  was lost at publish time. Windows has no Unix permission bit, so a release cut from
  Windows stages every freshly copied file as `100644`. Every release commit back to
  2026-06-19 shows `100644`; the same publish run on macOS produces `100755`.

  `scripts/publish-mysuperpower.ps1` now re-asserts the mode from the source index via
  `git update-index --chmod=+x` before committing the release. `git ls-files -s` reads the
  index rather than the filesystem, so it reports the committed `100755` on every platform.
  The file list is derived, not hardcoded, so a new upstream executable is covered with no
  further change to the script.

  This restored `+x` on 18 published paths — 9 files across the root (Claude) and
  `plugins/my-superpower/` (Codex) copies: both hooks plus `start-server.sh`,
  `stop-server.sh`, `review-package`, `sdd-workspace`, `task-brief`, `find-polluter.sh`
  and `render-graphs.js`.

- No upstream files were changed; the fix is confined to the fork's publish script, so
  upstream merges remain clean.

## 6.2.0+fork.1 — 2026-07-27

- **Synced to upstream superpowers 6.2.0** (from base 6.0.3). Merged 70 upstream commits;
  the only conflicts were the version fields in the seven declared manifests, resolved to
  the fork scheme. Notable upstream changes now in the fork:
  - **SDD lifecycle restructure** — plan-scoped durable workspace (`.superpowers/sdd/<plan>`),
    resume-based fix loop with a five-round breaker, a scoped re-review prompt, and a
    rationalization table in `subagent-driven-development`.
  - **Skills compression sweep** across `brainstorming`, `writing-plans`,
    `verification-before-completion`, `systematic-debugging`, `receiving-code-review`,
    `dispatching-parallel-agents`, and others.
  - **Windows SessionStart fix** — the hook is dispatched via Git Bash (`run-hook.cmd`,
    `shell: bash`), removing the PowerShell/CMD fallback hazards.
  - **Codex packaging** — `scripts/package-codex-plugin.sh` and the `.agents/plugins`
    marketplace manifest; the standalone `hooks/session-start-codex` /
    `hooks/hooks-codex.json` were removed upstream in favor of hook autodiscovery.
- **Fork customizations carried through cleanly.** All four HTML overlays (`brainstorming`,
  `writing-plans`, `executing-plans`, `subagent-driven-development`) still apply — every
  required build anchor survived the compression sweep, so no overlay edits were needed.
  The HTML templates, branding, and repo-root-anchored `docs/mySuperpower/` output paths
  are unchanged. The live implementation-notes overlays remain coherent with the new
  plan-scoped ledger, which they treat as the source of truth for the status table.

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
