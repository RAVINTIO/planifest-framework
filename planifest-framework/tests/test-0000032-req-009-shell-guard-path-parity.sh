#!/usr/bin/env bash
# Tests for feature 0000032-governance-continuity-and-write-gate-scope.
#
# req-009: shell-write-guard.mjs and gate-write.mjs share path-rules.mjs, so
#          they gate exactly the same paths. The guard passes read-only
#          commands, fails open on bad input, and finishes each call in under
#          200 ms.
#
# Every fixture lives under mktemp -d and runs git init, so the root walk stops
# at the fixture and never reaches the host repository.
#
# REGRESSION-CANDIDATE: covers shell guard parity with gate-write and the
# false-positive corpus, tagged by test-writer for human review at P7

set -uo pipefail

# The hooks prefer CLAUDE_PROJECT_DIR as the root. A Claude Code session sets
# it, so clear it here and set it only in the cases that test it.
unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
ENF="$FRAMEWORK/hooks/enforcement"
GUARD="$ENF/shell-write-guard.mjs"
GATE_WRITE="$ENF/gate-write.mjs"

# The req-008 suite holds the detection corpus. Load it without running it.
REQ008_CORPUS_ONLY=1 source "$SCRIPT_DIR/test-0000032-req-008-shell-writer-detection.sh"

# Git Bash gives /tmp/x, which node reads as C:\tmp\x. pwd -W gives the Windows form.
WORK="$(cd "$(mktemp -d -t planifest_0000032_req009_XXXXXX)" && { pwd -W 2>/dev/null || pwd; })"
trap 'rm -rf "$WORK"' EXIT

native() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

make_git_fixture() {
  local dir="$WORK/$1"
  mkdir -p "$dir/plan/current"
  git init "$dir" >/dev/null 2>&1
  printf '%s' "$dir"
}

write_design() {
  printf '## Component Paths\n- %s\n\n## Scope\n- In: test\n' "$2" > "$1/plan/current/design.md"
}

bash_payload() {
  # The command goes in on stdin. Windows caps an argument list near 32 KB, and
  # the F7 command is longer.
  printf '%s' "$2" | node -e 'process.stdout.write(JSON.stringify({cwd:process.argv[1],tool_name:"Bash",tool_input:{command:require("fs").readFileSync(0,"utf-8")}}))' \
    "$(native "$1")"
}

run_guard_raw() {
  local errfile="$WORK/stderr.txt"
  OUT=$(node "$GUARD" 2>"$errfile" <<< "$1")
  CODE=$?
  ERR=$(cat "$errfile" 2>/dev/null)
}

run_guard() {
  run_guard_raw "$(bash_payload "$1" "$2")"
}

# gate_code <cwd> <target>: the gate-write exit code for a Write to target.
gate_code() {
  node "$GATE_WRITE" >/dev/null 2>&1 <<< "{\"cwd\":\"$(native "$1")\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$2\"}}"
  echo $?
}

# =============================================================================
echo ""
echo "=== req-009: the corpus blocks with a design that doesn't cover src/ ==="

OTHER="$(make_git_fixture other)"
write_design "$OTHER" "lib/"
load_detection_corpus "$(native "$OTHER")"
i=0
for cmd in "${CORPUS[@]}"; do
  i=$((i + 1))
  run_guard "$OTHER" "$cmd"
  assert_equals "2" "$CODE" "req-009: corpus $i exits 2 when src/ isn't covered: ${cmd%%$'\n'*}"
done
run_guard "$OTHER" "echo x > src/a.js"
assert_contains "not covered by the confirmed design" "$ERR" "req-009: the component-path reason reaches stderr"

# =============================================================================
echo ""
echo "=== req-009: a design that covers src/ lets the writers through ==="

COVERED="$(make_git_fixture covered)"
write_design "$COVERED" "src/"
load_detection_corpus "$(native "$COVERED")"
for n in 1 7 12 18; do
  cmd="${CORPUS[$((n - 1))]}"
  run_guard "$COVERED" "$cmd"
  assert_equals "0" "$CODE" "req-009: corpus $n exits 0 when src/ is covered: $cmd"
  assert_equals "" "$ERR" "req-009: corpus $n writes no stderr when src/ is covered"
done

# =============================================================================
echo ""
echo "=== req-009: the false-positive corpus passes with no design.md ==="

