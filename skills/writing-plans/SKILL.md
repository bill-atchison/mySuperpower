---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans (HTML output)

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

The plan is delivered as a **distinctive, self-contained HTML document** (not markdown), styled with the `frontend-design` skill.

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

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Content

The HTML plan MUST open with the FIXED masthead from `templates/plan-doc-template.html` (same editorial identity as the spec):

- **Eyebrow (fixed):** `Plan · Implementation`
- **Title (`{{TITLE}}`):** the feature name / "[Feature] Implementation Plan"
- **Subtitle (`{{SUBTITLE}}`):** one-line scope summary (the bold-italic line; may start "TDD: …")
- **Meta-card:** Date (`{{DATE}}`, today), Branch (`{{BRANCH}}`, target branch or `TBD`), Spec (`{{SPEC}}`, path to the source spec html)
- **Agentic-note box (fixed):** REQUIRED SUB-SKILL — execute task-by-task with TDD (red → green → commit) using `subagent-driven-development` (recommended) or `executing-plans`; Codex review of this plan + spec before implementation; per-task two-stage review. Steps are checkbox-styled; track progress with task tools, not by editing the file.

Immediately after the masthead, the body opens with an **Overview** section carrying **Goal** (one sentence), **Architecture** (2-3 sentences), and **Tech Stack** (key technologies/libraries).

## Task Structure

Render each task as its own `<section>`:

- `<h2>` / `<h3>` task heading: `Task N: [Component Name]`
- A **Files** block listing exact paths — Create / Modify (`path:line-range`) / Test
- An ordered list of steps. Each step is a checkbox-styled `<li>` with the step title, followed by the concrete content:
  - **Code steps:** complete, runnable code in `<pre><code>` (escape `<`, `>`, `&`)
  - **Run steps:** the exact command and the expected output
  - **Commit steps:** the exact `git add` / `git commit` commands

Every task follows the TDD rhythm: write failing test → run it (expect FAIL) → minimal implementation → run it (expect PASS) → commit. Show the actual test code, the actual implementation, and the exact commands with expected output — never describe them abstractly.

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Required Closing Tasks

Every generated plan MUST end with these ordered steps in its final task (per project policy — a plan must not commit final code without a `/simplify` pass interposed before the last commit):

1. Complete all code changes for the plan.
2. Run `/simplify` to review the changed code for reuse, quality, and efficiency, and apply any fixes it identifies.
3. Re-run tests / verification after the `/simplify` edits.
4. Create the FINAL commit (the `/simplify` pass occurs BEFORE this last commit, not after).

## Documentation (HTML output)

Render the validated plan as a **distinctive, self-contained HTML document** and save it to `docs/mySuperpower/plans/YYYY-MM-DD-<feature-name>.html`. (User preferences for plan location override this default.)

- **REQUIRED SUB-SKILL:** Use `frontend-design` to style the document **body** — the Overview, task sections, checkbox-styled steps, tables, and high-contrast monospace code blocks — **within the fixed masthead and palette** defined by the template. It must NOT restyle the header or use off-palette accents (no stray cyan/purple); draw accents from the maroon/amber/ink set, and style the step checkboxes on-palette. Readability of the plan (code + commands) comes first.
- **Hard constraint — fully self-contained, no network:** Everything inline in one `.html` file. All CSS in a single `<style>` block. **No external fonts, no Google Fonts, no CDN libraries, no remote images, no `<link>` or external `<script>` references.** Use web-safe / system font stacks only (e.g. Georgia/Times serif, `system-ui` sans, `ui-monospace`/Consolas for code). The file MUST render identically when opened from `file://` with no internet access. **This constraint overrides `frontend-design`'s default preference for distinctive web fonts** — get distinctiveness from layout, color, and composition instead.
- **Fixed masthead + structure contract:** Start from `templates/plan-doc-template.html`. Its header block and CSS palette are **FIXED** — reproduce them as-is so every plan shares the spec's editorial identity (warm-paper background, Georgia display, maroon eyebrow `Plan · Implementation`, mono meta-card, tan agentic-note callout). `frontend-design` styles only the body (Overview → task sections → checkbox-styled steps), using the template's CSS variables.
- Create the `docs/mySuperpower/plans/` directory if it does not exist
- Use elements-of-style:writing-clearly-and-concisely skill if available
- Commit the HTML plan document to git

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. Closing tasks present:** Confirm the plan ends with the `/simplify`-before-final-commit sequence from "Required Closing Tasks".

