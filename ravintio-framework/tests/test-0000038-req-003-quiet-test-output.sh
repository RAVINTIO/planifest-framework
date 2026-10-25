#!/usr/bin/env bash
# Tests for feature 0000038-token-efficiency-windows-shard.
#
# req-003: run-tests.sh --quiet prints only FAIL lines, the failed-suite list,
#          and the totals. A suite fails on a non-zero exit, a signal, a
#          capture error, or a FAIL line with exit 0. Default output is
#          byte-identical. The refactor, validate, and codegen skills name
#          quiet mode and a full rerun of only the failing suite.
#
# Verified by: integration
# Verified by: unit
#
# Every runner call uses a fixture suite folder under mktemp -d. This suite
# never runs the full suite.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

RUNNER="$SCRIPT_DIR/run-tests.sh"
SKILLS="$(cd "$SCRIPT_DIR/../skills" && pwd)"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# make_fixture <name>: copies the runner into a fresh folder with a passing
# suite, a failing suite, and a passing regression suite. Prints the folder.
make_fixture() {
  local dir="$WORK/$1"
  mkdir -p "$dir/regression"
  cp "$RUNNER" "$dir/run-tests.sh"
  printf 'echo "  PASS: a ok"\nexit 0\n' > "$dir/test-a-pass.sh"
  printf 'echo "  FAIL: b broke"\nexit 1\n' > "$dir/test-b-fail.sh"
  printf 'echo "  PASS: c ok"\nexit 0\n' > "$dir/regression/test-c-pass.sh"
  printf '%s' "$dir"
}

# run_fixture <dir> [args...]: sets OUT (stdout and stderr) and CODE.
run_fixture() {
  local dir="$1"; shift
  OUT=$(cd "$dir" && bash run-tests.sh "$@" 2>&1)
  CODE=$?
}

lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

echo "=== req-003: default output is byte-identical ==="

F="$(make_fixture default)"
cat > "$WORK/golden.txt" <<'EOF'

--- test-a-pass.sh ---
  PASS: a ok

--- test-b-fail.sh ---
  FAIL: b broke

=== Regression Suite ===

--- test-c-pass.sh ---
  PASS: c ok

Failed suites:
  test-b-fail.sh

================================
Feature suites:    1 passed, 1 failed.
Regression suite:  1 passed, 0 failed.
Suites run: 3
================================
One or more tests failed.
EOF
(cd "$F" && bash run-tests.sh > "$WORK/default.txt" 2>&1)
assert_equals "0" "$(cmp -s "$WORK/golden.txt" "$WORK/default.txt"; echo $?)" \
  "req-003: output without --quiet matches the pre-change output byte for byte"

echo ""
echo "=== req-003: quiet mode prints failures and totals only ==="

run_fixture "$F" --quiet
assert_equals "1" "$CODE" "req-003: quiet run with a failing suite exits 1"
assert_contains "test-b-fail.sh: FAIL: b broke" "$OUT" "req-003: quiet run prints the FAIL line with the suite name"
assert_contains "Failed suites:" "$OUT" "req-003: quiet run prints the failed-suite list"
assert_contains "  test-b-fail.sh" "$OUT" "req-003: failed-suite list names the failing suite"
assert_contains "Feature suites:    1 passed, 1 failed." "$OUT" "req-003: quiet run prints the feature totals"
assert_contains "Suites run: 3" "$OUT" "req-003: quiet run prints the suites-run total"
lacks "PASS" "$OUT" "req-003: quiet run prints no PASS line"
lacks "--- " "$OUT" "req-003: quiet run prints no suite header"

echo ""
echo "=== req-003: quiet mode with all suites passing ==="

P="$(make_fixture allpass)"
rm "$P/test-b-fail.sh"
run_fixture "$P" --quiet
assert_equals "0" "$CODE" "req-003: quiet run with every suite passing exits 0"
assert_contains "All tests passed." "$OUT" "req-003: quiet run reports that all tests passed"
lacks "PASS" "$OUT" "req-003: quiet passing run prints no PASS line"

echo ""
echo "=== req-003: a non-zero exit with no FAIL line counts as failed ==="

N="$(make_fixture noline)"
rm "$N/test-b-fail.sh"
printf 'echo "chatter"\nexit 3\n' > "$N/test-x-silent.sh"
run_fixture "$N" --quiet
assert_equals "1" "$CODE" "req-003: silent non-zero suite makes the run exit 1"
assert_contains "  test-x-silent.sh" "$OUT" "req-003: silent non-zero suite appears in the failed-suite list"
assert_contains "FAIL: test-x-silent.sh exited 3 with no FAIL line" "$OUT" "req-003: silent non-zero suite gets a synthetic FAIL line"
lacks "chatter" "$OUT" "req-003: quiet run hides other suite output"

