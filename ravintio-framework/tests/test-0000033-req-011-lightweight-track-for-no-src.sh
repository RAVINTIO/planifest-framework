#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-011: Fast Path's prerequisite relaxes to admit a change with no src/
#          target. Its four criteria stay, and the orchestrator's track table
#          says so.
#
# REGRESSION-CANDIDATE: covers the Fast Path no-src prerequisite and its routing row, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
FAST="$FW/workflows/fast-path.md"
ORCH="$FW/skills/ravintio-orchestrator/SKILL.md"

# has <needle> <haystack> <label>: like assert_contains, without the haystack dump.
has() {
  assert_equals "present" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

PREREQ=$(sed -n '/^## Prerequisites/,/^## Fast Path Criteria/p' "$FAST")
CRITERIA=$(sed -n '/^## Fast Path Criteria/,/^## Steps/p' "$FAST")
STEP4=$(sed -n '/^4\. \*\*Update `component.yml`/,/^5\. /p' "$FAST")
STEP5=$(sed -n '/^5\. \*\*Log the change/,/^6\. /p' "$FAST")
TREE=$(sed -n '/^### Three-Track Decision Tree/,/^### Fast Path Criteria and Execution/p' "$ORCH")
FPCE=$(sed -n '/^### Fast Path Criteria and Execution/,/^## Phase Skip Protocol/p' "$ORCH")

echo "=== req-011: fast-path.md prerequisites and criteria ==="

has 'src/{component-id}/' "$PREREQ" "req-011: prerequisite keeps src/{component-id}/"
has 'no `src/` target' "$PREREQ" "req-011: prerequisite admits a change with no src/ target"
has "The request meets **ALL** Fast Path criteria" "$PREREQ" "req-011: prerequisite keeps ALL criteria"
has "1. Does **not** introduce new external dependencies" "$CRITERIA" "req-011: criterion 1 unchanged"
has "2. Does **not** alter, add, or remove database schemas or data models" "$CRITERIA" "req-011: criterion 2 unchanged"
has "3. Does **not** change security parameters, authentication, or routing logic" "$CRITERIA" "req-011: criterion 3 unchanged"
has "4. Is confined to: UI styling, copy changes, or isolated pure-function logic bugs" "$CRITERIA" "req-011: criterion 4 unchanged"
has "**If any criterion fails → use \`/change-pipeline\` instead.**" "$CRITERIA" "req-011: failed-criterion routing line unchanged"

echo ""
echo "=== req-011: fast-path.md steps 4 and 5 ==="

has "covers the changed paths" "$STEP4" "req-011: step 4 updates the covering component.yml"
has "skip step 4" "$STEP4" "req-011: step 4 is skipped when no manifest covers the paths"
has 'no-`src/`' "$STEP5" "req-011: step 5 names the no-src Component line"

echo ""
echo "=== req-011: orchestrator routing ==="

ROW=$(grep 'no `src/` target' <<< "$TREE")
has "**Fast Path** - if ALL Fast Path criteria are met" "$ROW" "req-011: track table routes a no-src change to Fast Path"
has 'no `src/` target' "$FPCE" "req-011: Fast Path Criteria and Execution names no src/ target"
has "ravintio-framework/workflows/fast-path.md" "$FPCE" "req-011: Fast Path Criteria and Execution still links the workflow"

echo ""
echo "=== req-011: Fast Path never admits enforcement paths (P5 G12) ==="

for path in 'ravintio-framework/hooks/' 'ravintio-framework/scripts/' 'setup.sh' 'setup.ps1' 'enforcement hook'; do
  has "$path" "$PREREQ" "req-011: prerequisite excludes $path (P5 G12)"
  has "$path" "$ROW" "req-011: track table row excludes $path (P5 G12)"
done
has "Change or Feature Pipeline" "$PREREQ" "req-011: excluded paths take the Change or Feature Pipeline (P5 G12)"

echo ""
echo "=== req-011: Fast Path never admits the autonomous-run standards (P5 C2-8) ==="

has "ravintio-framework/standards/autonomous-run-standards.md" "$PREREQ" "req-011: prerequisite excludes autonomous-run-standards.md (P5 C2-8)"
has "ravintio-framework/standards/autonomous-run-standards.md" "$ROW" "req-011: track table row excludes autonomous-run-standards.md (P5 C2-8)"
has "exception list and standing rules" "$PREREQ" "req-011: prerequisite says why the standards file is excluded (P5 C2-8)"

print_summary
