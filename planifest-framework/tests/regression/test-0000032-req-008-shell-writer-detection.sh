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

# The hooks prefer CLAUDE_PROJECT_DIR as the root. A Claude Code session sets
# it, so clear it here and set it only in the cases that test it.
unset CLAUDE_PROJECT_DIR

# load_detection_corpus <root>: fills CORPUS with the detection corpus. The
# root is the native fixture path for the absolute-path entry. Req-009 sources
# this file with REQ008_CORPUS_ONLY=1 to reuse the same list.
load_detection_corpus() {
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
    "echo x > $1/src/a.js"
    "FOO=1 touch src/a.js"
  )
}

if [ "${REQ008_CORPUS_ONLY:-}" = "1" ]; then
  return 0 2>/dev/null || exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/../.." && pwd)"
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

load_detection_corpus "$(native "$ROOT")"

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
echo "=== req-008: a cd that may not run can't move the base (F2) ==="

for cmd in \
  "false && cd /tmp; echo hi > src/x.js" \
  "(cd /tmp); echo hi > src/x.js" \
  "cd /tmp | true; echo hi > src/x.js" \
  "cd /tmp || true; echo hi > src/x.js" \
  "cd /tmp & echo hi > src/x.js" \
  'cd "$DIR" && echo hi > src/x.js' \
  "(cd src && echo x > a.js)"; do
  run_guard "$ROOT" "$cmd"
  assert_equals "2" "$CODE" "req-008: F2 blocks: $cmd"
done

# A command joined to a literal cd by && runs only after the cd succeeds, so
# its relative target is judged against the folder after cd alone (N-1).
run_guard "$ROOT" "cd /tmp && echo hi > x.txt"
assert_equals "0" "$CODE" "req-008: N-1 cd /tmp && echo hi > x.txt writes /tmp/x.txt and passes"
assert_equals "" "$ERR" "req-008: N-1 cd /tmp && echo hi > x.txt writes no stderr"
run_guard "$ROOT" "cd /tmp && echo hi > src/x.js"
assert_equals "0" "$CODE" "req-008: N-1 cd /tmp && echo hi > src/x.js writes /tmp/src/x.js and passes"
run_guard "$ROOT" "(cd src; echo x > a.js); echo x > plan/a.md"
assert_equals "2" "$CODE" "req-008: F2 a cd inside parentheses still applies inside them"
run_guard "$ROOT" "(cd plan); echo x > docs/a.md"
assert_equals "0" "$CODE" "req-008: F2 the base returns to the outer value at )"

# =============================================================================
echo ""
echo "=== req-008: a cd joined by && moves the base alone (N-1) ==="

# A design that covers src/app/ and build/ only.
SCOPED="$(make_git_fixture scoped)"
printf '## Component Paths\n- src/app/\n- build/\n\n## Scope\n- In: test\n' > "$SCOPED/plan/current/design.md"
mkdir -p "$SCOPED/src/app" "$SCOPED/build"

for cmd in \
  "cd /tmp && touch x" \
  "cd build && make > log.txt" \
  "cd src/app && npm test > test.log" \
  'cd src/app && sed -i "" s/a/b/ index.js' \
  "cd src && cd app && touch index.js" \
  "ls && cd build && touch out.o" \
  "cd src/app && { touch a.js; }" \
  "cd src/app && (touch a.js)" \
  "true || false && cd build && touch out.o" \
  "cd src/other; cd /tmp && touch x"; do
  run_guard "$SCOPED" "$cmd"
  assert_equals "0" "$CODE" "req-008: N-1 passes with a design: $cmd"
  assert_equals "" "$ERR" "req-008: N-1 writes no stderr: $cmd"
done