PLAIN="$(make_git_fixture plain)"
FALSE_POSITIVES=(
  "cat src/a.js"
  "grep -rn 'foo' src/" # portable-ok: payload string
  "grep '>' src/a.js"
  "ls -la src"
  "sed -n '1,5p' src/a.js"
  "sed 's/a/b/' src/a.js"
  "head -20 src/a.js | wc -l"
  "find src -name '*.js'"
  "diff src/a.js src/b.js"
  "git diff src/"
  "git log -- src/a.js"
  "node src/index.js > /dev/null 2>&1"
  "node src/index.js >&2"
  "echo \"a > src/b\""
  "perl -ne 'print' src/a.js"
  "test -f src/a.js && echo yes"
  "wc -l src/a.js > /tmp/out.txt"
  "cat src/a.js | tee /tmp/copy.txt"
  "echo x > plan/notes.md"
  "echo x > docs/a.md"
  "git commit -m \"\$(cat <<'EOF'
Body line that won't touch > src/a.js
EOF
)\""
)
i=0
for cmd in "${FALSE_POSITIVES[@]}"; do
  i=$((i + 1))
  run_guard "$PLAIN" "$cmd"
  assert_equals "0" "$CODE" "req-009: false positive $i exits 0: ${cmd%%$'\n'*}"
  assert_equals "" "$ERR" "req-009: false positive $i writes no stderr: ${cmd%%$'\n'*}"
done

run_guard "$PLAIN" "echo x > $(native "$WORK")/elsewhere.txt"
assert_equals "0" "$CODE" "req-009: a writer aimed outside the fixture exits 0"
run_guard "$PLAIN" "echo x > /tmp/elsewhere.txt"
assert_equals "0" "$CODE" "req-009: echo x > /tmp/elsewhere.txt exits 0"

# =============================================================================
echo ""
echo "=== req-009: exit codes match gate-write for the same path ==="

for path in "src/a.js" "README.md" "plan/current/x.md" "docs/a.md"; do
  run_guard "$PLAIN" "echo x > $path"
  assert_equals "$(gate_code "$PLAIN" "$path")" "$CODE" "req-009: guard and gate-write agree on $path with no sentinel"
done
: > "$PLAIN/plan/.orchestrator-active"
run_guard "$PLAIN" "echo x > plan/current/x.md"
assert_equals "$(gate_code "$PLAIN" "plan/current/x.md")" "$CODE" \
  "req-009: guard and gate-write agree on plan/current/x.md with the sentinel"
assert_equals "0" "$CODE" "req-009: plan/current/x.md passes once the sentinel exists"
for path in "src/a.js" "lib/a.js"; do
  run_guard "$OTHER" "touch $path"
  assert_equals "$(gate_code "$OTHER" "$path")" "$CODE" "req-009: guard and gate-write agree on $path with a design.md"
done

# =============================================================================
echo ""
echo "=== req-009: a planted marker can't move the guard's root (F1) ==="

PLANTED="$(make_git_fixture planted)"
mkdir -p "$PLANTED/plan/x/.git" "$PLANTED/plan/x/planifest-framework"
run_guard "$PLANTED/plan/x" "echo hi > $(native "$PLANTED")/src/x.js"
assert_equals "2" "$CODE" "req-009: planted markers in plan/x don't move the root for an absolute target"
run_guard "$PLANTED/plan/x" "echo hi > ../../src/x.js"
assert_equals "2" "$CODE" "req-009: planted markers in plan/x don't move the root for a relative target"
assert_equals "$(gate_code "$PLANTED/plan/x" "../../src/x.js")" "$CODE" \
  "req-009: guard and gate-write agree with planted markers"

NESTED="$(make_git_fixture nested)"
mkdir -p "$NESTED/vendor/lib/.git"
run_guard "$NESTED/vendor/lib" "echo hi > $(native "$NESTED")/src/x.js"
assert_equals "0" "$CODE" "req-009: a nested repository outside plan/ is its own root"
CLAUDE_PROJECT_DIR="$(native "$NESTED")" run_guard "$NESTED/vendor/lib" "echo hi > $(native "$NESTED")/src/x.js"
assert_equals "2" "$CODE" "req-009: the guard takes CLAUDE_PROJECT_DIR as the root"

# =============================================================================
echo ""
echo "=== req-009: the guard uses the nearest planifest-framework/ (N-5) ==="

