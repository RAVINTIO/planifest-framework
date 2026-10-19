#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-004: in autonomous a loop that hits its cap or the no-progress rule
#          tries a different approach, up to 3 per loop instance. A fourth
#          approach becomes an exception-list item. Escalation text for
#          interactive and continuous stays.
#
# REGRESSION-CANDIDATE: covers the autonomous approach budget and the unchanged escalation formats, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
STD="$FW/standards/autonomous-run-standards.md"
RUNNER="$FW/skills/planifest-loop-runner/SKILL.md"
LSTATE="$FW/templates/loop-state.template.md"
ORCH="$FW/skills/planifest-orchestrator/SKILL.md"
VALIDATE="$FW/skills/planifest-validate-agent/SKILL.md"
CODEGEN="$FW/skills/planifest-codegen-agent/SKILL.md"

has() {
  assert_equals "yes" "$([[ "$2" == *"$1"* ]] && echo yes || echo no)" "$3"
}

section() { # section <file> <heading-regex>: from heading to next heading of the same level
  awk -v h="$2" '$0 ~ h {f=1; print; next} f && /^## / {exit} f' "$1" 2>/dev/null
}

echo "=== req-004: standards file Changing approach ==="

CA=$(section "$STD" '^## Changing approach')
has "## Changing approach" "$CA" "req-004: standards file has a Changing approach heading"
has "3 approaches" "$CA" "req-004: section names 3 approaches per loop instance"
has "loop instance" "$CA" "req-004: section scopes the counter to a loop instance"
has "reversal budget stays at 2" "$CA" "req-004: section says the reversal budget stays at 2"
has "At P1, P2, P4, P5, and P6 the instance is the phase gate" "$CA" \
  "req-004: phase gate is the instance at P1, P2, P4, P5, and P6"
has "At P3 it is each requirement's TDD loop" "$CA" "req-004: each requirement's TDD loop is the instance at P3"
has "approach counter never restarts" "$CA" "req-004: approach counter never restarts"
has "exception-list item" "$CA" "req-004: a fourth approach is an exception-list item"
has "reversal assessor" "$CA" "req-004: design changes go to the reversal assessor"

echo ""
echo "=== req-004: loop runner ==="

CYCLE=$(section "$RUNNER" '^## The Iteration Cycle')
STOP=$(section "$RUNNER" '^## Stop Rules')
ESC=$(section "$RUNNER" '^## Escalation Format')
HL=$(section "$RUNNER" '^## Hard Limits')
has "change-approach" "$CYCLE" "req-004: Iteration Cycle names change-approach"
has "change-approach" "$STOP" "req-004: Stop Rules names change-approach"
has "autonomous" "$STOP" "req-004: Stop Rules names autonomous"
assert_equals "4" "$(grep -cE '^\| (Pass|Iteration cap|no-progress|Budget) \|' <<< "$STOP")" \
  "req-004: Stop Rules table keeps its four rows"
has "default **3**" "$STOP" "req-004: Stop Rules keeps cap 3"
has "existing **5**" "$STOP" "req-004: Stop Rules keeps P4's 5"
has "reversal budget 2/feature" "$STOP" "req-004: Stop Rules keeps the reversal budget of 2"
has "Exception waiting" "$ESC" "req-004: Escalation Format writes an Exception waiting line in autonomous"
has "Px: Blocked" "$ESC" "req-004: Escalation Format keeps the Px: Blocked line"
has "approach counter" "$HL" "req-004: Hard Limit 3 names the approach counter"

echo ""
echo "=== req-004: loop-state template ==="

LS=$(cat "$LSTATE")
has "| Approach | \`{{n}} of 3 (autonomous only)\` |" "$LS" "req-004: loop-state template has an Approach row"
has "change-approach" "$(grep 'Last decision' <<< "$LS")" "req-004: Last decision lists change-approach"
has "change-approach" "$(grep '\*\*Decision:\*\*' <<< "$LS")" "req-004: run-log Decision lists change-approach"
has "**Approach:**" "$LS" "req-004: run-log record has an Approach field"
has "Approaches tried" "$LS" "req-004: Escalation Context lists each approach tried"

echo ""
echo "=== req-004: validate, codegen, and cross-model gate ==="

V=$(cat "$VALIDATE")
SC=$(awk '/self-correct cycles/{f=1} f&&/^## /{exit} f' "$VALIDATE")
has "VALIDATION BLOCKED" "$V" "req-004: validate keeps VALIDATION BLOCKED"
has "autonomous" "$SC" "req-004: validate self-correct section names autonomous"
has "exception-list item" "$SC" "req-004: validate makes VALIDATION BLOCKED an exception-list item after 3 approaches"

C=$(cat "$CODEGEN")
TDD=$(awk '/^\*\*TDD Inner Loop Protocol:\*\*/{f=1} f&&/^## /{exit} f' "$CODEGEN")
has "TDD LOOP BLOCKED" "$C" "req-004: codegen keeps TDD LOOP BLOCKED"
has "wait for human direction" "$TDD" "req-004: codegen keeps the wait for human direction line"
has "autonomous" "$TDD" "req-004: codegen TDD protocol names autonomous"
has "exception-list item" "$TDD" "req-004: codegen makes the requirement an exception-list item"

CMR=$(sed -n '/^### Cross-Model Review Gate/,/^---/p' "$ORCH")
STEP5=$(grep '^5\. ' <<< "$CMR")
has "autonomous" "$STEP5" "req-004: cross-model step 5 names autonomous"
has "**block P7**" "$STEP5" "req-004: cross-model step 5 still blocks P7 in other modes"

print_summary
