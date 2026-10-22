#!/usr/bin/env bash
# promote-to-regression.sh — promote a test file into the long-term regression pack.
#
# Usage:
#   promote-to-regression.sh <test-file-path> <source-feature-id> <promoted-by>
#
# Arguments:
#   test-file-path    — path to the test file to promote. It must be a
#                       test-*.sh file directly inside planifest-framework/tests/.
#   source-feature-id — feature ID the test originated from (e.g. 0000004-tdd-regression-test-quality)
#   promoted-by       — "agent" or "human"
#
# Idempotent: running twice with the same test file produces no duplicate manifest entries.
#
# Hard Limit 8 sanctioned script (0000035 ADR-011, P5 finding P-S09):
#   - The source must be a regular file named test-*.sh, with one link,
#     whose real path lies directly inside {script dir}/../tests/.
#   - The destination is always {script dir}/../tests/regression/. Neither
#     that folder nor the destination file may be a link.
#   - PLANIFEST_REGRESSION_DIR is refused unless it names that same folder.
#
# Exit codes:
#   0 — success (or already promoted, idempotent)
#   1 — usage error or precondition failure

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
TESTS_DIR="$(cd "$SCRIPT_DIR/../tests" 2>/dev/null && pwd -P)" || { echo "ERROR: tests/ folder not found" >&2; exit 1; }
REGRESSION_DIR="$TESTS_DIR/regression"
MANIFEST="$REGRESSION_DIR/regression-manifest.json"

die() { echo "ERROR: $*" >&2; exit 1; }

# ── Argument validation ───────────────────────────────────────────────────────

[ $# -eq 3 ] || die "Usage: promote-to-regression.sh <test-file-path> <source-feature-id> <promoted-by>"

TEST_FILE="$1"
SOURCE_FEATURE="$2"
PROMOTED_BY="$3"

[ -f "$TEST_FILE" ] || die "Test file not found: $TEST_FILE"

case "$PROMOTED_BY" in
  agent|human) ;;
  *) die "promoted-by must be 'agent' or 'human', got: $PROMOTED_BY" ;;
esac

# ── Destination binding ───────────────────────────────────────────────────────

[ -L "$REGRESSION_DIR" ] && die "tests/regression/ must not be a link"
[ -d "$REGRESSION_DIR" ] || die "tests/regression/ folder not found"
if [ -n "${PLANIFEST_REGRESSION_DIR:-}" ]; then
  OVERRIDE_REAL="$(cd "$PLANIFEST_REGRESSION_DIR" 2>/dev/null && pwd -P)" || OVERRIDE_REAL=""
  [ "$OVERRIDE_REAL" = "$REGRESSION_DIR" ] || die "PLANIFEST_REGRESSION_DIR must name planifest-framework/tests/regression/"
fi

[ -f "$MANIFEST" ] || die "Manifest not found: $MANIFEST"

# ── Source binding ────────────────────────────────────────────────────────────
# The source must be a test-*.sh regular file with one link, directly inside
# tests/. Node checks it with lstat, so a link at the source never passes.

