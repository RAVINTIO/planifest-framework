#!/usr/bin/env bash
# Static tests for feature 0000037-green-ci-before-ship, req-011: Windows PowerShell coverage.
#
# Verified by: integration
# Verified by: e2e
#
# req-011 (integration): the workflow holds a setup-powershell-51 job (ADR-012), and
#   test_setup.ps1 text holds the stale seed, the flag run, and the four assertions.
# req-011 (e2e): the live run of test_setup.ps1 happens in the PowerShell 7 and 5.1 CI
#   jobs. This suite only checks that both jobs run that file.
#
# No YAML library is available, so the tests extract each job block with awk and grep it.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$FRAMEWORK/.." && pwd)"
WORKFLOW="$REPO_ROOT/.github/workflows/ravintio.yml"
CONSUMER_WORKFLOW="$FRAMEWORK/hooks/ravintio.yml"
TEST_PS1="$SCRIPT_DIR/test_setup.ps1"
SETUP_PS1="$FRAMEWORK/setup.ps1"

job_block() {
  awk -v id="  $1:" '
    $0 == id { on = 1; print; next }
    on && /^  [^ ]/ { exit }
    on { print }
  ' "$WORKFLOW"
}

has() { grep -Eq -- "$1" <<<"$2"; }
yes_no() { if has "$1" "$2"; then echo "yes"; else echo "no"; fi; }

J51="$(job_block setup-powershell-51)"
J7="$(job_block setup-powershell)"
PS1_TEXT="$(cat "$TEST_PS1")"

echo "== req-011: setup-powershell-51 job =="
assert_equals "yes" "$([ -n "$J51" ] && echo yes || echo no)" "req-011: workflow has a setup-powershell-51 job"
assert_equals "yes" "$(yes_no 'runs-on:[[:space:]]*windows-latest' "$J51")" "req-011: job runs on windows-latest"
assert_equals "yes" "$(yes_no 'shell:[[:space:]]*powershell$' "$J51")" "req-011: job uses shell powershell"
assert_equals "no" "$(yes_no 'shell:[[:space:]]*pwsh' "$J51")" "req-011: job does not use shell pwsh"
assert_equals "yes" "$(yes_no 'ravintio-framework/tests/test_setup\.ps1' "$J51")" "req-011: job runs test_setup.ps1"
assert_equals "yes" "$(yes_no '\$PSVersionTable\.PSVersion' "$J51")" "req-011: job prints PSVersionTable.PSVersion"
assert_equals "yes" "$(yes_no 'Major[[:space:]]*-ne[[:space:]]*5' "$J51")" "req-011: job fails unless the major version is 5"
assert_equals "yes" "$(yes_no 'permissions:' "$J51")" "req-011: job sets a permissions block"
assert_equals "yes" "$(yes_no 'contents:[[:space:]]*read' "$J51")" "req-011: permissions grant contents read"
assert_equals "yes" "$(yes_no 'timeout-minutes:[[:space:]]*10$' "$J51")" "req-011: job sets timeout-minutes 10"
assert_equals "yes" "$(yes_no 'actions/checkout@v4' "$J51")" "req-011: job uses actions/checkout@v4"
assert_equals "no" "$(yes_no 'secrets\.' "$J51")" "req-011: job references no secrets"
assert_equals "yes" "$(yes_no 'Setup under Windows PowerShell 5\.1' "$J51")" "req-011: job name is Setup under Windows PowerShell 5.1"
assert_equals "yes" "$(yes_no 'repository-only' "$(grep -B6 '^  setup-powershell-51:' "$WORKFLOW")")" "req-011: a comment above the job says it is repository-only"

echo "== req-011: existing PowerShell 7 job unchanged =="
assert_equals "yes" "$(yes_no 'shell:[[:space:]]*pwsh' "$J7")" "req-011: setup-powershell keeps shell pwsh"
assert_equals "yes" "$(yes_no 'Major[[:space:]]*-lt[[:space:]]*7' "$J7")" "req-011: setup-powershell keeps its PowerShell 7 check"

