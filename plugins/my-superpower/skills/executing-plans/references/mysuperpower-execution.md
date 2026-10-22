# mySuperpower: Executing a plan

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
