#!/usr/bin/env bash
# Tests for feature 0000031-ci-test-and-powershell-coverage.
#
# req-002: run-tests.sh names each failed suite under a "Failed suites:" heading
#          before its summary block. It prints no heading when every suite passes.
#
# The test runs a copy of run-tests.sh against fixture suites in a temporary
# folder. It never runs the real suite, which would recurse.

set -uo pipefail

# A direct run may inherit a CI shard. The fixture runner must see none.
unset PLANIFEST_SHARD_INDEX PLANIFEST_SHARD_COUNT

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

WORK="$(mktemp -d -t planifest_0000031_req002_XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

# make_fixture <name>: copies the runner and helpers into $WORK/<name>.
make_fixture() {
  local dir="$WORK/$1"
  mkdir -p "$dir/regression"
  cp "$SCRIPT_DIR/run-tests.sh" "$dir/run-tests.sh"
  cp -r "$SCRIPT_DIR/helpers" "$dir/helpers"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$dir/test-pass.sh"
  echo "$dir"
}

# line_of <needle> <text>: prints the first line number containing the needle.
line_of() { printf '%s\n' "$2" | grep -n -F -- "$1" | head -1 | cut -d: -f1; }

echo "=== req-002: failing suites are listed ==="

FAIL_DIR="$(make_fixture failing)"
printf '#!/usr/bin/env bash\nexit 1\n' > "$FAIL_DIR/test-fail-a.sh"
printf '#!/usr/bin/env bash\nexit 1\n' > "$FAIL_DIR/regression/test-fail-b.sh"

out=$(bash "$FAIL_DIR/run-tests.sh" 2>&1)
code=$?

assert_contains "Failed suites:" "$out" "req-002: output has a Failed suites heading"
heading_line=$(line_of "Failed suites:" "$out")
after_heading=$(printf '%s\n' "$out" | sed -n '/^Failed suites:/,$p')
assert_contains "test-fail-a.sh" "$after_heading" "req-002: feature suite is listed after the heading"
assert_contains "regression/test-fail-b.sh" "$after_heading" "req-002: regression suite is listed with its prefix"

list_lines=$(printf '%s\n' "$out" | grep -E '^ *(regression/)?test-fail-[ab]\.sh *$' || true)
assert_equals "2" "$(printf '%s\n' "$list_lines" | grep -c .)" "req-002: each failed suite has its own list line"

summary_line=$(line_of "Feature suites:" "$out")
assert_equals "yes" "$([ -n "$heading_line" ] && [ -n "$summary_line" ] && [ "$heading_line" -lt "$summary_line" ] && echo yes || echo no)" \
  "req-002: Failed suites heading appears before the Feature suites summary"
assert_equals "1" "$code" "req-002: exit code is 1 when suites fail"
assert_contains "Feature suites:    1 passed, 1 failed." "$out" "req-002: Feature suites line keeps its wording"
assert_contains "Regression suite:  0 passed, 1 failed." "$out" "req-002: Regression suite line keeps its wording"

echo ""
echo "=== req-002: no heading when every suite passes ==="

PASS_DIR="$(make_fixture passing)"
out=$(bash "$PASS_DIR/run-tests.sh" 2>&1)
code=$?

assert_equals "no" "$([[ "$out" == *"Failed suites:"* ]] && echo yes || echo no)" "req-002: no Failed suites heading when all pass"
assert_equals "0" "$code" "req-002: exit code is 0 when all pass"
assert_contains "Feature suites:    1 passed, 0 failed." "$out" "req-002: passing Feature suites line keeps its wording"

print_summary