echo "== req-011: consumer copy unchanged =="
assert_equals "no" "$(yes_no 'setup-powershell-51|test_setup\.ps1' "$(cat "$CONSUMER_WORKFLOW")")" "req-011: consumer workflow does not mention the 5.1 job"

# BEGIN retired-integrations (0000037 req-011 checks on the 0000030 clean-up fixtures)
echo "== req-011: test_setup.ps1 clean-up section =="
assert_equals "yes" "$(yes_no 'hooks[\\/]telemetry' "$PS1_TEXT")" "req-011: seeds the stale hook folder .claude/hooks/telemetry"
assert_equals "yes" "$(yes_no 'context-mode' "$PS1_TEXT")" "req-011: seeds a stale context-mode settings.json entry"
assert_equals "yes" "$(yes_no 'block-grep\.mjs' "$PS1_TEXT")" "req-011: stale entry is the context-mode Grep hook command"
assert_equals "yes" "$(yes_no 'hand-added' "$PS1_TEXT")" "req-011: seeds a hand-added hook"
assert_equals "yes" "$(yes_no 'setup\.ps1 claude-code --context-mode-mcp' "$PS1_TEXT")" "req-011: runs setup.ps1 claude-code --context-mode-mcp"
assert_equals "yes" "$(yes_no 'LASTEXITCODE|\$\?' "$PS1_TEXT")" "req-011: asserts the exit code"
assert_equals "yes" "$(yes_no -- '--context-mode-mcp was removed in 0\.29\.0 and has no effect' "$PS1_TEXT")" "req-011: asserts the notice substring"
assert_equals "yes" "$(yes_no 'exactly one|Count -ne 1' "$PS1_TEXT")" "req-011: asserts exactly one notice line"
assert_equals "yes" "$(yes_no 'FAIL: req-011' "$PS1_TEXT")" "req-011: failure messages name req-011"
# END retired-integrations
assert_equals "yes" "$(yes_no 'FAIL: req-011: .*ravintio-setup-flags' "$PS1_TEXT")" "req-011: checks .ravintio-setup-flags for the retired flag"
assert_equals "yes" "$(yes_no 'FAIL: req-011: .*(stale|survive|hand-added)' "$PS1_TEXT")" "req-011: asserts the clean-up and the surviving hook"

echo "== req-011: setup.ps1 runs under Windows PowerShell 5.1 =="
assert_equals "no" "$(yes_no '`u\{' "$(cat "$SETUP_PS1")")" "req-011: setup.ps1 has no backtick-u escape (PowerShell 6+ only)"
# ConvertFrom-Json -AsHashtable exists only in PowerShell 6+. Code lines must not call it.
SETUP_CODE="$(grep -vE '^[[:space:]]*#' "$SETUP_PS1")"
assert_equals "no" "$(yes_no 'ConvertFrom-Json[^|]*-AsHashtable' "$SETUP_CODE")" "req-011: setup.ps1 never calls ConvertFrom-Json -AsHashtable (PowerShell 6+ only)"
assert_equals "yes" "$(yes_no 'function ConvertTo-RavintioHashtable' "$SETUP_CODE")" "req-011: setup.ps1 defines the PSCustomObject-to-hashtable converter"
assert_equals "yes" "$(yes_no 'ConvertTo-RavintioHashtable -InputObject' "$(sed -n '/^function Merge-AllowedTools/,/^}/p' "$SETUP_PS1")")" "req-011: Merge-AllowedTools uses the converter"
assert_equals "no" "$(yes_no '\?\?|\?\.|-Parallel|-AsPlainText|\$Is(Windows|Linux|MacOS)\b' "$SETUP_CODE")" "req-011: setup.ps1 uses no other PowerShell 6+ only syntax (?? ?. -Parallel \$IsWindows)"

