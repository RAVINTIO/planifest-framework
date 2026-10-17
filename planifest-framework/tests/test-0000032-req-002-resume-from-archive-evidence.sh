#!/usr/bin/env bash
# Tests for feature 0000032-governance-continuity-and-write-gate-scope.
#
# req-002: orchestrator Resume Detection step 2a resumes an interrupted
#          close-out from archive evidence. It reads the feature ID from the
#          sentinel, picks the latest plan/_archive/{feature-id}-* directory,
#          and resumes at P8 or the P9 marker step. It never deletes a marker
#          on its own and never starts fresh.
#
# REGRESSION-CANDIDATE: covers interrupted close-out resume in the orchestrator, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ORCH="$SCRIPT_DIR/../skills/planifest-orchestrator/SKILL.md"

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

# Step 2a runs from its "2a." line to the next top-level numbered step.
STEP2A=$(sed -n '/^2a\. /,/^3\. /p' "$ORCH" | sed '$d')

echo "=== req-002: step 2a trigger and feature-ID source ==="

assert_equals "yes" "$([ -n "$STEP2A" ] && echo yes || echo no)" "req-002: step 2a found in Resume Detection"
assert_contains "plan/current/\` is empty" "$STEP2A" "req-002: trigger still needs an empty plan/current/"
assert_contains "Read the feature ID from \`plan/.orchestrator-active\`" "$STEP2A" \
  "req-002: feature ID comes from the sentinel"
assert_contains "plan/_archive/{feature-id}-*" "$STEP2A" "req-002: step 2a names the archive pattern"
assert_contains "lexical" "$STEP2A" "req-002: step 2a picks the last directory in lexical order"

echo ""
echo "=== req-002: resume points from build-report.md ==="

assert_contains "build-report.md" "$STEP2A" "req-002: step 2a checks for build-report.md"
assert_contains "no \`build-report.md\`" "$STEP2A" "req-002: step 2a handles a missing build report"
assert_contains "resume at P8" "$STEP2A" "req-002: no build report resumes at P8"
assert_contains "resume at the P9 marker step" "$STEP2A" "req-002: a build report resumes at the P9 marker step"
assert_contains "planifest-ship-agent" "$STEP2A" "req-002: step 2a loads the ship skill to resume"

echo ""
echo "=== req-002: stop and ask, never start fresh ==="

assert_contains "no directory matches" "$STEP2A" "req-002: step 2a handles no matching archive"
assert_contains "\`pending\`" "$STEP2A" "req-002: step 2a handles a pending sentinel"
assert_contains "stop and ask the human on the loop" "$STEP2A" "req-002: no match stops and asks the human on the loop"
assert_contains "Do not delete any marker" "$STEP2A" "req-002: step 2a deletes no marker"
lacks "Cleanup complete. Starting fresh." "$(cat "$ORCH")" "req-002: orchestrator drops the start-fresh message"
lacks "Delete \`plan/.orchestrator-active\`" "$STEP2A" "req-002: step 2a has no sentinel delete instruction"

print_summary
