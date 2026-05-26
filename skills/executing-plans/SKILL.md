---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans (HTML notes)

## Overview

Load plan, review critically, execute all tasks, report when complete. Throughout, keep a running **implementation-notes.html** for the owner.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (such as Claude Code or Codex). If subagents are available, use `subagent-driven-development` instead of this skill.

## Implementation Notes (HTML) — the running record

Implementation begins **after the plan's browser-preview gate** — i.e., after the owner reviewed the HTML plan in a browser (in `writing-plans`) and accepted it. Kick off with this intent — and honor it whether or not it is typed verbatim:

> implement &lt;PLAN/SPEC&gt; and while you do, keep a running implementation-notes.html
> file with decisions you had to make that weren't in the spec, things you had to
> change, tradeoffs you had to make, or anything else I should know

**Rules for the notes file:**
- It MUST be **HTML** (`.html`), NOT Markdown — self-contained and styled in the same editorial identity as the spec/plan. Start from `templates/implementation-notes-template.html` in this skill directory: its **fixed masthead + palette** (warm paper, Georgia display, maroon eyebrow `Notes · Implementation`, mono meta-card, on-palette table pills + Decisions cards) are reproduced as-is; `frontend-design` may refine the card bodies within that palette (no off-palette accents).
- Save to `docs/mySuperpower/implementation-notes/<YYYY-MM-DD>-<name>.html` (the folder already conveys "implementation-notes", so do NOT repeat it in the filename). Create the folder if it doesn't exist.
- **Self-contained, no network:** all CSS inline, web-safe/system fonts only, no external fonts/CDN/images/`<link>`/external `<script>`. Must render from `file://` offline.
- **Launch the browser as soon as the file is ready:** right after you create it, open it in the owner's browser so they can watch it grow (refresh as you append). Always print the clickable `file:///…` link AND best-effort auto-open with a QUOTED path — Windows/PowerShell `Start-Process "<path>"`, Windows cmd/bash `cmd /c start "" "<path>"`, macOS `open "<path>"`, Linux `xdg-open "<path>"`. Don't rely on the bare `.html` association (it may point at the removed Internet Explorer).
- **Update it LIVE (real-time):** the notes have two regions (no generic activity log): a **Task Status table** (tasks + subtask rows) and a **Decisions & Deviations** card section. As each subtask lands, flip its pill (pending → in progress → `&check; done`); flip the task's top-level row to `done · <short-sha>` on commit. For any substantive off-spec decision/deviation/fix/tradeoff (or anything else the owner should know), append a maroon-tagged `<div class="dd-card">` to the Decisions section. Edit in place; never add `<style>`/fonts/scripts/external refs.
- **Build at setup (Step 1.5):** the Task Status table (one task-row per plan task with its TDD **subtask** rows, all `pending`) plus an empty **Decisions & Deviations** section; keep both in sync as you work.
- **Surface it to the owner alongside the final result** — re-point them to the open browser tab, flip the meta-card status pill to `Implementation — Complete`, and remove the `<meta refresh>` (the live phase is over).

## The Process

### Step 1: Load and Review Plan
1. Read plan file (`docs/mySuperpower/plans/<...>.html`)
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite (the visible task list) and proceed

### Step 1.5: Create the Implementation Notes file (and open it)
- Create `docs/mySuperpower/implementation-notes/<YYYY-MM-DD>-<name>.html` from the template (fixed masthead + palette; `frontend-design` may refine entries on-palette), self-contained. Fill the meta-card (Started/Branch/Spec/Plan/Status) from the plan + spec paths.
- **This is separate from the TodoWrite task list created in Step 1 — keep BOTH.** The notes file does NOT replace the visible terminal task list.
- **As soon as it's ready, launch the browser** to it (quoted `Start-Process "<path>"` / `cmd /c start "" "<path>"` / `open` / `xdg-open`) and print the clickable `file:///…` link, so the owner can watch it as you work.

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress (TodoWrite)
2. Work through the bite-sized steps exactly. The notes hold a **Task Status table** with this task's **subtask** rows; flip each subtask pill to `in progress`/`&check; done` the moment that step lands (red test → implement → commit), and the task's **top-level** row to `done · <short-sha>` after you commit. Update in REAL TIME, editing rows in place (no activity log); the owner is watching in the browser.
3. Run verifications as specified
4. Mark as completed (TodoWrite)

### Step 3: Complete Development

After all tasks complete and verified:
- **Surface `implementation-notes.html` to the owner alongside the result.**
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.** (And record the blocker/decision in `implementation-notes.html`.)

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Stop when blocked, don't guess
- Keep the visible TodoWrite task list checked off as tasks complete
- Keep `implementation-notes.html` current (HTML, self-contained — never Markdown)
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
- **writing-plans** - Creates the HTML plan this skill executes (after its browser-preview gate)
- **frontend-design** - Initial structure/styling for implementation-notes.html
- **superpowers:finishing-a-development-branch** - Complete development after all tasks

**Preferred alternative (if subagents available):**
- **subagent-driven-development** - Same-session execution with fresh subagent per task and two-stage review
