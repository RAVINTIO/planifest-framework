#!/usr/bin/env bash
# Tests for feature 0000037-green-ci-before-ship
# req-006: verified-by-and-p3-scan (ADR-007, ADR-008)
# Verified by: unit
# Verified by: integration
#
# Covers:
#   (a) req-006 template shows Verified by with the six values and both forms
#   (b) req-006 spec-agent skill tells the spec agent to fill the field
#   (c) req-006 codegen-agent skill runs the P3 scan, blocks on a gap, logs the line,
#       applies indented-line precedence, and checks the header comment
#   (d) req-006 legacy files without the field pass and report unspecified (P3 and P4)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$FRAMEWORK/templates/requirement.template.md"
SPEC="$FRAMEWORK/skills/planifest-spec-agent/SKILL.md"
CODEGEN="$FRAMEWORK/skills/planifest-codegen-agent/SKILL.md"
VALIDATE="$FRAMEWORK/skills/planifest-validate-agent/SKILL.md"

has() { grep -qF -- "$2" "$1" 2>/dev/null && echo yes || echo no; }

# --- (a) req-006 template -------------------------------------------------
assert_equals "yes" "$(has "$TEMPLATE" "Verified by: {{unit | integration | contract | e2e | execution | manual}}")" "req-006 template: criterion line shows six values"
assert_equals "yes" "$(has "$TEMPLATE" "  - Verified by: {{type}}")" "req-006 template: indented form"
assert_equals "yes" "$(has "$TEMPLATE" "indented line governs")" "req-006 template: precedence note"
assert_equals "yes" "$(has "$TEMPLATE" "one-line reason")" "req-006 template: manual needs a reason"

# --- (b) req-006 spec-agent ----------------------------------------------
assert_equals "yes" "$(has "$SPEC" "Verified by")" "req-006 spec-agent: names the field"
assert_equals "yes" "$(has "$SPEC" "every new acceptance criterion")" "req-006 spec-agent: fills it for every new criterion"
assert_equals "yes" "$(has "$SPEC" "unit, integration, contract, e2e, execution, or manual")" "req-006 spec-agent: lists the six values"

# --- (c) req-006 codegen-agent P3 scan -----------------------------------
assert_equals "yes" "$(has "$CODEGEN" "Requirement-ID scan (P3): {N} requirements, {M} unmapped")" "req-006 codegen: log line"
assert_equals "yes" "$(has "$CODEGEN" "plan/current/requirements/")" "req-006 codegen: scans the requirements directory"
assert_equals "yes" "$(has "$CODEGEN" "before you commit P3")" "req-006 codegen: scan runs before P3 closes"
assert_equals "yes" "$(has "$CODEGEN" "blocks P3")" "req-006 codegen: gap blocks closing"
assert_equals "yes" "$(has "$CODEGEN" "indented \`Verified by:\` line governs")" "req-006 codegen: indented precedence"
assert_equals "yes" "$(has "$CODEGEN" "# Verified by: {type}")" "req-006 codegen: header comment check"
assert_equals "yes" "$(has "$CODEGEN" "deferred to P4")" "req-006 codegen: execution and manual deferred"
assert_equals "yes" "$(has "$CODEGEN" "3 approaches")" "req-006 codegen: autonomous exception-list rule"
assert_equals "yes" "$(has "$CODEGEN" "including a mapped suite with no header")" "req-006 codegen: missing header handling"

# --- (d) req-006 legacy files --------------------------------------------
assert_equals "yes" "$(has "$CODEGEN" "no \`Verified by\` field")" "req-006 codegen: legacy file passes"
assert_equals "yes" "$(has "$CODEGEN" "unspecified")" "req-006 codegen: unspecified type"
assert_equals "yes" "$(has "$VALIDATE" "unspecified")" "req-006 validate: coverage table reports unspecified"
assert_equals "yes" "$(has "$VALIDATE" "REQ-ID | AC | Type | Covered by test | Pass/Fail")" "req-006 validate: table has a Type column"
assert_equals "yes" "$(has "$VALIDATE" "indented \`Verified by:\` line governs")" "req-006 validate: same precedence rule as P3"
assert_equals "yes" "$(has "$VALIDATE" "missing \`Verified by\` field is never a failure")" "req-006 validate: missing field never fails"

print_summary
