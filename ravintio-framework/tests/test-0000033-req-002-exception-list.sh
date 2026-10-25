#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-002: in autonomous mode only exception-list items wait for the human on
#          the loop. Every other question becomes a recorded decision. A
#          product can add items in ravintio-overrides/exception-list.yml.
#
# REGRESSION-CANDIDATE: covers the declared exception list and its routing in autonomous, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
STD="$FW/standards/autonomous-run-standards.md"
TPL="$FW/templates/exception-list.template.yml"
ORCH="$FW/skills/ravintio-orchestrator/SKILL.md"
ASSESSOR="$FW/skills/ravintio-reversal-assessor/SKILL.md"
CODEGEN="$FW/skills/ravintio-codegen-agent/SKILL.md"

# section <heading-prefix> <file>: prints one `## ` section, heading included.
section() {
  awk -v h="$1" 'index($0, h) == 1 { on = 1; print; next } on && /^## / { exit } on { print }' "$2"
}

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
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
assert_contains "\`ravintio-reversal-assessor\`" "$EXC" "req-002: the reversal assessor classifies"
assert_contains "never classifies its own deviation" "$EXC" "req-002: the deviating agent never classifies its own deviation"
assert_contains "Decision (P{N}): {what was decided} / reason: {one line}" "$EXC" "req-002: Decision line format"
assert_contains "Deviation (P{N}, unclassified): {what changed from the confirmed artifact}" "$EXC" "req-002: Deviation line format (P5 C2-7)"
assert_contains "Exception waiting (P{N}, {item}): {what the human on the loop must do}" "$EXC" "req-002: Exception waiting line format"
assert_contains "Merging a PR stays human-only" "$EXC" "req-002: merging stays human-only"
assert_contains "every mode" "$EXC" "req-002: standing rules hold in every mode"
assert_contains "\`ravintio-overrides/exception-list.yml\`" "$EXC" "req-002: names the product override file"
assert_contains "can only add items" "$EXC" "req-002: the override can only add items"

echo ""
echo "=== req-002: exception-list template ==="

assert_equals "yes" "$([ -f "$TPL" ] && echo yes || echo no)" "req-002: exception-list.template.yml exists"
TPL_TEXT=$( [ -f "$TPL" ] && cat "$TPL" )
assert_equals "yes" "$(grep -q '^additional:' <<< "$TPL_TEXT" && echo yes || echo no)" "req-002: template has an additional: key"
assert_contains "ravintio-overrides/exception-list.yml" "$TPL_TEXT" "req-002: template says where to copy it"
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
assert_contains "In \`autonomous\`, option 2 becomes a defect report to \`ravintio-reversal-assessor\`" "$DEV" \
  "req-002: codegen Stop-and-Ask becomes a defect report in autonomous"
assert_contains "record the deviation per" "$DEV" "req-002: codegen otherwise records the deviation for the assessor to class (P5 C2-7)"

echo ""
echo "=== req-002: phase skills defer to the standards file ==="

for s in spec adr codegen validate security docs ship; do
  F="$FW/skills/ravintio-$s-agent/SKILL.md"
  LINE=$(grep -m1 'One question at a time' "$F")
  assert_contains "autonomous-run-standards.md" "$LINE" "req-002: ravintio-$s-agent one-question rule names autonomous-run-standards.md"
done

echo ""
echo "=== req-002: precedence of standing rules over overrides (P5 G2) ==="

RM=$(section "## Run modes" "$STD")
PREC=$(grep 'Precedence' <<< "$RM")
assert_contains "rank above every override" "$PREC" "req-002: standing rules rank above every override (P5 G2)"
assert_contains "\`ravintio-overrides/instructions/\`" "$PREC" "req-002: precedence names ravintio-overrides/instructions/ (P5 G2)"
assert_contains "Hard Limits" "$PREC" "req-002: precedence names the orchestrator Hard Limits (P5 G2)"
assert_contains "exception-list items" "$PREC" "req-002: precedence names the exception-list items (P5 G2)"
assert_contains "merging" "$PREC" "req-002: precedence names merging as human-only (P5 G2)"
assert_contains "all other behaviour only" "$RM" "req-002: overrides win for all other behaviour only (P5 G2)"
lacks "conflicts with the \`autonomous\` text, the override wins." "$RM" "req-002: the unqualified overrides-win sentence is gone (P5 G2)"

