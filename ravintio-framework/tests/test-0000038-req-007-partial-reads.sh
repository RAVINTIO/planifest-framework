#!/usr/bin/env bash
# Tests for feature 0000038-token-efficiency-windows-shard.
#
# req-007: the boot template gains one directive. For a file over about 20 KB,
#          search it or read the section you need with an offset and a limit.
#          The directive removes or softens no existing rule. Setup carries it
#          into the generated boot file.
#
# Verified by: unit
# Verified by: integration

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
STANDARD="$FRAMEWORK/templates/standard-boot.md"
# md5 of standard-boot.md before req-007 (6,112 bytes).
BASELINE_MD5="aa241e52bca637c83bc87fd01c16351a"

WORK="$(mktemp -d -t ravintio_0000038_req007_XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

# directive_lines <file>: the lines that name the 20 KB threshold.
directive_lines() {
  grep -F -- "20 KB" "$1" 2>/dev/null || true
}

md5_of() {
  if command -v md5sum >/dev/null 2>&1; then md5sum | cut -d' ' -f1; else md5 -q; fi
}

echo ""
echo "=== req-007: standard-boot.md directive (AC-007.1) ==="

LINES="$(directive_lines "$STANDARD")"
COUNT="$(printf '%s' "$LINES" | grep -c . || true)"
assert_equals "1" "$COUNT" "req-007: exactly one line names the 20 KB threshold"
assert_contains "offset" "$LINES" "req-007: the directive names an offset read"
assert_contains "limit" "$LINES" "req-007: the directive names a limit"
assert_contains "search" "$LINES" "req-007: the directive names searching"

echo ""
echo "=== req-007: no other line changes (AC-007.3) ==="

REST_MD5="$(grep -vF -- "20 KB" "$STANDARD" | md5_of)"
assert_equals "$BASELINE_MD5" "$REST_MD5" "req-007: every other line matches the pre-change template"

echo ""
echo "=== req-007: setup carries the directive into CLAUDE.md (AC-007.2) ==="

WS="$WORK/ws"
mkdir -p "$WS"
cp -r "$FRAMEWORK" "$WS/ravintio-framework"
git init "$WS" >/dev/null 2>&1
(cd "$WS" && bash ravintio-framework/setup.sh claude-code > "$WORK/setup.log" 2>&1)
assert_exit_zero "$?" "req-007: setup.sh claude-code exits 0"
assert_equals "$LINES" "$(directive_lines "$WS/CLAUDE.md" | head -1)" \
  "req-007: generated CLAUDE.md holds the directive"

print_summary
