#!/usr/bin/env bash
# Tests for feature 0000036-pipeline-friction-and-gate-fixes.
#
# req-009: the always-permitted file-name shortcut in evaluateWrite applies
#          only when isEnforcementPath is false. A permitted name such as
#          CLAUDE.md inside an enforcement path takes the normal design or
#          scope route. A permitted name outside every enforcement path still
#          passes at step 1 (ADR-003).
#
# Every fixture lives under mktemp -d. The suite uses git to build fixtures.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
ENF="$FRAMEWORK/hooks/enforcement"
GATE_WRITE="$ENF/gate-write.mjs"
SHELL_GUARD="$ENF/shell-write-guard.mjs"

WORK="$(mktemp -d -t planifest_0000036_req009_XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

native() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

GIT=(git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c init.defaultBranch=main)

FX="$WORK/repo"
DESIGN="$FX/plan/current/design.md"
mkdir -p "$FX/plan/current" "$FX/src"
: > "$FX/plan/.orchestrator-active"
"${GIT[@]}" init -q "$FX" >/dev/null 2>&1
"${GIT[@]}" -C "$FX" commit -q --allow-empty -m init --no-verify >/dev/null 2>&1
BRANCH="$(git -C "$FX" rev-parse --abbrev-ref HEAD)"
HEAD_ID="$(git -C "$FX" rev-parse HEAD)"

ENFORCEMENT_TARGETS=(
  "planifest-framework/hooks/enforcement/CLAUDE.md"
  ".claude/hooks/enforcement/AGENTS.md"
  "planifest-framework/hooks/enforcement/Claude.MD"
)
OUTSIDE_TARGET="src/a/CLAUDE.md"

# design <path>: a regular design.md whose Component Paths section lists <path>.
design() {
  printf '# Design\n\n## Component Paths\n\n- %s\n' "$1" > "$DESIGN"
}

# record <path>: a current scope record that lists <path>.
record() {
  printf 'branch: %s\nhead: %s\npaths:\n- %s\n' "$BRANCH" "$HEAD_ID" "$1" > "$FX/plan/.fast-path-scope"
}

reset_state() {
  rm -f "$DESIGN" "$FX/plan/.fast-path-scope"
}

# run_gate <target>: a Write of <target> through gate-write. Sets CODE and ERR.
run_gate() {
  local errfile="$WORK/stderr.txt"
  node "$GATE_WRITE" >/dev/null 2>"$errfile" <<< "{\"cwd\":\"$(native "$FX")\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$1\"}}"
  CODE=$?
  ERR=$(cat "$errfile")
}

# run_guard <command>: <command> through the shell-write guard. Sets CODE and ERR.
run_guard() {
  local errfile="$WORK/stderr.txt"
  node "$SHELL_GUARD" >/dev/null 2>"$errfile" <<< "{\"cwd\":\"$(native "$FX")\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$1\"}}"
  CODE=$?
  ERR=$(cat "$errfile")
}

# expect <code> <target> <state>: both hooks give <code> for a write to <target>.
expect() {
  run_gate "$2"
  assert_equals "$1" "$CODE" "req-009: gate-write gives exit $1 for $2 with $3"
  run_guard "touch $2"
  assert_equals "$1" "$CODE" "req-009: shell-write-guard gives exit $1 for $2 with $3"
}

# =============================================================================
echo ""
echo "=== req-009: no design.md and no scope record ==="

reset_state
for target in "${ENFORCEMENT_TARGETS[@]}"; do
  expect 2 "$target" "no design and no record"
done
run_gate "${ENFORCEMENT_TARGETS[0]}"
assert_contains "No confirmed design at plan/current/design.md" "$ERR" "req-009: the block gives the no-design reason"
expect 0 "$OUTSIDE_TARGET" "no design and no record"

# =============================================================================
echo ""
echo "=== req-009: no design.md and a current record that lists the target ==="

for target in "${ENFORCEMENT_TARGETS[@]}"; do
  reset_state
  record "$target"
  expect 2 "$target" "a record that lists it"
  run_gate "$target"
  assert_contains "is an enforcement path, so Fast Path never admits it" "$ERR" "req-009: the block for $target gives the enforcement-path reason"
done
reset_state
record "$OUTSIDE_TARGET"
expect 0 "$OUTSIDE_TARGET" "a record that lists it"

# =============================================================================
echo ""
echo "=== req-009: a regular design.md that doesn't cover the target ==="

reset_state
design "lib/"
for target in "${ENFORCEMENT_TARGETS[@]}"; do
  expect 2 "$target" "a design that doesn't cover it"
done
run_gate "${ENFORCEMENT_TARGETS[0]}"
assert_contains "is not covered by the confirmed design" "$ERR" "req-009: the block gives the component-path reason"
expect 0 "$OUTSIDE_TARGET" "a design that doesn't cover it"

# =============================================================================
echo ""
echo "=== req-009: a design that covers planifest-framework/ ==="

reset_state
design "planifest-framework/"
expect 0 "planifest-framework/hooks/enforcement/CLAUDE.md" "a design that covers planifest-framework/"
expect 0 "planifest-framework/hooks/enforcement/Claude.MD" "a design that covers planifest-framework/"
expect 0 "$OUTSIDE_TARGET" "a design that covers planifest-framework/"

# =============================================================================
echo ""
echo "=== req-009: the plan/ and docs/ prefix shortcut is unchanged ==="

reset_state
expect 0 "plan/hooks/enforcement/CLAUDE.md" "no design and no record"
expect 0 "docs/hooks/enforcement/notes.md" "no design and no record"

print_summary