echo "== req-011: native stderr never stops setup under 5.1 =="
# Windows PowerShell 5.1 turns native stderr into a terminating error when
# $ErrorActionPreference is Stop. In a non-git fixture, git config writes
# "fatal: not in a git directory", so the call must relax the preference first.
GUARD_FN="$(sed -n '/^function Invoke-RavintioGuardrails/,/^}/p' "$SETUP_PS1")"
GIT_LINE_NO="$(grep -nE '^[[:space:]]*git config core\.hooksPath' <<<"$GUARD_FN" | head -1 | cut -d: -f1)"
BEFORE_GIT="$(head -n "${GIT_LINE_NO:-0}" <<<"$GUARD_FN")"
assert_equals "yes" "$([ -n "$GIT_LINE_NO" ] && echo yes || echo no)" "req-011: guardrails function still runs git config core.hooksPath"
assert_equals "yes" "$(yes_no "ErrorActionPreference[[:space:]]*=[[:space:]]*'Continue'" "$BEFORE_GIT")" "req-011: guardrails relax ErrorActionPreference before the native git call"
assert_equals "yes" "$(yes_no 'finally' "$GUARD_FN")" "req-011: guardrails restore ErrorActionPreference in a finally block"
assert_equals "yes" "$(yes_no 'git config core\.hooksPath ravintio-framework/hooks[[:space:]]+2>&1' "$GUARD_FN")" "req-011: git config merges stderr so it never reaches the error stream"

echo "== req-011: a failed git config warns and skips the success lines (security review F-02) =="
assert_equals "yes" "$(yes_no 'LASTEXITCODE' "$GUARD_FN")" "req-011: guardrails read LASTEXITCODE after git config"
assert_equals "yes" "$(yes_no 'LASTEXITCODE[[:space:]]+-ne[[:space:]]+0' "$GUARD_FN")" "req-011: guardrails test for a non-zero git config exit"
assert_equals "yes" "$(yes_no '! Warning: could not set core\.hooksPath, the commit-msg hook is not active' "$GUARD_FN")" "req-011: the warning is true for any cause, not only a missing repository"
assert_equals "no" "$(yes_no 'not in a git repository' "$GUARD_FN")" "req-011: the warning does not name one cause"
# N-05: a stale LASTEXITCODE must not read as success when git is absent.
RESET_LINE="$(grep -nE 'LASTEXITCODE[[:space:]]*=[[:space:]]*0' <<<"$GUARD_FN" | head -1 | cut -d: -f1)"
assert_equals "yes" "$([ -n "$RESET_LINE" ] && [ -n "$GIT_LINE_NO" ] && [ "$RESET_LINE" -lt "$GIT_LINE_NO" ] && echo yes || echo no)" "req-011: LASTEXITCODE is reset before git config runs"
assert_equals "yes" "$(yes_no 'Get-Command git' "$GUARD_FN")" "req-011: guardrails check git exists before reading its exit code"
# The success lines must sit in the else branch of the exit-code test.
HOOKS_OK_LINE="$(grep -n '+ git config core\.hooksPath' <<<"$GUARD_FN" | head -1 | cut -d: -f1)"
EXIT_TEST_LINE="$(grep -n 'LASTEXITCODE' <<<"$GUARD_FN" | head -1 | cut -d: -f1)"
assert_equals "yes" "$([ -n "$EXIT_TEST_LINE" ] && [ -n "$HOOKS_OK_LINE" ] && [ "$EXIT_TEST_LINE" -lt "$HOOKS_OK_LINE" ] && echo yes || echo no)" "req-011: the exit-code test comes before the core.hooksPath success line"
assert_equals "yes" "$(yes_no 'Git guardrails activated' "$GUARD_FN")" "req-011: guardrails still print the activated line when git config succeeds"
assert_equals "yes" "$(yes_no 'hooksActive|\$hooksPathSet' "$GUARD_FN")" "req-011: the activated line depends on a recorded git config result"

echo "== req-011: architecture overview names the 5.1 runtime and job =="
DOC_TEXT="$(cat "$REPO_ROOT/docs/architecture-overview.md")"
assert_equals "yes" "$(yes_no 'setup-powershell-51' "$DOC_TEXT")" "req-011: the architecture overview lists the setup-powershell-51 job"
assert_equals "yes" "$(yes_no 'Windows PowerShell 5\.1 is a supported runtime' "$DOC_TEXT")" "req-011: the architecture overview names 5.1 as a supported runtime"
assert_equals "no" "$(yes_no 'Windows PowerShell 5\.1 has no CI coverage' "$DOC_TEXT")" "req-011: the architecture overview drops the old no-coverage line"

print_summary
