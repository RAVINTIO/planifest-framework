#!/usr/bin/env bash
# Tests for feature 0000032-governance-continuity-and-write-gate-scope.
#
# req-003: with ravintio-framework/ present and no sentinel, the auto-trigger
#          hook says no RAVINTIO run is active, names ravintio-orchestrator,
#          and asks for triage into Fast Path, Change Pipeline, or Feature
#          Pipeline. It no longer claims the skill "has not been loaded". The
#          orchestrator Routing Directive covers every request after P9.
#
# REGRESSION-CANDIDATE: covers the auto-trigger no-run message and post-P9 triage rule, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

HOOK="$SCRIPT_DIR/../hooks/enforcement/auto-trigger-orchestrator.mjs"
ORCH="$SCRIPT_DIR/../skills/ravintio-orchestrator/SKILL.md"

# Git Bash gives /tmp/x, which node reads as C:\tmp\x. pwd -W gives the Windows form.
WORK="$(cd "$(mktemp -d -t ravintio_0000032_req003_XXXXXX)" && { pwd -W 2>/dev/null || pwd; })"
trap 'rm -rf "$WORK"' EXIT

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

# now_ms: wall-clock milliseconds, portable across macOS and Linux.
now_ms() { perl -MTime::HiRes=time -e 'printf "%d\n", time * 1000'; }

# run_hook <stdin>: sets OUT, CODE, and MS for one hook call. One untimed
# warm-up call comes first and warms disk caches. The hook still starts as a
# fresh Node process each time. The timed call runs once and never retries.
run_hook() {
  local start end
  printf '%s' "$1" | node "$HOOK" >/dev/null 2>&1
  start=$(now_ms)
  OUT=$(printf '%s' "$1" | node "$HOOK" 2>/dev/null)
  CODE=$?
  end=$(now_ms)
  MS=$(( end - start ))
}

# under_200 <label>: passes when the last hook call took under 200 ms.
under_200() {
  assert_equals "yes" "$([ "$MS" -lt 200 ] && echo yes || echo no)" "$1 (took ${MS} ms)"
}

NO_RUN="$WORK/no-run"
ACTIVE="$WORK/active"
PLAIN="$WORK/plain"
mkdir -p "$NO_RUN/ravintio-framework" "$ACTIVE/ravintio-framework" "$ACTIVE/plan" "$PLAIN"
printf '0000032\n' > "$ACTIVE/plan/.orchestrator-active"

echo "=== req-003: no run active ==="

run_hook "{\"cwd\":\"$NO_RUN\"}"
assert_equals "0" "$CODE" "req-003: hook exits 0 with no sentinel"
assert_contains "no RAVINTIO run is active" "$OUT" "req-003: message says no RAVINTIO run is active"
assert_contains "ravintio-orchestrator" "$OUT" "req-003: message names ravintio-orchestrator"
assert_contains "Fast Path" "$OUT" "req-003: message names Fast Path"
assert_contains "Change Pipeline" "$OUT" "req-003: message names Change Pipeline"
assert_contains "Feature Pipeline" "$OUT" "req-003: message names Feature Pipeline"
assert_contains "triage" "$OUT" "req-003: message asks for triage before acting"
assert_contains "resume detection" "$OUT" "req-003: message still starts with resume detection"
lacks "has not been loaded" "$OUT" "req-003: message drops the has-not-been-loaded claim"
under_200 "req-003: no-run call completes under 200 ms"

echo ""
echo "=== req-003: silent cases ==="

run_hook "{\"cwd\":\"$ACTIVE\"}"
assert_equals "0" "$CODE" "req-003: hook exits 0 with the sentinel present"
assert_equals "" "$OUT" "req-003: stdout is empty with the sentinel present"
under_200 "req-003: sentinel call completes under 200 ms"

run_hook "{\"cwd\":\"$PLAIN\"}"
assert_equals "0" "$CODE" "req-003: hook exits 0 without ravintio-framework/"
assert_equals "" "$OUT" "req-003: stdout is empty without ravintio-framework/"
under_200 "req-003: non-RAVINTIO call completes under 200 ms"

run_hook "{not json"
assert_equals "0" "$CODE" "req-003: hook exits 0 on malformed JSON"
under_200 "req-003: malformed JSON call completes under 200 ms"

echo ""
echo "=== req-003: hook header and Routing Directive ==="

HEADER=$(sed -n '1,/\*\//p' "$HOOK")
assert_contains "no run is active" "$HEADER" "req-003: header describes check 2 as no run is active"
lacks "orchestrator not yet loaded" "$HEADER" "req-003: header drops orchestrator not yet loaded"
lacks "process.exit(2)" "$(cat "$HOOK")" "req-003: hook never exits 2"

ROUTING=$(sed -n '/^## Routing Directive/,/^### /p' "$ORCH")
assert_contains "Every request must be triaged before any action is taken." "$ROUTING" \
  "req-003: Routing Directive keeps the triage rule"
assert_contains "after P9" "$ROUTING" "req-003: Routing Directive covers requests after P9"
assert_contains "whether or not a run is active" "$ROUTING" \
  "req-003: Routing Directive applies whether or not a run is active"

print_summary