echo ""
echo "=== req-002: assessor reviews deviations before P7 (P5 G4) ==="

REVIEW=$(grep 'before P7' <<< "$EXC")
assert_contains "\`ravintio-reversal-assessor\`" "$REVIEW" "req-002: the fresh-context assessor reviews before P7 (P5 G4)"
assert_contains "every \`Deviation\` line" "$REVIEW" "req-002: review covers every Deviation line (P5 G4)"
assert_contains "data, a schema, or a destructive operation" "$REVIEW" "req-002: review covers data, schema, and destructive decisions (P5 G4)"
assert_contains "altering, schema, or destructive" "$REVIEW" "req-002: those classes become exception items (P5 G4)"
assert_contains "never classifies its own deviation" "$REVIEW" "req-002: the maker never classifies its own deviation (P5 G4)"
CG_RULES=$(sed -n '/^## Rules/,/^## /p' "$CODEGEN")
assert_contains "before P7" "$(grep 'Deviation' <<< "$CG_RULES")" "req-002: codegen Rules names the pre-P7 assessor review (P5 G4)"

echo ""
echo "=== req-002: assessor cascade rule matches autonomous (P5 G10) ==="

ROW3=$(grep -E '^\| 3 \| \*\*Blast radius' "$ASSESSOR")
assert_contains "\`autonomous\`" "$ROW3" "req-002: assessor row 3 names autonomous (P5 G10)"
assert_contains "*additive* cascade over 3 proceeds" "$ROW3" "req-002: an additive cascade over 3 proceeds (P5 G10)"
assert_contains "*altering* reversal waits" "$ROW3" "req-002: an altering reversal waits (P5 G10)"

echo ""
echo "=== req-002: Hard Limits 4 and 6 and the credential item (P5 G11) ==="

STAND=$(sed -n '/^\*\*Standing rules in every mode:\*\*/,/^\*\*Product extension/p' "$STD")
assert_contains "Hard Limit 4" "$STAND" "req-002: standing rules name Hard Limit 4 (P5 G11)"
assert_contains "Hard Limit 6" "$STAND" "req-002: standing rules name Hard Limit 6 (P5 G11)"
assert_contains "these seven items" "$EXC" "req-002: the list holds seven items (P5 G11)"
assert_equals "1" "$(grep -c -E '^7\. A credential sighting' <<< "$EXC")" "req-002: item 7 is a credential sighting (P5 G11)"
ITEM7=$(grep -E '^7\. ' <<< "$EXC")
assert_contains "stops using it" "$ITEM7" "req-002: the run stops using the credential (P5 G11)"
assert_contains "final report" "$ITEM7" "req-002: the credential goes in the final report (P5 G11)"
lacks "six" "$EXC" "req-002: the section no longer says six items (P5 G11)"
lacks "six" "$TPL_TEXT" "req-002: the template no longer says six items (P5 G11)"

echo ""
echo "=== req-002: standing rules cover the autonomous guards (P5 C2-4) ==="

STAND=$(sed -n '/^\*\*Standing rules in every mode:\*\*/,/^\*\*Product extension:\*\*/p' "$STD")
assert_contains "branch check before any \`autonomous\` push" "$STAND" "req-002: standing rules hold the branch check before a push (P5 C2-4)"
assert_contains "force push" "$STAND" "req-002: standing rules ban a force push (P5 C2-4)"
assert_contains "leftover credential guard" "$STAND" "req-002: standing rules hold the leftover credential guard (P5 C2-4)"
assert_contains "\`{archive-dir}/final-report.md\`" "$STAND" "req-002: standing rules hold the saved final report (P5 C2-4)"
assert_contains "Only the orchestrator writes" "$STAND" "req-002: standing rules hold the run-mode writer rule (P5 C2-4)"
assert_contains "can't switch these off" "$STAND" "req-002: overrides can't switch the standing rules off (P5 C2-4)"

