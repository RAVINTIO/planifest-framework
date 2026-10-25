#!/usr/bin/env bash
# Tests for feature 0000038-token-efficiency-windows-shard.
#
# req-006: the decomposition size floor sits in custom-002 and in the Agent
#          Dispatch Template with identical text, nine named exemptions, and the
#          no-removal rule (ADR-006).
#
# Verified by: unit

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
STD="$FW/standards/agent-dispatch-standards.md"
OVR="$FW/../ravintio-overrides/instructions/custom-002-prefer-subagent-decomposition.md"

# floor <file>: prints the floor paragraph, the line that starts with "**Size floor".
floor() {
  grep -m1 '^\*\*Size floor' "$1"
}

F_STD="$(floor "$STD")"
F_OVR="$(floor "$OVR")"

echo "req-006: floor text"
assert_equals "yes" "$([[ -n "$F_STD" ]] && echo yes || echo no)" "req-006: the dispatch template has a Size floor paragraph"
assert_equals "yes" "$([[ -n "$F_OVR" ]] && echo yes || echo no)" "req-006: custom-002 has a Size floor paragraph"
assert_equals "$F_STD" "$F_OVR" "req-006: both files carry identical floor text"

for F in "$F_STD" "$F_OVR"; do
  assert_contains "only when the unit needs its own reads or many tool calls" "$F" "req-006: floor states the dispatch condition"
  assert_contains "parallel tool calls in the main thread" "$F" "req-006: floor states the main-thread alternative"
  for ROLE in "design critic" "security review" "cross-model review" "reversal assessor" "test-writer" "implementer" "refactor" "verify-by-execution" "Scope Lock drafts"; do
    assert_contains "$ROLE" "$F" "req-006: floor names exempt role $ROLE"
  done
  assert_contains "never removes a maker-checker split or a TDD step" "$F" "req-006: floor keeps maker-checker and TDD"
  assert_contains "runs in a subagent" "$F" "req-006: fresh-context roles run in a subagent"
done

echo "req-006: escape clause and placement"
assert_contains "state the reason rather than defaulting to sequential work silently" "$(cat "$OVR")" "req-006: custom-002 keeps the escape clause"
TEMPLATE="$(awk '/^## Agent Dispatch Template/ {on=1; next} on && /^## / {exit} on {print}' "$STD")"
assert_contains "Size floor" "$TEMPLATE" "req-006: the floor sits inside the Agent Dispatch Template section"

print_summary
