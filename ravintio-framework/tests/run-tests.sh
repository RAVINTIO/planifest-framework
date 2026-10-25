#!/usr/bin/env bash
# Test runner for ravintio-framework tests
# Usage: bash ravintio-framework/tests/run-tests.sh [--quiet]

set -uo pipefail

# A run inside Claude Code inherits CLAUDE_PROJECT_DIR. Hooks under test would
# then resolve the real repo as their root instead of the suite fixture.
unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TOTAL_PASS=0
TOTAL_FAIL=0
FAILED_SUITES=()

# Optional sharding (ADR-014). When both RAVINTIO_SHARD_INDEX (1-based) and
# RAVINTIO_SHARD_COUNT are set and non-empty, run only the suites whose
# position in the sorted feature-plus-regression list satisfies
# (position - 1) % count == index - 1. With neither set, every suite runs.
SHARD_INDEX="${RAVINTIO_SHARD_INDEX:-}"
SHARD_COUNT="${RAVINTIO_SHARD_COUNT:-}"
SHARDED=0
# Clear both so a suite that runs this runner on a fixture does not inherit the shard.
unset RAVINTIO_SHARD_INDEX RAVINTIO_SHARD_COUNT
if [ -n "$SHARD_INDEX" ] && [ -n "$SHARD_COUNT" ]; then
  # Accept only 1 or 2 digits with no leading zero, so bash never reads octal
  # and arithmetic never overflows. The count runs from 1 to 99.
  for shard_value in "$SHARD_INDEX" "$SHARD_COUNT"; do
    case "$shard_value" in
      [1-9]|[1-9][0-9]) ;;
      *) echo "RAVINTIO_SHARD_INDEX and RAVINTIO_SHARD_COUNT must be decimal numbers from 1 to 99 with no leading zero." >&2; exit 2 ;;
    esac
  done
  if [ "$SHARD_INDEX" -gt "$SHARD_COUNT" ]; then
    echo "RAVINTIO_SHARD_INDEX must be between 1 and RAVINTIO_SHARD_COUNT." >&2
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

# Quiet mode (ADR-004 in feature 0000038). With --quiet each suite runs with
# its output captured to a temporary file. The runner prints only FAIL lines,
# the failed-suite list, and the totals. A suite counts as failed when it
# exits non-zero (a signal or an outside timeout included), when it prints a
# FAIL: line and exits 0, or when the capture cannot be made or read. The
# runner adds no timeout of its own.
QUIET=0
for arg in "$@"; do
  [ "$arg" = "--quiet" ] && QUIET=1
done

CAPTURE=""
RUNNING=""
CHILD_PID=""

# Prints each FAIL: line of a capture file, prefixed with the suite label.
quiet_fail_lines() {
  awk -v label="$1" '/^[[:space:]]*FAIL:/ { sub(/^[[:space:]]+/, ""); print label ": " $0 }' "$2" 2>/dev/null
}

quiet_cleanup() {
  if [ -n "$CAPTURE" ]; then rm -f "$CAPTURE"; fi
}

# Runs on INT or TERM so a stopped runner still shows the suite that was running.
quiet_on_signal() {
  trap '' INT TERM
  if [ -n "$CHILD_PID" ]; then kill "$CHILD_PID" 2>/dev/null; fi
  if [ -n "$RUNNING" ]; then
    local fails=""
    if [ -n "$CAPTURE" ] && [ -r "$CAPTURE" ]; then fails="$(quiet_fail_lines "$RUNNING" "$CAPTURE")"; fi
    if [ -n "$fails" ]; then
      printf '%s\n' "$fails"
    else
      echo "$RUNNING: FAIL: $RUNNING was running when the runner stopped"
    fi
    FAILED_SUITES+=("$RUNNING")
  fi
  quiet_cleanup
  if [ "${#FAILED_SUITES[@]}" -gt 0 ]; then
    echo ""
    echo "Failed suites:"
    for failed in "${FAILED_SUITES[@]}"; do
      echo "  $failed"
    done
  fi
  exit $((128 + $1))
}

if [ "$QUIET" -eq 1 ]; then
  trap quiet_cleanup EXIT
  trap 'quiet_on_signal 2' INT
  trap 'quiet_on_signal 15' TERM
fi

# run_suite_quiet <label> <file>: returns 0 when the suite passed, 1 when it failed.
run_suite_quiet() {
  local label="$1" file="$2" rc fails
  CAPTURE="$(mktemp 2>/dev/null)" || CAPTURE=""
  if [ -z "$CAPTURE" ] || [ ! -w "$CAPTURE" ]; then
    CAPTURE=""
    echo "$label: FAIL: $label could not create its capture file"
    return 1
  fi
  RUNNING="$label"
  bash "$file" >"$CAPTURE" 2>&1 &
  CHILD_PID=$!
  { wait "$CHILD_PID"; } 2>/dev/null
  rc=$?
  CHILD_PID=""
  if [ ! -r "$CAPTURE" ]; then
    echo "$label: FAIL: $label capture file could not be read"
    CAPTURE=""; RUNNING=""
    return 1
  fi
  fails="$(quiet_fail_lines "$label" "$CAPTURE")"
  rm -f "$CAPTURE"
  CAPTURE=""; RUNNING=""
  if [ -n "$fails" ]; then
    printf '%s\n' "$fails"
    return 1
  fi
  if [ "$rc" -ne 0 ]; then
    echo "$label: FAIL: $label exited $rc with no FAIL line"
    return 1
  fi
  return 0
}

run_suite() {
  local file="$1"
  local name
  name="$(basename "$file")"
  if [ "$QUIET" -eq 1 ]; then
    if run_suite_quiet "$name" "$file"; then
      TOTAL_PASS=$((TOTAL_PASS + 1))
    else
      TOTAL_FAIL=$((TOTAL_FAIL + 1))
      FAILED_SUITES+=("$name")
    fi
    return
  fi
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

if [ "$QUIET" -eq 0 ]; then
  echo ""
  echo "=== Regression Suite ==="
fi

if [ ! -e "${REGRESSION_TESTS[0]}" ]; then
  [ "$QUIET" -eq 0 ] && echo "  No regression tests yet."
else
  for regression_test in "${REGRESSION_TESTS[@]}"; do
    in_shard || continue
    name="$(basename "$regression_test")"
    if [ "$QUIET" -eq 1 ]; then
      if run_suite_quiet "regression/$name" "$regression_test"; then
        REGRESSION_PASS=$((REGRESSION_PASS + 1))
      else
        REGRESSION_FAIL=$((REGRESSION_FAIL + 1))
        FAILED_SUITES+=("regression/$name")
      fi
      continue
    fi
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