echo ""
echo "=== req-002: the maker writes an unclassified deviation (P5 C2-7) ==="

assert_contains "Deviation (P{N}, unclassified): {what changed from the confirmed artifact}" "$EXC" "req-002: the maker writes Deviation (P{N}, unclassified) (P5 C2-7)"
assert_contains "sets \`additive\` or \`altering\`" "$(grep 'before P7' <<< "$EXC")" "req-002: the assessor sets the class in its pre-P7 review (P5 C2-7)"
lacks "the agent records it as *additive*" "$EXC" "req-002: the deviating agent no longer records additive (P5 C2-7)"
assert_contains "\`Deviation (P{N}, unclassified)\`" "$DEV" "req-002: codegen writes an unclassified Deviation line (P5 C2-7)"
lacks "record an *additive* deviation" "$DEV" "req-002: codegen no longer records an additive deviation itself (P5 C2-7)"

echo ""
echo "=== req-002: the pre-P7 deviation review has an executor (P5 C3-8) ==="

DR_ORCH=$(awk '/^### Deviation Review/ { on = 1; print; next } on && /^##/ { exit } on { print }' "$ORCH")
assert_equals "yes" "$([ -n "$DR_ORCH" ] && echo yes || echo no)" "req-002: orchestrator has a Deviation Review step (P5 C3-8)"
DR_LINE=$(grep -n '^### Deviation Review' "$ORCH" | head -1 | cut -d: -f1)
CM_LINE=$(grep -n '^### Cross-Model Review Gate' "$ORCH" | head -1 | cut -d: -f1)
P6_LINE=$(grep -n '^## Phase 6' "$ORCH" | head -1 | cut -d: -f1)
assert_equals "yes" "$([ -n "$DR_LINE" ] && [ "$DR_LINE" -gt "$P6_LINE" ] && [ "$DR_LINE" -lt "$CM_LINE" ] && echo yes || echo no)" "req-002: the review runs at the end of P6, before the cross-model gate (P5 C3-8)"
assert_contains "fresh-context \`ravintio-reversal-assessor\`" "$DR_ORCH" "req-002: the orchestrator spawns the fresh-context assessor (P5 C3-8)"
assert_contains "\`Deviation (P{N}, unclassified)\`" "$DR_ORCH" "req-002: the review covers every unclassified Deviation line (P5 C3-8)"
assert_contains "data, schema, or a destructive operation" "$DR_ORCH" "req-002: the review covers data, schema, and destructive decisions (P5 C3-8)"
assert_contains "\`plan/current/deviation-review.md\`" "$DR_ORCH" "req-002: the orchestrator reads the assessor's verdicts file (P5 C3-8)"
assert_contains "rewrites each" "$DR_ORCH" "req-002: the orchestrator rewrites each build-log line with the class (P5 C3-8)"
assert_contains "exception-list item" "$DR_ORCH" "req-002: altering, schema, or destructive items become exception items (P5 C3-8)"
DR_AS=$(section "## Deviation review" "$ASSESSOR")
assert_equals "yes" "$([ -n "$DR_AS" ] && echo yes || echo no)" "req-002: the assessor skill has a Deviation review procedure (P5 C3-8)"
assert_contains "\`additive\` or \`altering\`" "$DR_AS" "req-002: the assessor classifies each line additive or altering (P5 C3-8)"
assert_contains "\`plan/current/deviation-review.md\`" "$DR_AS" "req-002: the assessor writes its verdicts to deviation-review.md (P5 C3-8)"
assert_contains "exception-list item" "$DR_AS" "req-002: altering, schema, or destructive verdicts become exception items (P5 C3-8)"
assert_contains "never edit the build log" "$DR_AS" "req-002: the assessor leaves the build-log rewrite to the orchestrator (P5 C3-8)"

print_summary