# The starting folder is still judged when the hook can't prove the cd ran.
NL=$'\n'
for cmd in \
  "cd src/app && true; echo hi > index.js" \
  "cd src/app && true${NL}echo hi > index.js" \
  "cd src/app && true || echo hi > index.js" \
  "cd src/app || echo hi > index.js" \
  "true || cd src/app && echo hi > index.js" \
  "! cd src/app && echo hi > index.js" \
  "(cd src/app) && echo hi > index.js" \
  "(cd src/app && true) && echo hi > index.js" \
  "{ cd src/app; } && echo hi > index.js" \
  "if cd src/app; then echo hi > index.js; fi" \
  "cd src/app | true && echo hi > index.js" \
  "cd src/app & echo hi > index.js" \
  "cd src/app; cd lib && echo hi > index.js" \
  "cd src/app && cd ../other && echo hi > index.js" \
  'cd "$D" && echo hi > src/other/x.js' \
  "pushd src/other && echo hi > index.js" \
  "cd src/other || true; echo hi > build/x" \
  "pushd src/other && pushd /tmp && popd && echo hi > build/x"; do
  run_guard "$SCOPED" "$cmd"
  assert_equals "2" "$CODE" "req-008: N-1 blocks with a design: $cmd"
done

# Seven cd steps that may fail give more than 64 possible folders. A relative
# target then blocks, and a command with no relative target still passes.
MANY_CD="cd a; cd b; cd c; cd d; cd e; cd f; cd g"
run_guard "$SCOPED" "$MANY_CD; touch build/x"
assert_equals "2" "$CODE" "req-008: N-1 a relative target after too many folders blocks"
assert_contains "too many to judge" "$ERR" "req-008: N-1 the reason says there are too many folders"
run_guard "$SCOPED" "$MANY_CD; ls"
assert_equals "0" "$CODE" "req-008: N-1 too many folders with no writer passes"
run_guard "$SCOPED" "$MANY_CD; touch /tmp/x"
assert_equals "0" "$CODE" "req-008: N-1 an absolute target after too many folders is still judged"

# =============================================================================
echo ""
echo "=== req-008: functions, loops, and a redefined cd turn off the && rule (G-1) ==="

# The hook tracks folders in text order. A function body runs where it's
# called, and a loop runs again after a later cd, so these commands are judged
# against every folder they reach plus the starting folder.
R="$(native "$ROOT")"
for cmd in \
  "cd /tmp && f() { echo hi > src/x.js; }; cd $R; f" \
  "cd /tmp && f () { echo hi > src/x.js; }; cd $R; f" \
  "cd /tmp && function f { echo hi > src/x.js; }; cd $R; f" \
  "cd /tmp && while echo hi > src/x.js && test \$PWD = /tmp; do cd $R; done" \
  "cd /tmp && until echo hi > src/x.js; do cd $R; done" \
  "cd /tmp && for ((i=0; i<2; i++)); do echo hi > src/x.js; cd $R; done" \
  "cd /tmp && for d in a b; do echo hi > src/x.js; cd $R; done" \
  "cd() { :; }; cd /tmp && echo hi > src/x.js" \
  "function cd { :; }; cd /tmp && echo hi > src/x.js" \
  "pushd() { :; }; pushd /tmp && echo hi > src/x.js" \
  "alias cd=true; cd /tmp && echo hi > src/x.js" \
  "for f in a b; do touch build/\$f.o; done"; do
  run_guard "$ROOT" "$cmd"
  assert_equals "2" "$CODE" "req-008: G-1 blocks with no design: $cmd"
done

# =============================================================================
echo ""
echo "=== req-008: a cd to home or to the previous folder isn't certain (G-2) ==="

for cmd in \
  "pushd $R && pushd /tmp && pushd && echo hi > src/x.js" \
  "export HOME=$R/src; cd && echo hi > x.js" \
  "cd /tmp && cd - && echo hi > src/x.js" \
  "cd /tmp && cd ~ && echo hi > src/x.js" \
  "cd /tmp && cd ~/x && echo hi > src/x.js"; do
  run_guard "$ROOT" "$cmd"
  assert_equals "2" "$CODE" "req-008: G-2 blocks with no design: $cmd"
done
run_guard "$SCOPED" "cd ~ && touch .foo"
assert_equals "2" "$CODE" "req-008: G-2 cd ~ && touch .foo also judges the starting folder"

