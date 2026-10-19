#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-001: P0 offers autonomous as a third run mode. Only the human on the
#          loop's choice writes it to plan/.run-mode, and resume restores it.
#          The run-mode table lives in standards/autonomous-run-standards.md.
#
# REGRESSION-CANDIDATE: covers the autonomous run-mode value, its prompt option, and resume, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
STD="$FW/standards/autonomous-run-standards.md"
ORCH="$FW/skills/planifest-orchestrator/SKILL.md"
GS="$FW/getting-started.md"
PR="$FW/pipeline-reference.md"

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

# section <heading-prefix> <file>: prints one `## ` section, heading included.
section() {
  awk -v h="$1" 'index($0, h) == 1 { on = 1; print; next } on && /^## / { exit } on { print }' "$2"
}

echo "=== req-001: standards file run-mode table ==="

assert_equals "yes" "$([ -f "$STD" ] && echo yes || echo no)" "req-001: autonomous-run-standards.md exists"
RUN_MODES=$( [ -f "$STD" ] && section "## Run modes" "$STD" )
assert_equals "yes" "$([ -n "$RUN_MODES" ] && echo yes || echo no)" "req-001: standards file has a ## Run modes heading"
assert_contains "\`interactive\`" "$RUN_MODES" "req-001: Run modes names interactive"
assert_contains "\`continuous\`" "$RUN_MODES" "req-001: Run modes names continuous"
assert_contains "\`autonomous\`" "$RUN_MODES" "req-001: Run modes names autonomous"
assert_contains "\`continuous_run: true\`" "$RUN_MODES" "req-001: autonomous sets continuous_run"
assert_contains "\`autonomous_run: true\`" "$RUN_MODES" "req-001: autonomous sets autonomous_run"
assert_contains "reads as \`interactive\`" "$RUN_MODES" "req-001: unknown value reads as interactive"
assert_contains "0000012-ADR-005" "$RUN_MODES" "req-001: Run modes names 0000012-ADR-005"
assert_contains "never counts as choosing \`autonomous\`" "$RUN_MODES" \
  "req-001: an override never counts as choosing autonomous"
assert_contains "the override wins" "$RUN_MODES" "req-001: a conflicting override wins"

echo ""
echo "=== req-001: orchestrator run-mode prompt ==="

OPTIONS=$(grep -E '^[[:space:]]*\[[123]\] (Interactive|Continuous|Autonomous):' "$ORCH")
assert_equals "3" "$(grep -c . <<< "$OPTIONS")" "req-001: run-mode prompt has three named options"
assert_contains "[3] Autonomous" "$OPTIONS" "req-001: run-mode prompt contains [3] Autonomous"
assert_equals "3" "$(grep -c 'the agent' <<< "$OPTIONS")" "req-001: every option names the agent"
assert_equals "0" "$(grep -cwE 'I|me' <<< "$OPTIONS")" "req-001: no option contains I or me"

RECORD=$(sed -n '/^Record their answer\./,/^In \*\*interactive\*\* mode/p' "$ORCH")
assert_contains "If [3], set \`continuous_run: true\` and \`autonomous_run: true\`, and write \`autonomous\` to \`plan/.run-mode\`" \
  "$RECORD" "req-001: option [3] writes autonomous to plan/.run-mode"
assert_equals "1" "$(grep -c 'write `autonomous` to `plan/.run-mode`' <<< "$RECORD")" \
  "req-001: only one sentence writes autonomous to plan/.run-mode"
assert_contains "\`continuous\` for [2] or \`interactive\` for [1]" "$RECORD" \
  "req-001: options [1] and [2] keep their own values"
assert_contains "Run mode" "$RECORD" "req-001: recording text points to the build-log Run mode row"
assert_contains "Any other value defaults to \`interactive\`" "$RECORD" \
  "req-001: resume sentence defaults any other value to interactive"

echo ""
echo "=== req-001: Resume Detection step 6 ==="

STEP6=$(grep -E '^6\. Read `plan/.run-mode`' "$ORCH")
assert_contains "\`continuous\`" "$STEP6" "req-001: step 6 names continuous"
assert_contains "\`interactive\`" "$STEP6" "req-001: step 6 names interactive"
assert_contains "\`autonomous\`" "$STEP6" "req-001: step 6 names autonomous"
assert_contains "\`autonomous_run: true\`" "$STEP6" "req-001: restoring autonomous sets both flags"
assert_contains "Any other value" "$STEP6" "req-001: step 6 defaults any other value"
assert_contains "default to \`interactive\`" "$STEP6" "req-001: step 6 defaults to interactive"

echo ""
echo "=== req-001: Phase Conventions and back-compat ==="

CONV=$(section "## Phase Conventions" "$ORCH")
assert_contains "standards/autonomous-run-standards.md" "$CONV" \
  "req-001: Phase Conventions links to the standards file"
CONTENT=$(cat "$ORCH")
assert_contains "STOP, present requirement count/scope decisions/deferred items. Exception: \`continuous_run: true\` was set at P0." \
  "$CONTENT" "req-001: P1 row keeps the continuous_run exception"
assert_contains "STOP, present ADR list with one-line summaries. Exception: \`continuous_run: true\` was set at P0." \
  "$CONTENT" "req-001: P2 row keeps the continuous_run exception"
assert_contains "STOP, present components built/tests produced/deviations. Exception: \`continuous_run: true\` was set at P0." \
  "$CONTENT" "req-001: P3 row keeps the continuous_run exception"

echo ""
echo "=== req-001: guides ==="

assert_contains "autonomous run" "$(cat "$GS")" "req-001: getting-started.md names the autonomous run"
assert_contains "[3] Autonomous" "$(cat "$PR")" "req-001: pipeline-reference.md shows the autonomous option"
assert_contains "autonomous" "$(grep '^| `P0:`' "$PR")" "req-001: pipeline-reference.md P0 row names autonomous"

print_summary
