#!/usr/bin/env bash
# Tests for feature 0000036-pipeline-friction-and-gate-fixes.
#
# req-010: run-tests.sh clears CLAUDE_PROJECT_DIR before any suite, and every
#          suite that names an enforcement hook clears it before its first
#          node command, so a standalone run tests its fixture.
#
# Two checks:
#   1. Runner check: a copy of run-tests.sh runs a stub suite that prints the
#      variable. The stub must see it unset.
#   2. Suite-rule check: every test-*.sh under tests/ and tests/regression/
#      that names an enforcement hook holds an unset line before its first
#      node command.

set -uo pipefail

# A direct run may inherit a CI shard. The fixture runner must see none.
unset RAVINTIO_SHARD_INDEX RAVINTIO_SHARD_COUNT

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

WORK="$(mktemp -d -t ravintio_0000036_req010_XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

# ── Runner check ─────────────────────────────────────────────────────────────

RUNNER_DIR="$WORK/runner"
mkdir -p "$RUNNER_DIR"
cp "$SCRIPT_DIR/run-tests.sh" "$RUNNER_DIR/run-tests.sh"
printf '%s\n' '#!/usr/bin/env bash' 'echo "[${CLAUDE_PROJECT_DIR-unset}]"' > "$RUNNER_DIR/test-probe.sh"

FIXTURE="$WORK/fixture"
mkdir -p "$FIXTURE"

START=$(date +%s)
RUNNER_OUT="$(CLAUDE_PROJECT_DIR="$FIXTURE" bash "$RUNNER_DIR/run-tests.sh" 2>&1)"
END=$(date +%s)

assert_contains "[unset]" "$RUNNER_OUT" "req-010: run-tests.sh clears CLAUDE_PROJECT_DIR before a suite runs"
assert_equals "no" "$([[ "$RUNNER_OUT" == *"[$FIXTURE]"* ]] && echo yes || echo no)" "req-010: the suite does not see the fixture path"
assert_equals "yes" "$([ $((END - START)) -lt 2 ] && echo yes || echo no)" "req-010: the runner check finishes in under 2 seconds"

# ── Suite-rule check ─────────────────────────────────────────────────────────

HOOKS_RE='gate-write\.mjs|shell-write-guard\.mjs|ratchet-check\.mjs|em-dash-guard\.mjs|path-rules\.mjs|check-design\.mjs'
NODE_RE='(^|[^[:alnum:]_])node([^[:alnum:]_]|$)'

for suite in "$SCRIPT_DIR"/test-*.sh "$SCRIPT_DIR"/regression/test-*.sh; do
  [ -e "$suite" ] || continue
  rel="${suite#"$SCRIPT_DIR"/}"
  if ! grep -qE "$HOOKS_RE" "$suite"; then
    continue
  fi
  unset_line="$(grep -nE '^[[:space:]]*unset CLAUDE_PROJECT_DIR' "$suite" | head -1 | cut -d: -f1)"
  node_line="$(grep -nE "$NODE_RE" "$suite" | grep -vE '^[0-9]+:[[:space:]]*#' | head -1 | cut -d: -f1)"
  if [ -z "$unset_line" ]; then
    ok="no"
  elif [ -z "$node_line" ] || [ "$unset_line" -lt "$node_line" ]; then
    ok="yes"
  else
    ok="no"
  fi
  assert_equals "yes" "$ok" "req-010: $rel clears CLAUDE_PROJECT_DIR before its first node command"
done

print_summary
