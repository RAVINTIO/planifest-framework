#!/usr/bin/env bash
# Tests for feature 0000035-write-gate-scope-and-path-hardening.
#
# req-004: resolveRoot finds the repository root from CLAUDE_PROJECT_DIR, then
#          from the nearest existing parent, when the working directory no
#          longer exists (ADR-006). A resolution error for a target inside the
#          CLAUDE_PROJECT_DIR root blocks with exit 2 and names the error code.
#
# Every fixture lives under mktemp -d. Each fixture runs git init so the root
# walk stops at the fixture and never reaches the host repository.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
ENF="$FRAMEWORK/hooks/enforcement"
GATE_WRITE="$ENF/gate-write.mjs"
SHELL_GUARD="$ENF/shell-write-guard.mjs"
PATH_RULES="$ENF/path-rules.mjs"

WORK="$(mktemp -d -t planifest_0000035_req004_XXXXXX)"
LOCKED=""
cleanup() {
  [ -n "$LOCKED" ] && chmod 755 "$LOCKED" 2>/dev/null
  rm -rf "$WORK"
}
trap cleanup EXIT

native() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

# make_fixture <name>: a git repository with no design.
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

# =============================================================================
echo ""
echo "=== req-004: a deleted cwd with CLAUDE_PROJECT_DIR set ==="

FX="$(make_fixture set)"
mkdir -p "$FX/gone" && rmdir "$FX/gone"
CLAUDE_PROJECT_DIR="$FX" run_gate "$FX/gone" "$(native "$FX/src/x.js")"
assert_equals "2" "$CODE" "req-004: gate-write blocks src/x.js from a deleted cwd with CLAUDE_PROJECT_DIR set"
assert_contains "No confirmed design" "$ERR" "req-004: gate-write gives the no-design reason"
CLAUDE_PROJECT_DIR="$FX" run_gate "$FX/gone" "src/x.js"
assert_equals "2" "$CODE" "req-004: gate-write blocks a relative src/x.js from a deleted cwd"
CLAUDE_PROJECT_DIR="$FX" run_guard "$FX/gone" "touch $(native "$FX/src/x.js")"
assert_equals "2" "$CODE" "req-004: shell guard blocks src/x.js from a deleted cwd with CLAUDE_PROJECT_DIR set"
CLAUDE_PROJECT_DIR="$FX" run_guard "$FX/gone" "touch src/x.js"
assert_equals "2" "$CODE" "req-004: shell guard blocks a relative src/x.js from a deleted cwd"

# The deleted folder may sit outside the project. CLAUDE_PROJECT_DIR still names the root.
mkdir -p "$WORK/elsewhere/gone" && rmdir "$WORK/elsewhere/gone"
CLAUDE_PROJECT_DIR="$FX" run_gate "$WORK/elsewhere/gone" "$(native "$FX/src/x.js")"
assert_equals "2" "$CODE" "req-004: CLAUDE_PROJECT_DIR is the root for a deleted cwd outside the project"

# Logging policy: neither the cwd nor CLAUDE_PROJECT_DIR appears in hook output.
for hook in gate guard; do
  if [ "$hook" = "gate" ]; then
    CLAUDE_PROJECT_DIR="$FX" run_gate "$WORK/elsewhere/gone" "src/x.js"
  else
    CLAUDE_PROJECT_DIR="$FX" run_guard "$WORK/elsewhere/gone" "touch src/x.js"
  fi
  assert_equals "no" "$([[ "$ERR" == *"elsewhere"* ]] && echo yes || echo no)" "req-004: the $hook output never prints the cwd"
  assert_equals "no" "$([[ "$ERR" == *"$(native "$FX")"* ]] && echo yes || echo no)" \
    "req-004: the $hook output never prints CLAUDE_PROJECT_DIR"
done

# A target past MAX_PATH_SEGMENTS keeps its warn-and-allow result from a deleted cwd.
LONG_TARGET="src/$(printf 'd/%.0s' $(seq 1 300))x.js"
CLAUDE_PROJECT_DIR="$FX" run_gate "$FX/gone" "$LONG_TARGET"
assert_equals "0" "$CODE" "req-004: a too-long target from a deleted cwd keeps its warn-and-allow exit 0"
assert_contains "Warning" "$ERR" "req-004: a too-long target from a deleted cwd keeps its warning"

