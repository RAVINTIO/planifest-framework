#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-006: each phase writes a progress line to the build log, the build-log
#          Header records the run mode, and in autonomous mode the P8 report
#          flags any human touchpoint outside the exception list.
#
# REGRESSION-CANDIDATE: covers on-the-loop visibility lines and the P8 touchpoint audit, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

STD="$SCRIPT_DIR/../standards/autonomous-run-standards.md"
TPL="$SCRIPT_DIR/../templates/build-log.template.md"
ORCH="$SCRIPT_DIR/../skills/planifest-orchestrator/SKILL.md"
SHIP="$SCRIPT_DIR/../skills/planifest-ship-agent/SKILL.md"
BA="$SCRIPT_DIR/../skills/planifest-build-assessment-agent/SKILL.md"

VIS=$(awk '/^## Visibility/{f=1; print; next} f && /^## /{exit} f' "$STD" 2>/dev/null)
HEADER=$(sed -n '/^## Header/,/^---/p' "$TPL")
TPL_ALL=$(cat "$TPL")
CONV=$(sed -n '/^## Phase Conventions/,/^## Phase Invocation/p' "$ORCH")
AUDIT=$(sed -n '/^## Critical Audit/,/^## Rules/p' "$BA")
TOUCH=$(sed -n '/\*\*Human touchpoint audit\*\*/,/^$/p' <<< "$AUDIT")
INTEG=$(sed -n '/\*\*Build log integrity\*\*/,/^$/p' <<< "$AUDIT")
GATE=$(sed -n '/\*\*Phase gate audit\*\*/,/^$/p' <<< "$AUDIT")

echo "=== req-006: standards Visibility section ==="

assert_equals "yes" "$([ -n "$VIS" ] && echo yes || echo no)" "req-006: standards file has a ## Visibility section"
assert_contains 'Progress: P{N} {done | blocked} at {End}: {one-line summary}' "$VIS" \
  "req-006: Visibility gives the progress line format"
assert_contains 'Human touchpoint (P{N}): {what the run asked or waited for} [{exception: item | outside list}]' "$VIS" \
  "req-006: Visibility gives the touchpoint line format"
assert_contains "reuses the phase block's \`End\` value" "$VIS" \
  "req-006: progress line reuses the phase block End value"
assert_contains "\`autonomous\` only" "$VIS" "req-006: touchpoint line marked autonomous only"
assert_contains "A touchpoint is" "$VIS" "req-006: Visibility defines a touchpoint"
assert_contains "no push notification" "$VIS" "req-006: Visibility says no push notification"

echo ""
echo "=== req-006: build log template ==="

assert_contains "| Run mode |" "$HEADER" "req-006: Header table has a Run mode row"
assert_contains 'Progress: P{N} {done | blocked} at {End}: {one-line summary}' "$TPL_ALL" \
  "req-006: template shows the progress line format"
assert_contains 'Human touchpoint (P{N}):' "$TPL_ALL" "req-006: template shows the touchpoint line format"
assert_contains "\`autonomous\` only" "$TPL_ALL" "req-006: template marks the touchpoint line autonomous only"

echo ""
echo "=== req-006: orchestrator Phase Conventions ==="

assert_contains "progress line" "$CONV" "req-006: Phase Conventions name the progress line"
assert_contains "autonomous-run-standards.md" "$CONV" "req-006: Phase Conventions link to the standards file"

echo ""
echo "=== req-006: ship skill P7, P8, and P9 ==="

for P in P7 P8 P9; do
  LINE=$(grep -E "^\*\*Build log( first)?:\*\* Append a $P phase block" "$SHIP")
  assert_contains "progress line" "$LINE" "req-006: ship $P build-log line names the progress line"
done

echo ""
echo "=== req-006: build assessment Critical Audit ==="

assert_equals "yes" "$([ -n "$TOUCH" ] && echo yes || echo no)" "req-006: Critical Audit has a Human touchpoint audit"
assert_contains "\`autonomous\`" "$TOUCH" "req-006: touchpoint audit applies to autonomous only"
assert_contains "outside the exception list" "$TOUCH" "req-006: touchpoint audit counts touchpoints outside the list"
assert_contains "progress line" "$INTEG" "req-006: build log integrity names the progress line"
assert_contains "\`Run mode\` row" "$INTEG" "req-006: build log integrity names the Run mode row"
assert_contains "continuous_run" "$GATE" "req-006: phase gate audit keeps its continuous_run check"

print_summary
