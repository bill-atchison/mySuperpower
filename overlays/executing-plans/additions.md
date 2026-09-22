
## mySuperpower additions — live HTML implementation notes

The implementation-notes document is a **live artifact**: create it at the start of
execution, keep it current as you work, and finalize it at the end. Use the template at
`skills/executing-plans/templates/implementation-notes-template.html` — it already carries
the auto-refresh, the task/subtask status table, and the unified **Implementation Log ·
By Task** (per-task `h3.tglabel` group headings, `dd-card` decision cards, and `.cc`
before→after code-change cards, appended at the `TASK_LOG` comment marker so each task's
rationale and code stay co-located). Save
to `docs/mySuperpower/implementation-notes/YYYY-MM-DD-<feature>.html`, rooted at the repo root
(`$(git rev-parse --show-toplevel)/docs/mySuperpower/implementation-notes/...`) — never relative
to the current working directory.

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
   task is complete and committed — in the same call as `task-done`, never deferred. At most
   one task row is `in progress` at a time. Append the task's log group at the `TASK_LOG`
   marker: its `h3.tglabel` heading (task number, title, `· <sha>`), a decision card for any
   substantive decision, deviation, important fix, or tradeoff, and one `.cc` before→after
   code card per change (minimal excerpts; elide unchanged runs with `...`).

3. **Rulings and final-review fixes** go in the doc as well as the ledger: every
   `Ruling:` line becomes a decision card in its task's log group, and each fix from the
   final review's fix pass gets a `.cc` code card under a final group.

4. **At the end (after the final whole-branch review):** flip the status pill to
   `Implementation — Complete`, add any deferred-minors roll-up as a final card, **remove
   the `<meta ... refresh>` tag**, and commit the finalized document once (keep transient
   states out of history). Then open it for the acceptance gate before finishing the branch.

## mySuperpower additions — executing a plan

The plan's kickoff prompt is honored whether or not your human partner types it verbatim:
*"implement &lt;SPEC&gt; and while you do, keep a running implementation-notes.html file
with decisions you had to make that weren't in the spec, things you had to change,
tradeoffs you had to make, or anything else I should know."* The folder already says what
the notes are — do not repeat "implementation-notes" in the filename.

**Open every file the plan names before acting on the instruction that names it.** This
is measured, not theoretical: across one six-task plan, roughly fifteen claims about the
repository did not match it — an import alias that did not exist (hit independently by
three tasks), a settings builder that did not exist, a function asserted to be
module-level that was imported function-locally, three wrong line numbers inside
docstrings shipped *as code*, and a shared helper hardcoded to one resolution with no
geometry parameter. Six spec reviews and three plan reviews missed all of them; opening
the file caught them every time.

**A supplied test is not a passing test until you have watched it fail.** Plan-supplied
test bodies have shipped that could not fail — one parametrised an expected value and
never asserted on it, one asserted only the last element of a sequence too short to
exercise the rule, and one patched an attribute the function under test never reads.
Mutate the implementation and watch it go red before recording a pass.

When you find a mismatch: fix it, and record it in the implementation notes as a decision
card. Do not work around it silently, and do not adjust an assertion to make it green
without first establishing which behaviour is correct.

## mySuperpower additions — ablation pass before the final review

Once every task has its `Task <N>: complete` ledger line, and before running
`review-package` for the final review, run one ablation pass over the branch:

1. List every abstraction the branch added: helpers, interfaces, base
   classes, config knobs, wrappers, layers, indirection of any kind.
2. For each one, replace it with the direct thing — inline the single-use
   helper, call the one implementation, write the never-changing value —
   and run the full test suite. Behavior stays; only the layer goes.
3. Name what failed: a test, a spec requirement, or a second caller that
   now has nothing to call. "It might be useful later" is not a failure.
4. If something failed, restore the abstraction and move on. If nothing
   failed, commit the removal.
5. Record each removal, and each restore with its reason, as a decision
   card in the implementation notes and a `Ruling:` line in the ledger.

The final reviewer then reviews the ablated branch. Run this once, at the
end; per-task ablation removes scaffolding before its consumer exists.
