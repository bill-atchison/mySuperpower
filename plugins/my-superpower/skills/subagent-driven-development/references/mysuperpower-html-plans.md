# mySuperpower: HTML plans

The fork's `writing-plans` skill saves implementation plans as self-contained
HTML under `docs/mySuperpower/plans/`. **When `PLAN_FILE` ends in `.html`, use
`scripts/task-brief-html` everywhere this skill says `scripts/task-brief`.** A
markdown plan still follows SKILL.md's instructions exactly - this override is
scoped to HTML plans only.

`scripts/task-brief-html` takes the same arguments, writes to the same workspace,
and exits with the same codes as `scripts/task-brief`:

```
bash scripts/task-brief-html PLAN_FILE TASK_NUMBER   # -> <workspace>/task-N-brief.md
bash scripts/task-brief-html --plan PLAN_FILE        # -> <workspace>/plan-body.md
```

**At setup, do not open the `.html` plan directly.** Run
`bash scripts/task-brief-html --plan PLAN_FILE` and read the file it writes. That is
the whole plan body - Overview, Global Constraints, and every task in full, with
the stylesheet and presentational markup removed. It is not a summary: the
pre-flight conflict scan needs every task's full text to produce its per-pair
rows, and a scan run on missing input looks exactly like a clean scan.

Read the Spec the same way when the plan names one and it is also `.html`.

Two failure modes are worth recognizing, because both mean the plan is wrong
rather than the tool:

- **Exit 3, "section N is headed Task M"** - the plan's task sections are
  numbered inconsistently with their order. Fix the plan; do not guess which
  numbering was meant.
- **Exit 3, "task N not found"** - there is no Nth `<section class="task">` and
  no heading naming that task. Any brief previously written at the default path
  has been deleted, so there is no stale brief to mistake for a current one.

Warnings on stderr about undecoded entities are not failures - the brief is
still written. Report them, because they mean the plan template has grown an
entity the extractor does not know yet.