# Builds and test runs in a covered folder still pass with the design.
for cmd in \
  "cd build && make > log.txt" \
  "cd build && cmake .. && make > log.txt" \
  "cd src/app && npm ci && npm test > out.log" \
  "mkdir -p build && cd build && touch x" \
  "pushd build && make; popd" \
  "cd src && cd app && touch index.js" \
  "for f in a b; do touch build/\$f.o; done"; do
  run_guard "$SCOPED" "$cmd"
  assert_equals "0" "$CODE" "req-008: G-1 and G-2 still pass with a design: $cmd"
  assert_equals "" "$ERR" "req-008: G-1 and G-2 write no stderr: $cmd"
done

# =============================================================================
echo ""
echo "=== req-008: short-option clusters are read one letter at a time (F4) ==="

for cmd in \
  "cp -vt src/ /tmp/a" \
  "cp -vtsrc/ /tmp/a" \
  "mv -fvt src/ /tmp/a /tmp/b" \
  "install -Dm 644 /tmp/a src/x" \
  "ln -sft src/ /tmp/a" \
  "perl -lpi -e 's/a/b/' src/x" \
  "perl -l0pi -e 's/a/b/' src/x" \
  "perl -0777 -pi -e 's/a/b/' src/x" \
  "perl -nli.bak -e 'print' src/x" \
  "sed -Ei 's/a/b/' src/x" \
  "sed -nEi 's/a/b/' src/x" \
  "sed -Ei '' 's/a/b/' src/x" \
  "touch -cd 2020-01-01 src/x"; do
  run_guard "$ROOT" "$cmd"
  assert_equals "2" "$CODE" "req-008: F4 blocks: $cmd"
done
run_guard "$ROOT" "cp -vt /tmp/ src/a.js"
assert_equals "0" "$CODE" "req-008: F4 cp -vt /tmp/ src/a.js copies out of the repository and passes"
run_guard "$ROOT" "perl -lne 'print' src/x"
assert_equals "0" "$CODE" "req-008: F4 perl -lne without -i passes"

# =============================================================================
echo ""
echo "=== req-008: arithmetic << is not a here-document (F5) ==="

for cmd in \
  "((x = 1 << 2))${NL}echo hi > src/x.js" \
  "echo \$((1 <<${NL}2))${NL}echo hi > src/x.js" \
  "echo \$[1<<2]${NL}echo hi > src/x.js" \
  "for ((i=0; i<<2; i++)); do :; done${NL}echo hi > src/x.js" \
  "cat <<EOF${NL}echo hi > src/x.js" \
  "cat <<EOF${NL}body${NL}EOF${NL}cat <<END${NL}touch src/x.js"; do
  run_guard "$ROOT" "$cmd"
  assert_equals "2" "$CODE" "req-008: F5 blocks: ${cmd//$NL/\\n}"
done
# (( that an adjacent )) doesn't close is two subshells, not arithmetic (N-2).
for cmd in \
  "((echo hi > src/other/x); true)" \
  "((echo hi > src/other/x) )" \
  "((true) && echo hi > src/other/x)" \
  "( (echo hi > src/other/x) )" \
  "(((echo hi > src/other/x) ) )" \
  "((echo \"a)\" > src/other/x) )"; do
  run_guard "$ROOT" "$cmd"
  assert_equals "2" "$CODE" "req-008: N-2 blocks: $cmd"
done
run_guard "$ROOT" "((x = (1 + 2) * 3)) && echo ok"
assert_equals "0" "$CODE" "req-008: N-2 inner parentheses in (( )) stay arithmetic"
assert_equals "" "$ERR" "req-008: N-2 inner parentheses in (( )) write no stderr"
run_guard "$ROOT" "((x > 3)) && echo ok"
assert_equals "0" "$CODE" "req-008: F5 > inside (( )) is not a redirect"
assert_equals "" "$ERR" "req-008: F5 > inside (( )) writes no stderr"
run_guard "$ROOT" "echo \$[2 > 1] \$((3 > 2))"
assert_equals "0" "$CODE" "req-008: F5 > inside \$[ ] and \$(( )) is not a redirect"

# =============================================================================
echo ""
echo "=== req-008: deep nesting warns and passes (F8) ==="

