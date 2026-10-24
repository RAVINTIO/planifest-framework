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
source "$SCRIPT_DIR/../helpers/assert.sh"

FW="$SCRIPT_DIR/../.."
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
assert_contains "Outside \`autonomous\`, an absent \`design_critic\` key reads as **report-only**" "$TP" \
  "0000036 req-006: absent design_critic key reads as report-only outside autonomous"
assert_contains "An absent \`loop-toggles.yml\` reads the same as an absent key" "$TP" \
  "0000036 req-006: absent toggles file reads as an absent key for design_critic"
assert_contains "An invalid \`design_critic\` value still reads as **off**" "$TP" \
  "0000036 req-006: invalid design_critic value still reads as off"
assert_contains "Outside \`autonomous\`, every other key still reads as **off** when absent" "$TP" \
  "0000036 req-006: other keys still read as off when absent outside autonomous"
lacks "Outside \`autonomous\`, an absent key still reads as **off**" "$TP" \
  "0000036 req-006: Toggle Protocol drops the all-keys-off rule outside autonomous"
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
assert_contains "default report-only" "$(grep '^# *design_critic:' <<< "$TOGT")" \
  "0000036 req-006: commented design_critic line names the report-only default"
assert_contains "design_critic reads as report-only" "$HEADER" \
  "0000036 req-006: template header states the design_critic report-only default"
lacks "identical to a" "$HEADER" "0000036 req-006: template header drops the zero-config identity claim"
CRITIC_PARA=$(grep '^\*\*Design-critic (toggle' "$ORCH")
assert_contains "\`design_critic: report-only (absent default)\`" "$CRITIC_PARA" \
  "0000036 req-006: orchestrator design-critic paragraph names the Toggle record outside autonomous"
assert_contains "build-log block" "$CRITIC_PARA" \
  "0000036 req-006: orchestrator writes the critic verdict line to the build-log block"
assert_contains "\`report-only\` outside \`autonomous\`" "$(grep '^- \*\*Toggle defaults' "$STD")" \
  "0000036 req-006: standards toggle-defaults bullet names report-only outside autonomous"
ARCH_OVERVIEW="$(cat "$FW/../docs/architecture-overview.md" 2>/dev/null || true)"
assert_contains "Outside \`autonomous\`, an absent \`design_critic\` key or an absent file reads as \`report-only\`" "$ARCH_OVERVIEW" \
  "0000036 req-006: architecture overview states the design_critic report-only default"

echo ""
echo "=== req-003: validate and security checkers ==="

assert_contains "autonomous" "$(grep '^6\. \*\*Verify by execution' "$VALIDATE")" \
  "req-003: validate step 6 runs verify-by-execution as the P4 checker in autonomous"
assert_contains "fresh-context re-review" "$(cat "$SECURITY")" \
  "req-003: security skill re-reviews each fixed finding in autonomous"

echo ""
echo "=== req-003: explicit off for a checker blocks autonomous (P5 G1) ==="

for txt in "$TP" "$GATES"; do
  assert_contains "blocks the \`autonomous\` choice at P0" "$txt" "req-003: explicit off or report-only blocks autonomous at P0 (P5 G1)"
  for k in design_critic reversal_protocol verify_by_execution cross_model_review; do
    assert_contains "\`$k\`" "$(grep 'blocks the `autonomous` choice' <<< "$txt")" "req-003: block rule names $k (P5 G1)"
  done
  assert_contains "\`report-only\`" "$(grep 'blocks the `autonomous` choice' <<< "$txt")" "req-003: block rule names report-only (P5 G1)"
  assert_contains "removing it or setting \`on\`" "$txt" "req-003: P0 recommends removing the key or setting on (P5 G1)"
  assert_contains "\`parallel_streams\` stays free to set" "$txt" "req-003: parallel_streams stays free to set (P5 G1)"
done
RM_TEXT=$(sed -n '/^### What you produce at the end of Phase 0/,/^### Scope Lock Challenge/p' "$FW/skills/planifest-orchestrator/references/phase-0-assess-and-coach.md")
assert_contains "checker key" "$RM_TEXT" "req-003: orchestrator run-mode text names the checker-key block (P5 G1)"
assert_contains "Toggle Protocol" "$(grep 'checker key' <<< "$RM_TEXT")" "req-003: orchestrator block line links to the Toggle Protocol (P5 G1)"
lacks "always wins, including \`off\` and \`report-only\`" "$TP" "req-003: Toggle Protocol no longer says an explicit off always wins (P5 G1)"
assert_contains "checker key" "$(sed -n '1,/p0_completeness/p' "$TOG")" "req-003: toggles template header states the checker-key block (P5 G1)"

echo ""
echo "=== req-003: P1 records every resolved toggle and its source (P5 G8) ==="

REC=$(grep 'Toggle record' <<< "$TP")
assert_contains "at P1 start" "$REC" "req-003: toggle record happens at P1 start (P5 G8)"
assert_contains "every resolved toggle" "$REC" "req-003: build log records every resolved toggle (P5 G8)"
for s in "file value" "autonomous default" "absent default"; do
  assert_contains "\`$s\`" "$REC" "req-003: toggle record names the $s source (P5 G8)"
done

echo ""
echo "=== req-003: the P1 Toggle record freezes checker keys in autonomous (P5 C2-3) ==="

for txt in "$TP" "$GATES"; do
  FROZEN=$(grep 'Frozen checkers' <<< "$txt")
  assert_contains "binding for the run" "$FROZEN" "req-003: the P1 Toggle record is binding for the run (P5 C2-3)"
  for k in design_critic reversal_protocol verify_by_execution cross_model_review; do
    assert_contains "\`$k\`" "$FROZEN" "req-003: frozen-checker rule names $k (P5 C2-3)"
  done
  assert_contains "later edit to \`planifest-overrides/loop-toggles.yml\`" "$FROZEN" "req-003: a later toggles edit is ignored for those keys (P5 C2-3)"
  assert_contains "Human touchpoint" "$FROZEN" "req-003: the ignored edit is logged as a touchpoint-style line (P5 C2-3)"
done

echo ""
echo "=== req-003: P1 re-applies the P0 checker block (P5 C3-7) ==="

RECHECK=$(grep 'P1 checker re-check' <<< "$TP")
assert_contains "at P1 start" "$RECHECK" "req-003: the checker block runs again at P1 start (P5 C3-7)"
assert_contains "\`off\` or \`report-only\`" "$RECHECK" "req-003: P1 re-check names off and report-only (P5 C3-7)"
assert_contains "drops to \`continuous\`" "$RECHECK" "req-003: a blocked checker drops the run to continuous at P1 (P5 C3-7)"
assert_contains "Run mode dropped (P1)" "$RECHECK" "req-003: the drop is logged with its reason (P5 C3-7)"
assert_contains "Only the orchestrator writes the Toggle record" "$(grep '^\*\*Toggle record' <<< "$TP")" "req-003: only the orchestrator writes the Toggle record (P5 C3-7)"

print_summary
