#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-014: the docs agent reruns the P4 check set after its P6 edits, or a
#          smaller doc-check command declared in planifest-overrides/doc-checks.yml.
#
# REGRESSION-CANDIDATE: covers the post-P6 revalidation section and the doc-checks template, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

DOCS="$SCRIPT_DIR/../skills/planifest-docs-agent/SKILL.md"
TPL="$SCRIPT_DIR/../templates/doc-checks.template.yml"

line_of() {
  grep -n -m1 -F "$1" "$2" | cut -d: -f1
}

SEC=$(awk '/^## Post-P6 revalidation/{f=1; print; next} f && /^## /{exit} f' "$DOCS")

echo "=== req-014: docs agent section placement ==="

L_WHAT=$(line_of "## What You Produce" "$DOCS")
L_REVAL=$(line_of "## Post-P6 revalidation" "$DOCS")
L_RULES=$(line_of "## Rules" "$DOCS")
assert_equals "yes" "$([ -n "$L_REVAL" ] && [ "$L_REVAL" -gt "${L_WHAT:-0}" ] && [ "$L_REVAL" -lt "${L_RULES:-0}" ] && echo yes || echo no)" \
  "req-014: Post-P6 revalidation sits after What You Produce and before Rules"

echo ""
echo "=== req-014: section content ==="

assert_contains "planifest-overrides/doc-checks.yml" "$SEC" "req-014: section names the doc-checks override"
assert_contains "\`command\`" "$SEC" "req-014: section names the command key"
assert_contains "steps 0 to 5" "$SEC" "req-014: section names validate-agent Process steps 0 to 5"
assert_contains "## Process" "$SEC" "req-014: section names the validate-agent Process section"
assert_contains "planifest-loop-runner" "$SEC" "req-014: section names planifest-loop-runner"
assert_contains "cap of 5" "$SEC" "req-014: section names a cap of 5"
assert_contains "VALIDATION BLOCKED" "$SEC" "req-014: section names VALIDATION BLOCKED"
assert_contains "P6 build-log block" "$SEC" "req-014: section records the result in the P6 build-log block"
assert_contains "Post-P6 revalidation: skipped, no P6 edits" "$SEC" "req-014: section names the skip case"
assert_contains "Fix the doc, never the check" "$SEC" "req-014: section fixes the doc, never the check"

echo ""
echo "=== req-014: doc-checks template ==="

assert_equals "yes" "$([ -f "$TPL" ] && echo yes || echo no)" "req-014: doc-checks.template.yml exists"
TPL_ALL=$(cat "$TPL" 2>/dev/null)
assert_contains "command:" "$TPL_ALL" "req-014: template declares command"
assert_contains "never creates" "$TPL_ALL" "req-014: template says the framework never creates the override file"
assert_contains "optional" "$TPL_ALL" "req-014: template says the file is optional"

print_summary
