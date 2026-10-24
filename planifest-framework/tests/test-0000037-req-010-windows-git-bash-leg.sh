#!/usr/bin/env bash
# Static tests for feature 0000037-green-ci-before-ship, req-010: Windows Git Bash leg.
#
# Verified by: integration
#
# req-010: the test-suite job adds windows-latest with shell bash (ADR-013, ADR-014).
# req-010: the job keeps fail-fast false, contents read, no secrets, and the pull_request trigger.
# req-010: the consumer workflow at planifest-framework/hooks/planifest.yml has no mention of the leg.
# req-010: the skip table in planifest-framework/tests/README.md exists with its header row.
#
# Cap rule (ADR-014): the first pass keeps timeout-minutes 10. If P3 measures a
# Git Bash run over 10 minutes, the job uses the expression named in WINDOWS_CAP_EXPR
# and this suite expects that expression instead.
#
# No YAML library is available, so the tests extract each job block with awk and grep it.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$FRAMEWORK/.." && pwd)"
WORKFLOW="$REPO_ROOT/.github/workflows/planifest.yml"
CONSUMER_WORKFLOW="$FRAMEWORK/hooks/planifest.yml"
TESTS_README="$SCRIPT_DIR/README.md"

# Set to "20" when ADR-014 decision 2 applies. Leave "10" until P3 measures.
CAP_BRANCH="10"
WINDOWS_CAP_EXPR="\\\$\\{\\{ matrix\\.os == 'windows-latest' && 20 \\|\\| 10 \\}\\}"

job_block() {
  awk -v id="  $1:" '
    $0 == id { on = 1; print; next }
    on && /^  [^ ]/ { exit }
    on { print }
  ' "$WORKFLOW"
}

has() { grep -Eq -- "$1" <<<"$2"; }
yes_no() { if has "$1" "$2"; then echo "yes"; else echo "no"; fi; }

SUITE="$(job_block test-suite)"

echo "== req-010: matrix and shell =="
assert_equals "yes" "$([ -n "$SUITE" ] && echo yes || echo no)" "req-010: workflow has a test-suite job"
assert_equals "yes" "$(yes_no 'os:.*windows-latest' "$SUITE")" "req-010: matrix os holds windows-latest"
assert_equals "yes" "$(yes_no 'os:.*ubuntu-latest' "$SUITE")" "req-010: matrix os still holds ubuntu-latest"
assert_equals "yes" "$(yes_no 'os:.*macos-latest' "$SUITE")" "req-010: matrix os still holds macos-latest"
assert_equals "yes" "$(yes_no 'shell:[[:space:]]*bash' "$SUITE")" "req-010: the run step sets shell bash"
assert_equals "yes" "$(yes_no 'run:[[:space:]]*bash planifest-framework/tests/run-tests\.sh' "$SUITE")" "req-010: the step runs bash planifest-framework/tests/run-tests.sh"

echo "== req-010: job posture =="
assert_equals "yes" "$(yes_no 'fail-fast:[[:space:]]*false' "$SUITE")" "req-010: strategy keeps fail-fast false"
assert_equals "yes" "$(yes_no 'contents:[[:space:]]*read' "$SUITE")" "req-010: permissions keep contents read"
if [ "$CAP_BRANCH" = "20" ]; then
  assert_equals "yes" "$(yes_no "timeout-minutes:[[:space:]]*$WINDOWS_CAP_EXPR\$" "$SUITE")" "req-010: job uses the 20-minute windows expression (ADR-014)"
else
  assert_equals "yes" "$(yes_no 'timeout-minutes:[[:space:]]*10$' "$SUITE")" "req-010: job keeps timeout-minutes 10 (ADR-014, 10 branch)"
fi
assert_equals "no" "$(yes_no 'secrets\.' "$SUITE")" "req-010: job references no secrets"
assert_equals "yes" "$(yes_no '^  pull_request:' "$(cat "$WORKFLOW")")" "req-010: workflow keeps the pull_request trigger"
assert_equals "no" "$(yes_no 'pull_request_target' "$(cat "$WORKFLOW")")" "req-010: workflow never uses pull_request_target"

echo "== req-010: consumer copy unchanged =="
assert_equals "no" "$(yes_no 'windows-latest' "$(cat "$CONSUMER_WORKFLOW")")" "req-010: consumer workflow does not mention windows-latest"
assert_equals "no" "$(yes_no 'run-tests\.sh' "$(cat "$CONSUMER_WORKFLOW")")" "req-010: consumer workflow does not mention run-tests.sh"

echo "== req-010: skip table =="
assert_equals "yes" "$(yes_no '^## Windows skip table' "$(cat "$TESTS_README")")" "req-010: tests README has a Windows skip table section"
assert_equals "yes" "$(yes_no '^\|[[:space:]]*Suite[[:space:]]*\|[[:space:]]*Reason[[:space:]]*\|[[:space:]]*Date[[:space:]]*\|' "$(cat "$TESTS_README")")" "req-010: skip table has Suite, Reason, and Date columns"

print_summary
