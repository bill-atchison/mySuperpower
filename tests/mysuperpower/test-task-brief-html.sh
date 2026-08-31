#!/usr/bin/env bash
# Tests for the fork-owned task-brief-html extractor.
#
# The script under test lives in the overlay that owns it, but at RUNTIME it
# sits beside upstream's sdd-workspace inside the built skill. Each test stages
# that layout in a throwaway git repo, so the default-output path (which
# sdd-workspace resolves from `git rev-parse --show-toplevel`) is exercised for
# real without writing into this repo's working tree.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SUT="$REPO_ROOT/overlays/subagent-driven-development/scripts/task-brief-html"
WORKSPACE_SCRIPT="$REPO_ROOT/skills/subagent-driven-development/scripts/sdd-workspace"
FIXTURES="$SCRIPT_DIR/fixtures"

fails=0
pass() { printf '  ok   %s\n' "$1"; }
fail() { printf '  FAIL %s\n' "$1"; fails=$((fails + 1)); }

check() { # check <name> <expected> <actual>
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1 (expected '$2', got '$3')"; fi
}
contains() { # contains <name> <needle> <file>
  if grep -qF -- "$2" "$3"; then pass "$1"; else fail "$1 (missing '$2')"; fi
}
lacks() { # lacks <name> <needle> <file>
  if grep -qF -- "$2" "$3"; then fail "$1 (unexpectedly found '$2')"; else pass "$1"; fi
}

[ -x "$SUT" ] || { echo "FAIL: $SUT is missing or not executable" >&2; exit 1; }

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

