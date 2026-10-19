
## mySuperpower additions — HTML-native output

This is the HTML-native variant of brainstorming. Override the design-doc output format
**for a project with a written design** — the only size that writes a document. A quick
task or a small change is described in chat, and a spike brings what it taught you back
into the conversation; none of them writes a document, so none uses the template or the
gates below. The approval gate for those sizes is unchanged.

- Write the validated design as a **distinctive, self-contained HTML document** (not markdown), styled with the `frontend-design` skill, using the template at `skills/brainstorming/templates/design-doc-template.html`.
- Save to `docs/mySuperpower/specs/YYYY-MM-DD-<topic>-design.html`, rooted at the repo root (`$(git rev-parse --show-toplevel)/docs/mySuperpower/specs/...`) — never relative to the current working directory — and commit.

### Format rules

- One `.html` file with an inline `<style>` block (inline `<script>` only if genuinely
  needed). No external assets, fonts, or CDN links — the document must render from
  `file://` with no network.
- Use `frontend-design` so the document is polished and readable, not generic AI
  boilerplate: styled headings, `<pre><code>` blocks, real `<table>`s.
- Cover what The Written Design asks for: intent and the why; goals, non-goals,
  anti-goals; constraints; the parts of the how they decided; what's left to the
  builder. HTML changes the rendering, not the content.
- This applies to NEW documents. Existing `.md` specs are not migrated. Everything
  else in the repository stays markdown.

### Layout: one measure

The template already sets a single reading measure: body text (`p`, `ul`, `ol`) is
capped just under the width of the widest full-width block (tables, `pre`, callouts),
so the right edge of the page varies by tens of pixels, not hundreds. When
`frontend-design` adds body styles, **do not narrow `p`/`ul`/`ol` below the template's
measure** and do not widen any block past the wrap. A document whose widest code line
needs more room widens the wrap, and the body-text measure moves with it.

Check it before sign-off — two greps settle it:

- every `grid-template-columns` rule, resolved last-wins with `@media` blocks stripped —
  confirms no later per-document rule has captured an earlier grid;
- the widest line inside each `<pre><code>` — confirms nothing scrolls horizontally.

### Gates, in order

Run these before invoking `my-superpower:writing-plans`:

1. **Builder check:** run the builder check above on the `.html` document and settle
   its three piles before anything else.
2. **Codex review (≤3 rounds):** have Codex review the spec; revise up to three times.
3. **Browser preview:** open the `.html` in your human partner's browser
   (Windows PowerShell `Start-Process "<path>.html"`; macOS `open`; Linux `xdg-open`).
4. **Owner sign-off — STOP here.** Surface the spec and wait for explicit acceptance.
   Do NOT auto-proceed to the plan: changes are cheaper at the spec stage than derived
   through a plan.
