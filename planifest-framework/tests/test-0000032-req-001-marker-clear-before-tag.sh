#!/usr/bin/env bash
# Tests for feature 0000032-governance-continuity-and-write-gate-scope.
#
# req-001: the ship skill keeps the session markers through P8. It deletes and
#          commits them in a P9 "Clear session markers" step before the Step 9
#          tag. P7 no longer touches a marker, and Step 9b is gone.
#
# REGRESSION-CANDIDATE: covers session-marker deletion timing in the ship skill, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

SHIP="$SCRIPT_DIR/../skills/planifest-ship-agent/SKILL.md"
ORCH="$SCRIPT_DIR/../skills/planifest-orchestrator/SKILL.md"

# line_no <fixed-string>: first line number in the ship skill holding the string.
line_no() { grep -n -F -- "$1" "$SHIP" | head -1 | cut -d: -f1; }

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

# before <a> <b> <label>: passes when both line numbers exist and a < b.
before() {
  assert_equals "yes" "$([ -n "$1" ] && [ -n "$2" ] && [ "$1" -lt "$2" ] && echo yes || echo no)" "$3"
}

echo "=== req-001: P7 no longer touches the session markers ==="

STEP6=$(sed -n '/^### Step 6: Archive plan\/current\//,/^### Step 6b/p' "$SHIP")
for m in .orchestrator-active .orchestrator-ack .run-mode; do
  lacks "$m" "$STEP6" "req-001: P7 Step 6 does not name $m"
done

STEP7=$(sed -n '/^### Step 7: Commit archive/,/^## P8/p' "$SHIP")
GIT_ADD=$(grep '^git add ' <<< "$STEP7")
assert_equals "git add plan/current/ plan/_archive/ plan/changelog/ docs/about.md" "$GIT_ADD" \
  "req-001: P7 Step 7 git add line stages no marker"
for m in .orchestrator-active .orchestrator-ack .run-mode; do
  lacks "$m" "$STEP7" "req-001: P7 Step 7 does not name $m"
done

echo ""
echo "=== req-001: P9 Clear session markers step sits before the tag ==="

P9_LINE=$(line_no "## P9: Ship")
CLEAR_LINE=$(grep -n '^###.*Clear session markers' "$SHIP" | head -1 | cut -d: -f1)
TAG_LINE=$(line_no "### Step 9: Create git tag")
before "$P9_LINE" "$CLEAR_LINE" "req-001: Clear session markers heading follows ## P9: Ship"
before "$CLEAR_LINE" "$TAG_LINE" "req-001: Clear session markers heading precedes Step 9 tag"

CLEAR=$(sed -n "${CLEAR_LINE:-1},$(( ${TAG_LINE:-2} - 1 ))p" "$SHIP")
[ -z "$CLEAR_LINE" ] && CLEAR=""
for m in plan/.orchestrator-active plan/.orchestrator-ack plan/.run-mode; do
  assert_contains "Delete \`$m\`" "$CLEAR" "req-001: marker step deletes $m"
done
assert_contains 'git commit -m "plan(p9): clear session markers for {feature-id}"' "$CLEAR" \
  "req-001: marker step commits with the plan(p9) subject"
assert_contains "git ls-files plan/.orchestrator-active plan/.orchestrator-ack plan/.run-mode" "$CLEAR" \
  "req-001: marker step runs the git ls-files check"
assert_contains "plan/_archive/" "$CLEAR" "req-001: marker step stages the archive directory"
assert_contains "build-report.md" "$CLEAR" "req-001: marker step carries the P8 build report"
assert_contains "Do not tag" "$CLEAR" "req-001: marker step stops before tagging if a marker stays tracked"

DEL_LINE=$(grep -n -F 'Delete `plan/.orchestrator-active`' <<< "$CLEAR" | head -1 | cut -d: -f1)
COMMIT_LINE=$(grep -n -F 'git commit' <<< "$CLEAR" | head -1 | cut -d: -f1)
LS_LINE=$(grep -n -F 'git ls-files' <<< "$CLEAR" | head -1 | cut -d: -f1)
before "$DEL_LINE" "$COMMIT_LINE" "req-001: delete instructions come before the git commit"
before "$COMMIT_LINE" "$LS_LINE" "req-001: git ls-files check follows the commit"

echo ""
echo "=== req-001: Step 9b gone, no marker after Step 9 ==="

lacks "Step 9b" "$(grep '^#' "$SHIP")" "req-001: no Step 9b heading remains"
AFTER_TAG=$(sed -n "${TAG_LINE:-1},\$p" "$SHIP")
for m in .orchestrator-active .orchestrator-ack .run-mode; do
  lacks "$m" "$AFTER_TAG" "req-001: nothing from Step 9 onward names $m"
done

STEP10=$(sed -n '/^### Step 10: Push\/PR decision/,/^### Step 11/p' "$SHIP")
assert_contains "[1] Agent pushes" "$STEP10" "req-001: Step 10 still offers the agent push option"
assert_contains "[2] I'll do it" "$STEP10" "req-001: Step 10 still offers the human push option"

echo ""
echo "=== req-001: orchestrator phase summaries ==="

P9_ORCH=$(sed -n '/^## Phase 9 - Ship/,/^## /p' "$ORCH")
P7_ORCH=$(sed -n '/^## Phase 7 - Archive/,/^## Phase 8/p' "$ORCH")
P9_PRODUCES=$(sed -n '/What P9 produces/,/^\*\*[A-Z]/p' <<< "$P9_ORCH")
# Character offsets, since the paragraph is one line.
# offset_of <needle> <text>: 1-based character offset, or empty if absent.
offset_of() { [[ "$2" == *"$1"* ]] || return 0; local pre="${2%%"$1"*}"; echo $(( ${#pre} + 1 )); }
MARK_POS=$(offset_of "session markers" "$P9_PRODUCES")
TAGP_POS=$(offset_of "git tag" "$P9_PRODUCES")
before "$MARK_POS" "$TAGP_POS" "req-001: What P9 produces names the marker commit before the tag"
P7_PRODUCES=$(sed -n '/What P7 produces/,/^\*\*[A-Z]/p' <<< "$P7_ORCH")
assert_equals "yes" "$([ -n "$P7_PRODUCES" ] && echo yes || echo no)" "req-001: What P7 produces section found"
for m in "session marker" .orchestrator-active .orchestrator-ack .run-mode; do
  lacks "$m" "$P7_PRODUCES" "req-001: What P7 produces does not list $m deletion"
done

print_summary
