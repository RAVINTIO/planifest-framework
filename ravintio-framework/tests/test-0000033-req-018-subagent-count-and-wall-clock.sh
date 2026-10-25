#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-018: the build log records subagent count and wall-clock time per
#          phase, and the P8 report uses them to measure parallel dispatch.
#
# REGRESSION-CANDIDATE: covers per-phase End, Wall-clock, and Streams fields and the P8 Phase Timing table, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

TPL="$SCRIPT_DIR/../templates/build-log.template.md"
ORCH="$SCRIPT_DIR/../skills/ravintio-orchestrator/SKILL.md"
SHIP="$SCRIPT_DIR/../skills/ravintio-ship-agent/SKILL.md"
BA="$SCRIPT_DIR/../skills/ravintio-build-assessment-agent/SKILL.md"

TPL_ALL=$(cat "$TPL")
CONV=$(sed -n '/^## Phase Conventions/,/^## Phase Invocation/p' "$ORCH")
AUDIT=$(sed -n '/^## Critical Audit/,/^## Rules/p' "$BA")
PAR=$(sed -n '/\*\*Parallelism audit\*\*/,/^$/p' <<< "$AUDIT")
INTEG=$(sed -n '/\*\*Build log integrity\*\*/,/^$/p' <<< "$AUDIT")

# line_of <pattern> <file> [after-line]: first line number matching pattern at or after after-line.
line_of() {
  awk -v p="$1" -v a="${3:-0}" 'NR>=a && index($0,p){print NR; exit}' "$2"
}

echo "=== req-018: build log template fields ==="

for F in "| Parallel streams |" "| End |" "| Wall-clock |" "| Streams |" "| Total wall-clock |" "| Phases using streams |"; do
  assert_contains "$F" "$TPL_ALL" "req-018: template names $F"
done
assert_contains "| Agents spawned |" "$TPL_ALL" "req-018: template still names Agents spawned"
assert_contains "| Parallel task batches |" "$TPL_ALL" "req-018: template still names Parallel task batches"

BLOCK=$(line_of "Copy and fill in this block" "$TPL")
B_START=$(line_of "| Start |" "$TPL" "$BLOCK")
B_END=$(line_of "| End |" "$TPL" "$BLOCK")
B_WALL=$(line_of "| Wall-clock |" "$TPL" "$BLOCK")
B_STREAMS=$(line_of "| Streams |" "$TPL" "$BLOCK")
assert_equals "yes" "$([ -n "$B_END" ] && [ "$B_END" -gt "${B_START:-0}" ] && echo yes || echo no)" \
  "req-018: copyable block End comes after Start"
assert_equals "yes" "$([ -n "$B_WALL" ] && [ "$B_WALL" -gt "${B_END:-0}" ] && echo yes || echo no)" \
  "req-018: copyable block Wall-clock comes after End"
assert_equals "yes" "$([ -n "$B_STREAMS" ] && [ "$B_STREAMS" -gt "${B_START:-0}" ] && echo yes || echo no)" \
  "req-018: copyable block has Streams after Start"

P0=$(line_of "### P0:" "$TPL")
P0_START=$(line_of "| Start |" "$TPL" "$P0")
P0_END=$(line_of "| End |" "$TPL" "$P0")
assert_equals "yes" "$([ -n "$P0_END" ] && [ "$P0_END" -gt "${P0_START:-0}" ] && [ "$P0_END" -lt "$BLOCK" ] && echo yes || echo no)" \
  "req-018: P0 block has End after Start"

echo ""
echo "=== req-018: orchestrator ==="

assert_contains "date -u" "$CONV" "req-018: Phase Conventions name date -u"
assert_contains "Wall-clock" "$CONV" "req-018: Phase Conventions name Wall-clock"
HL8=$(grep -E '^8\. \*\*Write a build log entry' "$ORCH")
assert_contains "Wall-clock" "$HL8" "req-018: Hard Limit 8 gate entry fills Wall-clock"
assert_contains "Streams" "$HL8" "req-018: Hard Limit 8 gate entry fills Streams"

echo ""
echo "=== req-018: ship skill P7, P8, and P9 ==="

for P in P7 P8 P9; do
  LINE=$(grep -E "^\*\*Build log( first)?:\*\* Append a $P phase block" "$SHIP")
  assert_contains "Wall-clock" "$LINE" "req-018: ship $P build-log line names Wall-clock"
done

echo ""
echo "=== req-018: build assessment ==="

RS=$(line_of "## Report Structure" "$BA")
SD=$(line_of "## Subagent Dispatch" "$BA" "$RS")
PT=$(line_of "## Phase Timing" "$BA" "$RS")
MCP=$(line_of "## MCP Tool Usage" "$BA" "$RS")
assert_equals "yes" "$([ -n "$PT" ] && [ "$PT" -gt "${SD:-0}" ] && [ "$PT" -lt "${MCP:-0}" ] && echo yes || echo no)" \
  "req-018: Phase Timing heading sits after Subagent Dispatch in the report structure"
assert_contains "Parallel streams" "$PAR" "req-018: parallelism audit names Parallel streams"
assert_contains "10 or more independent requirements" "$PAR" "req-018: parallelism audit names the 10-requirement threshold"
assert_contains "Wall-clock" "$PAR" "req-018: parallelism audit names Wall-clock"
assert_contains "Wall-clock" "$INTEG" "req-018: build log integrity names Wall-clock"
assert_contains "Streams" "$INTEG" "req-018: build log integrity names Streams"

echo ""
# Split the retired word so the 0000030 residue check does not match this file.
RETIRED="tele""metry"
echo "=== req-018: no retired integration wording ==="

for F in "$TPL" "$ORCH" "$SHIP" "$BA"; do
  assert_equals "0" "$(grep -ci "$RETIRED" "$F")" "req-018: $(basename "$(dirname "$F")")/$(basename "$F") has no retired integration wording"
done

print_summary
