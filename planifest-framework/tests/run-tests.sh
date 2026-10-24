#!/usr/bin/env bash
# Test runner for planifest-framework tests
# Usage: bash planifest-framework/tests/run-tests.sh

set -uo pipefail

# A run inside Claude Code inherits CLAUDE_PROJECT_DIR. Hooks under test would
# then resolve the real repo as their root instead of the suite fixture.
unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TOTAL_PASS=0
TOTAL_FAIL=0
FAILED_SUITES=()

# Optional sharding (ADR-014). When both PLANIFEST_SHARD_INDEX (1-based) and
# PLANIFEST_SHARD_COUNT are set and non-empty, run only the suites whose
# position in the sorted feature-plus-regression list satisfies
# (position - 1) % count == index - 1. With neither set, every suite runs.
SHARD_INDEX="${PLANIFEST_SHARD_INDEX:-}"
SHARD_COUNT="${PLANIFEST_SHARD_COUNT:-}"
SHARDED=0
# Clear both so a suite that runs this runner on a fixture does not inherit the shard.
unset PLANIFEST_SHARD_INDEX PLANIFEST_SHARD_COUNT
if [ -n "$SHARD_INDEX" ] && [ -n "$SHARD_COUNT" ]; then
  # Accept only 1 or 2 digits with no leading zero, so bash never reads octal
  # and arithmetic never overflows. The count runs from 1 to 99.
  for shard_value in "$SHARD_INDEX" "$SHARD_COUNT"; do
    case "$shard_value" in
      [1-9]|[1-9][0-9]) ;;
      *) echo "PLANIFEST_SHARD_INDEX and PLANIFEST_SHARD_COUNT must be decimal numbers from 1 to 99 with no leading zero." >&2; exit 2 ;;
    esac
  done
  if [ "$SHARD_INDEX" -gt "$SHARD_COUNT" ]; then
    echo "PLANIFEST_SHARD_INDEX must be between 1 and PLANIFEST_SHARD_COUNT." >&2
    exit 2
  fi
  SHARDED=1
  echo "Shard $SHARD_INDEX of $SHARD_COUNT: running suites at positions where (position - 1) % $SHARD_COUNT == $((SHARD_INDEX - 1))."
fi

POSITION=0

# Returns 0 when the next suite belongs to this run. Advances the position.
in_shard() {
  POSITION=$((POSITION + 1))
  [ "$SHARDED" -eq 0 ] && return 0
  [ $(( (POSITION - 1) % SHARD_COUNT )) -eq $((SHARD_INDEX - 1)) ]
}

run_suite() {
  local file="$1"
  local name
  name="$(basename "$file")"
  echo ""
  echo "--- $name ---"
  if bash "$file"; then
    TOTAL_PASS=$((TOTAL_PASS + 1))
  else
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
    FAILED_SUITES+=("$name")
  fi
}

# Every test-*.sh in this directory is discovered and run automatically —
# no suite needs to be registered by hand. Add a new test-*.sh file and it
# runs on the next invocation (backlog 0000004: hardcoded list silently
# skipped 5 of 14 suites, including this feature's own).
# The regression list is read before the loop so the shard position counts
# feature suites first, then regression suites.
REGRESSION_DIR="$SCRIPT_DIR/regression"
REGRESSION_TESTS=("$REGRESSION_DIR"/test-*.sh)

for suite in "$SCRIPT_DIR"/test-*.sh; do
  in_shard || continue
  run_suite "$suite"
done

# ── Regression Suite ──────────────────────────────────────────────────────────

REGRESSION_PASS=0
REGRESSION_FAIL=0

echo ""
echo "=== Regression Suite ==="

if [ ! -e "${REGRESSION_TESTS[0]}" ]; then
  echo "  No regression tests yet."
else
  for regression_test in "${REGRESSION_TESTS[@]}"; do
    in_shard || continue
    name="$(basename "$regression_test")"
    echo ""
    echo "--- $name ---"
    if bash "$regression_test"; then
      REGRESSION_PASS=$((REGRESSION_PASS + 1))
    else
      REGRESSION_FAIL=$((REGRESSION_FAIL + 1))
      FAILED_SUITES+=("regression/$name")
    fi
  done
fi

# ── Summary ───────────────────────────────────────────────────────────────────

if [ "${#FAILED_SUITES[@]}" -gt 0 ]; then
  echo ""
  echo "Failed suites:"
  for failed in "${FAILED_SUITES[@]}"; do
    echo "  $failed"
  done
fi

SUITES_RUN=$((TOTAL_PASS + TOTAL_FAIL + REGRESSION_PASS + REGRESSION_FAIL))

echo ""
echo "================================"
echo "Feature suites:    $TOTAL_PASS passed, $TOTAL_FAIL failed."
echo "Regression suite:  $REGRESSION_PASS passed, $REGRESSION_FAIL failed."
echo "Suites run: $SUITES_RUN"
echo "================================"

# A shard that selects no suite proves nothing, so it must not pass.
if [ "$SHARDED" -eq 1 ] && [ "$SUITES_RUN" -eq 0 ]; then
  echo "Shard $SHARD_INDEX of $SHARD_COUNT ran no suites. Check the shard count against the suite list." >&2
  exit 3
fi

if [ "$TOTAL_FAIL" -eq 0 ] && [ "$REGRESSION_FAIL" -eq 0 ]; then
  echo "All tests passed."
  exit 0
else
  echo "One or more tests failed."
  exit 1
fi
