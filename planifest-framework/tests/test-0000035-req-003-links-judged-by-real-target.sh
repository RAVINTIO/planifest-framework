#!/usr/bin/env bash
# Tests for feature 0000035-write-gate-scope-and-path-hardening.
#
# req-003: resolveTarget walks a target one segment at a time through
#          symbolic links, with a 40-hop limit, so the gates judge where a
#          write lands (ADR-005). A link loop, a chain past 40, or another
#          resolution error inside the root blocks with exit 2.
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

WORK="$(mktemp -d -t planifest_0000035_req003_XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

native() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

# now_ms: the current time in milliseconds.
now_ms() { node -e 'process.stdout.write(String(Date.now()))'; }

# run_gate <cwd> <target>: runs gate-write and sets CODE, ERR, and MS.
run_gate() {
  local errfile="$WORK/stderr.txt" t0
  t0=$(now_ms)
  node "$GATE_WRITE" >/dev/null 2>"$errfile" <<< "{\"cwd\":\"$(native "$1")\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$2\"}}"
  CODE=$?
  MS=$(( $(now_ms) - t0 ))
  ERR=$(cat "$errfile")
}

# run_guard <cwd> <command>: runs the shell-write guard and sets CODE, ERR, and MS.
run_guard() {
  local errfile="$WORK/stderr.txt" t0
  t0=$(now_ms)
  node "$SHELL_GUARD" >/dev/null 2>"$errfile" <<< "{\"cwd\":\"$(native "$1")\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$2\"}}"
  CODE=$?
  MS=$(( $(now_ms) - t0 ))
  ERR=$(cat "$errfile")
}

FX="$WORK/repo"
mkdir -p "$FX/plan/current" "$FX/src" "$FX/a/b/c"
git init "$FX" >/dev/null 2>&1

ln -s "$FX/src" "$WORK/link-probe" 2>/dev/null
if [ ! -L "$WORK/link-probe" ]; then
  echo "  SKIP: req-003: this platform can't create symbolic links, so the link cases don't run"
  print_summary
fi

# =============================================================================
echo ""
echo "=== req-003: a dangling link under plan/ to a src/ target ==="

ln -s ../src/new.js "$FX/plan/dangling"
run_gate "$FX" "plan/dangling"
assert_equals "2" "$CODE" "req-003: gate-write blocks a write through a dangling plan/ link to src/new.js"
assert_contains "No confirmed design" "$ERR" "req-003: gate-write judges the dangling link's target"
run_guard "$FX" "touch plan/dangling"
assert_equals "2" "$CODE" "req-003: shell guard blocks a write through a dangling plan/ link to src/new.js"

# A dangling link whose target folder is missing too.
ln -s ../lib/deep/new.js "$FX/plan/dangling-deep"
run_gate "$FX" "plan/dangling-deep"
assert_equals "2" "$CODE" "req-003: gate-write judges a dangling link into a missing folder by its target"

# A link to a folder carries a write below it.
ln -s ../src "$FX/plan/srcdir"
run_gate "$FX" "plan/srcdir/x.js"
assert_equals "2" "$CODE" "req-003: gate-write blocks plan/srcdir/x.js through a link to src/"
run_guard "$FX" "touch plan/srcdir/x.js"
assert_equals "2" "$CODE" "req-003: shell guard blocks plan/srcdir/x.js through a link to src/"

# =============================================================================
echo ""
echo "=== req-003: .. after a link resolves from the link's real target ==="

ln -s "$FX/a/b/c" "$FX/plan/l"
run_gate "$FX" "plan/l/../../../src/x.js"
assert_equals "2" "$CODE" "req-003: gate-write judges plan/l/../../../src/x.js as src/x.js"
assert_contains "No confirmed design" "$ERR" "req-003: gate-write gives the no-design reason for plan/l/../../../src/x.js"
run_guard "$FX" "touch plan/l/../../../src/x.js"
assert_equals "2" "$CODE" "req-003: shell guard judges plan/l/../../../src/x.js as src/x.js"
run_gate "$FX" "$(native "$FX")/plan/l/../../../src/x.js"
assert_equals "2" "$CODE" "req-003: gate-write judges the absolute form the same way"

# =============================================================================
echo ""
echo "=== req-003: a link loop inside the root ==="

ln -s loop-b "$FX/plan/loop-a"
ln -s loop-a "$FX/plan/loop-b"
run_gate "$FX" "plan/loop-a"
assert_equals "2" "$CODE" "req-003: gate-write blocks a write through a link loop"
assert_contains "link loop" "$ERR" "req-003: gate-write names the link loop"
run_guard "$FX" "touch plan/loop-a"
assert_equals "2" "$CODE" "req-003: shell guard blocks a write through a link loop"
assert_contains "link loop" "$ERR" "req-003: shell guard names the link loop"
assert_equals "no" "$([[ "$ERR" == *"loop-b"* ]] && echo yes || echo no)" "req-003: the block reason never prints link text"