ABOVE="$WORK/plant-above"
mkdir -p "$ABOVE/planifest-framework" "$ABOVE/plan/current" "$ABOVE/repo/planifest-framework" "$ABOVE/repo/plan/current"
: > "$ABOVE/plan/.orchestrator-active"
write_design "$ABOVE" "repo/"
run_guard "$ABOVE/repo" "echo hi > src/x.js"
assert_equals "2" "$CODE" "req-009: N-5 a planted marker and design above the repository don't move the guard's root"
assert_equals "$(gate_code "$ABOVE/repo" "src/x.js")" "$CODE" "req-009: N-5 guard and gate-write agree with a planted marker above"

LONE="$WORK/lone-above"
mkdir -p "$LONE/planifest-framework" "$LONE/repo/planifest-framework" "$LONE/repo/plan/current"
: > "$LONE/repo/plan/.orchestrator-active"
write_design "$LONE/repo" "src/"
run_guard "$LONE/repo" "echo hi > src/x.js"
assert_equals "0" "$CODE" "req-009: N-5 a lone planifest-framework/ above doesn't lock the guard out"
assert_equals "$(gate_code "$LONE/repo" "src/x.js")" "$CODE" "req-009: N-5 guard and gate-write agree with a lone marker above"

MONO="$WORK/mono"
mkdir -p "$MONO/planifest-framework" "$MONO/plan/current" "$MONO/packages/app/planifest-framework" "$MONO/packages/app/plan/current"
write_design "$MONO" "lib/"
write_design "$MONO/packages/app" "src/"
run_guard "$MONO/packages/app" "echo hi > src/x.js"
assert_equals "0" "$CODE" "req-009: N-5 a nested install judges its own paths with the guard"
assert_equals "$(gate_code "$MONO/packages/app" "src/x.js")" "$CODE" "req-009: N-5 guard and gate-write agree in a nested install"

# =============================================================================
echo ""
echo "=== req-009: CLAUDE_PROJECT_DIR only starts the guard's marker walk (N-4) ==="

N4="$WORK/n4/repo"
mkdir -p "$N4/planifest-framework" "$N4/plan/current" "$N4/src" "$N4/lib"
for target in "../lib/x.js" "../plan/current/x.md" "../.claude/settings.json"; do
  CLAUDE_PROJECT_DIR="$(native "$N4/src")" run_guard "$N4/src" "echo hi > $target"
  assert_equals "2" "$CODE" "req-009: N-4 CLAUDE_PROJECT_DIR set to src/ still gates $target"
  assert_equals "$(CLAUDE_PROJECT_DIR="$(native "$N4/src")" gate_code "$N4/src" "$target")" "$CODE" \
    "req-009: N-4 guard and gate-write agree on $target"
done

N4P="$WORK/n4p"
mkdir -p "$N4P/repo/planifest-framework" "$N4P/repo/plan/current"
: > "$N4P/repo/plan/.orchestrator-active"
write_design "$N4P/repo" "src/"
CLAUDE_PROJECT_DIR="$(native "$N4P")" run_guard "$N4P/repo" "echo hi > src/x.js"
assert_equals "0" "$CODE" "req-009: N-4 CLAUDE_PROJECT_DIR set to the parent doesn't lock the guard out"

UNRELATED="$WORK/unrelated"
mkdir -p "$UNRELATED"
CLAUDE_PROJECT_DIR="$(native "$UNRELATED")" run_guard "$N4" "echo hi > src/other/x.js"
assert_equals "2" "$CODE" "req-009: N-4 an unmarked unrelated CLAUDE_PROJECT_DIR doesn't ungate src/other/x.js"

CLAUDE_PROJECT_DIR="$(native "$N4")" run_guard "$OTHER" "echo hi > $(native "$N4")/src/x.js"
assert_equals "2" "$CODE" "req-009: N-4 a cd into another repository doesn't ungate the project"

# =============================================================================
echo ""
echo "=== req-009: both hooks take their rules from path-rules.mjs ==="

GUARD_SRC="$(cat "$GUARD")"
GATE_SRC="$(cat "$GATE_WRITE")"
assert_contains 'from "./path-rules.mjs"' "$GUARD_SRC" "req-009: shell-write-guard.mjs imports path-rules.mjs"
assert_contains 'from "./path-rules.mjs"' "$GATE_SRC" "req-009: gate-write.mjs imports path-rules.mjs"
for src_name in GUARD_SRC GATE_SRC; do
  src="${!src_name}"
  assert_equals "no" "$([[ "$src" == *"ALWAYS_PERMITTED"* ]] && echo yes || echo no)" \
    "req-009: $src_name keeps no always-permitted list"
  assert_equals "no" "$([[ "$src" == *'"pause.md"'* ]] && echo yes || echo no)" \
    "req-009: $src_name defines no always-permitted basename"
  assert_equals "no" "$([[ "$src" == *"Component Paths|Scope"* ]] && echo yes || echo no)" \
    "req-009: $src_name keeps no component-path parser"