BASENAME="$(basename "$TEST_FILE")"
[[ "$BASENAME" =~ ^test-[A-Za-z0-9._-]+\.sh$ ]] || die "Test file must be named test-*.sh"
SOURCE_DIR="$(cd "$(dirname "$TEST_FILE")" 2>/dev/null && pwd -P)" || die "Test file folder not found"
[ "$SOURCE_DIR" = "$TESTS_DIR" ] || die "Test file must sit directly inside planifest-framework/tests/"
( cd "$TESTS_DIR" && PLANIFEST_BASENAME="$BASENAME" node -e "
const st = require('fs').lstatSync(process.env.PLANIFEST_BASENAME);
process.exit(st.isFile() && !st.isSymbolicLink() && st.nlink === 1 ? 0 : 1);
" 2>/dev/null ) || die "Test file must be a regular file with one link, not a link"
TEST_FILE="$TESTS_DIR/$BASENAME"

# ── Idempotency check ─────────────────────────────────────────────────────────
# cd into REGRESSION_DIR so node.js uses relative paths — avoids POSIX/Windows
# path translation issues on Windows hosts.

DEST="$REGRESSION_DIR/$BASENAME"
[ -L "$DEST" ] && die "Destination must not be a link: tests/regression/$BASENAME"

ALREADY_PROMOTED=false
if ( cd "$REGRESSION_DIR" && PLANIFEST_BASENAME="$BASENAME" node -e "
const fs = require('fs');
const m = JSON.parse(fs.readFileSync('regression-manifest.json', 'utf8'));
const found = (m.tests || []).some(t => t.name === process.env.PLANIFEST_BASENAME);
process.exit(found ? 0 : 1);
" 2>/dev/null ); then
  ALREADY_PROMOTED=true
fi

if [ "$ALREADY_PROMOTED" = "true" ]; then
  echo "INFO: $BASENAME is already in the regression pack — skipping (idempotent)."
  exit 0
fi

# ── Copy test file ────────────────────────────────────────────────────────────

cp "$TEST_FILE" "$DEST" || die "Failed to copy $TEST_FILE to $DEST"

# tests/regression/ sits one directory level deeper than tests/, so any
# $SCRIPT_DIR-relative path a test computed for its original location
# (tests/) now resolves one level short of where it needs to land. Rewrite
# the two known relative-path shapes to add the extra "../" the new depth
# requires. Portable sed via temp-file + mv (no -i, avoids GNU/BSD flag
# differences). A no-op for tests that don't use these patterns.
# Order matters: the "..\" rule must run first. If "helpers/" ran first, its
# own replacement text ("../helpers/") would contain a fresh ".." that the
# second rule would then re-match and double-add, corrupting the path.
sed \
  -e 's|\$SCRIPT_DIR/\.\.|$SCRIPT_DIR/../..|g' \
  -e 's|\$SCRIPT_DIR/helpers/|$SCRIPT_DIR/../helpers/|g' \
  "$DEST" > "$DEST.tmp" && mv "$DEST.tmp" "$DEST" || die "Failed to rewrite relative paths in $DEST"

echo "  copied: $BASENAME → tests/regression/ (relative paths adjusted for one extra directory level)"

# ── Update manifest ───────────────────────────────────────────────────────────

PROMOTION_DATE="$(date +%Y-%m-%d)"
RELATIVE_PATH="tests/regression/$BASENAME"

( cd "$REGRESSION_DIR" && \
  PLANIFEST_BASENAME="$BASENAME" \
  PLANIFEST_SOURCE_FEATURE="$SOURCE_FEATURE" \
  PLANIFEST_PROMOTION_DATE="$PROMOTION_DATE" \
  PLANIFEST_PROMOTED_BY="$PROMOTED_BY" \
  PLANIFEST_FILE_PATH="$RELATIVE_PATH" \
  node -e "
const fs = require('fs');
const e = process.env;
const manifest = JSON.parse(fs.readFileSync('regression-manifest.json', 'utf8'));
if (!Array.isArray(manifest.tests)) { manifest.tests = []; }
manifest.tests.push({
  name: e.PLANIFEST_BASENAME,
  sourceFeature: e.PLANIFEST_SOURCE_FEATURE,
  promotionDate: e.PLANIFEST_PROMOTION_DATE,
  promotedBy: e.PLANIFEST_PROMOTED_BY,
  filePath: e.PLANIFEST_FILE_PATH
});
fs.writeFileSync('regression-manifest.json', JSON.stringify(manifest, null, 2) + '\n');
" ) || die "Failed to update regression manifest"

echo "  manifest updated: $BASENAME promoted by $PROMOTED_BY from $SOURCE_FEATURE on $PROMOTION_DATE"
echo "Promotion complete: $BASENAME"