# A loop whose link name runs past 80 characters and whose link text is distinctive.
LONG_NAME="$(printf 'L%.0s' $(seq 1 100))"
ln -s SECRETTEXT-loop "$FX/plan/$LONG_NAME"
ln -s "$LONG_NAME" "$FX/plan/SECRETTEXT-loop"
SHOWN="plan/$(printf 'L%.0s' $(seq 1 75))"
for hook in gate guard; do
  if [ "$hook" = "gate" ]; then run_gate "$FX" "plan/$LONG_NAME"; else run_guard "$FX" "touch plan/$LONG_NAME"; fi
  assert_equals "2" "$CODE" "req-003: $hook blocks a loop with a long link name"
  assert_contains "$SHOWN" "$ERR" "req-003: the $hook reason shows the first 80 characters of the target"
  assert_equals "no" "$([[ "$ERR" == *"${SHOWN}L"* ]] && echo yes || echo no)" \
    "req-003: the $hook reason shows no more than 80 characters of the target"
  assert_equals "no" "$([[ "$ERR" == *"SECRETTEXT"* ]] && echo yes || echo no)" \
    "req-003: the $hook reason never prints link text"
done

# =============================================================================
echo ""
echo "=== req-003: a path too long after a link substitution ==="

ln -s "$(printf 'a/%.0s' $(seq 1 300))x" "$FX/plan/huge"
run_gate "$FX" "plan/huge"
assert_equals "2" "$CODE" "req-003: gate-write blocks a path past MAX_PATH_SEGMENTS after its link"
assert_contains "too long to judge after its links" "$ERR" "req-003: gate-write names the length cause"
run_guard "$FX" "touch plan/huge"
assert_equals "2" "$CODE" "req-003: shell guard blocks a path past MAX_PATH_SEGMENTS after its link"

# =============================================================================
echo ""
echo "=== req-003: a chain of 41 links ==="

mkdir -p "$FX/plan/chain41"
: > "$FX/plan/chain41/end.md"
ln -s end.md "$FX/plan/chain41/l41"
for i in $(seq 40 -1 1); do ln -s "l$((i + 1))" "$FX/plan/chain41/l$i"; done
run_gate "$FX" "plan/chain41/l1"
assert_equals "2" "$CODE" "req-003: gate-write blocks a 41-link chain"
assert_contains "more than 40 links" "$ERR" "req-003: gate-write names the hop limit"
run_guard "$FX" "touch plan/chain41/l1"
assert_equals "2" "$CODE" "req-003: shell guard blocks a 41-link chain"
assert_contains "more than 40 links" "$ERR" "req-003: shell guard names the hop limit"

# 40 links is within the limit.
run_gate "$FX" "plan/chain41/l2"
assert_equals "0" "$CODE" "req-003: a 40-link chain into plan/ passes"

# =============================================================================
echo ""
echo "=== req-003: a chain of 10 links into plan/ passes quickly ==="

mkdir -p "$FX/plan/chain10"
: > "$FX/plan/chain10/end.md"
ln -s end.md "$FX/plan/chain10/l10"
for i in $(seq 9 -1 1); do ln -s "l$((i + 1))" "$FX/plan/chain10/l$i"; done
run_gate "$FX" "plan/chain10/l1"
echo "  gate-write 10-link call: ${MS} ms"
assert_equals "0" "$CODE" "req-003: gate-write passes a 10-link chain into plan/"
assert_equals "yes" "$([ "$MS" -lt 500 ] && echo yes || echo no)" "req-003: gate-write judges a 10-link chain in under 500 ms"
run_guard "$FX" "touch plan/chain10/l1"
echo "  shell guard 10-link call: ${MS} ms"
assert_equals "0" "$CODE" "req-003: shell guard passes a 10-link chain into plan/"
assert_equals "yes" "$([ "$MS" -lt 500 ] && echo yes || echo no)" "req-003: shell guard judges a 10-link chain in under 500 ms"

# A 10-link chain into src/ is judged by its end.
ln -s ../../src/x.js "$FX/plan/chain10/to-src10"
for i in $(seq 9 -1 1); do ln -s "to-src$((i + 1))" "$FX/plan/chain10/to-src$i"; done
run_gate "$FX" "plan/chain10/to-src1"
assert_equals "2" "$CODE" "req-003: a 10-link chain into src/ is judged as src/x.js"

# =============================================================================
echo ""
echo "=== req-003: a link under plan/ to a file outside the root passes ==="

