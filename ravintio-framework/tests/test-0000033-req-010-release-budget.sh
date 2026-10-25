#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-010: a repo sets a release target and ceiling in size points in
#          ravintio-overrides/release-budget.yml. P0 sizes each candidate and
#          recommends a fill from the backlog up to the target.
#
# REGRESSION-CANDIDATE: covers the release budget template, sizing standard, and P0 fill text, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
BUDGET="$FW/templates/release-budget.template.yml"
SIZING="$FW/standards/release-sizing.md"
ORCH="$FW/skills/ravintio-orchestrator/references/phase-0-assess-and-coach.md"
DESIGN="$FW/templates/design.template.md"
BRIEF="$FW/templates/feature-brief.template.md"
GUIDE="$FW/templates/feature-brief-guide.md"

# has <needle> <haystack> <label>: like assert_contains, without the haystack dump.
has() {
  assert_equals "present" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

BUDGET_TEXT="$(cat "$BUDGET" 2>/dev/null || true)"
SIZING_TEXT="$(cat "$SIZING" 2>/dev/null || true)"
DECOMP=$(sed -n '/^### Decomposition/,/^### Waves/p' "$ORCH")
STEP3C=$(sed -n '/^3c\. \*\*Backlog pickup/,/^3d\. /p' "$ORCH")
SCOPE=$(sed -n '/^## Scope/,/^## Assumptions/p' "$DESIGN")

echo "=== req-010: release-budget.template.yml ==="

assert_equals "yes" "$([ -f "$BUDGET" ] && echo yes || echo no)" "req-010: templates/release-budget.template.yml exists"
TARGET=$(sed -n 's/^target:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$BUDGET" 2>/dev/null | head -1)
CEILING=$(sed -n 's/^ceiling:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$BUDGET" 2>/dev/null | head -1)
assert_equals "yes" "$([[ "$TARGET" =~ ^[1-9][0-9]*$ ]] && echo yes || echo no)" "req-010: target is a positive whole number"
assert_equals "yes" "$([[ "$CEILING" =~ ^[1-9][0-9]*$ ]] && echo yes || echo no)" "req-010: ceiling is a positive whole number"
assert_equals "yes" "$([ -n "$TARGET" ] && [ -n "$CEILING" ] && [ "$TARGET" -le "$CEILING" ] && echo yes || echo no)" \
  "req-010: target is no greater than ceiling"
has "ravintio-overrides/release-budget.yml" "$BUDGET_TEXT" "req-010: template comment names the override path"
has "three-story rule" "$BUDGET_TEXT" "req-010: template comment says an absent file keeps the three-story rule"
has "never write" "$BUDGET_TEXT" "req-010: template comment says the framework never writes the file"
has "warning" "$BUDGET_TEXT" "req-010: template comment warns on an invalid file"

echo ""
echo "=== req-010: release-sizing.md standard ==="

assert_equals "yes" "$([ -f "$SIZING" ] && echo yes || echo no)" "req-010: standards/release-sizing.md exists"
for term in "small (1)" "medium (2)" "large (3)" "target" "ceiling" "candidate" "later wave"; do
  has "$term" "$SIZING_TEXT" "req-010: release-sizing.md names '$term'"
done

echo ""
echo "=== req-010: orchestrator Decomposition and step 3c ==="

has "more than 3 user stories" "$DECOMP" "req-010: Decomposition keeps the three-story rule"
has "release-budget.yml" "$DECOMP" "req-010: Decomposition names release-budget.yml"
has "release-sizing.md" "$DECOMP" "req-010: Decomposition links to release-sizing.md"
assert_equals "yes" "$([ -n "$STEP3C" ] && echo yes || echo no)" "req-010: step 3c found"
has "release-budget.yml" "$STEP3C" "req-010: step 3c names release-budget.yml"
has "Release budget: {total} of target" "$STEP3C" "req-010: step 3c has the budget build-log form"
has "Release budget: none, three-story rule" "$STEP3C" "req-010: step 3c has the no-budget build-log form"
has "If the file is absent or invalid, step 3c behaves as above" "$STEP3C" "req-010: step 3c keeps the three-story path for an absent or invalid file (AC-3)"

echo ""
echo "=== req-010: fill confirmation and ceiling ==="

has "The human confirms or edits the list in one answer" "$SIZING_TEXT" "req-010: the human confirms or edits the fill (AC-2)"
has "P0 never recommends a fill above \`ceiling\`" "$SIZING_TEXT" "req-010: P0 never recommends a fill above the ceiling (AC-2)"
has "The human confirms or edits it in one answer" "$STEP3C" "req-010: step 3c asks the human to confirm or edit the fill (AC-2)"

echo ""
echo "=== req-010: design and brief templates ==="

has "Release size" "$SCOPE" "req-010: design ## Scope has a Release size line"
has "release-budget.yml" "$(cat "$BRIEF")" "req-010: feature-brief template names release-budget.yml"
has "release-budget.yml" "$(cat "$GUIDE")" "req-010: feature-brief guide names release-budget.yml"

print_summary
