#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-002: in autonomous mode only exception-list items wait for the human on
#          the loop. Every other question becomes a recorded decision. A
#          product can add items in planifest-overrides/exception-list.yml.
#
# REGRESSION-CANDIDATE: covers the declared exception list and its routing in autonomous, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
STD="$FW/standards/autonomous-run-standards.md"
TPL="$FW/templates/exception-list.template.yml"
ORCH="$FW/skills/planifest-orchestrator/SKILL.md"
ASSESSOR="$FW/skills/planifest-reversal-assessor/SKILL.md"
CODEGEN="$FW/skills/planifest-codegen-agent/SKILL.md"

# section <heading-prefix> <file>: prints one `## ` section, heading included.
section() {
  awk -v h="$1" 'index($0, h) == 1 { on = 1; print; next } on && /^## / { exit } on { print }' "$2"
}

echo "=== req-002: standards file exception list ==="

EXC=$( [ -f "$STD" ] && section "## Exception list" "$STD" )
assert_equals "yes" "$([ -n "$EXC" ] && echo yes || echo no)" "req-002: standards file has a ## Exception list heading"
assert_contains "schema change or a destructive operation" "$EXC" "req-002: item 1 schema or destructive change"
assert_contains "A gross deviation" "$EXC" "req-002: item 2 gross deviation"
assert_contains "Human review of the running result" "$EXC" "req-002: item 3 human review of the running result"
assert_contains "Promotion beyond the candidate environment" "$EXC" "req-002: item 4 promotion beyond the candidate environment"
assert_contains "A human-only input" "$EXC" "req-002: item 5 human-only input"
assert_contains "An exhausted budget" "$EXC" "req-002: item 6 exhausted budget"
assert_contains "*altering*" "$EXC" "req-002: gross deviation is the altering class"
assert_contains "\`planifest-reversal-assessor\`" "$EXC" "req-002: the reversal assessor classifies"
assert_contains "never classifies its own deviation" "$EXC" "req-002: the deviating agent never classifies its own deviation"
assert_contains "Decision (P{N}): {what was decided} / reason: {one line}" "$EXC" "req-002: Decision line format"
assert_contains "Deviation (P{N}, {additive | altering}): {what changed from the confirmed artifact}" "$EXC" "req-002: Deviation line format"
assert_contains "Exception waiting (P{N}, {item}): {what the human on the loop must do}" "$EXC" "req-002: Exception waiting line format"
assert_contains "Merging a PR stays human-only" "$EXC" "req-002: merging stays human-only"
assert_contains "every mode" "$EXC" "req-002: standing rules hold in every mode"
assert_contains "\`planifest-overrides/exception-list.yml\`" "$EXC" "req-002: names the product override file"
assert_contains "can only add items" "$EXC" "req-002: the override can only add items"

echo ""
echo "=== req-002: exception-list template ==="

assert_equals "yes" "$([ -f "$TPL" ] && echo yes || echo no)" "req-002: exception-list.template.yml exists"
TPL_TEXT=$( [ -f "$TPL" ] && cat "$TPL" )
assert_equals "yes" "$(grep -q '^additional:' <<< "$TPL_TEXT" && echo yes || echo no)" "req-002: template has an additional: key"
assert_contains "planifest-overrides/exception-list.yml" "$TPL_TEXT" "req-002: template says where to copy it"
assert_contains "never writes" "$TPL_TEXT" "req-002: template says the framework never writes there"

echo ""
echo "=== req-002: orchestrator ==="

CONV=$(section "## Phase Conventions" "$ORCH")
assert_contains "one-question rule and recommend-then-confirm give way" "$CONV" \
  "req-002: Phase Conventions defers the one-question rule in autonomous"
STEP4=$(grep -E '^\*\*4\. Human gates' "$ORCH")
assert_contains "**Always stop regardless of run mode" "$STEP4" "req-002: step 4 keeps the always-stop text"
assert_contains "\`interactive\` and \`continuous\`" "$STEP4" "req-002: step 4 always-stop text names interactive and continuous"
assert_contains "In \`autonomous\`, cases (a), (b), and (c) become exception-list items" "$STEP4" \
  "req-002: step 4 routes cases (a) to (c) to the exception list in autonomous"
assert_contains "Case (d)" "$STEP4" "req-002: step 4 treats case (d) separately in autonomous"

echo ""
echo "=== req-002: reversal assessor and codegen ==="

ROW5=$(grep -E '^\| 5 \| \*\*Classification' "$ASSESSOR")
assert_contains "\`autonomous\`" "$ROW5" "req-002: assessor row 5 names autonomous"
assert_contains "exception-list item" "$ROW5" "req-002: assessor row 5 names the exception list"

DEV=$(sed -n '/^\*\*Deviation & Escalation Protocol:\*\*/,/^\*\*Domain language:\*\*/p' "$CODEGEN")
assert_contains "In \`autonomous\`, option 2 becomes a defect report to \`planifest-reversal-assessor\`" "$DEV" \
  "req-002: codegen Stop-and-Ask becomes a defect report in autonomous"
assert_contains "*additive* deviation" "$DEV" "req-002: codegen otherwise records an additive deviation"

echo ""
echo "=== req-002: phase skills defer to the standards file ==="

for s in spec adr codegen validate security docs ship; do
  F="$FW/skills/planifest-$s-agent/SKILL.md"
  LINE=$(grep -m1 'One question at a time' "$F")
  assert_contains "autonomous-run-standards.md" "$LINE" "req-002: planifest-$s-agent one-question rule names autonomous-run-standards.md"
done

print_summary