echo ""
echo "=== req-003: a FAIL line with exit 0 counts as failed ==="

Z="$(make_fixture failzero)"
rm "$Z/test-b-fail.sh"
printf 'echo "  FAIL: hidden"\nexit 0\n' > "$Z/test-y-hidden.sh"
run_fixture "$Z" --quiet
assert_equals "1" "$CODE" "req-003: FAIL line with exit 0 makes the run exit 1"
assert_contains "  test-y-hidden.sh" "$OUT" "req-003: FAIL line with exit 0 appears in the failed-suite list"
assert_contains "test-y-hidden.sh: FAIL: hidden" "$OUT" "req-003: FAIL line with exit 0 is printed"

echo ""
echo "=== req-003: a suite ended by a signal counts as failed ==="

G="$(make_fixture signal)"
rm "$G/test-b-fail.sh"
printf 'kill -TERM $$\nsleep 5\n' > "$G/test-z-signal.sh"
run_fixture "$G" --quiet
assert_equals "1" "$CODE" "req-003: signalled suite makes the run exit 1"
assert_contains "  test-z-signal.sh" "$OUT" "req-003: signalled suite appears in the failed-suite list"
assert_contains "exited 143" "$OUT" "req-003: signalled suite reports the signal exit code"

echo ""
echo "=== req-003: a capture error counts as failed ==="

E="$(make_fixture capture)"
rm "$E/test-b-fail.sh"
mkdir -p "$WORK/badbin"
printf '#!/bin/sh\nexit 1\n' > "$WORK/badbin/mktemp"
chmod +x "$WORK/badbin/mktemp"
OUT=$(cd "$E" && PATH="$WORK/badbin:$PATH" bash run-tests.sh --quiet 2>&1)
CODE=$?
assert_equals "1" "$CODE" "req-003: capture error makes the run exit 1"
assert_contains "  test-a-pass.sh" "$OUT" "req-003: capture error puts the suite in the failed-suite list"
assert_contains "capture" "$OUT" "req-003: capture error prints the reason"

echo ""
echo "=== req-003: quiet mode works with shard variables ==="

S="$(make_fixture shard)"
OUT=$(cd "$S" && RAVINTIO_SHARD_INDEX=2 RAVINTIO_SHARD_COUNT=3 bash run-tests.sh --quiet 2>&1)
CODE=$?
assert_equals "1" "$CODE" "req-003: shard 2 of 3 holds the failing suite and exits 1"
assert_contains "Suites run: 1" "$OUT" "req-003: shard 2 of 3 runs one suite"
assert_contains "test-b-fail.sh: FAIL: b broke" "$OUT" "req-003: shard 2 of 3 prints the FAIL line"

echo ""
echo "=== req-003: INT and TERM print the running suite ==="

T="$(make_fixture trap)"
rm "$T/test-b-fail.sh"
printf 'echo "  FAIL: partial"\ntouch started.flag\nsleep 20\n' > "$T/test-h-hang.sh"
(cd "$T" && exec bash run-tests.sh --quiet > "$WORK/trap.txt" 2>&1) &
RPID=$!
for _ in $(seq 1 100); do
  [ -e "$T/started.flag" ] && break
  sleep 0.1
done
kill -TERM "$RPID" 2>/dev/null
wait "$RPID"
CODE=$?
TRAP_OUT="$(cat "$WORK/trap.txt")"
assert_equals "no" "$([ "$CODE" -eq 0 ] && echo yes || echo no)" "req-003: stopped runner exits non-zero"
assert_contains "test-h-hang.sh: FAIL: partial" "$TRAP_OUT" "req-003: stopped runner prints the running suite's FAIL lines"
assert_contains "  test-h-hang.sh" "$TRAP_OUT" "req-003: stopped runner lists the running suite as failed"
assert_contains "Failed suites:" "$TRAP_OUT" "req-003: stopped runner prints the failed-suite list"

echo ""
echo "=== req-003: the runner adds no timeout ==="

assert_equals "absent" "$(grep -v '^[[:space:]]*#' "$RUNNER" | grep -Eq '(^|[^a-z_])timeout ' && echo present || echo absent)" \
  "req-003: run-tests.sh does not call timeout"

echo ""
echo "=== req-003: skills name quiet mode and a full rerun of the failing suite ==="

for skill in ravintio-refactor ravintio-validate-agent ravintio-codegen-agent; do
  body="$(cat "$SKILLS/$skill/SKILL.md")"
  assert_contains "run-tests.sh --quiet" "$body" "req-003: $skill names quiet mode for full-suite runs"
  assert_contains "rerun only the failing suite in full" "$body" "req-003: $skill reruns only the failing suite in full"
done

print_summary