mkdir -p "$WORK/outside"
ln -s "$WORK/outside/x.js" "$FX/plan/out"
run_gate "$FX" "plan/out"
assert_equals "0" "$CODE" "req-003: gate-write passes a link to a file outside the root"
run_guard "$FX" "touch plan/out"
assert_equals "0" "$CODE" "req-003: shell guard passes a link to a file outside the root"

# A link loop wholly outside the root passes, since neither path lies inside it.
ln -s oloop-b "$WORK/outside/oloop-a"
ln -s oloop-a "$WORK/outside/oloop-b"
run_gate "$FX" "$(native "$WORK/outside/oloop-a")"
assert_equals "0" "$CODE" "req-003: a link loop outside the root passes"

# =============================================================================
echo ""
echo "=== req-003: healthy links and errors outside resolution ==="

ln -s ../plan "$FX/a/plan-link"
run_gate "$FX" "a/plan-link/notes.md"
assert_equals "0" "$CODE" "req-003: a link into plan/ makes the write a plan/ write"

node "$GATE_WRITE" >/dev/null 2>&1 <<< "not json"
assert_equals "0" "$?" "req-003: bad JSON on stdin still fails open"

# =============================================================================
echo ""
echo "=== req-003: gate-write also judges the path with .. collapsed as text (G-S01) ==="

# The Write tool collapses .. as text before the system follows any link. With
# docs/L -> ../plan/x/y, docs/L/../../src/a.js lands in src/a.js, not plan/src/a.js.
mkdir -p "$FX/plan/x/y" "$FX/docs"
ln -s ../plan/x/y "$FX/docs/L"
run_gate "$FX" "docs/L/../../src/a.js"
assert_equals "2" "$CODE" "req-003: gate-write blocks docs/L/../../src/a.js with no design"
assert_contains "No confirmed design" "$ERR" "req-003: gate-write judges docs/L/../../src/a.js as src/a.js"
run_gate "$FX" "$(native "$FX")/docs/L/../../src/a.js"
assert_equals "2" "$CODE" "req-003: gate-write blocks the absolute form of docs/L/../../src/a.js"
# The shell runs .. through the link, as the kernel does, so it lands in plan/.
run_guard "$FX" "touch docs/L/../../src/a.js"
assert_equals "0" "$CODE" "req-003: the shell guard keeps the physical walk, which lands in plan/src/a.js"

# Under a current scope record, the text-collapsed path still meets the enforcement list.
FXR="$WORK/repo-record"
mkdir -p "$FXR/plan/current" "$FXR/plan/x/y" "$FXR/docs" "$FXR/src" "$FXR/.claude"
git init -q "$FXR" >/dev/null 2>&1
git -C "$FXR" -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -q --allow-empty -m init --no-verify >/dev/null 2>&1
printf 'branch: %s\nhead: %s\npaths:\n- src/a.js\n' \
  "$(git -C "$FXR" rev-parse --abbrev-ref HEAD)" "$(git -C "$FXR" rev-parse HEAD)" > "$FXR/plan/.fast-path-scope"
ln -s ../plan/x/y "$FXR/docs/L"
run_gate "$FXR" "docs/L/../../.claude/settings.json"
assert_equals "2" "$CODE" "req-003: gate-write blocks docs/L/../../.claude/settings.json under a scope record"
assert_contains "enforcement path" "$ERR" "req-003: gate-write judges docs/L/../../.claude/settings.json as .claude/settings.json"
run_gate "$FXR" "src/a.js"
assert_equals "0" "$CODE" "req-003: control, the record still admits src/a.js"

# =============================================================================
echo ""
echo "=== req-003: path-rules.mjs exports resolveTarget and spawns nothing ==="

RULES_SRC="$(cat "$PATH_RULES")"
assert_contains "export function resolveTarget(root, cwd, target)" "$RULES_SRC" "req-003: path-rules.mjs exports resolveTarget"
assert_contains "lstatSync" "$RULES_SRC" "req-003: resolveTarget walks with lstatSync"
assert_contains "readlinkSync" "$RULES_SRC" "req-003: resolveTarget reads link text with readlinkSync"
assert_equals "no" "$([[ "$RULES_SRC" == *"node:child_process"* ]] && echo yes || echo no)" \
  "req-003: path-rules.mjs imports no node:child_process"
STATUS=$(node --input-type=module -e "
import { resolveTarget } from '$(native "$PATH_RULES")';
const r = resolveTarget(process.argv[1], process.argv[1], 'plan/l/../../../src/x.js');
process.stdout.write(r.status + ' ' + r.relPath);
" "$(cd "$FX" && pwd -P)")
assert_equals "inside src/x.js" "$STATUS" "req-003: resolveTarget returns { status: inside, relPath: src/x.js }"

print_summary
