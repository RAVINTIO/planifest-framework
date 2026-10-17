#!/usr/bin/env bash
# Tests for feature 0000032-governance-continuity-and-write-gate-scope.
#
# req-006: a shared path-rules module finds the repository root, and
#          gate-write.mjs uses it to pass every target outside that root.
#
# Every fixture lives under mktemp -d. Git fixtures run git init so the root
# walk stops at the fixture and never reaches the host repository.
#
# REGRESSION-CANDIDATE: covers the gate-write repository root and the
# outside-root pass, tagged by test-writer for human review at P7

set -uo pipefail

# The hooks prefer CLAUDE_PROJECT_DIR as the root. A Claude Code session sets
# it, so clear it here and set it only in the cases that test it.
unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
ENF="$FRAMEWORK/hooks/enforcement"
GATE_WRITE="$ENF/gate-write.mjs"
PATH_RULES="$ENF/path-rules.mjs"

WORK="$(mktemp -d -t planifest_0000032_req006_XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

# native <path>: a path Node reads the same way Bash does. Git Bash on Windows
# hands out /tmp/... paths that Node would resolve to \tmp\..., so convert them.
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

# write_design <root> <component path>: a design.md whose paths cover only that path.
write_design() {
  printf '## Component Paths\n- %s\n\n## Scope\n- In: test\n' "$2" > "$1/plan/current/design.md"
}

# run_gate <cwd> <target>: runs gate-write and sets CODE, OUT, and ERR.
run_gate() {
  local payload errfile
  payload="{\"cwd\":\"$(native "$1")\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$2\"}}"
  run_gate_raw "$payload"
}

# run_gate_raw <stdin>: runs gate-write on the raw stdin and sets CODE, OUT, and ERR.
run_gate_raw() {
  local errfile="$WORK/stderr.txt"
  OUT=$(node "$GATE_WRITE" 2>"$errfile" <<< "$1")
  CODE=$?
  ERR=$(cat "$errfile")
}

# =============================================================================
echo ""
echo "=== req-006: a target outside the root passes ==="

ROOT="$(make_git_fixture plain)"
OUTSIDE="$WORK/outside"
mkdir -p "$OUTSIDE"

run_gate "$ROOT" "$(native "$OUTSIDE/a.js")"
assert_equals "0" "$CODE" "req-006: outside write with no design.md exits 0"
assert_equals "" "$OUT" "req-006: outside write with no design.md prints no stdout"
assert_equals "" "$ERR" "req-006: outside write with no design.md prints no stderr"

# Control: the same fixture still gates an in-repository path.
run_gate "$ROOT" "src/a.js"
assert_equals "2" "$CODE" "req-006: in-root src/a.js with no design.md exits 2"
assert_contains "No confirmed design at plan/current/design.md" "$OUT" \
  "req-006: the no-design reason keeps its wording"

DESIGNED="$(make_git_fixture designed)"
write_design "$DESIGNED" "lib/"
run_gate "$DESIGNED" "$(native "$OUTSIDE/a.js")"
assert_equals "0" "$CODE" "req-006: outside write with an uncovering design.md exits 0"
assert_equals "" "$OUT" "req-006: outside write with an uncovering design.md prints no stdout"

run_gate "$ROOT" "$(native "$OUTSIDE/plan/current/x.md")"
assert_equals "0" "$CODE" "req-006: outside plan/current/ path skips the sentinel check"

# =============================================================================
echo ""
echo "=== req-006: the root falls back to cwd outside a repository ==="

NOGIT="$WORK/nogit"
mkdir -p "$NOGIT"
run_gate "$NOGIT" "$(native "$OUTSIDE/a.js")"
assert_equals "0" "$CODE" "req-006: non-git fixture passes a write outside cwd"
run_gate "$NOGIT" "$(native "$NOGIT/src/a.js")"
assert_equals "2" "$CODE" "req-006: non-git fixture gates cwd/src/a.js with no design.md"

