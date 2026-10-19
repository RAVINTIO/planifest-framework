#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-013: the P9 marker-step commit always carries the P8 build report. P8
#          and P9 each end with a scoped clean-tree check. In autonomous mode
#          it commits leftovers by explicit path. In other modes Step 11 lists
#          them and asks whether to commit and push.
#
# REGRESSION-CANDIDATE: covers the P8 and P9 clean-tree checks and the build-report guard, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

SHIP="$SCRIPT_DIR/../skills/planifest-ship-agent/SKILL.md"
ORCH="$SCRIPT_DIR/../skills/planifest-orchestrator/SKILL.md"
CMD="git status --porcelain -- plan/ docs/ ':(glob)src/**/docs/**'"

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

# before <a> <b> <label>: passes when both line numbers exist and a < b.
before() {
  assert_equals "yes" "$([ -n "$1" ] && [ -n "$2" ] && [ "$1" -lt "$2" ] && echo yes || echo no)" "$3"
}

# line_no <regex> [from]: first ship skill line at or after <from> matching the regex.
line_no() {
  awk -v re="$1" -v from="${2:-1}" 'NR >= from && $0 ~ re { print NR; exit }' "$SHIP"
}

P8_LINE=$(line_no '^## P8: Build Assessment')
P9_LINE=$(line_no '^## P9: Ship')
S10_LINE=$(line_no '^### Step 10')
S11_LINE=$(line_no '^### Step 11')
S12_LINE=$(line_no '^### Step 12')
P8_CHECK=$(line_no '^###.*Clean-tree check' "${P8_LINE:-1}")
P9_CHECK=$(line_no '^###.*Clean-tree check' "${S10_LINE:-1}")

echo "=== req-013: clean-tree check headings sit in P8 and between Step 10 and Step 11 ==="

before "$P8_LINE" "$P8_CHECK" "req-013: P8 clean-tree check follows ## P8"
before "$P8_CHECK" "$P9_LINE" "req-013: P8 clean-tree check precedes ## P9"
before "$S10_LINE" "$P9_CHECK" "req-013: P9 clean-tree check follows Step 10"
before "$P9_CHECK" "$S11_LINE" "req-013: P9 clean-tree check precedes Step 11"

# section <start> <end>: ship skill lines from start up to end - 1.
section() { [ -n "$1" ] && [ -n "$2" ] && sed -n "${1},$(( $2 - 1 ))p" "$SHIP"; }
C8=$(section "$P8_CHECK" "$P9_LINE")
C9=$(section "$P9_CHECK" "$S11_LINE")
STEP11=$(section "$S11_LINE" "$S12_LINE")

echo ""
echo "=== req-013: both checks run the scoped command and read the Run mode row ==="

for P in 8 9; do
  C=$([ "$P" = 8 ] && echo "$C8" || echo "$C9")
  assert_contains "$CMD" "$C" "req-013: P$P check runs the scoped git status command"
  assert_contains "\`Run mode\` row" "$C" "req-013: P$P check reads the Run mode row"
  assert_contains "{archive-dir}/build-log.md" "$C" "req-013: P$P check reads the archived build log"
  lacks "plan/.run-mode" "$C" "req-013: P$P check never names plan/.run-mode as a source"
  assert_contains "\`autonomous\`" "$C" "req-013: P$P check names autonomous"
  assert_contains "plan(p$P): commit close-out leftovers" "$C" "req-013: P$P check names its commit subject"
  assert_equals "1" "$(grep -E "git commit .*plan\(p$P\): commit close-out leftovers" <<< "$C" | grep -c -F ' -- ')" \
    "req-013: P$P leftover commit names its paths after --"
  lacks "git add -A" "$C" "req-013: P$P check has no git add -A"
  lacks "git add ." "$C" "req-013: P$P check has no git add ."
  assert_equals "0" "$(grep -c -w 'rm' <<< "$C")" "req-013: P$P check has no rm"
  assert_contains "Clean-tree check: clean" "$C" "req-013: P$P check logs a clean result"
done
assert_contains "Leave out lines under \`{archive-dir}\`" "$C8" "req-013: P8 check leaves out {archive-dir}"
assert_contains "Leave out nothing" "$C9" "req-013: P9 check leaves out nothing"
assert_contains "Step 11" "$C8" "req-013: P8 leftovers outside autonomous go to Step 11"
assert_contains "Step 11" "$C9" "req-013: P9 leftovers outside autonomous go to Step 11"

echo ""
echo "=== req-013: Step 11 reports the result and lists leftovers outside autonomous ==="

assert_contains "Clean-tree check:" "$STEP11" "req-013: Step 11 reports the clean-tree result"
assert_contains "committed {n} files" "$STEP11" "req-013: Step 11 names the committed result"
assert_contains "{n} files listed below" "$STEP11" "req-013: Step 11 names the listed result"
assert_contains "ask whether to commit and push them" "$STEP11" \
  "req-013: Step 11 asks whether to commit and push leftovers outside autonomous"
assert_contains "adds no new stop" "$STEP11" "req-013: the leftover question adds no new stop"

echo ""
echo "=== req-013: marker step checks for build-report.md before its commit ==="

CLEAR_LINE=$(line_no '^###.*Clear session markers')
TAG_LINE=$(line_no '^### Step 9')
REPORT_LINE=$(awk -v a="${CLEAR_LINE:-1}" -v b="${TAG_LINE:-1}" 'NR >= a && NR < b && index($0, "git cat-file -e \":{archive-dir}/build-report.md\"") { print NR; exit }' "$SHIP")
COMMIT_LINE=$(awk -v a="${CLEAR_LINE:-1}" -v b="${TAG_LINE:-1}" 'NR >= a && NR < b && /git commit/ { print NR; exit }' "$SHIP")
before "$REPORT_LINE" "$COMMIT_LINE" "req-013: the build-report.md check precedes the marker commit"
GUARD=$(section "${CLEAR_LINE:-1}" "${TAG_LINE:-1}")
assert_contains "resume at P8" "$GUARD" "req-013: a missing build report resumes at P8"

echo ""
echo "=== req-013: orchestrator Phase 9 names the clean-tree check ==="

P9_PRODUCES=$(sed -n '/^## Phase 9 - Ship/,/^## /p' "$ORCH" | grep 'What P9 produces')
assert_contains "clean-tree check" "$P9_PRODUCES" "req-013: What P9 produces names the clean-tree check"

echo ""
echo "=== req-013: the scoped command in a fixture repo ==="

SCRATCH=$(mktemp -d -t planifest_0000033_req013_XXXXXX)
trap 'rm -rf "$SCRATCH"' EXIT
R="$SCRATCH/repo"
mkdir -p "$R/docs" "$R/src/x/docs" "$R/plan"
git -C "$R" init -q
git -C "$R" config user.email test@example.com
git -C "$R" config user.name test
git -C "$R" config commit.gpgsign false
for f in docs/a.md src/x/docs/b.md src/x/app.js plan/p.md; do echo one > "$R/$f"; done
git -C "$R" add -A
git -C "$R" commit -q -m init
for f in docs/a.md src/x/docs/b.md src/x/app.js; do echo two >> "$R/$f"; done
OUT=$(cd "$R" && eval "$CMD")
assert_contains "docs/a.md" "$OUT" "req-013: the scoped command reports docs/a.md"
assert_contains "src/x/docs/b.md" "$OUT" "req-013: the scoped command reports src/x/docs/b.md"
lacks "src/x/app.js" "$OUT" "req-013: the scoped command skips src/x/app.js"

print_summary
