#!/usr/bin/env bash
# Tests for feature 0000032-governance-continuity-and-write-gate-scope.
#
# req-004: a ship Hard Limit routes every next step in a P9 handover note,
#          next-steps list, or runbook pointer through Fast Path, Change
#          Pipeline, or Feature Pipeline. A note never says a code change needs
#          no P0, and never points to a runbook that pushes to main. Step 11
#          names the track for each next step it lists.
#
# REGRESSION-CANDIDATE: covers the ship handover-note routing rule, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

SHIP="$SCRIPT_DIR/../skills/ravintio-ship-agent/SKILL.md"

HARD_LIMITS=$(sed -n '/^## Hard Limits/,/^## P7/p' "$SHIP")
RULE=$(grep -i 'handover note' <<< "$HARD_LIMITS")
STEP11=$(sed -n '/^### Step 11: Confirm to human/,/^### Step 12/p' "$SHIP")

echo "=== req-004: handover-note Hard Limit ==="

assert_equals "yes" "$([ -n "$RULE" ] && echo yes || echo no)" "req-004: Hard Limits holds a handover-note rule"
assert_contains "next-steps list" "$RULE" "req-004: rule covers next-steps lists"
assert_contains "runbook" "$RULE" "req-004: rule covers runbook pointers"
assert_contains "Fast Path" "$RULE" "req-004: rule names Fast Path"
assert_contains "Change Pipeline" "$RULE" "req-004: rule names Change Pipeline"
assert_contains "Feature Pipeline" "$RULE" "req-004: rule names Feature Pipeline"
assert_contains "code change always needs a track" "$RULE" "req-004: rule states a code change always needs a track"
assert_contains "never says a code change needs no P0" "$RULE" "req-004: rule forbids saying a code change needs no P0"
assert_contains "pushes to \`main\`" "$RULE" "req-004: rule forbids runbooks that push to main"

echo ""
echo "=== req-004: Step 11 names a track per next step ==="

assert_contains "next steps" "$STEP11" "req-004: Step 11 addresses listed next steps"
assert_contains "names its track" "$STEP11" "req-004: Step 11 requires each next step to name its track"

print_summary
