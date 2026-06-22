---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (Claude Code, Codex CLI, Codex App, Copilot CLI, and Gemini CLI all qualify; see the per-platform tool refs in `../using-superpowers/references/`). If subagents are available, use my-superpower:subagent-driven-development instead of this skill.

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create todos for the plan items and proceed

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use my-superpower:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

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
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **my-superpower:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
- **my-superpower:writing-plans** - Creates the plan this skill executes
- **my-superpower:finishing-a-development-branch** - Complete development after all tasks


## mySuperpower additions — live HTML implementation notes

The implementation-notes document is a **live artifact**: create it at the start of
execution, keep it current as you work, and finalize it at the end. Use the template at
`skills/executing-plans/templates/implementation-notes-template.html` — it already carries
the auto-refresh, the task/subtask status table, and the Decisions & Deviations cards. Save
to `docs/mySuperpower/implementation-notes/YYYY-MM-DD-<feature>.html`.

Here there is no implementer subagent — **you update the document yourself**, live. Write
**atomically**: render to a temp file and rename it into place.

1. **At execution start (or on resume):**
   - *Repair pass:* if a notes file for this branch already exists with a `<meta ... refresh>`
     tag from a crashed run, strip that tag first.
   - **Rebuild the table from the progress ledger**, not from memory: every task the ledger
     marks complete renders `done`, the first unfinished task becomes the next `in progress`,
     the rest `pending`. On a fresh branch all rows start `pending`.
   - **Open it once in the default browser** (Windows PowerShell `Start-Process <file>`, or
     `cmd /c start "" "<file>"`; macOS `open <file>`; Linux `xdg-open <file>`). If it can't
     open, print the path and continue. Keep that tab visible; the refresh pauses on background tabs.

2. **As you work each task:** flip its row to `in progress`, then to `done · <sha>` once the
   task is complete and committed — within the batch, not deferred to the checkpoint. At most
   one task row is `in progress` at a time. Append a Decisions & Deviations card for any
   substantive decision, deviation, important fix, or tradeoff.

3. **At each checkpoint:** the doc already reflects the completed batch — the checkpoint is for
   review, not for catching the doc up.

4. **At the end:** flip the status pill to `Implementation — Complete`, add any final roll-up
   card, **remove the `<meta ... refresh>` tag**, and commit the finalized document once
   (keep transient states out of history). Then open it for the acceptance gate before finishing
   the branch.