done

# =============================================================================
echo ""
echo "=== req-009: the guard fails open with no output ==="

run_guard_raw "not json"
assert_equals "0" "$CODE" "req-009: malformed stdin exits 0"
assert_equals "" "$OUT$ERR" "req-009: malformed stdin prints nothing"
run_guard_raw "{\"cwd\":\"$(native "$PLAIN")\",\"tool_input\":{}}"
assert_equals "0" "$CODE" "req-009: JSON with no command exits 0"
assert_equals "" "$OUT$ERR" "req-009: JSON with no command prints nothing"
run_guard_raw "{\"cwd\":\"$(native "$PLAIN")\",\"tool_input\":{\"command\":[\"rm\",\"src\"]}}"
assert_equals "0" "$CODE" "req-009: a non-string command exits 0"
assert_equals "" "$OUT$ERR" "req-009: a non-string command prints nothing"

# =============================================================================
echo ""
echo "=== req-009: a path too long to judge warns and passes quickly (F7) ==="

DEEP_CMD="echo x > src/$(printf 'a/%.0s' $(seq 1 20000))x.js"
T0=$(node -e 'process.stdout.write(String(Date.now()))')
run_guard "$PLAIN" "$DEEP_CMD"
T1=$(node -e 'process.stdout.write(String(Date.now()))')
echo "  deep path call: $((T1 - T0)) ms"
assert_equals "0" "$CODE" "req-009: F7 a 20,000-segment target passes"
assert_contains "Warning" "$ERR" "req-009: F7 a 20,000-segment target writes a warning"
assert_equals "yes" "$([ $((T1 - T0)) -lt 2000 ] && echo yes || echo no)" "req-009: F7 a 20,000-segment target returns within 2 seconds"
run_guard "$PLAIN" "cd $(printf 'a/%.0s' $(seq 1 300)) && echo x > y.js"
assert_equals "2" "$CODE" "req-009: F7 a deep cd base still judges the target against the starting folder"

run_guard "$PLAIN" "echo x > src/other/$(printf './%.0s' $(seq 1 300))x.js"
assert_equals "2" "$CODE" "req-009: N-3 src/other/ plus 300 './' segments is judged as src/other/x.js"
assert_equals "no" "$([[ "$ERR" == *"too long"* ]] && echo yes || echo no)" "req-009: N-3 a short resolved path gets no too-long warning"
run_guard "$PLAIN" "echo x > src/other/$(printf 'a/../%.0s' $(seq 1 1000))x.js"
assert_equals "2" "$CODE" "req-009: N-3 a 5,000-character a/../ repetition is judged as src/other/x.js"

# =============================================================================
echo ""
echo "=== req-009: each call finishes in under 200 ms ==="

# Times one guard process per command, Node start-up included. Each command
# takes the best of three runs, so a busy host doesn't fail the check.
TIMING_PAYLOADS="$WORK/timing.json"
node -e '
  const [cwd, ...cmds] = process.argv.slice(1);
  process.stdout.write(JSON.stringify(cmds.map((command) => JSON.stringify({ cwd, tool_input: { command } }))));
' "$(native "$PLAIN")" "echo x > src/a.js" "cat src/a.js | tee /tmp/copy.txt" "sed -i 's/a/b/' src/a.js" > "$TIMING_PAYLOADS" # portable-ok: payload string
SLOWEST=$(node -e '
  const { spawnSync } = require("node:child_process");
  const { readFileSync } = require("node:fs");
  const payloads = JSON.parse(readFileSync(process.argv[2], "utf-8"));
  let slowest = 0;
  for (const input of payloads) {
    let best = Infinity;
    for (let run = 0; run < 3; run++) {
      const t0 = process.hrtime.bigint();
      spawnSync(process.execPath, [process.argv[1]], { input });
      best = Math.min(best, Number(process.hrtime.bigint() - t0) / 1e6);
    }
    if (best > slowest) slowest = best;
  }
  process.stdout.write(String(Math.round(slowest)));
' "$GUARD" "$TIMING_PAYLOADS")
echo "  slowest call: ${SLOWEST} ms"
assert_equals "yes" "$([ "${SLOWEST:-999}" -lt 200 ] && echo yes || echo no)" "req-009: each guard call completes in under 200 ms"

print_summary