# A folder holding planifest-framework/ and no .git is a root too.
PFONLY="$WORK/pfonly"
mkdir -p "$PFONLY/planifest-framework" "$PFONLY/plan/current" "$PFONLY/sub/deeper"
run_gate "$PFONLY/sub/deeper" "$(native "$PFONLY/src/a.js")"
assert_equals "2" "$CODE" "req-006: planifest-framework/ marks the root with no .git, so subfolder cwd gates {root}/src/a.js"
run_gate "$PFONLY/sub/deeper" "$(native "$PFONLY/sub/x.md")"
assert_equals "2" "$CODE" "req-006: planifest-framework/ root gates {root}/sub/x.md from a subfolder cwd"
run_gate "$PFONLY/sub/deeper" "$(native "$OUTSIDE/a.js")"
assert_equals "0" "$CODE" "req-006: planifest-framework/ root passes a write outside it"

# =============================================================================
echo ""
echo "=== req-006: the root is the walked-up repository root ==="

mkdir -p "$ROOT/sub/deeper"
run_gate "$ROOT/sub/deeper" "$(native "$ROOT/src/a.js")"
assert_equals "2" "$CODE" "req-006: subfolder cwd gates {root}/src/a.js with no design.md"

run_gate "$ROOT/sub" "../src/a.js"
assert_equals "2" "$CODE" "req-006: subfolder cwd gates ../src/a.js with no design.md"

mkdir -p "$DESIGNED/sub"
run_gate "$DESIGNED/sub" "$(native "$DESIGNED/lib/a.js")"
assert_equals "0" "$CODE" "req-006: subfolder cwd finds design.md at the root"
run_gate "$DESIGNED/sub" "$(native "$DESIGNED/src/a.js")"
assert_equals "2" "$CODE" "req-006: subfolder cwd applies the component-path check"
assert_contains "Path 'src/a.js' is not covered" "$OUT" \
  "req-006: the out-of-design reason names the root-relative path"

SENT="$(make_git_fixture sentinel)"
mkdir -p "$SENT/sub"
run_gate "$SENT/sub" "$(native "$SENT/plan/current/x.md")"
assert_equals "2" "$CODE" "req-006: plan/current/ write with no root sentinel exits 2"
assert_contains "plan/.orchestrator-active" "$OUT" "req-006: the sentinel reason keeps its wording"
: > "$SENT/plan/.orchestrator-active"
run_gate "$SENT/sub" "$(native "$SENT/plan/current/x.md")"
assert_equals "0" "$CODE" "req-006: the sentinel lookup uses the root, not cwd"

# =============================================================================
echo ""
echo "=== req-006: .. segments and sibling prefixes ==="

run_gate "$ROOT" "../outside/a.js"
assert_equals "0" "$CODE" "req-006: ../outside/a.js leaves the root and exits 0"
run_gate "$ROOT" "src/../../outside/a.js"
assert_equals "0" "$CODE" "req-006: src/../../outside/a.js leaves the root and exits 0"
run_gate "$ROOT" "docs/../src/a.js"
assert_equals "2" "$CODE" "req-006: docs/../src/a.js is gated like src/a.js"

mkdir -p "$ROOT-other"
run_gate "$ROOT" "$(native "$ROOT-other/a.js")"
assert_equals "0" "$CODE" "req-006: {root}-other/a.js is outside the root and exits 0"

# =============================================================================
echo ""
echo "=== req-006: real paths decide the comparison ==="

LINK="$WORK/link-to-plain"
ln -s "$ROOT" "$LINK" 2>/dev/null
if [ -L "$LINK" ]; then
  run_gate "$LINK" "$(native "$LINK/src/a.js")"
  assert_equals "2" "$CODE" "req-006: symlinked cwd gates {link}/src/a.js with no design.md"
  run_gate "$LINK" "$(native "$ROOT/src/a.js")"
  assert_equals "2" "$CODE" "req-006: symlinked cwd gates the real {root}/src/a.js"
else
  echo "  SKIP: req-006: symbolic links are not available on this host"
fi

# =============================================================================
echo ""
echo "=== req-006: a planted marker can't move the root (F1) ==="

# plan/ is always permitted, so an agent can plant a marker there. The root
# must stay at the outer repository.
PLANTED="$(make_git_fixture planted)"
mkdir -p "$PLANTED/plan/x/.git" "$PLANTED/plan/x/planifest-framework"
run_gate "$PLANTED/plan/x" "$(native "$PLANTED/src/x.js")"
assert_equals "2" "$CODE" "req-006: planted plan/x/.git and planifest-framework/ don't move the root"
run_gate "$PLANTED/plan/x" "../../src/x.js"
assert_equals "2" "$CODE" "req-006: planted markers don't move the root for a relative target"

