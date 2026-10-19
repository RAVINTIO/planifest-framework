#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-015: a parallel_streams toggle, on by default in autonomous, moves
#          independent requirements through P1 to P4 as separate streams.
#          Each stream keeps a state file under plan/current/streams/ that
#          the orchestrator's Resume Detection step 6b reads.
#
# REGRESSION-CANDIDATE: covers the parallel_streams toggle, the stream state template, and resume step 6b, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
TOGGLES="$FRAMEWORK/templates/loop-toggles.template.yml"
RUNNER="$FRAMEWORK/skills/planifest-loop-runner/SKILL.md"
DISPATCH="$FRAMEWORK/standards/agent-dispatch-standards.md"
STATE="$FRAMEWORK/templates/stream-state.template.md"
ORCH="$FRAMEWORK/skills/planifest-orchestrator/SKILL.md"

# section <file> <heading-prefix>: body of a "## " section up to the next "## ".
section() {
  awk -v h="$2" 'index($0, h) == 1 {f=1; print; next} f && /^## /{exit} f' "$1" 2>/dev/null
}

# line_of <file> <fixed-string>: first line number holding the string, or 0.
line_of() {
  local n
  n=$(grep -nF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1)
  echo "${n:-0}"
}

# yes_if <label> <command...>: passes when the command exits zero.
yes_if() {
  local label="$1"; shift
  assert_equals "yes" "$("$@" >/dev/null 2>&1 && echo yes || echo no)" "$label"
}

echo "=== req-015: loop toggles template ==="

NONCOMMENT=$(grep -n "parallel_streams" "$TOGGLES" | grep -v "^[0-9]*:#" | wc -l | tr -d ' ')
assert_equals "0" "$NONCOMMENT" "req-015: parallel_streams appears only on lines that start with #"
yes_if "req-015: the template names parallel_streams" grep -q "^# parallel_streams:" "$TOGGLES"
ON_LINES=$(grep -cE '^[a-z_]*: on$' "$TOGGLES")
assert_equals "0" "$ON_LINES" "req-015: no uncommented template line reads ': on'"

echo "=== req-015: loop-runner Toggle Protocol ==="

TP=$(section "$RUNNER" "## Toggle Protocol")
assert_contains '- `parallel_streams`' "$TP" "req-015: the autonomous key list names parallel_streams"
BULLET=$(line_of "$RUNNER" '**`parallel_streams` resolution')
EXPLICIT=$(awk -v s="$BULLET" 'NR > s && /explicit `on` or `off` wins/ {print NR; exit}' "$RUNNER")
ABSENT=$(awk -v s="$BULLET" 'NR > s && /absent file or absent key/ {print NR; exit}' "$RUNNER")
yes_if "req-015: Toggle Protocol has a parallel_streams resolution bullet" test "$BULLET" -gt 0
yes_if "req-015: the explicit-value rule comes before the absent-key rule" \
  test "${EXPLICIT:-0}" -gt "$BULLET" -a "${ABSENT:-0}" -gt "${EXPLICIT:-0}"
assert_contains "dispatch setting, not a loop" "$TP" "req-015: the bullet says parallel_streams is a dispatch setting"
assert_contains "report-only" "$TP" "req-015: Toggle Protocol covers report-only"

echo "=== req-015: dispatch standards ==="

RULES=$(line_of "$DISPATCH" "## Parallelism Rules")
STREAMS=$(line_of "$DISPATCH" "## Parallel Streams")
yes_if "req-015: ## Parallel Streams sits after ## Parallelism Rules" \
  test "$STREAMS" -gt "$RULES" -a "$RULES" -gt 0
PS=$(section "$DISPATCH" "## Parallel Streams")
assert_contains "plan/current/streams/" "$PS" "req-015: Parallel Streams names plan/current/streams/"
assert_contains "P1, P2, P3, and P4" "$PS" "req-015: Parallel Streams names the P1 to P4 stream scope"
assert_contains "block of requirement IDs, ADR IDs, and backlog IDs" "$PS" "req-015: Parallel Streams names the ID blocks"
assert_contains "Stream subagents don't commit" "$PS" "req-015: Parallel Streams says stream subagents don't commit"
assert_contains "Stream: {stream-id}" "$PS" "req-015: Parallel Streams names the Stream trailer"
assert_contains "autonomous default" "$PS" "req-015: Parallel Streams names the toggle sources"

echo "=== req-015: stream state template ==="

yes_if "req-015: templates/stream-state.template.md exists" test -f "$STATE"
TEXT=$(cat "$STATE" 2>/dev/null)
for needle in "stream-id:" "kind: stream" "start-commit:" "status:" "phase:" "requirements:" "stories:" "id-blocks:" "updated:" \
  "## Phase history" "## Files changed" "## Declares" "## Consumes" "## Next step"; do
  assert_contains "$needle" "$TEXT" "req-015: the stream state template names $needle"
done
FM=$(sed -n '2,/^---$/p' "$ORCH" | grep '^bundle_templates:')
assert_contains "stream-state.template.md" "$FM" "req-015: orchestrator bundle_templates lists stream-state.template.md"

echo "=== req-015: orchestrator Resume Detection and dispatch link ==="

RD=$(section "$ORCH" "## Resume Detection")
S6A=$(line_of "$ORCH" "6a. Check \`plan/current/discovery.md\`")
S6B=$(line_of "$ORCH" "6b. **Stream resume")
S7=$(line_of "$ORCH" "7. If artifacts are found")
assert_contains "6b. **Stream resume" "$RD" "req-015: Resume Detection has a step 6b"
STEP6B=$(awk -v s="$S6B" -v e="$S7" 'NR >= s && NR < e' "$ORCH")
assert_contains "plan/current/streams/" "$STEP6B" "req-015: step 6b names plan/current/streams/"
assert_contains "status: active" "$STEP6B" "req-015: step 6b names status: active"
assert_contains "at-join" "$STEP6B" "req-015: step 6b names at-join"
assert_contains "blocked" "$STEP6B" "req-015: step 6b handles a blocked stream"
yes_if "req-015: step 6b sits after step 6a and before step 7" \
  test "$S6B" -gt "$S6A" -a "$S7" -gt "$S6B" -a "$S6A" -gt 0

ADS=$(section "$ORCH" "## Agent Dispatch Standards")
assert_contains "## Parallel Streams" "$ADS" "req-015: orchestrator Agent Dispatch Standards links to ## Parallel Streams"

PIT=$(section "$ORCH" "## Phase Invocation Table")
assert_contains "once over the joined streams" "$PIT" "req-015: each P1 to P4 gate runs once over the joined streams"

print_summary
