
## mySuperpower additions — live HTML implementation notes

The implementation-notes document is a **live artifact**: create it at the start of
execution, keep it current as tasks run, and finalize it at the end. Use the template at
`skills/subagent-driven-development/templates/implementation-notes-template.html` — it
already carries the auto-refresh, the task/subtask status table, and the unified
**Implementation Log · By Task** (per-task `h3.tglabel` group headings, `dd-card` decision
cards, and `.cc` before→after code-change cards, appended at the `TASK_LOG` comment marker
so each task's rationale and code stay co-located). Save to
`docs/mySuperpower/implementation-notes/YYYY-MM-DD-<feature>.html`,
rooted at the repo root (`$(git rev-parse --show-toplevel)/docs/mySuperpower/implementation-notes/...`)
— never relative to the current working directory.

**The controller owns every write to this document.** Implementer subagents stay
report-only — never hand the notes file to a subagent. You already hold the per-task
results (each implementer's report plus the progress ledger) needed to update it. Write
**atomically**: render to a temp file and rename it into place, so a refresh that lands
mid-write never shows a truncated document.

1. **At execution start (before Task 1):**
   - *Repair pass:* if a notes file for this branch already exists and still contains the
     `<meta ... refresh>` tag, it was left by a crashed run — strip that tag before continuing.
   - Render the template with one task row per plan task (plus its TDD subtask rows), all
     pills `pending`; fill the SPEC / PLAN / BRANCH / DATE fields.
   - **Open it once in the default browser** (Windows PowerShell `Start-Process <file>`, or
     `cmd /c start "" "<file>"`; macOS `open <file>`; Linux `xdg-open <file>`). If it can't
     open, print the path and continue — never block on the viewer. Tell your human partner
     to keep that tab visible; the refresh pauses on background tabs.

2. **Before dispatching each task's implementer:** flip that task's row to `in progress`.

3. **When that task's review comes back clean** (same step as the ledger line): flip the
   task row and its subtask rows to `done · <sha>` from the implementer's report, and append
   the task's log group at the `TASK_LOG` marker: its `h3.tglabel` heading (task number,
   title, `· <sha>` in the `st-mini` span), a decision card for any substantive off-spec
   decision, deviation, important fix, cross-task interaction, or tradeoff the report
   surfaced, and one `.cc` before→after code card per applied change (minimal excerpts from
   the implementer's report; elide unchanged runs with `...`). Routine progress gets no
   decision card, but every applied code change gets its code card.

4. **If a task is BLOCKED:** leave its row `in progress` and append a card naming the blocker,
   so the doc shows the stall instead of going silent.

5. **At the end (after the final whole-branch review):** flip the status pill to
   `Implementation — Complete`, add any minor-findings roll-up as a final card, **remove the
   `<meta ... refresh>` tag**, commit the finalized document once, then proceed to
   `my-superpower:finishing-a-development-branch`.

Commit cadence: rewrite the file on disk at every step above, but **commit only the finalized
document once**, in step 5 — keep the run's transient states out of git history.
