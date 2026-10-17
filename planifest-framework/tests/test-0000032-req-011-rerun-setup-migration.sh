#!/usr/bin/env bash
# Tests for feature 0000032-governance-continuity-and-write-gate-scope.
#
# req-011: a 0.31.0 migration tells downstream projects to re-run setup, so
#          they gain the Bash shell-write guard and the stderr block reasons.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
MIGRATION="$FRAMEWORK/migrations/migrate-0.31.0-rerun-setup-for-shell-write-guard.md"
DONE_COPY="$FRAMEWORK/migrations/_done/migrate-0.31.0-rerun-setup-for-shell-write-guard.md"

echo ""
echo "=== req-011: the migration file is pending ==="

assert_equals "yes" "$([ -f "$MIGRATION" ] && echo yes || echo no)" "req-011: the 0.31.0 migration exists in migrations/"
assert_equals "no" "$([ -f "$DONE_COPY" ] && echo yes || echo no)" "req-011: the migration isn't archived in _done/"

SRC="$(cat "$MIGRATION" 2>/dev/null || true)"

echo ""
echo "=== req-011: the migration follows the migration layout ==="

assert_contains "# Migration:" "$SRC" "req-011: the migration has a title"
assert_contains "**Target:**" "$SRC" "req-011: the header block names a target"
assert_contains "**Safe to skip:**" "$SRC" "req-011: the header block says whether it's safe to skip"
for section in "## Background" "## What This Migration Does" "## Migrator Instructions" "## Archive"; do
  assert_contains "$section" "$SRC" "req-011: the migration has the section: $section"
done

echo ""
echo "=== req-011: the migration names the version, the hook, and the re-run ==="

assert_contains "0.31.0" "$SRC" "req-011: the migration names version 0.31.0"
assert_contains "shell-write-guard" "$SRC" "req-011: the migration names shell-write-guard"
assert_contains "Re-run setup" "$SRC" "req-011: the migration says to re-run setup"
assert_contains "planifest-refresh-setup" "$SRC" "req-011: the migration points to planifest-refresh-setup"
assert_contains "exactly one" "$SRC" "req-011: the migration checks for exactly one Bash group"
assert_contains "_done/" "$SRC" "req-011: the migration says to archive to _done/"

BACKGROUND="${SRC#*## Background}"
BACKGROUND="${BACKGROUND%%## What This Migration Does*}"
assert_contains "Bash" "$BACKGROUND" "req-011: the Background names the Bash hook"
assert_contains "stderr" "$BACKGROUND" "req-011: the Background names the stderr block reasons"

print_summary
