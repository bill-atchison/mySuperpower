---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** If working in an isolated worktree, it should have been created via the `my-superpower:using-git-worktrees` skill at execution time.

**Save plans to:** `docs/mySuperpower/plans/YYYY-MM-DD-<feature-name>.html`
- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a
fresh reviewer's gate. When drawing task boundaries: fold setup,
configuration, scaffolding, and documentation steps into the task whose
deliverable needs them; split only where a reviewer could meaningfully
reject one task while approving its neighbor. Each task ends with an
independently testable deliverable.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use my-superpower:subagent-driven-development (recommended) or my-superpower:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Spec:** [path to the spec/design doc this plan implements — the plan
argues from the spec, so the spec travels with it; executors read both]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/mySuperpower/plans/<filename>.html`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use my-superpower:subagent-driven-development
- Fresh subagent per task + two-stage review

**If Inline Execution chosen:**
- **REQUIRED SUB-SKILL:** Use my-superpower:executing-plans
- Batch execution with checkpoints for review


## mySuperpower additions — HTML-native output

This is the HTML-native variant of writing-plans. Override the plan output format:

- Write the implementation plan as a **self-contained, styled HTML document** (not markdown), using the template at `skills/writing-plans/templates/plan-doc-template.html`.
- Save to `docs/mySuperpower/plans/YYYY-MM-DD-<feature-name>.html`, rooted at the repo root (`$(git rev-parse --show-toplevel)/docs/mySuperpower/plans/...`) — never relative to the current working directory.
- Keep the plan's task/step structure (goal, architecture, tasks, bite-sized steps) inside the HTML body.

### Format rules

- One `.html` file with an inline `<style>` block (inline `<script>` only if genuinely
  needed). No external assets, fonts, or CDN links — the document must render from
  `file://` with no network.
- Use `frontend-design` so the document is polished and readable, not generic AI
  boilerplate: styled headings, `<pre><code>` blocks, real `<table>`s.
- Keep the structure a markdown plan would have: problem, task breakdown, risk
  assessment, verification, self-review. HTML changes the rendering, not the content.
- This applies to NEW documents. Existing `.md` plans are not migrated. Everything
  else in the repository stays markdown.

### Layout: one measure

The template already sets a single reading measure: body text (`p`, `ul`, `ol`) is
capped just under the width of the widest full-width block (tables, `pre`, task
sections), so the right edge of the page varies by tens of pixels, not hundreds. When
`frontend-design` adds body styles, **do not narrow `p`/`ul`/`ol` below the template's
measure** and do not widen any block past the wrap. A plan whose widest code line needs
more room widens the wrap, and the body-text measure moves with it.

Check it before sign-off — two greps settle it:

- every `grid-template-columns` rule, resolved last-wins with `@media` blocks stripped —
  confirms no later per-document rule has captured an earlier grid;
- the widest line inside each `<pre><code>` — confirms nothing scrolls horizontally.

### Gates, in order

1. **Codex review (≤3 rounds):** have Codex review the plan against the spec; revise up
   to three times.
2. **Browser preview:** once review has concluded (READY, or owner sign-off on the
   remaining items), open the `.html` in your human partner's browser
   (Windows PowerShell `Start-Process "<path>.html"`; macOS `open`; Linux `xdg-open`).
   This is the last gate before coding — get explicit sign-off.

### Handing off to implementation

Implementation keeps a **live implementation-notes file** as it goes, not a write-up at
the end. Save it to `docs/mySuperpower/implementation-notes/YYYY-MM-DD-<feature>.html`;
the folder already says what it is, so do not repeat "implementation-notes" in the
filename. The kickoff prompt, honored whether or not your human partner types it verbatim:

> implement &lt;SPEC&gt; and while you do, keep a running implementation-notes.html
> file with decisions you had to make that weren't in the spec, things you had to
> change, tradeoffs you had to make, or anything else I should know

## mySuperpower additions — Self-Review, item 4

Add this to the Self-Review checklist after type consistency:

**4. Ablation:** For each abstraction the plan introduces — a helper,
interface, base class, config knob, wrapper, or layer — name the task that
cannot be completed without it. If no task needs it, or one direct call
site would do, replace it in the plan with the direct thing: inline the
helper's body at its one caller, name the one implementation instead of
the interface, write the value instead of the knob. The plan still shows
that concrete code. A plan gets no credit for structure it will not use.
