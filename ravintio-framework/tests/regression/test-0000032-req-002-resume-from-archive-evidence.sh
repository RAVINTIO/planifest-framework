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
source "$SCRIPT_DIR/../helpers/assert.sh"

ORCH="$SCRIPT_DIR/../../skills/ravintio-orchestrator/SKILL.md"

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
assert_contains "ravintio-ship-agent" "$STEP2A" "req-002: step 2a loads the ship skill to resume"

echo ""
echo "=== req-002: stop and ask, never start fresh ==="

assert_contains "no directory matches" "$STEP2A" "req-002: step 2a handles no matching archive"
assert_contains "\`pending\`" "$STEP2A" "req-002: step 2a handles a pending sentinel"
assert_contains "stop and ask the human on the loop" "$STEP2A" "req-002: no match stops and asks the human on the loop"
assert_contains "Do not delete any marker" "$STEP2A" "req-002: step 2a deletes no marker"
lacks "Cleanup complete. Starting fresh." "$(cat "$ORCH")" "req-002: orchestrator drops the start-fresh message"
lacks "Delete \`plan/.orchestrator-active\`" "$STEP2A" "req-002: step 2a has no sentinel delete instruction"

echo ""
echo "=== req-002 (K-1): sentinel ID checked before use ==="

ID_RE='^[0-9]{7}-[a-z0-9-]+$'
assert_contains "\`$ID_RE\`" "$STEP2A" "req-002 K-1: step 2a checks the ID against the feature-ID pattern"
RE_LINE=$(grep -n -F -- "$ID_RE" <<< "$STEP2A" | head -1 | cut -d: -f1)
LIST_LINE=$(grep -n -F 'plan/_archive/{feature-id}-*' <<< "$STEP2A" | head -1 | cut -d: -f1)
assert_equals "yes" "$([ -n "$RE_LINE" ] && [ -n "$LIST_LINE" ] && [ "$RE_LINE" -lt "$LIST_LINE" ] && echo yes || echo no)" \
  "req-002 K-1: the ID check comes before the archive listing"
assert_contains "If the ID doesn't match, stop and ask the human on the loop" "$STEP2A" \
  "req-002 K-1: a mismatched ID stops and asks the human on the loop"
assert_contains "sits inside \`plan/_archive/\`" "$STEP2A" \
  "req-002 K-1: step 2a confirms the chosen directory sits inside plan/_archive/"
assert_contains "Quote the ID in every shell command" "$STEP2A" "req-002 K-1: step 2a quotes the ID in commands"
assert_contains 'ls -d "plan/_archive/$id"-*/' "$STEP2A" "req-002 K-1: the example listing quotes the ID"

echo ""
echo "=== req-002 (K-3): interrupted marker commit ==="

STEP2B=$(sed -n '/^2b\. /,/^3\. /p' "$ORCH" | sed '$d')
assert_equals "yes" "$([ -n "$STEP2B" ] && echo yes || echo no)" "req-002 K-3: step 2b found in Resume Detection"
assert_contains "git ls-files plan/.orchestrator-active" "$STEP2B" "req-002 K-3: step 2b checks whether the sentinel is still tracked"
assert_contains "absent on disk" "$STEP2B" "req-002 K-3: step 2b fires when the sentinel is gone from disk"
assert_contains "git show HEAD:plan/.orchestrator-active" "$STEP2B" "req-002 K-3: step 2b reads the ID from the last commit"
assert_contains "$ID_RE" "$STEP2B" "req-002 K-3: step 2b checks the ID like step 2a"
assert_contains "resume at the P9 marker step" "$STEP2B" "req-002 K-3: step 2b resumes at the P9 marker step"
assert_contains "Step 9 tag" "$STEP2B" "req-002 K-3: step 2b continues to the Step 9 tag"
assert_contains "Tell the human on the loop" "$STEP2B" "req-002 K-3: step 2b tells the human on the loop"
lacks "Delete \`plan/.orchestrator-active\`" "$STEP2B" "req-002 K-3: step 2b has no sentinel delete instruction"

echo ""
echo "=== req-002 (N-8): step 2b applies step 2a's archive rule ==="

assert_contains "a human on the loop deleted the sentinel by hand" "$STEP2B" \
  "req-002 N-8: step 2b names a hand-deleted sentinel as a trigger"
assert_contains "If that directory has no \`build-report.md\`, load the \`ravintio-ship-agent\` skill and resume at P8" "$STEP2B" \
  "req-002 N-8: step 2b resumes at P8 without a build report"
assert_contains "If that directory has a \`build-report.md\`, load the \`ravintio-ship-agent\` skill and resume at the P9 marker step" "$STEP2B" \
  "req-002 N-8: step 2b resumes at the P9 marker step only with a build report"
assert_contains "If no directory matches, stop and ask the human on the loop" "$STEP2B" \
  "req-002 N-8: step 2b stops and asks when no archive matches"
assert_contains "sits inside \`plan/_archive/\`" "$STEP2B" \
  "req-002 N-8: step 2b confirms the directory sits inside plan/_archive/"
P8_LINE=$(grep -n -F 'resume at P8' <<< "$STEP2B" | head -1 | cut -d: -f1)
TAG_LINE=$(grep -n -F 'Step 9 tag' <<< "$STEP2B" | head -1 | cut -d: -f1)
assert_equals "yes" "$([ -n "$P8_LINE" ] && [ -n "$TAG_LINE" ] && [ "$P8_LINE" -lt "$TAG_LINE" ] && echo yes || echo no)" \
  "req-002 N-8: the P8 branch comes before the Step 9 tag"

print_summary
