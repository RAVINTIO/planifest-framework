#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-003: in autonomous every P1 to P6 gate runs as a loop under
#          planifest-loop-runner with a fresh-context checker. Five toggle
#          keys read as on when absent in autonomous, and the loop-toggles
#          template ships the checker keys commented out.
#
# REGRESSION-CANDIDATE: covers gates as loops and the autonomous toggle defaults, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
STD="$FW/standards/autonomous-run-standards.md"
RUNNER="$FW/skills/planifest-loop-runner/SKILL.md"
TOG="$FW/templates/loop-toggles.template.yml"
ORCH="$FW/skills/planifest-orchestrator/SKILL.md"
VALIDATE="$FW/skills/planifest-validate-agent/SKILL.md"
SECURITY="$FW/skills/planifest-security-agent/SKILL.md"

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

GATES=$(awk '/^## Gates as loops/{f=1;print;next} f&&/^## /{exit} f' "$STD" 2>/dev/null)

echo "=== req-003: standards file Gates as loops ==="

assert_equals "yes" "$(grep -q '^## Gates as loops' "$STD" 2>/dev/null && echo yes || echo no)" \
  "req-003: standards file has a Gates as loops heading"
for p in P1 P2 P3 P4 P5 P6; do
  assert_equals "yes" "$(grep -q "^| $p |" <<< "$GATES" && echo yes || echo no)" \
    "req-003: Gates as loops table has a $p row"
done
assert_contains "planifest-design-critic" "$GATES" "req-003: table names planifest-design-critic"
assert_contains "planifest-verify-by-execution" "$GATES" "req-003: table names planifest-verify-by-execution"
assert_contains "cross-model review gate" "$GATES" "req-003: table names the cross-model review gate"
assert_contains "P4 CI run" "$(grep '^| P3 |' <<< "$GATES")" "req-003: P3 row names the P4 CI run"
assert_contains "fresh-context re-review" "$(grep '^| P5 |' <<< "$GATES")" "req-003: P5 row names a fresh-context re-review"
assert_contains "keeps its cap" "$GATES" "req-003: section says each loop keeps its cap"
assert_contains "P4 validate keeps 5" "$GATES" "req-003: section names 5 for P4"

echo ""
echo "=== req-003: orchestrator Phase Invocation Table ==="

TABLE=$(sed -n '/^## Phase Invocation Table/,/^## /p' "$ORCH")
AUTO_LINE=$(grep 'autonomous' <<< "$TABLE" | grep -v '^|')
assert_contains "autonomous-run-standards.md" "$AUTO_LINE" \
  "req-003: autonomous sentence below the table links to the standards file"
ROWS=$(grep -c '^| P[1-6] ' <<< "$TABLE")
assert_equals "6" "$ROWS" "req-003: table keeps six phase rows"
assert_equals "absent" "$(grep '^| P[1-6] ' <<< "$TABLE" | grep -q autonomous && echo present || echo absent)" \
  "req-003: no table row mentions autonomous"
assert_contains "| P4 Validate | validate-agent | CI passes | STOP, present checks run and self-correction count." "$TABLE" \
  "req-003: P4 row text unchanged"
assert_contains "| P5 Security | security-agent | Report produced with specific findings | STOP, present risk rating" "$TABLE" \
  "req-003: P5 row text unchanged"
assert_contains "| P6 Documentation | docs-agent |" "$TABLE" "req-003: P6 row present"
CRITIC_PARA=$(grep '^\*\*Design-critic (toggle' "$ORCH")
assert_contains "Toggle Protocol" "$CRITIC_PARA" "req-003: design-critic paragraph links to the Toggle Protocol"
CMR=$(sed -n '/^### Cross-Model Review Gate/,/^---/p' "$ORCH")
assert_contains "Toggle Protocol" "$CMR" "req-003: cross-model gate links to the Toggle Protocol"

echo ""
echo "=== req-003: loop runner Toggle Protocol ==="

TP=$(sed -n '/^## Toggle Protocol/,/^## /p' "$RUNNER")
assert_contains "autonomous" "$TP" "req-003: Toggle Protocol names autonomous"
for k in design_critic verify_by_execution cross_model_review reversal_protocol parallel_streams; do
  assert_contains "$k" "$TP" "req-003: Toggle Protocol names $k"
done
assert_contains "explicit value" "$TP" "req-003: Toggle Protocol says an explicit value wins"
assert_contains "Outside \`autonomous\`, an absent key still reads as **off**" "$TP" \
  "req-003: absent key reads as off outside autonomous"
assert_contains "The framework never creates \`planifest-overrides/loop-toggles.yml\`" "$TP" \
  "req-003: never-creates line stays"

echo ""
echo "=== req-003: loop-toggles template ==="

TOGT=$(cat "$TOG")
for k in design_critic verify_by_execution cross_model_review reversal_protocol; do
  assert_equals "0" "$(grep -c "^$k:" <<< "$TOGT")" "req-003: template has no uncommented $k line"
  assert_contains "autonomous" "$(grep "^# *$k:" <<< "$TOGT")" "req-003: commented $k line names autonomous"
done
assert_contains "p0_completeness: off" "$TOGT" "req-003: p0_completeness line stays"
HEADER=$(sed -n '1,/^[a-z#]* *p0_completeness/p' <<< "$TOGT")
assert_contains "autonomous" "$HEADER" "req-003: template header states the autonomous rule"

echo ""
echo "=== req-003: validate and security checkers ==="

assert_contains "autonomous" "$(grep '^6\. \*\*Verify by execution' "$VALIDATE")" \
  "req-003: validate step 6 runs verify-by-execution as the P4 checker in autonomous"
assert_contains "fresh-context re-review" "$(cat "$SECURITY")" \
  "req-003: security skill re-reviews each fixed finding in autonomous"

print_summary