# A cwd that is not a non-empty string gives no root. A non-string stdin cwd
# first falls back to process.cwd() (FR hookCwd), so the null case reaches a
# hook only when no cwd is usable at all. Both hooks then pass with exit 0.
NS="$WORK/nostring"
mkdir -p "$NS"
(cd "$NS" && rmdir "$NS" && node "$SHELL_GUARD" >/dev/null 2>&1 <<< '{"tool_name":"Bash","tool_input":{"command":"touch src/x.js"}}')
assert_equals "0" "$?" "req-004: with no cwd and CLAUDE_PROJECT_DIR unset, the shell guard passes"
RR=$(node --input-type=module -e "
const { resolveRoot } = await import(process.argv[1]);
process.stdout.write([resolveRoot(''), resolveRoot(42), resolveRoot(undefined)].map(String).join(','));
" "$(native "$PATH_RULES")" 2>&1)
assert_equals "null,null,null" "$RR" "req-004: resolveRoot returns null for a cwd that is not a non-empty string"

# =============================================================================
echo ""
echo "=== req-004: a deleted cwd with CLAUDE_PROJECT_DIR unset ==="

FX="$(make_fixture unset)"
mkdir -p "$FX/a/b/gone" && rm -rf "$FX/a/b/gone"
run_gate "$FX/a/b/gone" "$(native "$FX/src/x.js")"
assert_equals "2" "$CODE" "req-004: the nearest existing parent finds the fixture, so gate-write blocks src/x.js"
run_gate "$FX/a/b/gone/deeper" "../../../../src/x.js"
assert_equals "2" "$CODE" "req-004: a relative target resolves against the deleted cwd text"
run_guard "$FX/a/b/gone" "touch $(native "$FX/src/x.js")"
assert_equals "2" "$CODE" "req-004: the shell guard finds the fixture from the nearest existing parent"
run_gate "$FX/a/b/gone" "$(native "$WORK/outside/x.js")"
assert_equals "0" "$CODE" "req-004: a target outside the fixture still passes"

# A cwd that names a file walks up to its folder.
: > "$FX/a/file.txt"
run_gate "$FX/a/file.txt" "$(native "$FX/src/x.js")"
assert_equals "2" "$CODE" "req-004: a cwd that names a file finds the fixture root"

# =============================================================================
echo ""
echo "=== req-004: a deleted cwd with no marker above ==="

NOMARK="$WORK/nomark/a/b"
mkdir -p "$NOMARK/gone" && rmdir "$NOMARK/gone"
run_gate "$NOMARK/gone" "src/x.js"
assert_equals "2" "$CODE" "req-004: the nearest existing folder is the root, so src/x.js below it is gated"
run_gate "$NOMARK/gone" "$(native "$NOMARK/src/x.js")"
assert_equals "2" "$CODE" "req-004: an absolute path inside the nearest existing folder is gated"
run_gate "$NOMARK/gone" "$(native "$WORK/nomark/x.js")"
assert_equals "0" "$CODE" "req-004: a path above the nearest existing folder passes"

# =============================================================================
echo ""
echo "=== req-004: a walk that stops at an unreadable path ==="

if [ "$(id -u)" = "0" ]; then
  echo "  SKIP: req-004: chmod 000 doesn't block the root user"
else
  FX="$(make_fixture locked)"
  mkdir -p "$FX/locked/inner"
  LOCKED="$FX/locked"
  chmod 000 "$LOCKED"
  CLAUDE_PROJECT_DIR="$FX" run_gate "$FX/locked/inner/gone" "src/x.js"
  assert_equals "2" "$CODE" "req-004: an EACCES stop inside the CLAUDE_PROJECT_DIR root blocks"
  assert_contains "EACCES" "$ERR" "req-004: the block reason names EACCES"
  CLAUDE_PROJECT_DIR="$FX" run_guard "$FX/locked/inner/gone" "touch src/x.js"
  assert_equals "2" "$CODE" "req-004: shell guard blocks an EACCES stop inside the CLAUDE_PROJECT_DIR root"
  assert_contains "EACCES" "$ERR" "req-004: the shell guard reason names EACCES"
  run_gate "$FX/locked/inner/gone" "src/x.js"
  assert_equals "0" "$CODE" "req-004: with CLAUDE_PROJECT_DIR unset, an EACCES stop fails open"
  chmod 755 "$LOCKED"
  LOCKED=""
fi

# =============================================================================
echo ""
echo "=== req-004: hook cwd fallback when stdin has no cwd ==="

FX="$(make_fixture fallback)"
mkdir -p "$FX/gone"
ERRFILE="$WORK/stderr.txt"
(cd "$FX/gone" && rmdir "$FX/gone" && CLAUDE_PROJECT_DIR="$FX" node "$GATE_WRITE" >/dev/null 2>"$ERRFILE" <<< '{"tool_input":{"file_path":"src/x.js"}}')
CODE=$?
assert_equals "2" "$CODE" "req-004: process.cwd() throws, so gate-write uses CLAUDE_PROJECT_DIR"
mkdir -p "$FX/gone"
(cd "$FX/gone" && rmdir "$FX/gone" && CLAUDE_PROJECT_DIR="$FX" node "$SHELL_GUARD" >/dev/null 2>"$ERRFILE" <<< '{"tool_input":{"command":"touch src/x.js"}}')
CODE=$?
assert_equals "2" "$CODE" "req-004: process.cwd() throws, so the shell guard uses CLAUDE_PROJECT_DIR"
mkdir -p "$FX/gone"
(cd "$FX/gone" && rmdir "$FX/gone" && node "$GATE_WRITE" >/dev/null 2>"$ERRFILE" <<< '{"tool_input":{"file_path":"src/x.js"}}')
CODE=$?
assert_equals "0" "$CODE" "req-004: with no cwd and CLAUDE_PROJECT_DIR unset, gate-write passes"

# =============================================================================
echo ""
echo "=== req-004: hook call time with a deleted cwd 20 segments deep ==="

FX="$(make_fixture deep)"
DEEPCWD="$FX/$(printf 'd/%.0s' $(seq 1 20))"
T0=$(node -e 'process.stdout.write(String(Date.now()))')
run_gate "$DEEPCWD" "x.js"
T1=$(node -e 'process.stdout.write(String(Date.now()))')
MS=$((T1 - T0))
echo "  deleted 20-segment cwd call: ${MS} ms"
assert_equals "2" "$CODE" "req-004: a deleted 20-segment cwd still gates its write"
assert_equals "yes" "$([ "$MS" -lt 500 ] && echo yes || echo no)" "req-004: a hook call with a deleted 20-segment cwd takes under 500 ms"

# =============================================================================
echo ""
echo "=== req-004: path-rules.mjs walks with statSync and spawns nothing ==="

RULES_SRC="$(cat "$PATH_RULES")"
assert_contains '"ENOTDIR"' "$RULES_SRC" \
  "req-004: the walk tells ENOENT and ENOTDIR apart from other statSync errors"
assert_equals "no" "$([[ "$RULES_SRC" == *"node:child_process"* ]] && echo yes || echo no)" \
  "req-004: path-rules.mjs imports no node:child_process"

print_summary
