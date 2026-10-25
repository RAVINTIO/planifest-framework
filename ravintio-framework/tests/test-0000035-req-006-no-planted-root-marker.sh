#!/usr/bin/env bash
# Tests for feature 0000035-write-gate-scope-and-path-hardening.
#
# req-006: markedRoot ignores a .git or ravintio-framework/ marker when any
#          segment of its path below a higher marked folder matches an
#          always-permitted basename (ADR-008). A marker planted under plan/
#          and moved to src/claude.md can't move the root.
#
# Every fixture lives under mktemp -d. Each fixture runs git init so the root
# walk stops at the fixture and never reaches the host repository.

set -uo pipefail

# The hooks prefer CLAUDE_PROJECT_DIR as the root. A Claude Code session sets
# it, so clear it here.
unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
ENF="$FRAMEWORK/hooks/enforcement"
GATE_WRITE="$ENF/gate-write.mjs"
SHELL_GUARD="$ENF/shell-write-guard.mjs"
PATH_RULES="$ENF/path-rules.mjs"

WORK="$(mktemp -d -t ravintio_0000035_req006_XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

# native <path>: a path Node reads the same way Bash does.
native() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

# make_fixture <name>: a git repository with no ravintio-framework/ and no design.
make_fixture() {
  local dir="$WORK/$1"
  mkdir -p "$dir/plan/current" "$dir/src"
  git init "$dir" >/dev/null 2>&1
  printf '%s' "$dir"
}

# run_gate <cwd> <target>: runs gate-write and sets CODE and ERR.
run_gate() {
  local errfile="$WORK/stderr.txt"
  node "$GATE_WRITE" >/dev/null 2>"$errfile" <<< "{\"cwd\":\"$(native "$1")\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$2\"}}"
  CODE=$?
  ERR=$(cat "$errfile")
}

# run_guard <cwd> <command>: runs the shell-write guard and sets CODE and ERR.
run_guard() {
  local errfile="$WORK/stderr.txt"
  node "$SHELL_GUARD" >/dev/null 2>"$errfile" <<< "{\"cwd\":\"$(native "$1")\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$2\"}}"
  CODE=$?
  ERR=$(cat "$errfile")
}

# plant <fixture> <marker> <name>: plants plan/w/<marker> and moves plan/w to src/<name>.
plant() {
  (cd "$1" && mkdir -p "plan/w/$2" && mv plan/w "src/$3")
}

# =============================================================================
echo ""
echo "=== req-006: a .git planted under an always-permitted basename ==="

for name in claude.md pause.md CLAUDE.md; do
  FX="$(make_fixture "git-$name")"
  plant "$FX" .git "$name"
  run_gate "$FX/src/$name" "../other/x.js"
  assert_equals "2" "$CODE" "req-006: gate-write blocks ../other/x.js from planted src/$name/.git"
  assert_contains "No confirmed design" "$ERR" "req-006: gate-write gives the no-design reason for planted src/$name/.git"
  run_guard "$FX/src/$name" "touch ../other/x.js"
  assert_equals "2" "$CODE" "req-006: shell guard blocks touch ../other/x.js from planted src/$name/.git"
done

# A marker deeper below the permitted name is distrusted too.
FX="$(make_fixture deeper)"
(cd "$FX" && mkdir -p plan/w/inner/.git && mv plan/w src/claude.md)
run_gate "$FX/src/claude.md/inner" "../../other/x.js"
assert_equals "2" "$CODE" "req-006: gate-write blocks from src/claude.md/inner/.git"
run_guard "$FX/src/claude.md/inner" "touch ../../other/x.js"
assert_equals "2" "$CODE" "req-006: shell guard blocks from src/claude.md/inner/.git"

# A .git file, as in a worktree, counts as a marker and is distrusted too.
FX="$(make_fixture gitfile)"
(cd "$FX" && mkdir -p plan/w && printf 'gitdir: /nowhere\n' > plan/w/.git && mv plan/w src/claude.md)
run_gate "$FX/src/claude.md" "../other/x.js"
assert_equals "2" "$CODE" "req-006: gate-write blocks from a planted .git file under src/claude.md"

# =============================================================================
echo ""
echo "=== req-006: a planted ravintio-framework/ marker ==="

FX="$(make_fixture pf)"
plant "$FX" ravintio-framework claude.md
run_gate "$FX/src/claude.md" "../other/x.js"
assert_equals "2" "$CODE" "req-006: gate-write blocks from planted src/claude.md/ravintio-framework/"
run_guard "$FX/src/claude.md" "touch ../other/x.js"
assert_equals "2" "$CODE" "req-006: shell guard blocks from planted src/claude.md/ravintio-framework/"

FX="$(make_fixture pf-pause)"
plant "$FX" ravintio-framework pause.md
run_gate "$FX/src/pause.md" "../other/x.js"
assert_equals "2" "$CODE" "req-006: gate-write blocks from planted src/pause.md/ravintio-framework/"

# =============================================================================
echo ""
echo "=== req-006: CLAUDE_PROJECT_DIR walk applies the same rule ==="

FX="$(make_fixture project-dir)"
plant "$FX" .git claude.md
CLAUDE_PROJECT_DIR="$FX/src/claude.md" run_gate "$FX/src/claude.md" "../other/x.js"
assert_equals "2" "$CODE" "req-006: a CLAUDE_PROJECT_DIR at planted src/claude.md doesn't move the root"

# =============================================================================
echo ""
echo "=== req-006: a genuine nested repository stays a root ==="

FX="$(make_fixture nested)"
mkdir -p "$FX/vendor/lib/.git"
run_gate "$FX/vendor/lib" "../../src/x.js"
assert_equals "0" "$CODE" "req-006: vendor/lib/.git is its own root, so ../../src/x.js is outside it"
run_gate "$FX/vendor/lib" "src/x.js"
assert_equals "2" "$CODE" "req-006: vendor/lib/.git gates its own src/x.js"
run_guard "$FX/vendor/lib" "touch ../../src/x.js"
assert_equals "0" "$CODE" "req-006: shell guard keeps vendor/lib as its own root"

# The existing plan/ and docs/ first-segment rule still holds.
FX="$(make_fixture plan-first)"
mkdir -p "$FX/plan/x/.git"
run_gate "$FX/plan/x" "../../src/x.js"
assert_equals "2" "$CODE" "req-006: a planted plan/x/.git still doesn't move the root"

# =============================================================================
echo ""
echo "=== req-006: hook call time with a 20-segment cwd ==="

FX="$(make_fixture deep)"
DEEPCWD="$FX/$(printf 'd/%.0s' $(seq 1 20))"
mkdir -p "$DEEPCWD"
T0=$(node -e 'process.stdout.write(String(Date.now()))')
run_gate "$DEEPCWD" "x.js"
T1=$(node -e 'process.stdout.write(String(Date.now()))')
MS=$((T1 - T0))
echo "  20-segment cwd call: ${MS} ms"
assert_equals "2" "$CODE" "req-006: a 20-segment cwd still gates its write"
assert_equals "yes" "$([ "$MS" -lt 500 ] && echo yes || echo no)" "req-006: a hook call with a 20-segment cwd takes under 500 ms"

# =============================================================================
echo ""
echo "=== req-006: path-rules.mjs stays on Node built-ins ==="

RULES_SRC="$(cat "$PATH_RULES")"
assert_equals "no" "$([[ "$RULES_SRC" == *"node:child_process"* ]] && echo yes || echo no)" \
  "req-006: path-rules.mjs imports no node:child_process"

print_summary
