#!/usr/bin/env bash
# Tests for feature 0000032-governance-continuity-and-write-gate-scope.
#
# req-008: a Bash PreToolUse hook, shell-write-guard.mjs, finds common shell
#          writers aimed at gated paths and blocks them with a stderr reason.
#          It fails open on commands it can't parse.
#
# Every fixture lives under mktemp -d and runs git init, so the root walk stops
# at the fixture and never reaches the host repository.
#
# REGRESSION-CANDIDATE: covers the Bash shell-write guard detection corpus,
# tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
GUARD="$FRAMEWORK/hooks/enforcement/shell-write-guard.mjs"

WORK="$(mktemp -d -t planifest_0000032_req008_XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

# native <path>: a path Node reads the same way Bash does (Git Bash on Windows).
native() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

# make_git_fixture <name>: an empty git repository under $WORK.
make_git_fixture() {
  local dir="$WORK/$1"
  mkdir -p "$dir/plan/current"
  git init "$dir" >/dev/null 2>&1
  printf '%s' "$dir"
}

# bash_payload <cwd> <command>: the Claude Code Bash PreToolUse JSON.
bash_payload() {
  node -e 'process.stdout.write(JSON.stringify({cwd:process.argv[1],tool_name:"Bash",tool_input:{command:process.argv[2]}}))' \
    "$(native "$1")" "$2"
}

# run_guard_raw <stdin>: runs the guard on raw stdin and sets CODE, OUT, and ERR.
run_guard_raw() {
  local errfile="$WORK/stderr.txt"
  OUT=$(node "$GUARD" 2>"$errfile" <<< "$1")
  CODE=$?
  ERR=$(cat "$errfile" 2>/dev/null)
}

# run_guard <cwd> <command>: runs the guard on a Bash command.
run_guard() {
  run_guard_raw "$(bash_payload "$1" "$2")"
}

ROOT="$(make_git_fixture plain)"

# The detection corpus. Req-009 reuses the same list for its design.md runs.
CORPUS=(
  "echo x > src/a.js"
  "echo x >> src/a.js"
  "printf x 2> src/err.log"
  "make &> src/build.log"
  "printf x | tee src/a.js"
  "printf x | tee -a /tmp/ok.txt src/a.js"
  "sed -i 's/a/b/' src/a.js"
  "sed -i.bak 's/a/b/' src/a.js"
  "sed -i '' 's/a/b/' src/a.js"
  "perl -pi -e 's/a/b/' src/a.js"
  "perl -i.bak -pe 's/a/b/' src/a.js"
  "cp /tmp/a.js src/a.js"
  "cp -r /tmp/dir src/"
  "cp -t src/ /tmp/a.js"
  "mv /tmp/a.js src/a.js"
  "install -m 644 /tmp/a.js src/a.js"
  "ln -s /tmp/a.js src/a.js"
  "rm src/a.js"
  "rm -rf src"
  "touch src/new.js"
  "mkdir -p src/new"
  "cd src && echo x > a.js"
  "ls; echo x > src/a.js"
  "cat > src/a.js <<'EOF'
body line
EOF"
  "echo x > $(native "$ROOT")/src/a.js"
  "FOO=1 touch src/a.js"
)

# =============================================================================
echo ""
echo "=== req-008: the hook exists ==="

assert_equals "yes" "$([ -f "$GUARD" ] && echo yes || echo no)" "req-008: shell-write-guard.mjs exists"

# =============================================================================
echo ""
echo "=== req-008: every corpus command blocks with no design.md ==="

i=0
for cmd in "${CORPUS[@]}"; do
  i=$((i + 1))
  label="${cmd%%$'\n'*}"
  run_guard "$ROOT" "$cmd"
  assert_equals "2" "$CODE" "req-008: corpus $i exits 2: $label"
  assert_equals "" "$OUT" "req-008: corpus $i prints no stdout: $label"
  assert_equals "yes" "$([ -n "$ERR" ] && echo yes || echo no)" "req-008: corpus $i writes a stderr reason: $label"
done

# =============================================================================
echo ""
echo "=== req-008: the block reason names the path and the tools ==="

run_guard "$ROOT" "echo x > src/a.js"
assert_contains "src/a.js" "$ERR" "req-008: the reason names the root-relative target"
assert_contains "No confirmed design" "$ERR" "req-008: the reason carries the evaluateWrite reason"
assert_contains "Write or Edit" "$ERR" "req-008: the reason points to Write or Edit"

