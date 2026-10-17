#!/usr/bin/env bash
# Tests for feature 0000032-governance-continuity-and-write-gate-scope.
#
# req-007: every enforcement hook block path that exits 2 writes a plain-text
#          reason to stderr and keeps its stdout byte for byte (ADR-005).
#
# Hooks covered: gate-write.mjs, ratchet-check.mjs, em-dash-guard.mjs, and the
# Windsurf adapter relay of a gate-write block.
#
# Every fixture lives under mktemp -d. Git fixtures run git init so the root
# walk stops at the fixture and never reaches the host repository.
#
# REGRESSION-CANDIDATE: covers the stderr block reason and the unchanged
# stdout contract, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
ENF="$FRAMEWORK/hooks/enforcement"
GATE_WRITE="$ENF/gate-write.mjs"
RATCHET="$ENF/ratchet-check.mjs"
EM_DASH_GUARD="$ENF/em-dash-guard.mjs"
WINDSURF="$FRAMEWORK/hooks/adapters/windsurf.mjs"

WORK="$(mktemp -d -t planifest_0000032_req007_XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

OUTFILE="$WORK/stdout.txt"
ERRFILE="$WORK/stderr.txt"
EXPFILE="$WORK/expected.txt"

# native <path>: a path Node reads the same way Bash does. Git Bash on Windows
# hands out /tmp/... paths that Node would resolve to \tmp\..., so convert them.
native() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

# now_ms: wall-clock milliseconds, portable across macOS and Linux.
now_ms() { perl -MTime::HiRes=time -e 'printf "%d\n", time * 1000'; }

# run_node <dir> <script> <stdin>: runs a hook from dir. It keeps the raw
# stdout and stderr in files and sets CODE, OUT, ERR, and MS.
run_node() {
  local start end
  start=$(now_ms)
  (cd "$1" && node "$2" >"$OUTFILE" 2>"$ERRFILE" <<< "$3")
  CODE=$?
  end=$(now_ms)
  MS=$(( end - start ))
  OUT=$(cat "$OUTFILE")
  ERR=$(cat "$ERRFILE")
}

# under_200 <label>: passes when the last hook call took under 200 ms.
under_200() {
  assert_equals "yes" "$([ "$MS" -lt 200 ] && echo yes || echo no)" "$1 (took ${MS} ms)"
}

# stdout_is <expected> <label>: passes when the raw stdout matches byte for byte.
stdout_is() {
  printf '%s' "$1" > "$EXPFILE"
  assert_equals "same" "$(cmp -s "$EXPFILE" "$OUTFILE" && echo same || echo differs)" "$2"
}

# stderr_matches_stdout <label>: passes when the raw stderr equals the raw stdout.
stderr_matches_stdout() {
  assert_equals "same" "$(cmp -s "$OUTFILE" "$ERRFILE" && echo same || echo differs)" "$1"
}

# non_empty <value> <label>: passes when the value holds at least one character.
non_empty() {
  assert_equals "non-empty" "$([ -n "$1" ] && echo non-empty || echo empty)" "$2"
}

# not_json <value> <label>: passes when the value does not parse as JSON.
not_json() {
  local verdict
  verdict=$(node -e 'try { JSON.parse(process.argv[1]); console.log("json"); } catch { console.log("plain"); }' "$1")
  assert_equals "plain" "$verdict" "$2"
}

# json_field <json> <expression>: prints one field of the parsed JSON, or PARSE_ERROR.
json_field() {
  node -e 'try { const o = JSON.parse(process.argv[1]); console.log(eval(process.argv[2])); } catch { console.log("PARSE_ERROR"); }' "$1" "$2"
}

# make_git_fixture <name>: a git repository under $WORK with plan/current/.
make_git_fixture() {
  local dir="$WORK/$1"
  mkdir -p "$dir/plan/current"
  git init "$dir" >/dev/null 2>&1
  printf '%s' "$dir"
}

gate_payload() {
  printf '{"cwd":"%s","tool_name":"Write","tool_input":{"file_path":"%s"}}' "$(native "$1")" "$2"
}

SENTINEL_TEXT="[Planifest] No orchestrator sentinel at plan/.orchestrator-active. Load the planifest-orchestrator skill and complete Phase 0 before writing plan artefacts.
"
NO_DESIGN_TEXT="[Planifest] No confirmed design at plan/current/design.md. Complete Phase 0 first.
"
OUT_OF_DESIGN_TEXT="[Planifest] Path 'src/a.js' is not covered by the confirmed design. Add it to the '## Component Paths' section of plan/current/design.md first.
"

# =============================================================================
echo ""
echo "=== req-007: gate-write block paths write the reason to stderr ==="

GATE="$(make_git_fixture gate)"

run_node "$GATE" "$GATE_WRITE" "$(gate_payload "$GATE" "plan/current/x.md")"
assert_equals "2" "$CODE" "req-007: gate-write no-sentinel block exits 2"
non_empty "$ERR" "req-007: gate-write no-sentinel block writes stderr"
stdout_is "$SENTINEL_TEXT" "req-007: gate-write no-sentinel stdout is unchanged"
stderr_matches_stdout "req-007: gate-write no-sentinel stderr matches stdout"
under_200 "req-007: gate-write no-sentinel call completes under 200 ms"

run_node "$GATE" "$GATE_WRITE" "$(gate_payload "$GATE" "src/a.js")"
assert_equals "2" "$CODE" "req-007: gate-write no-design block exits 2"
non_empty "$ERR" "req-007: gate-write no-design block writes stderr"
stdout_is "$NO_DESIGN_TEXT" "req-007: gate-write no-design stdout is unchanged"
stderr_matches_stdout "req-007: gate-write no-design stderr matches stdout"
under_200 "req-007: gate-write no-design call completes under 200 ms"

