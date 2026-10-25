#!/usr/bin/env bash
# Tests for feature 0000032-governance-continuity-and-write-gate-scope.
#
# req-012: the boot templates gain a Hard Limit that code changes go through
#          Write or Edit, never through Bash. It covers the writes the shell
#          guard can't see. Setup carries the rule into the generated CLAUDE.md.
#
# REGRESSION-CANDIDATE: covers the Write or Edit boot-file Hard Limit, tagged
# by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
STANDARD="$FRAMEWORK/templates/standard-boot.md"
CURSOR="$FRAMEWORK/templates/cursor-boot.md"
RULE="through **Write** or **Edit**, never through Bash"

WORK="$(mktemp -d -t ravintio_0000032_req012_XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

# section <file> <heading>: the lines from the heading up to the next ## heading.
section() {
  awk -v h="## $2" '$0 == h { on = 1; print; next } on && /^## / { exit } on { print }' "$1"
}

# check_hard_limit <file> <label>: the Hard Limits section holds the rule.
check_hard_limit() {
  local limits
  limits="$(section "$1" "Hard Limits")"
  assert_contains "$RULE" "$limits" "req-012: $2 Hard Limits route code changes through Write or Edit"
  assert_contains "heuristic" "$limits" "req-012: $2 Hard Limit says the shell guard is a heuristic"
  assert_contains "inside scripts" "$limits" "req-012: $2 Hard Limit says the guard can't see writes inside scripts"
}

echo ""
echo "=== req-012: standard-boot.md ==="

check_hard_limit "$STANDARD" "standard-boot.md"
HOOKS="$(section "$STANDARD" "Hook Enforcement")"
assert_contains "**shell-write-guard** (PreToolUse: Bash, Claude Code only)" "$HOOKS" \
  "req-012: standard-boot.md Hook Enforcement has a shell-write-guard bullet"
GATE_LINE="$(printf '%s\n' "$HOOKS" | awk '/^- \*\*gate-write\*\*/')"
assert_contains "outside the repository" "$GATE_LINE" "req-012: the gate-write bullet says outside paths are never gated"
assert_contains "stderr" "$HOOKS" "req-012: the Hook Enforcement section says block reasons go to stderr"

echo ""
echo "=== req-012: cursor-boot.md ==="

check_hard_limit "$CURSOR" "cursor-boot.md"

echo ""
echo "=== req-012: setup carries the rule into CLAUDE.md ==="

WS="$WORK/ws"
mkdir -p "$WS"
cp -r "$FRAMEWORK" "$WS/ravintio-framework"
git init "$WS" >/dev/null 2>&1
(cd "$WS" && bash ravintio-framework/setup.sh claude-code > "$WORK/setup.log" 2>&1)
assert_exit_zero "$?" "req-012: setup.sh claude-code exits 0"
check_hard_limit "$WS/CLAUDE.md" "generated CLAUDE.md"

print_summary
