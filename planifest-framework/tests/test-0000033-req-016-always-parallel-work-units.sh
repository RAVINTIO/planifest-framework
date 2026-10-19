#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-016: each phase skill lists its always-parallel work units under an
#          **Always parallel:** list and dispatches them in one batch. The
#          dispatch standards gain an Always-parallel work units subsection.
#
# REGRESSION-CANDIDATE: covers the always-parallel work-unit lists in phase skills, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

SKILLS="$SCRIPT_DIR/../skills"
DISPATCH="$SCRIPT_DIR/../standards/agent-dispatch-standards.md"
SHIP="$SKILLS/planifest-ship-agent/SKILL.md"

# section <file> <exact-heading>: prints the section from that heading to the
# next heading of the same or higher level.
section() {
  awk -v h="$2" '
    BEGIN { lvl = length(h) - length(substr(h, index(h, " "))) }
    $0 == h { on = 1; print; next }
    on && /^#+ / { l = index($0, " ") - 1; if (l <= lvl) exit }
    on { print }
  ' "$1"
}

# line_of <file> <exact-heading>: prints the first line number of the heading.
line_of() {
  grep -n -x -F "$2" "$1" | head -1 | cut -d: -f1
}

# list_items <section-text>: counts bullet items directly after **Always parallel:**.
list_items() {
  awk '
    /\*\*Always parallel:\*\*/ { on = 1; next }
    on && /^[[:space:]]*- / { n++; next }
    on && /^[[:space:]]*$/ && n == 0 { next }
    on { exit }
    END { print n + 0 }
  ' <<< "$1"
}

echo "=== req-016: dispatch standards Always-parallel work units ==="

RULES_LINE=$(line_of "$DISPATCH" "## Parallelism Rules")
SUB_LINE=$(line_of "$DISPATCH" "### Always-parallel work units")
NEXT_H2=$(awk -v s="${RULES_LINE:-0}" 'NR > s && /^## / { print NR; exit }' "$DISPATCH")
assert_equals "yes" "$([ -n "$SUB_LINE" ] && [ -n "$RULES_LINE" ] && [ -n "$NEXT_H2" ] \
  && [ "$SUB_LINE" -gt "$RULES_LINE" ] && [ "$SUB_LINE" -lt "$NEXT_H2" ] && echo yes || echo no)" \
  "req-016: Always-parallel work units sits inside Parallelism Rules"

SUB=$(section "$DISPATCH" "### Always-parallel work units")
assert_contains "**Always parallel:**" "$SUB" "req-016: subsection names the Always parallel list"
assert_contains "one batch" "$SUB" "req-016: subsection says to dispatch in one batch"
assert_contains "\`Notes\`" "$SUB" "req-016: subsection names the build-log Notes field"
assert_contains "every phase" "$SUB" "req-016: subsection makes parallel the default in every phase"
assert_contains "floor" "$SUB" "req-016: subsection says the list sets a floor"

echo ""
echo "=== req-016: phase skills list always-parallel units ==="

for agent in spec adr validate security docs; do
  F="$SKILLS/planifest-$agent-agent/SKILL.md"
  SEC=$(section "$F" "## Parallelism Directive")
  assert_contains "**Always parallel:**" "$SEC" "req-016: $agent-agent Parallelism Directive has Always parallel list"
  assert_equals "yes" "$([ "$(list_items "$SEC")" -ge 1 ] && echo yes || echo no)" \
    "req-016: $agent-agent Always parallel list has at least one item"
done

CODEGEN_SEC=$(section "$SKILLS/planifest-codegen-agent/SKILL.md" "## Parallel Dispatch Checklist")
assert_contains "**Always parallel:**" "$CODEGEN_SEC" "req-016: codegen-agent Parallel Dispatch Checklist has Always parallel list"
assert_equals "yes" "$([ "$(list_items "$CODEGEN_SEC")" -ge 1 ] && echo yes || echo no)" \
  "req-016: codegen-agent Always parallel list has at least one item"

echo ""
echo "=== req-016: ship skill Parallelism Directive ==="

PD_LINE=$(line_of "$SHIP" "## Parallelism Directive")
P7_LINE=$(line_of "$SHIP" "## P7: Archive")
assert_equals "yes" "$([ -n "$PD_LINE" ] && [ -n "$P7_LINE" ] && [ "$PD_LINE" -lt "$P7_LINE" ] && echo yes || echo no)" \
  "req-016: ship Parallelism Directive comes before P7: Archive"

SHIP_SEC=$(section "$SHIP" "## Parallelism Directive")
assert_contains "**Always parallel:**" "$SHIP_SEC" "req-016: ship Parallelism Directive has Always parallel list"
assert_equals "yes" "$([ "$(list_items "$SHIP_SEC")" -ge 1 ] && echo yes || echo no)" \
  "req-016: ship Always parallel list has at least one item"
assert_contains "REGRESSION-CANDIDATE" "$SHIP_SEC" "req-016: ship section names the regression-candidate scan"
assert_contains "cross-reference search" "$SHIP_SEC" "req-016: ship section names the cross-reference search"
assert_contains "in order" "$SHIP_SEC" "req-016: ship section keeps the numbered steps in order"

print_summary
