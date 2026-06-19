
## mySuperpower additions — HTML-native output

This is the HTML-native variant of brainstorming. Override the design-doc output format:

- Write the validated design as a **distinctive, self-contained HTML document** (not markdown), styled with the `frontend-design` skill, using the template at `skills/brainstorming/templates/design-doc-template.html`.
- Save to `docs/mySuperpower/specs/YYYY-MM-DD-<topic>-design.html` and commit.

Then run two gates before transitioning to `my-superpower:writing-plans`:

1. **Codex review (≤3 iterations):** have Codex review the spec; revise up to three times.
2. **Browser-preview acceptance gate:** open the `.html` in the user's browser and get explicit sign-off. Do not proceed until the user accepts.
