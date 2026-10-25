#!/usr/bin/env bash
# Guard for feature 0000031 (P4 cycle 3).
#
# Under `set -o pipefail`, a printf or echo piped into a quiet grep can fail at
# random. The quiet grep exits at its first match, the writer then gets SIGPIPE, and pipefail reports
# the pipeline as failed. CI on macOS hit this in test-attribution-validation.sh.
# Suites must feed the quiet grep from a here-string or a file instead.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

echo "=== 0000031: no suite pipes printf or echo into grep -q ==="

# Match a printf or echo whose output goes straight into grep -q, -qi, -qF, and
# so on. The pattern is assembled from parts so this file doesn't match itself.
writer='(printf|echo)[^|]*'
reader='grep -q'
offenders=$(grep -lE "${writer}\| *${reader}" "$SCRIPT_DIR"/test-*.sh "$SCRIPT_DIR"/regression/test-*.sh 2>/dev/null | sed "s|$SCRIPT_DIR/||" | tr '\n' ' ')

assert_equals "" "$offenders" "0000031: no suite pipes printf or echo into grep -q (found: ${offenders:-none})"

print_summary
