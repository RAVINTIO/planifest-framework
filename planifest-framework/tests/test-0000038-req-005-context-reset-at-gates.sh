#!/usr/bin/env bash
# Verified by: unit
# test-0000038-req-005-context-reset-at-gates.sh
# req-005: after each passed phase gate, Context Hygiene recommends /compact or
# a new session. The prompt names plan/current/ and the build log as the resume
# state, never needs pause.md, and never blocks a phase. The blocking reset
# after P9 (0000032) stays unchanged.
# Run from any directory: bash planifest-framework/tests/test-0000038-req-005-context-reset-at-gates.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_DIR="$SCRIPT_DIR"
if [ "$(basename "$SCRIPT_DIR")" = "regression" ]; then
  TESTS_DIR="$(dirname "$SCRIPT_DIR")"
fi
source "$TESTS_DIR/helpers/assert.sh"

FW="$TESTS_DIR/.."
ORCH="$FW/skills/planifest-orchestrator/SKILL.md"
BASE_BLOB="5966840:planifest-framework/skills/planifest-orchestrator/SKILL.md"

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

HYGIENE=$(sed -n '/^## Context Hygiene/,/^## Phase 0/p' "$ORCH")
GATE_PROMPT=$(grep -F 'After each passed phase gate' <<< "$HYGIENE")

echo "=== req-005: gate reset prompt ==="
assert_equals "yes" "$([ -n "$GATE_PROMPT" ] && echo yes || echo no)" "req-005: Context Hygiene has an after-each-gate prompt"
assert_contains '`/compact`' "$GATE_PROMPT" "req-005: prompt recommends /compact"
assert_contains "new session" "$GATE_PROMPT" "req-005: prompt recommends a new session"
assert_contains '`plan/current/`' "$GATE_PROMPT" "req-005: prompt names plan/current/ as resume state"
assert_contains "build log" "$GATE_PROMPT" "req-005: prompt names the build log as resume state"

echo ""
echo "=== req-005: advisory, no pause.md ==="
assert_contains '`pause.md`' "$GATE_PROMPT" "req-005: prompt addresses pause.md"
assert_contains "never needs" "$GATE_PROMPT" "req-005: prompt never needs pause.md"
assert_contains "advisory" "$GATE_PROMPT" "req-005: prompt is advisory"
assert_contains "doesn't block a phase" "$GATE_PROMPT" "req-005: prompt doesn't block a phase"
assert_contains '`continuous` and `autonomous`' "$GATE_PROMPT" "req-005: prompt covers continuous and autonomous runs"
assert_contains "don't wait for an answer" "$GATE_PROMPT" "req-005: those runs carry on without an answer"

echo ""
echo "=== req-005: blocking reset after P9 is unchanged ==="
AFTER_P9=$(grep -F '**After P9 (blocking' <<< "$HYGIENE")
BASE_P9=$(git -C "$FW" show "$BASE_BLOB" 2>/dev/null | grep -F '**After P9 (blocking')
assert_equals "yes" "$([ -n "$BASE_P9" ] && echo yes || echo no)" "req-005: baseline after-P9 paragraph is readable"
assert_equals "$BASE_P9" "$AFTER_P9" "req-005: after-P9 paragraph matches the baseline byte for byte"

print_summary
