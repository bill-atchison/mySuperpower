
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