printf '## Component Paths\n- lib/\n\n## Scope\n- In: test\n' > "$GATE/plan/current/design.md"
run_node "$GATE" "$GATE_WRITE" "$(gate_payload "$GATE" "src/a.js")"
assert_equals "2" "$CODE" "req-007: gate-write out-of-design block exits 2"
non_empty "$ERR" "req-007: gate-write out-of-design block writes stderr"
stdout_is "$OUT_OF_DESIGN_TEXT" "req-007: gate-write out-of-design stdout is unchanged"
stderr_matches_stdout "req-007: gate-write out-of-design stderr matches stdout"
under_200 "req-007: gate-write out-of-design call completes under 200 ms"

# Control: a covered path passes with no output on either stream.
run_node "$GATE" "$GATE_WRITE" "$(gate_payload "$GATE" "lib/a.js")"
assert_equals "0" "$CODE" "req-007: gate-write covered path exits 0"
assert_equals "" "$OUT" "req-007: gate-write covered path prints no stdout"
assert_equals "" "$ERR" "req-007: gate-write covered path prints no stderr"

# =============================================================================
echo ""
echo "=== req-007: the Windsurf adapter still relays the reason on stdout ==="

WS="$(make_git_fixture windsurf)"
WS_PAYLOAD=$(printf '{"agent_action_name":"pre_write_code","trajectory_id":"t1","tool_info":{"cwd":"%s","path":"src/a.js"}}' "$(native "$WS")")
run_node "$WS" "$WINDSURF" "$WS_PAYLOAD"
assert_equals "2" "$CODE" "req-007: Windsurf pre_write_code on a gated path exits 2"
assert_contains "No confirmed design at plan/current/design.md" "$OUT" \
  "req-007: Windsurf adapter stdout holds the block reason"

# =============================================================================
echo ""
echo "=== req-007: ratchet-check block paths write the reason to stderr ==="

RAT="$(make_git_fixture ratchet)"
RAT_N="$(native "$RAT")"
printf -- '---\nstatus: active\n---\n' > "$RAT/plan/current/loop-state-test.md"
printf '# Req\n\n## Acceptance Criteria\n\n- [ ] keep this\n- [ ] drop this\n' > "$RAT/plan/current/req.md"
WEAKEN=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s/plan/current/req.md","content":"# Req\\n\\n## Acceptance Criteria\\n\\n- [ ] keep this\\n"}}' "$RAT_N")

run_node "$RAT" "$RATCHET" "$WEAKEN"
assert_equals "2" "$CODE" "req-007: ratchet-check weakening block exits 2"
non_empty "$ERR" "req-007: ratchet-check weakening block writes stderr"
not_json "$ERR" "req-007: ratchet-check weakening stderr is plain text"
assert_equals "deny" "$(json_field "$OUT" 'o.hookSpecificOutput.permissionDecision')" \
  "req-007: ratchet-check weakening stdout still parses as deny JSON"
assert_equals "$(json_field "$OUT" 'o.hookSpecificOutput.permissionDecisionReason')" "$ERR" \
  "req-007: ratchet-check weakening stderr is the deny reason"
assert_contains "Ratchet: this write weakens plan/current/req.md" "$ERR" \
  "req-007: ratchet-check weakening stderr names the artefact"
under_200 "req-007: ratchet-check weakening call completes under 200 ms"

printf 'plan/current/req.md | human approved | 2026-10-17T00:00:00Z\n' > "$RAT/plan/current/.ratchet-approve"
run_node "$RAT" "$RATCHET" "$WEAKEN"
assert_equals "2" "$CODE" "req-007: ratchet-check uncommitted-marker block exits 2"
non_empty "$ERR" "req-007: ratchet-check uncommitted-marker block writes stderr"
not_json "$ERR" "req-007: ratchet-check uncommitted-marker stderr is plain text"
assert_equals "deny" "$(json_field "$OUT" 'o.hookSpecificOutput.permissionDecision')" \
  "req-007: ratchet-check uncommitted-marker stdout still parses as deny JSON"
assert_equals "$(json_field "$OUT" 'o.hookSpecificOutput.permissionDecisionReason')" "$ERR" \
  "req-007: ratchet-check uncommitted-marker stderr is the deny reason"
assert_contains "that marker file itself is uncommitted" "$ERR" \
  "req-007: ratchet-check uncommitted-marker stderr names the marker"
under_200 "req-007: ratchet-check uncommitted-marker call completes under 200 ms"

# =============================================================================
echo ""
echo "=== req-007: em-dash-guard block path writes the reason to stderr ==="

EMD="$WORK/emdash"
mkdir -p "$EMD/docs"
EM_PAYLOAD=$(printf '{"cwd":"%s","tool_name":"Write","tool_input":{"file_path":"docs/x.md","content":"one\\ntwo \xe2\x80\x94 three\\n"}}' "$(native "$EMD")")
EM_TEXT="[Planifest] Em dash (U+2014) found in 'docs/x.md' at line(s): 2. Replace with a comma, colon, semicolon, full stop, or parentheses depending on the sentence. If the character is genuinely required (a literal quotation, for example), add <!-- planifest-em-dash-allow --> anywhere in the content to bypass.
"

run_node "$EMD" "$EM_DASH_GUARD" "$EM_PAYLOAD"
assert_equals "2" "$CODE" "req-007: em-dash-guard block exits 2"
non_empty "$ERR" "req-007: em-dash-guard block writes stderr"
stdout_is "$EM_TEXT" "req-007: em-dash-guard stdout is unchanged"
stderr_matches_stdout "req-007: em-dash-guard stderr matches stdout"
under_200 "req-007: em-dash-guard call completes under 200 ms"

print_summary
