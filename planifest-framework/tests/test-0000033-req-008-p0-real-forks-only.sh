#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-008: P0 asks only real forks. Derivable items go into the design draft.
#          The design, the Scope Lock batch, and the run mode confirm in one
#          turn, and the P0 build-log block records the question count.
#
# REGRESSION-CANDIDATE: covers the P0 real-forks policy and the combined confirmation turn, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
POLICY="$FW/standards/p0-question-policy.md"
ORCH="$FW/skills/planifest-orchestrator/references/phase-0-assess-and-coach.md"
BUILD_LOG="$FW/templates/build-log.template.md"
ASSESS="$FW/skills/planifest-build-assessment-agent/SKILL.md"

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

# has <needle> <haystack> <label>: like assert_contains, without the haystack dump.
has() {
  assert_equals "present" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

POLICY_TEXT="$(cat "$POLICY" 2>/dev/null || true)"
ORCH_TEXT="$(cat "$ORCH")"
COACH=$(sed -n '/^### How you coach/,/^### Decomposition/p' "$ORCH")
STEP3A=$(sed -n '/^3a\. \*\*Detect adoption mode/,/^3b\. /p' "$ORCH")
END_P0=$(sed -n '/^### What you produce at the end of Phase 0/,/^### Scope Lock Challenge/p' "$ORCH")
SCOPE_LOCK=$(sed -n '/^### Scope Lock Challenge/,/^### P0 Audit Trail/p' "$ORCH")
AUDIT=$(sed -n '/^### P0 Audit Trail/,/^### Phase 0 → Phase 1 Gate Checklist/p' "$ORCH")
GATE=$(sed -n '/^### Phase 0 → Phase 1 Gate Checklist/,/^## Phase Conventions/p' "$ORCH")
P0_TABLE=$(sed -n '/^### P0: Assess & Coach/,/^---/p' "$BUILD_LOG")
CRITICAL=$(sed -n '/^## Critical Audit/,/^## Rules/p' "$ASSESS")

echo "=== req-008: p0-question-policy.md standard ==="

assert_equals "yes" "$([ -f "$POLICY" ] && echo yes || echo no)" "req-008: standards/p0-question-policy.md exists"
has "real fork" "$POLICY_TEXT" "req-008: policy defines a real fork"
for item in "adoption mode" "version" "stack, when unchanged" "NFR targets" "risks" "the component split" "the feature ID"; do
  has "- $item" "$POLICY_TEXT" "req-008: policy lists derivable item '$item'"
done
has "combined confirmation turn" "$POLICY_TEXT" "req-008: policy defines the combined confirmation turn"
has "0000014-ADR-008" "$POLICY_TEXT" "req-008: policy keeps 0000014-ADR-008 for real forks"
has "conflict warning" "$POLICY_TEXT" "req-008: policy keeps the conflict warning exception"
has "is lower than the last known version" "$POLICY_TEXT" "req-008: policy keeps the version hard block"
has "versionPolicy: external" "$POLICY_TEXT" "req-008: policy keeps the external version exception"
has "product id" "$POLICY_TEXT" "req-008: policy keeps the declared product id hard stop"
has "separate, explicit accept / edit / reject" "$POLICY_TEXT" "req-008: policy keeps per-item Scope Lock answers"
has "counts as one" "$POLICY_TEXT" "req-008: policy counts the combined turn as one question"

echo ""
echo "=== req-008: orchestrator How you coach and step 3a ==="

has "p0-question-policy.md" "$COACH" "req-008: How you coach links to p0-question-policy.md"
has "real forks" "$COACH" "req-008: How you coach asks only real forks"
has "design draft" "$COACH" "req-008: How you coach puts derivable items in the design draft"
has "P0: [Observation]. I recommend [X]" "$COACH" "req-008: recommend-then-confirm format block stays"
has "This pattern applies across all pipeline phases (P0–P9)" "$COACH" "req-008: other-phases sentence stays"
assert_equals "yes" "$([ -n "$STEP3A" ] && echo yes || echo no)" "req-008: step 3a found"
lacks "confirm before proceeding" "$STEP3A" "req-008: step 3a no longer confirms before proceeding"
has "conflict warning protocol" "$STEP3A" "req-008: step 3a still names the conflict warning protocol"
has "design draft" "$STEP3A" "req-008: step 3a puts the detected mode in the design draft"

echo ""
echo "=== req-008: orchestrator version text ==="

has "is lower than the last known version" "$ORCH_TEXT" "req-008: Hard block message stays"
lacks "Present the last known version and the suggested bump to the human" "$ORCH_TEXT" \
  "req-008: separate version prompt removed"

echo ""
echo "=== req-008: combined confirmation turn ==="

has "combined confirmation turn" "$(tr '[:upper:]' '[:lower:]' <<< "$END_P0")" "req-008: end of P0 names the combined confirmation turn"
has "Scope Lock" "$END_P0" "req-008: combined turn includes the Scope Lock batch"
has "run mode" "$END_P0" "req-008: combined turn includes the run mode"
has "Do not proceed to Phase 1 until the human has confirmed the Design" "$END_P0" "req-008: hard gate sentence stays"
lacks "Before asking for design confirmation, ask:" "$END_P0" "req-008: separate run-mode prompt removed"
has "names who acts" "$END_P0" "req-008: combined turn says each run-mode option names who acts"
has "the agent stops for you" "$END_P0" "req-008: combined turn gives an actor-naming example"

echo ""
echo "=== req-008: Scope Lock scope note ==="

has "separate, explicit accept / edit / reject" "$SCOPE_LOCK" "req-008: Scope Lock keeps separate accept / edit / reject"
has "No blanket or implied confirmation" "$SCOPE_LOCK" "req-008: Scope Lock keeps no blanket confirmation"
has "does not alter" "$SCOPE_LOCK" "req-008: Scope Lock scope note keeps does not alter"
has "0000014-ADR-008" "$SCOPE_LOCK" "req-008: Scope Lock scope note names 0000014-ADR-008"
has "second narrow exception" "$SCOPE_LOCK" "req-008: combined turn named as the second narrow exception"

echo ""
echo "=== req-008: question count lines ==="

for line in "P0 questions asked" "Brief complete" "Stack unchanged"; do
  has "$line" "$AUDIT" "req-008: P0 Audit Trail writes '$line'"
  has "$line" "$P0_TABLE" "req-008: build-log P0 table has '$line'"
  has "$line" "$CRITICAL" "req-008: Critical Audit names '$line'"
done
has "above 3" "$CRITICAL" "req-008: Critical Audit flags a count above 3"
has "design that contains them" "$GATE" "req-008: gate checklist meets adoption mode and version through the design"

print_summary