# A throwaway repo laid out the way dist/ lays the skill out.
REPO="$TEST_ROOT/repo"
BIN="$REPO/skills/subagent-driven-development/scripts"
mkdir -p "$BIN"
git init -q "$REPO"
cp "$SUT" "$WORKSPACE_SCRIPT" "$BIN/"
chmod +x "$BIN"/*
cp "$FIXTURES"/*.html "$REPO/"
TB="$BIN/task-brief-html"
cd "$REPO" || exit 1

echo "== argument and file handling =="
"$TB" >/dev/null 2>&1; check "no args exits 2" 2 $?
"$TB" plan-sections.html >/dev/null 2>&1; check "one arg exits 2" 2 $?
"$TB" plan-sections.html 1 a b >/dev/null 2>&1; check "four args exits 2" 2 $?
"$TB" missing.html 1 out.md >/dev/null 2>&1; check "missing plan exits 2" 2 $?
"$TB" plan-sections.html zero out.md >/dev/null 2>&1; check "non-numeric task exits 2" 2 $?

echo "== task selection: numbered sections =="
"$TB" plan-sections.html 2 t2.md >/dev/null 2>&1
check "task 2 exits 0" 0 $?
contains "task 2 has its own heading" "Task 2 — BETAONLY" t2.md
lacks    "task 2 excludes task 1"     "ALPHAONLY" t2.md
lacks    "task 2 excludes task 3"     "GAMMAONLY" t2.md
contains "files block renders"        "- Create src/beta.txt" t2.md
contains "files block second entry"   "- Modify src/shared.txt" t2.md
contains "ol renders numbered steps"  "1. Step 1: indented code survives" t2.md

echo "== entity decoding =="
contains "&lt;meta&gt; decodes"        "<meta>" t2.md
contains "&amp;lt; stays escaped"      "&lt;kept&gt;" t2.md
contains "&middot; decodes"            "·" t2.md
contains "&rarr; decodes"              "→" t2.md

echo "== code blocks =="
contains "indentation survives"        "        return 1" t2.md
# The step-2 payload carries its own ``` fence, so the wrapper must be longer.
check "payload fence is 4 backticks" 2 "$(grep -c '^````$' t2.md)"
check "inner fences sit inside the wrapper" 2   "$(sed -n '/^````$/,/^````$/p' t2.md | grep -c '^```$')"
contains "content after inner fence"   "tail after the inner fence" t2.md

echo "== provenance header =="
contains "names the plan" "Source plan: plan-sections.html" t2.md
check "names the plan hash" "$(git hash-object plan-sections.html)" "$(awk '/^Plan hash:/ {print $3}' t2.md)"

echo "== positional selection, unnumbered headings =="
"$TB" plan-unnumbered.html 2 u2.md >/dev/null 2>&1
check "unnumbered task 2 exits 0" 0 $?
contains "second section selected" "SECONDBODY" u2.md
lacks    "first section excluded"  "FIRSTBODY"  u2.md
lacks    "third section excluded"  "THIRDBODY"  u2.md
contains "inline tags stripped from heading" "Takeover — brainstorming" u2.md

echo "== fallback selection, headings only =="
"$TB" plan-headings.html 2 f2.md >/dev/null 2>&1
check "fallback task 2 exits 0" 0 $?
contains "fallback body selected"  "BETABODY"  f2.md
lacks    "fallback excludes prior" "ALPHABODY" f2.md
lacks    "fallback stops at next Task heading" "GAMMABODY" f2.md

echo "== position/label conflict =="
"$TB" plan-conflict.html 2 c2.md >/dev/null 2>err.txt
check "conflict exits 3" 3 $?
contains "conflict names both numbers" 'section 2 of plan-conflict.html is headed "Task 3"' err.txt

echo "== heading fallback never rescues an out-of-range task =="
# plan-conflict.html has two sections, the second headed "Task 3". Asking for
# task 3 must NOT fall through to the heading search and return section 2 --
# that is a silent wrong answer, worse than the conflict it was meant to catch.
"$TB" plan-conflict.html 3 oor.md >/dev/null 2>oor.err
check "out-of-range exits 3" 3 $?
contains "says the plan is out of range" "has only 2 task section(s); task 3 is out of range" oor.err
if [ -e oor.md ]; then fail "no brief written for an out-of-range task"; else pass "no brief written for an out-of-range task"; fi

echo "== failure never leaves a stale brief at the default path =="
"$TB" plan-sections.html 1 >/dev/null 2>&1
WS="$(./skills/subagent-driven-development/scripts/sdd-workspace plan-sections.html)"
BRIEF="$WS/task-1-brief.md"
if [ -s "$BRIEF" ]; then pass "default path brief written"; else fail "default path brief written"; fi
"$TB" plan-sections.html 9 >/dev/null 2>&1
check "missing task exits 3" 3 $?
if [ -e "$WS/task-9-brief.md" ]; then fail "no zero-byte brief left behind"; else pass "no zero-byte brief left behind"; fi

# A brief that was good a moment ago must not survive a later failed extraction
# of the SAME task: it would sit at the expected path looking current.
"$TB" plan-sections.html 2 >/dev/null 2>&1
BRIEF2="$WS/task-2-brief.md"
if [ -s "$BRIEF2" ]; then pass "task 2 brief written"; else fail "task 2 brief written"; fi
cp "$FIXTURES/plan-conflict.html" plan-sections.html   # section 2 is now headed "Task 3"
"$TB" plan-sections.html 2 >/dev/null 2>&1
check "conflict at default path exits 3" 3 $?
if [ -e "$BRIEF2" ]; then fail "stale default-path brief deleted"; else pass "stale default-path brief deleted"; fi

# Every failure path runs through one cleanup point, so a failed run must never
# leave its temp file behind either -- a stray .task-brief-html.XXXXXX in the
# workspace is the visible symptom of a cleanup path that was missed.
leftover=$(find "$WS" -name '.task-brief-html.*' 2>/dev/null | wc -l | tr -d ' ')
check "no temp files left in the workspace" 0 "$leftover"

echo "== an explicit OUTFILE is never deleted =="
cp "$FIXTURES/plan-conflict.html" plan-conflict.html
printf 'CALLER OWNED CONTENT\n' > owned.md
cp owned.md owned.expected
"$TB" plan-conflict.html 2 owned.md >/dev/null 2>&1
check "conflict with OUTFILE exits 3" 3 $?
"$TB" plan-conflict.html 9 owned.md >/dev/null 2>&1
check "missing task with OUTFILE exits 3" 3 $?
if cmp -s owned.md owned.expected; then pass "caller's file survives byte-for-byte"
else fail "caller's file survives byte-for-byte"; fi

echo "== --plan mode =="
cp "$FIXTURES/plan-sections.html" plan-sections.html
"$TB" --plan plan-sections.html body.md >/dev/null 2>&1
check "--plan exits 0" 0 $?
contains "--plan keeps task 1" "ALPHAONLY" body.md
contains "--plan keeps task 2" "BETAONLY"  body.md
contains "--plan keeps task 3" "GAMMAONLY" body.md
contains "--plan keeps the overview" "Fixture overview text." body.md
lacks    "--plan drops the stylesheet" "background:#f4efe1" body.md
lacks    "--plan drops the title tag"  "Fixture Plan" body.md

echo "== unrecognized entities warn but still write =="
printf '%s\n' '<html><body><section class="task"><h3>Task 1</h3><p>&copy; sign</p></section></body></html>' > ent.html
"$TB" ent.html 1 ent.md >/dev/null 2>ent.err
check "unknown entity still exits 0" 0 $?
contains "unknown entity left as-is" "&copy;" ent.md
contains "unknown entity warned"     "undecoded entity &copy;" ent.err

echo "== unbalanced markup degrades gracefully =="
"$TB" plan-unbalanced.html 1 ub.md >/dev/null 2>ub.err
check "unbalanced still exits 0" 0 $?
contains "selected task body kept"  "BROKENBODY" ub.md
lacks    "stops at the next task"   "NEXTBODY"   ub.md
contains "warns about the missing tag" "missing a closing </section>" ub.err

echo "== smoke test against a real fork plan =="
REAL="$REPO_ROOT/docs/mySuperpower/plans/2026-06-21-live-implementation-notes.html"
if [ -f "$REAL" ]; then
  cp "$REAL" real.html
  "$TB" real.html 1 real1.md >/dev/null 2>&1
  check "real plan task 1 exits 0" 0 $?
  if [ -s real1.md ]; then pass "real plan task 1 is non-empty"; else fail "real plan task 1 is non-empty"; fi
  lacks "real plan task 1 excludes task 2" "Task 2 — Rewrite the executing-plans overlay" real1.md
else
  echo "  skip real-plan smoke test ($REAL not present)"
fi

echo
if [ "$fails" -eq 0 ]; then echo "task-brief-html tests passed"; else echo "$fails assertion(s) failed"; exit 1; fi
