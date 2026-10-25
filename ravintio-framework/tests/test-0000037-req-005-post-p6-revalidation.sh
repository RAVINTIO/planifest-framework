#!/usr/bin/env bash
# Verified by: integration
# Verified by: unit
# test-0000037-req-005-post-p6-revalidation.sh
# req-005: post-P6 revalidation runs after the P6 commit, logs one line,
# loops with cap 3 in autonomous (cap 5 elsewhere), and is named in the
# orchestrator P6 gate and the autonomous standard P6 row (ADR-006).
# Run from any directory: bash ravintio-framework/tests/test-0000037-req-005-post-p6-revalidation.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_DIR="$SCRIPT_DIR"
if [ "$(basename "$SCRIPT_DIR")" = "regression" ]; then
  TESTS_DIR="$(dirname "$SCRIPT_DIR")"
fi
source "$TESTS_DIR/helpers/assert.sh"

FW="$TESTS_DIR/.."
DOCS="$FW/skills/ravintio-docs-agent/SKILL.md"
ORCH="$FW/skills/ravintio-orchestrator/SKILL.md"
STD="$FW/standards/autonomous-run-standards.md"

SEC=$(awk '/^## Post-P6 revalidation/{f=1; print; next} f && /^## /{exit} f' "$DOCS")
ORCH_P6=$(grep -F "| P6 Documentation |" "$ORCH")
STD_P6=$(grep -E '^\| P6 \|' "$STD")

echo "=== req-005: timing and command (integration) ==="
assert_contains "after the P6 commit" "$SEC" "req-005: revalidation runs after the P6 commit"
assert_contains "before you report P6 complete" "$SEC" "req-005: revalidation runs before P6 is reported complete"
assert_contains "ravintio-overrides/doc-checks.yml" "$SEC" "req-005: section names the doc-checks override"
assert_contains "steps 0 to 5" "$SEC" "req-005: fallback is P4 steps 0 to 5"
assert_contains "Revalidation (P6): {command | P4 steps 0-5}, {pass | fail | skipped, no P6 edits}" "$SEC" "req-005: section gives the log line form"
assert_contains "failing check and its cycle count" "$SEC" "req-005: a failure logs the failing check and cycle count"

echo ""
echo "=== req-005: fixture with and without the override (integration) ==="
FIX=$(mktemp -d)
mkdir -p "$FIX/with/ravintio-overrides" "$FIX/without"
cp "$FW/templates/doc-checks.template.yml" "$FIX/with/ravintio-overrides/doc-checks.yml"
CMD=$(grep -E '^command:' "$FIX/with/ravintio-overrides/doc-checks.yml" | head -1 | sed 's/^command:[[:space:]]*//')
assert_equals "yes" "$([ -n "$CMD" ] && [ "${#CMD}" -le 500 ] && echo yes || echo no)" "req-005: fixture with the override has a valid command of at most 500 characters"
assert_equals "no" "$([ -f "$FIX/without/ravintio-overrides/doc-checks.yml" ] && echo yes || echo no)" "req-005: fixture without the override has no file, so P4 steps 0 to 5 apply"
rm -rf "$FIX"

echo ""
echo "=== req-005: caps and exception line (unit) ==="
assert_contains "cap of 3" "$SEC" "req-005: autonomous cap of 3 named in the docs-agent section"
assert_contains "cap of 5" "$SEC" "req-005: cap of 5 kept outside autonomous"
assert_contains "VALIDATION BLOCKED" "$SEC" "req-005: VALIDATION BLOCKED escalation kept"
assert_contains "3 approaches" "$SEC" "req-005: up to 3 approaches named"
assert_contains "## Changing approach" "$SEC" "req-005: section points to Changing approach"
assert_contains "Exception waiting (P6, 6): revalidation {failing check}" "$SEC" "req-005: exception line keeps the (P{N}, {item}) format"

echo ""
echo "=== req-005: routing surfaces (unit) ==="
assert_contains "revalidation" "$ORCH_P6" "req-005: orchestrator P6 gate condition names revalidation"
assert_contains "revalidation" "$STD_P6" "req-005: autonomous standard P6 pass condition names revalidation"

print_summary
