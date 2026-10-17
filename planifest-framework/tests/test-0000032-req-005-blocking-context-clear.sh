#!/usr/bin/env bash
# Tests for feature 0000032-governance-continuity-and-write-gate-scope.
#
# req-005: ship Step 12 becomes a blocking context clear. It asks for /clear
#          or a new session and refuses new work in the same session. The
#          orchestrator Context Hygiene and Phase 9 sections match it.
#
# REGRESSION-CANDIDATE: covers the blocking context clear after P9, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

SHIP="$SCRIPT_DIR/../skills/planifest-ship-agent/SKILL.md"
ORCH="$SCRIPT_DIR/../skills/planifest-orchestrator/SKILL.md"

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

STEP12=$(sed -n '/^### Step 12/,$p' "$SHIP")
HYGIENE=$(sed -n '/^## Context Hygiene/,/^## Phase 0/p' "$ORCH")
P9_ORCH=$(sed -n '/^## Phase 9 - Ship/,/^## Agent Dispatch/p' "$ORCH")

echo "=== req-005: ship Step 12 blocks new work ==="

assert_equals "yes" "$([ -n "$STEP12" ] && echo yes || echo no)" "req-005: Step 12 section found"
assert_contains "context clear" "$(head -1 <<< "$STEP12" | tr '[:upper:]' '[:lower:]')" \
  "req-005: Step 12 heading names a context clear"
assert_contains "/clear" "$STEP12" "req-005: Step 12 asks for /clear"
assert_contains "new session" "$STEP12" "req-005: Step 12 offers a new session"
assert_contains "refuse that work" "$STEP12" "req-005: Step 12 refuses new work in the same session"
assert_contains "repeat the request to clear context" "$STEP12" "req-005: Step 12 repeats the clear request"
assert_contains "Don't start triage, P0, or any edit" "$STEP12" "req-005: Step 12 starts no triage, P0, or edit"
lacks "do not block" "$STEP12" "req-005: Step 12 drops do not block"
lacks "⚡" "$STEP12" "req-005: Step 12 drops the advisory symbol"

echo ""
echo "=== req-005: orchestrator Context Hygiene and Phase 9 ==="

assert_contains "After P9" "$HYGIENE" "req-005: Context Hygiene has an after-P9 rule"
assert_contains "refuse any new request in the same session" "$HYGIENE" \
  "req-005: Context Hygiene refuses new requests after P9 in the same session"
assert_contains "confirms a cleared context or a new session" "$HYGIENE" \
  "req-005: no-clear fallback refuses new work until the human confirms"
assert_contains "Phase 0 Start Actions step -1" "$HYGIENE" "req-005: P0 clear point stays"

COMPLETION=$(grep 'Completion context reset' <<< "$P9_ORCH")
assert_contains "Context Hygiene" "$COMPLETION" "req-005: Phase 9 completion reset points to Context Hygiene"
assert_contains "blocks new work" "$COMPLETION" "req-005: Phase 9 completion reset blocks new work"

print_summary