PLANTED_GIT="$(make_git_fixture planted-git)"
mkdir -p "$PLANTED_GIT/plan/x/.git"
run_gate "$PLANTED_GIT/plan/x" "$(native "$PLANTED_GIT/src/x.js")"
assert_equals "2" "$CODE" "req-006: a planted plan/x/.git alone doesn't move the root"

PLANTED_DOCS="$(make_git_fixture planted-docs)"
mkdir -p "$PLANTED_DOCS/docs/y/z/.git"
run_gate "$PLANTED_DOCS/docs/y/z" "$(native "$PLANTED_DOCS/src/x.js")"
assert_equals "2" "$CODE" "req-006: a planted docs/y/z/.git doesn't move the root"

# The outermost planifest-framework/ wins over a nearer .git.
OUTER_PF="$WORK/outer-pf"
mkdir -p "$OUTER_PF/planifest-framework" "$OUTER_PF/plan/current" "$OUTER_PF/vendor/lib/.git"
run_gate "$OUTER_PF/vendor/lib" "$(native "$OUTER_PF/src/x.js")"
assert_equals "2" "$CODE" "req-006: the outermost planifest-framework/ beats a nearer .git"

# A nested .git outside plan/ and docs/ is still the nearest root when no
# planifest-framework/ exists above it.
NESTED="$(make_git_fixture nested)"
mkdir -p "$NESTED/vendor/lib/.git"
run_gate "$NESTED/vendor/lib" "$(native "$NESTED/src/x.js")"
assert_equals "0" "$CODE" "req-006: a nested repository outside plan/ is its own root"

echo ""
echo "=== req-006: CLAUDE_PROJECT_DIR names the root when set (F1) ==="

CLAUDE_PROJECT_DIR="$NESTED" run_gate "$NESTED/vendor/lib" "$(native "$NESTED/src/x.js")"
assert_equals "2" "$CODE" "req-006: CLAUDE_PROJECT_DIR is the root, ahead of the nearer .git"
CLAUDE_PROJECT_DIR="$WORK/no-such-dir" run_gate "$NESTED/vendor/lib" "$(native "$NESTED/src/x.js")"
assert_equals "0" "$CODE" "req-006: a CLAUDE_PROJECT_DIR that doesn't exist falls back to the walk"
CLAUDE_PROJECT_DIR="$NESTED" run_gate "$NESTED" "$(native "$OUTSIDE/a.js")"
assert_equals "0" "$CODE" "req-006: a target outside CLAUDE_PROJECT_DIR passes"
if [ -L "$LINK" ]; then
  CLAUDE_PROJECT_DIR="$LINK" run_gate "$ROOT" "$(native "$ROOT/src/a.js")"
  assert_equals "2" "$CODE" "req-006: CLAUDE_PROJECT_DIR resolves to its real path"
fi

# =============================================================================
echo ""
echo "=== req-006: a path too long to judge warns and passes quickly (F7) ==="

# time_gate <payload file>: runs gate-write and sets CODE, OUT, ERR, and MS.
time_gate() {
  local errfile="$WORK/stderr.txt" t0 t1
  t0=$(node -e 'process.stdout.write(String(Date.now()))')
  OUT=$(node "$GATE_WRITE" 2>"$errfile" < "$1")
  CODE=$?
  t1=$(node -e 'process.stdout.write(String(Date.now()))')
  ERR=$(cat "$errfile")
  MS=$((t1 - t0))
}

DEEP="$WORK/deep.json"
node -e 'process.stdout.write(JSON.stringify({cwd:process.argv[1],tool_name:"Write",tool_input:{file_path:"src/"+"a/".repeat(20000)+"x.js"}}))' \
  "$(native "$ROOT")" > "$DEEP"
time_gate "$DEEP"
echo "  deep path call: ${MS} ms"
assert_equals "0" "$CODE" "req-006: F7 a 20,000-segment path passes"
assert_equals "" "$OUT" "req-006: F7 a 20,000-segment path prints no stdout"
assert_contains "Warning" "$ERR" "req-006: F7 a 20,000-segment path writes a warning"
assert_equals "yes" "$([ "$MS" -lt 2000 ] && echo yes || echo no)" "req-006: F7 a 20,000-segment path returns within 2 seconds"

node -e 'process.stdout.write(JSON.stringify({cwd:process.argv[1],tool_name:"Write",tool_input:{file_path:"src/"+"b".repeat(5000)+".js"}}))' \
  "$(native "$ROOT")" > "$DEEP"
