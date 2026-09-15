
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
