#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-009: when a design depends on existing records, P0 discovery samples
#          recent rows and states how often each value is usable. The design
#          names that rate as an assumption.
#
# REGRESSION-CANDIDATE: covers the Record Samples discovery section and its design assumption, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
DISC="$FW/templates/discovery.template.md"
ORCH="$FW/skills/planifest-orchestrator/SKILL.md"
DESIGN="$FW/templates/design.template.md"

# has <needle> <haystack> <label>: like assert_contains, without the haystack dump.
has() {
  assert_equals "present" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

SAMPLES=$(sed -n '/^## Record Samples/,$p' "$DISC")
SDP=$(sed -n '/^### Structured Discovery Pass (all modes)/,/^### Mode Taxonomy/p' "$ORCH")
STEP3D=$(sed -n '/^3d\. \*\*Write discovery.md/,/^   After adoption mode is/p' "$ORCH")
ASSUMPTIONS=$(sed -n '/^## Assumptions/,/^## Risks/p' "$DESIGN")

echo "=== req-009: discovery template Record Samples ==="

MODE_LINE=$(grep -n '^## Mode Findings' "$DISC" | head -1 | cut -d: -f1)
SAMPLE_LINE=$(grep -n '^## Record Samples' "$DISC" | head -1 | cut -d: -f1)
assert_equals "yes" "$([ -n "$SAMPLE_LINE" ] && echo yes || echo no)" "req-009: discovery template has ## Record Samples"
assert_equals "yes" "$([ -n "$SAMPLE_LINE" ] && [ -n "$MODE_LINE" ] && [ "$SAMPLE_LINE" -gt "$MODE_LINE" ] && echo yes || echo no)" \
  "req-009: ## Record Samples comes after ## Mode Findings"
for col in "Source" "Value relied on" "Rows sampled" "Usable rows" "Usable rate"; do
  has "| $col " "$SAMPLES" "req-009: Record Samples has column '$col'"
done
has "None" "$SAMPLES" "req-009: Record Samples uses None when no records are read"
has "could not be determined" "$SAMPLES" "req-009: an unreadable source states the rate could not be determined"

echo ""
echo "=== req-009: orchestrator discovery text ==="

has "samples recent rows" "$SDP" "req-009: Structured Discovery Pass samples recent rows"
has "usable" "$SDP" "req-009: Structured Discovery Pass states how often a value is usable"
has "read-only" "$SDP" "req-009: the sample is read-only"
assert_equals "yes" "$([ -n "$STEP3D" ] && echo yes || echo no)" "req-009: step 3d found"
has "Record Samples" "$STEP3D" "req-009: step 3d names Record Samples"
has "coaching reveals" "$STEP3D" "req-009: step 3d names the later-sampling path"
has "commits \`discovery.md\` again" "$STEP3D" "req-009: step 3d commits discovery.md again"

echo ""
echo "=== req-009: design template assumption ==="

has "Record Samples" "$ASSUMPTIONS" "req-009: design Assumptions names Record Samples"
has "usable rate" "$ASSUMPTIONS" "req-009: design Assumptions names the usable rate"

print_summary