time_gate "$DEEP"
assert_equals "0" "$CODE" "req-006: F7 a path over 4096 characters passes"
assert_contains "Warning" "$ERR" "req-006: F7 a path over 4096 characters writes a warning"

node -e 'process.stdout.write(JSON.stringify({cwd:process.argv[1],tool_name:"Write",tool_input:{file_path:"src/"+"a/".repeat(200)+"x.js"}}))' \
  "$(native "$ROOT")" > "$DEEP"
time_gate "$DEEP"
assert_equals "2" "$CODE" "req-006: F7 a 200-segment path is still judged"

# =============================================================================
echo ""
echo "=== req-006: gate-write fails open on bad input ==="

run_gate_raw "not json"
assert_equals "0" "$CODE" "req-006: malformed stdin exits 0"
assert_equals "" "$OUT" "req-006: malformed stdin prints no stdout"

run_gate_raw "{\"cwd\":\"$(native "$ROOT")\",\"tool_input\":{}}"
assert_equals "0" "$CODE" "req-006: JSON with no target path exits 0"
assert_equals "" "$OUT" "req-006: JSON with no target path prints no stdout"

run_gate_raw "{\"cwd\":\"$(native "$ROOT")\",\"tool_input\":{\"file_path\":42}}"
assert_equals "0" "$CODE" "req-006: a non-string file_path exits 0"
assert_equals "" "$OUT" "req-006: a non-string file_path prints no stdout"

run_gate "$WORK/does-not-exist" "src/a.js"
assert_equals "0" "$CODE" "req-006: a cwd that doesn't exist exits 0"
assert_equals "" "$OUT" "req-006: a cwd that doesn't exist prints no stdout"

run_gate_raw "{\"cwd\":\"$(native "$ROOT")\",\"path\":\"src/a.js\"}"
assert_equals "2" "$CODE" "req-006: raw Claude Code input with a top-level path is still gated"

# =============================================================================
echo ""
echo "=== req-006: gate-write takes its rules from path-rules.mjs ==="

assert_equals "yes" "$([ -f "$PATH_RULES" ] && echo yes || echo no)" "req-006: path-rules.mjs exists"
GATE_SRC="$(cat "$GATE_WRITE")"
RULES_SRC="$(cat "$PATH_RULES" 2>/dev/null || true)"
assert_contains 'from "./path-rules.mjs"' "$GATE_SRC" "req-006: gate-write.mjs imports path-rules.mjs"
assert_equals "no" "$([[ "$GATE_SRC" == *"ALWAYS_PERMITTED"* ]] && echo yes || echo no)" \
  "req-006: gate-write.mjs keeps no always-permitted list"
assert_equals "no" "$([[ "$GATE_SRC" == *'"pause.md"'* ]] && echo yes || echo no)" \
  "req-006: gate-write.mjs defines no always-permitted basename"
assert_contains '"pause.md"' "$RULES_SRC" "req-006: path-rules.mjs holds the always-permitted basenames"
assert_equals "no" "$([[ "$RULES_SRC" == *"node:child_process"* ]] && echo yes || echo no)" \
  "req-006: path-rules.mjs spawns no process"

# =============================================================================
echo ""
echo "=== req-006: setup installs path-rules.mjs beside gate-write.mjs ==="

PS1_SRC="$(cat "$FRAMEWORK/setup.ps1")"
assert_contains "-Filter '*.mjs'" "$PS1_SRC" "req-006: setup.ps1 copies every enforcement *.mjs"

WS="$WORK/setup-ws"
mkdir -p "$WS"
cp -r "$FRAMEWORK" "$WS/planifest-framework"
git init "$WS" >/dev/null 2>&1
(cd "$WS" && bash planifest-framework/setup.sh claude-code > "$WORK/setup.log" 2>&1)
assert_exit_zero "$?" "req-006: setup.sh claude-code exits 0"
assert_equals "yes" "$([ -f "$WS/.claude/hooks/enforcement/gate-write.mjs" ] && echo yes || echo no)" \
  "req-006: setup installs gate-write.mjs"
assert_equals "yes" "$([ -f "$WS/.claude/hooks/enforcement/path-rules.mjs" ] && echo yes || echo no)" \
  "req-006: setup installs path-rules.mjs next to gate-write.mjs"

print_summary