run_guard "$ROOT" "sed -i 's/a/b/' src/a.js"
assert_contains "sed" "$ERR" "req-008: the reason names the writer"

run_guard "$ROOT" "cd src && echo x > a.js"
assert_contains "src/a.js" "$ERR" "req-008: a cd base change resolves the target against the new base"

# =============================================================================
echo ""
echo "=== req-008: parse failures and targets with no literal prefix warn ==="

run_guard "$ROOT" 'echo x > "src/a.js'
assert_equals "0" "$CODE" "req-008: an unbalanced quote exits 0"
assert_equals "yes" "$([ -n "$ERR" ] && echo yes || echo no)" "req-008: an unbalanced quote writes a warning"
assert_equals "" "$OUT" "req-008: an unbalanced quote prints no stdout"

run_guard "$ROOT" 'echo x > $TARGET'
assert_equals "0" "$CODE" "req-008: echo x > \$TARGET exits 0"
assert_equals "yes" "$([ -n "$ERR" ] && echo yes || echo no)" "req-008: echo x > \$TARGET writes a warning"

run_guard "$ROOT" 'echo x > "$DIR/a"'
assert_equals "0" "$CODE" "req-008: echo x > \"\$DIR/a\" exits 0"
assert_equals "yes" "$([ -n "$ERR" ] && echo yes || echo no)" "req-008: echo x > \"\$DIR/a\" writes a warning"

run_guard "$ROOT" 'rm src/*.js'
assert_equals "2" "$CODE" "req-008: rm src/*.js is judged by its literal prefix src/"
run_guard "$ROOT" 'cp a src/$NAME'
assert_equals "2" "$CODE" "req-008: cp a src/\$NAME is judged by its literal prefix src/"

# =============================================================================
echo ""
echo "=== req-008: commands with no writer pass in silence ==="

run_guard "$ROOT" 'echo "$(date)" `whoami`; ls src'
assert_equals "0" "$CODE" "req-008: a command with expansions and no writer exits 0"
assert_equals "" "$ERR" "req-008: a command with no writer writes no stderr"

run_guard "$ROOT" "echo x >&2; ls 2>&1; ls 2>/dev/null"
assert_equals "0" "$CODE" "req-008: descriptor duplicates and /dev/null pass"
assert_equals "" "$ERR" "req-008: descriptor duplicates and /dev/null write no stderr"

run_guard "$ROOT" "echo 'x > src/a.js'"
assert_equals "0" "$CODE" "req-008: a redirect inside quotes is not a writer"

run_guard "$ROOT" "echo x > $(native "$WORK")/outside.txt"
assert_equals "0" "$CODE" "req-008: a target outside the root passes"

# =============================================================================
echo ""
echo "=== req-008: git commands are a documented limit ==="

run_guard "$ROOT" "git checkout -- src/a.js"
assert_equals "0" "$CODE" "req-008: git checkout -- src/a.js exits 0"
assert_equals "" "$OUT" "req-008: git checkout prints no stdout"
assert_equals "" "$ERR" "req-008: git checkout writes no stderr"

GUARD_SRC="$(cat "$GUARD" 2>/dev/null || true)"
for limit in "git" "node -e" "python -c" "build tool" "package manager" "script"; do
  assert_contains "$limit" "$GUARD_SRC" "req-008: the header comment lists the limit: $limit"
done
assert_equals "no" "$([[ "$GUARD_SRC" == *"node:child_process"* ]] && echo yes || echo no)" \
  "req-008: the hook spawns no process"
assert_contains 'from "./path-rules.mjs"' "$GUARD_SRC" "req-008: the hook imports path-rules.mjs"

# =============================================================================
echo ""
echo "=== req-008: the hook fails open on bad input ==="

run_guard_raw "not json"
assert_equals "0" "$CODE" "req-008: malformed stdin exits 0"
assert_equals "" "$OUT" "req-008: malformed stdin prints no stdout"

run_guard_raw "{\"cwd\":\"$(native "$ROOT")\",\"tool_input\":{}}"
assert_equals "0" "$CODE" "req-008: a missing command exits 0"

run_guard_raw "{\"cwd\":\"$(native "$ROOT")\",\"tool_input\":{\"command\":42}}"
assert_equals "0" "$CODE" "req-008: a non-string command exits 0"

print_summary