**5. Self-contained check:** No external CSS/JS/font/image references, no `<link>` or CDN URLs; web-safe/system font stacks only; all CSS inline; code in `<pre><code>` with escaped entities; valid HTML; renders from `file://` offline.

**6. Masthead check:** Header reproduced from the template — fixed eyebrow `Plan · Implementation`, title, subtitle, meta-card (Date/Branch/Spec), and the agentic-note callout; body (incl. step checkboxes) styled on-palette with the template's variables — no off-palette accent colors.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Codex Review (max 3 iterations)

After the self-review passes, have Codex review the HTML plan before the execution hand-off (per project policy — review the plan before execution begins):

1. Dispatch Codex via the `codex:rescue` skill (the `codex:codex-rescue` agent), pointing it at the HTML plan file path, and ask it to return concrete, actionable feedback on the plan (coverage, correctness, ordering, missing steps).
   - **Fallback when Codex is unavailable:** if Codex cannot be reached or does not respond, dispatch a general-purpose subagent using `plan-document-reviewer-prompt.md` (in this skill directory) to perform the equivalent review instead. The 3-iteration cap applies either way.
2. Address Codex's actionable feedback by revising the HTML plan, then re-submit to Codex.
3. **Cap this loop at 3 iterations total.** If material concerns remain unresolved after the 3rd iteration, STOP looping and surface the open items to the user for a decision.
4. Proceed to the browser-preview gate only after the loop concludes — either Codex has no further material feedback, or the open items have been surfaced to the user.

## Browser-Preview Gate (user acceptance) — HARD STOP

After the Codex review loop concludes, **automatically open the finished HTML plan in the browser, then STOP.** Do NOT proceed to the execution hand-off, and do NOT invoke any executor, until the user **explicitly agrees** to the HTML plan. Reaching this gate is not acceptance; silence is not acceptance; only an explicit approval from the user (e.g. "yes", "approved", "looks good") passes the gate. Because the plan is self-contained, it renders correctly straight from disk.

1. **Open the rendered plan in the browser.** Always do BOTH:
   - **Print the clickable file URL** — absolute path, forward slashes: `file:///C:/.../<file>.html`. This is the reliable fallback; it works regardless of OS, shell, or file associations.
   - **Best-effort auto-open with a QUOTED absolute path** (an unquoted path breaks on spaces):
     - Windows / PowerShell: `Start-Process "<absolute path>"`
     - Windows / cmd or bash: `cmd /c start "" "<absolute path>"`
     - macOS: `open "<absolute path>"`
     - Linux: `xdg-open "<absolute path>"`
   - Prefer these forms — they honor the user's **default browser**. Do NOT rely on the bare `.html` association (`ftype`/`iexplore`): on some Windows machines it still points at the removed Internet Explorer and will fail. If auto-open errors or opens the wrong app, tell the user to click the printed `file://` link.
2. Ask:
   > "HTML plan written and committed to `<path>`. Open it in your browser to review — let me know if you want any changes before we start implementing."
3. Wait for the user's response. If they request changes, revise the plan and re-run the self-review and Codex review loops, then re-present for preview.
4. **Only an explicit user approval passes the gate.** Once the user approves, offer the execution hand-off below. If they request changes, revise, re-run the self-review + Codex loops, **re-open the plan in the browser**, and wait again. Never continue on silence or assumption. The downstream executors (`subagent-driven-development` / `executing-plans`) treat this acceptance as the "browser-preview gate" their implementation-notes flow refers to.

## Execution Handoff

After the browser-preview gate (user acceptance), offer the execution choice:

**"Plan complete and saved to `docs/mySuperpower/plans/<filename>.html`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use `subagent-driven-development`
- Fresh subagent per task + two-stage review; keeps the visible task list checked off and a running implementation-notes.html

**If Inline Execution chosen:**
- **REQUIRED SUB-SKILL:** Use `executing-plans`
- Batch execution with checkpoints; keeps the visible task list checked off and a running implementation-notes.html
