#!/usr/bin/env bash
# Tests for feature 0000020-setup-refresh-skill, req-008:
# install-time-marker-write.
#
# Covers ADR-002: setup.sh writes .claude/.ravintio-setup-flags (generalised to
# <tool-dir>/.ravintio-setup-flags for non-Claude-Code tools, since the marker
# doubles as the refresh skill's retry cache per tool, see ADR-002 and
# src/setup-hook-integration/docs/data-contract.md) on every successful install,
# recording the tool name, flags passed, a timestamp, and attemptStatus: completed.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$SCRIPT_DIR/.."
SETUP_SH="$FRAMEWORK/setup.sh"
SETUP_PS1="$FRAMEWORK/setup.ps1"

file_exists() { [ -f "$1" ] && echo "yes" || echo "no"; }

read_json_field() {
  local file="$1"
  local field="$2"
  python3 -c "
import json
with open('$file') as f:
    data = json.load(f)
val = data.get('$field')
print(json.dumps(val))
" 2>/dev/null
}

make_workspace() {
  local dir
  dir=$(mktemp -d -t ravintio_0000020_req008_test_XXXXXX)
  cp -r "$FRAMEWORK" "$dir/ravintio-framework"
  git init "$dir" >/dev/null 2>&1
  git config --global --add safe.directory "$dir" >/dev/null 2>&1 || true
  echo "$dir"
}

# ── (a): setup.sh writes the marker on a successful install with no flags ───

echo ""
echo "=== (a): setup.sh claude-code (no flags) writes .claude/.ravintio-setup-flags ==="

WS=$(make_workspace); cd "$WS"
bash ravintio-framework/setup.sh claude-code >/dev/null 2>&1
assert_exit_zero $? "(a): setup exits 0"

assert_equals "yes" "$(file_exists ".claude/.ravintio-setup-flags")" \
  "(a): marker file created"

assert_equals '"claude-code"' "$(read_json_field ".claude/.ravintio-setup-flags" "tool")" \
  "(a): tool field is claude-code"

assert_equals "[]" "$(read_json_field ".claude/.ravintio-setup-flags" "flags")" \
  "(a): flags field is empty array when no flags passed"

assert_equals '"completed"' "$(read_json_field ".claude/.ravintio-setup-flags" "attemptStatus")" \
  "(a): attemptStatus is completed after a successful install"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (b): setup.sh records every flag passed ───────────────

echo ""
echo "=== (b): setup.sh claude-code with all flags records them all ==="

WS=$(make_workspace); cd "$WS"
bash ravintio-framework/setup.sh claude-code --strict-orchestrator \
  --include-full-skill-library >/dev/null 2>&1
assert_exit_zero $? "(b): setup exits 0 with all flags"

FLAGS_JSON="$(read_json_field ".claude/.ravintio-setup-flags" "flags")"
assert_contains "--strict-orchestrator" "$FLAGS_JSON" "(b): --strict-orchestrator recorded"
assert_contains "--include-full-skill-library" "$FLAGS_JSON" "(b): --include-full-skill-library recorded"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (c): marker lives under the target tool's own directory, not just .claude/ ──

echo ""
echo "=== (c): setup.sh cursor writes .cursor/.ravintio-setup-flags, not .claude/ ==="

WS=$(make_workspace); cd "$WS"
bash ravintio-framework/setup.sh cursor >/dev/null 2>&1
assert_exit_zero $? "(c): setup exits 0 for cursor"

assert_equals "yes" "$(file_exists ".cursor/.ravintio-setup-flags")" \
  "(c): marker written under .cursor/ for the cursor tool"

assert_equals "no" "$(file_exists ".claude/.ravintio-setup-flags")" \
  "(c): no marker written under .claude/ when only cursor was set up"

assert_equals '"cursor"' "$(read_json_field ".cursor/.ravintio-setup-flags" "tool")" \
  "(c): tool field is cursor"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (d): a failed install does not write or update the marker ───────────────

echo ""
echo "=== (d): a rejected/unknown tool does not write a marker anywhere ==="

WS=$(make_workspace); cd "$WS"
bash ravintio-framework/setup.sh not-a-real-tool >/dev/null 2>&1
UNKNOWN_EXIT=$?
assert_equals "1" "$UNKNOWN_EXIT" "(d): unknown tool exits non-zero"

assert_equals "no" "$(file_exists ".claude/.ravintio-setup-flags")" \
  "(d): no marker file written anywhere for a failed/unknown-tool run"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (e): setup.ps1 defines the same marker-write logic (static source check) ─
# A live pwsh invocation is not run here, this environment has no PowerShell
# runtime available. Parity is checked statically; see quirks.md for the gap.

echo ""
echo "=== (e): setup.ps1 defines Write-SetupFlagsMarker with the matching schema ==="

grep_has() { grep -q "$1" "$2" 2>/dev/null && echo "yes" || echo "no"; }

assert_equals "yes" "$(grep_has 'function Write-SetupFlagsMarker' "$SETUP_PS1")" \
  "(e): setup.ps1 defines Write-SetupFlagsMarker"

assert_equals "yes" "$(grep_has "'.ravintio-setup-flags'" "$SETUP_PS1")" \
  "(e): setup.ps1 writes to the same marker filename as setup.sh"

assert_equals "yes" "$(grep_has 'attemptStatus' "$SETUP_PS1")" \
  "(e): setup.ps1 marker schema includes attemptStatus"

assert_equals "yes" "$(grep_has 'Write-SetupFlagsMarker -ToolName \$ToolName -ToolDir \$toolDir' "$SETUP_PS1")" \
  "(e): setup.ps1 calls the marker writer from inside Invoke-RavintioSetup"

print_summary
