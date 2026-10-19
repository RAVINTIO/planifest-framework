#!/usr/bin/env bash
# Static tests for feature 0000031-ci-test-and-powershell-coverage.
#
# req-001: .github/workflows/planifest.yml runs run-tests.sh as an ubuntu and macos matrix.
# req-003: the same file runs test_setup.ps1 under PowerShell 7 on windows-latest.
# ADR-002: the consumer copy at planifest-framework/hooks/planifest.yml stays unchanged.
# ADR-003: the new jobs use read-only permissions, no secrets, and a 10-minute timeout.
#
# No YAML library is available, so the tests extract each job block with awk and grep it.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$FRAMEWORK/.." && pwd)"
WORKFLOW="$REPO_ROOT/.github/workflows/planifest.yml"
CONSUMER_WORKFLOW="$FRAMEWORK/hooks/planifest.yml"

# Prints the lines of one top-level job, from its id line to the next 2-space-indented line.
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
PWSH="$(job_block setup-powershell)"

echo "== req-001: suite job =="
assert_equals "yes" "$([ -n "$SUITE" ] && echo yes || echo no)" "req-001: workflow has a test-suite job"
assert_equals "yes" "$(yes_no 'run:[[:space:]]*bash planifest-framework/tests/run-tests\.sh' "$SUITE")" "req-001: job runs bash planifest-framework/tests/run-tests.sh"
assert_equals "yes" "$(yes_no 'os:.*ubuntu-latest' "$SUITE")" "req-001: matrix os holds ubuntu-latest"
assert_equals "yes" "$(yes_no 'os:.*macos-latest' "$SUITE")" "req-001: matrix os holds macos-latest"
assert_equals "yes" "$(yes_no 'runs-on:[[:space:]]*\$\{\{[[:space:]]*matrix\.os[[:space:]]*\}\}' "$SUITE")" "req-001: job runs on matrix.os"
assert_equals "yes" "$(yes_no 'fail-fast:[[:space:]]*false' "$SUITE")" "req-001: strategy sets fail-fast false"
assert_equals "yes" "$(yes_no 'permissions:' "$SUITE")" "req-001: job sets a permissions block"
assert_equals "yes" "$(yes_no 'contents:[[:space:]]*read' "$SUITE")" "req-001: permissions grant contents read"
assert_equals "yes" "$(yes_no 'timeout-minutes:[[:space:]]*10$' "$SUITE")" "req-001: job sets timeout-minutes 10"
assert_equals "yes" "$(yes_no 'actions/checkout@v4' "$SUITE")" "req-001: job uses actions/checkout@v4"

echo "== req-001/ADR-003: security posture =="
assert_equals "no" "$(yes_no 'secrets\.' "$SUITE$PWSH")" "req-001: new jobs reference no secrets"
assert_equals "no" "$(yes_no 'pull_request_target' "$(cat "$WORKFLOW")")" "req-001: workflow never uses pull_request_target"
assert_equals "yes" "$(yes_no '^  pull_request:' "$(cat "$WORKFLOW")")" "req-001: workflow keeps the pull_request trigger"

echo "== req-001/ADR-002: consumer copy unchanged =="
assert_equals "no" "$(yes_no 'run-tests\.sh' "$(cat "$CONSUMER_WORKFLOW")")" "req-001: consumer workflow does not mention run-tests.sh"
assert_equals "no" "$(yes_no 'test_setup\.ps1' "$(cat "$CONSUMER_WORKFLOW")")" "req-001: consumer workflow does not mention test_setup.ps1"

echo "== req-003: Windows PowerShell job =="
assert_equals "yes" "$([ -n "$PWSH" ] && echo yes || echo no)" "req-003: workflow has a setup-powershell job"
assert_equals "yes" "$(yes_no 'runs-on:[[:space:]]*windows-latest' "$PWSH")" "req-003: job runs on windows-latest"
assert_equals "yes" "$(yes_no 'shell:[[:space:]]*pwsh' "$PWSH")" "req-003: job uses shell pwsh"
assert_equals "yes" "$(yes_no 'planifest-framework/tests/test_setup\.ps1' "$PWSH")" "req-003: job runs test_setup.ps1"
assert_equals "yes" "$(yes_no '\$PSVersionTable\.PSVersion' "$PWSH")" "req-003: job prints PSVersionTable.PSVersion"
assert_equals "yes" "$(yes_no 'Major[[:space:]]*-lt[[:space:]]*7' "$PWSH")" "req-003: job fails when the major version is below 7"
assert_equals "yes" "$(yes_no 'permissions:' "$PWSH")" "req-003: job sets a permissions block"
assert_equals "yes" "$(yes_no 'contents:[[:space:]]*read' "$PWSH")" "req-003: permissions grant contents read"
assert_equals "yes" "$(yes_no 'timeout-minutes:[[:space:]]*10$' "$PWSH")" "req-003: job sets timeout-minutes 10"
assert_equals "yes" "$(yes_no 'actions/checkout@v4' "$PWSH")" "req-003: job uses actions/checkout@v4"

print_summary
