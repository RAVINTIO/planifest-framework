#!/usr/bin/env bash
# Static tests for feature 0000031 req-004: test_setup.ps1 checks the
# .ravintio-setup-flags marker. pwsh is not needed. The Windows CI job runs
# the PowerShell for real, so this file only confirms the assertions exist.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

TARGET="$SCRIPT_DIR/test_setup.ps1"

yes_no() { if "$@"; then echo "yes"; else echo "no"; fi; }
has() { grep -qF -- "$1" "$TARGET" 2>/dev/null; }

echo "req-004: setup-flags marker assertions in test_setup.ps1"

assert_equals "yes" "$(yes_no has '.ravintio-setup-flags')" \
  "req-004: reads the .ravintio-setup-flags marker"
assert_equals "yes" "$(yes_no has 'ConvertFrom-Json')" \
  "req-004: parses the marker with ConvertFrom-Json"
assert_equals "yes" "$(yes_no has 'function Assert-SetupFlagsMarker')" \
  "req-004: defines the Assert-SetupFlagsMarker helper"
assert_equals "yes" "$(yes_no has '$marker.tool')" \
  "req-004: checks the tool field"
assert_equals "yes" "$(yes_no has "-ExpectedTool 'claude-code'")" \
  "req-004: expects tool equal to claude-code"
assert_equals "yes" "$(yes_no has '-ExpectedFlags @()')" \
  "req-004: expects an empty flags array after the plain run"
assert_equals "yes" "$(yes_no has "-ExpectedFlags @('--include-full-skill-library')")" \
  "req-004: expects exactly --include-full-skill-library after the flagged run"
assert_equals "yes" "$(yes_no has '@($marker.flags)')" \
  "req-004: compares flags as an array so one-item arrays do not unroll"
assert_equals "yes" "$(yes_no has '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$')" \
  "req-004: matches writtenAt against yyyy-MM-ddTHH:mm:ssZ"
assert_equals "yes" "$(yes_no has "'completed'")" \
  "req-004: expects attemptStatus equal to completed"
assert_equals "yes" "$(yes_no has '"flags"\s*:\s*\[')" \
  "req-004: raw-text check that flags is a JSON array literal"
assert_equals "yes" "$(yes_no has 'FAIL: setup-flags marker')" \
  "req-004: failures throw FAIL messages naming the field and value"

# The helper must be defined before its first call and called twice.
def_line=$(grep -nF 'function Assert-SetupFlagsMarker' "$TARGET" | head -1 | cut -d: -f1)
first_call=$(grep -nE '^\s+Assert-SetupFlagsMarker ' "$TARGET" | head -1 | cut -d: -f1)
call_count=$(grep -cE '^\s+Assert-SetupFlagsMarker ' "$TARGET")
order="no"
if [ -n "$def_line" ] && [ -n "$first_call" ] && [ "$def_line" -lt "$first_call" ]; then order="yes"; fi
assert_equals "yes" "$order" "req-004: helper is defined before its first call"
assert_equals "2" "$call_count" "req-004: helper is called after the plain and flagged runs"

# Negative cases: broken markers must make the helper throw (acceptance criterion 2).
assert_equals "yes" "$(yes_no has 'function Assert-MarkerRejected')" \
  "req-004: defines a helper that expects a broken marker to be rejected"
assert_equals "yes" "$(yes_no has "Assert-MarkerRejected -Case 'invalid JSON'")" \
  "req-004: rejects a marker that is not valid JSON"
assert_equals "yes" "$(yes_no has "Assert-MarkerRejected -Case 'missing field'")" \
  "req-004: rejects a marker with a missing field"
assert_equals "yes" "$(yes_no has "Assert-MarkerRejected -Case 'flags as a string'")" \
  "req-004: rejects a marker whose flags field is a string"

print_summary