# nested <depth>: echo "$(echo "$(...x...)")" nested depth times.
nested() {
  node -e 'const n=+process.argv[1];process.stdout.write("echo "+"\"$(echo ".repeat(n)+"x"+")\"".repeat(n))' "$1"
}
DEEP_PAYLOAD="$WORK/deep-nesting.json"
node -e 'const n=20000;process.stdout.write(JSON.stringify({cwd:process.argv[1],tool_input:{command:"echo "+"\"$(".repeat(n)+"x"+")\"".repeat(n)}}))' \
  "$(native "$ROOT")" > "$DEEP_PAYLOAD"
OUT=$(node "$GUARD" 2>"$WORK/stderr.txt" < "$DEEP_PAYLOAD")
CODE=$?
ERR=$(cat "$WORK/stderr.txt")
assert_equals "0" "$CODE" "req-008: F8 20,000 nested \"\$( exits 0"
assert_equals "" "$OUT" "req-008: F8 20,000 nested \"\$( prints no stdout"
assert_contains "Warning" "$ERR" "req-008: F8 20,000 nested \"\$( writes a warning"
assert_equals "1" "$(printf '%s\n' "$ERR" | grep -c .)" "req-008: F8 the warning is one line"

run_guard "$ROOT" "$(nested 65)"
assert_equals "0" "$CODE" "req-008: F8 65 nested levels exit 0"
assert_contains "Warning" "$ERR" "req-008: F8 65 nested levels write a warning"
run_guard "$ROOT" "$(nested 20); echo x > src/a.js"
assert_equals "2" "$CODE" "req-008: F8 20 nested levels still parse and judge the writer"

# =============================================================================
echo ""
echo "=== req-008: stderr stays small on repeated targets (F11) ==="

# guard_payload_file <file> <js expression for the command>: writes a payload.
guard_payload_file() {
  node -e 'const command=eval(process.argv[2]);process.stdout.write(JSON.stringify({cwd:process.argv[1],tool_input:{command}}))' \
    "$(native "$ROOT")" "$2" > "$1"
}
# run_guard_file <file>: runs the guard on a payload file and sets CODE, OUT, ERR.
run_guard_file() {
  OUT=$(node "$GUARD" 2>"$WORK/stderr.txt" < "$1")
  CODE=$?
  ERR=$(cat "$WORK/stderr.txt")
}
BIG="$WORK/big.json"

guard_payload_file "$BIG" '"echo x > src/a.js; ".repeat(10000)'
run_guard_file "$BIG"
assert_equals "2" "$CODE" "req-008: F11 a target repeated 10,000 times still blocks"
assert_equals "yes" "$([ "$(wc -c < "$WORK/stderr.txt")" -lt 10240 ] && echo yes || echo no)" \
  "req-008: F11 a target repeated 10,000 times writes under 10 KB of stderr"
assert_equals "1" "$(grep -c "Shell write blocked" "$WORK/stderr.txt")" "req-008: F11 a repeated reason appears once"

guard_payload_file "$BIG" 'Array.from({length:10000},(_,n)=>"echo x > src/f"+n+".js").join("; ")'
run_guard_file "$BIG"
assert_equals "2" "$CODE" "req-008: F11 10,000 different targets block"
assert_equals "yes" "$([ "$(wc -c < "$WORK/stderr.txt")" -lt 10240 ] && echo yes || echo no)" \
  "req-008: F11 10,000 different targets write under 10 KB of stderr"
assert_equals "20" "$(grep -c "Shell write blocked" "$WORK/stderr.txt")" "req-008: F11 stderr holds at most 20 reasons"
assert_contains "9980 more" "$ERR" "req-008: F11 a summary line counts the remaining reasons"

guard_payload_file "$BIG" '"echo x > $T; ".repeat(10000)'
run_guard_file "$BIG"
assert_equals "0" "$CODE" "req-008: F11 10,000 targets with no literal prefix pass"
assert_equals "yes" "$([ "$(wc -c < "$WORK/stderr.txt")" -lt 10240 ] && echo yes || echo no)" \
  "req-008: F11 repeated warnings write under 10 KB of stderr"

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
