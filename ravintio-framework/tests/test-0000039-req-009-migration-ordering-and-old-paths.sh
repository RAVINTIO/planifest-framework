#!/usr/bin/env bash
# Tests for feature 0000039-ravintio-rebrand.
#
# req-009: the migrator runs older migrations against the new paths, confirms
#          the rename migration with a check pass, and skips a migration whose
#          `Applies when:` condition is false (ADR-006).
#   AC1: file-name order, the old-to-new path mapping, and no reads inside
#        .ravintio-backup/.
#   AC2: the check pass for migrate-0.37.0-ravintio-rename.md, and the
#        `Applies when:` line naming old pack, old overrides, and backup.
#   AC3: the skip rule, the orchestrator's skip report, and this repo's
#        `not applicable` record.
#
# The migrator is a skill, so these checks read its text and the records.
# Verified by: integration

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$FRAMEWORK/.." && pwd)"
MIGRATOR="$FRAMEWORK/skills/ravintio-migrator/SKILL.md"
ORCH="$FRAMEWORK/skills/ravintio-orchestrator/SKILL.md"
RENAME_STEM="migrate-0.37.0-ravintio-rename"
RENAME="$FRAMEWORK/migrations/$RENAME_STEM.md"
RECORD="$REPO/plan/_migrations/$RENAME_STEM.md"

MIG_TEXT="$(cat "$MIGRATOR" 2>/dev/null || true)"
ORCH_TEXT="$(cat "$ORCH" 2>/dev/null || true)"
RENAME_TEXT="$(cat "$RENAME" 2>/dev/null || true)"
RECORD_TEXT="$(cat "$RECORD" 2>/dev/null || true)"

# has <label> <text> <ERE>: pass when the text matches the pattern.
has() {
  local label="$1" text="$2" re="$3"
  if grep -Eiq -- "$re" <<< "$text"; then
    echo "  PASS: $label"
    ((PASS++)) || true
  else
    echo "  FAIL: $label"
    echo "        pattern: $re"
    ((FAIL++)) || true
  fi
}

# --- AC1: ordering, path mapping, backup never read -------------------------
echo "AC1: ordering and old paths"
has "req-009 AC1: migrator states file-name order" "$MIG_TEXT" 'file-name order'
has "req-009 AC1: migrator maps planifest-framework/ to ravintio-framework/" "$MIG_TEXT" 'planifest-framework/.{0,40}(as|to|with).{0,20}ravintio-framework/'
has "req-009 AC1: migrator maps planifest-overrides/ to ravintio-overrides/" "$MIG_TEXT" 'planifest-overrides/.{0,40}(as|to|with).{0,20}ravintio-overrides/'
has "req-009 AC1: migrator applies the mapping to shipped pre-0.37.0 migrations" "$MIG_TEXT" '(shipped|before|pre-?)[^.]{0,60}0\.37\.0'
has "req-009 AC1: migrator never reads inside .ravintio-backup/" "$MIG_TEXT" 'never[^.]{0,60}\.ravintio-backup/'

# --- AC2: check pass and Applies when line ----------------------------------
echo "AC2: rename check pass"
has "req-009 AC2: migrator names the rename migration" "$MIG_TEXT" 'migrate-0\.37\.0-ravintio-rename\.md'
has "req-009 AC2: migrator describes a check pass" "$MIG_TEXT" 'check pass'
has "req-009 AC2: check pass reruns the helper as a no-op" "$MIG_TEXT" '(helper[^.]{0,80}(again|rerun|re-run)|(again|rerun|re-run)[^.]{0,80}helper)'
has "req-009 AC2: check pass records applied" "$MIG_TEXT" 'check pass[^.]{0,200}applied|applied[^.]{0,200}check pass'
if [ -f "$RENAME" ]; then
  echo "  PASS: req-009 AC2: the rename migration file exists"
  ((PASS++)) || true
else
  echo "  FAIL: req-009 AC2: the rename migration file exists at $RENAME"
  ((FAIL++)) || true
fi
APPLIES_LINE="$(grep -E '^\*\*Applies when:\*\*' <<< "$RENAME_TEXT" | head -n 1 || true)"
has "req-009 AC2: the rename migration has an Applies when line" "$APPLIES_LINE" 'Applies when:'
has "req-009 AC2: Applies when names the old pack folder" "$APPLIES_LINE" 'planifest-framework/'
has "req-009 AC2: Applies when names the old overrides folder" "$APPLIES_LINE" 'planifest-overrides/'
has "req-009 AC2: Applies when names the backup folder" "$APPLIES_LINE" '\.ravintio-backup/'

# --- AC3: skip rule, orchestrator report, this repo's record ----------------
echo "AC3: Applies when skip rule"
has "req-009 AC3: migrator reads the Applies when line" "$MIG_TEXT" '\*\*Applies when:\*\*'
has "req-009 AC3: migrator reports Skipped:" "$MIG_TEXT" 'Skipped:'
MIG_FLAT="${MIG_TEXT//$'\n'/ }"
has "req-009 AC3: migrator records not applicable on a false condition" "$MIG_FLAT" 'Applies when.{0,250}not applicable'
has "req-009 AC3: migrator skips Steps 2 to 4 on a false condition" "$MIG_FLAT" 'Applies when.{0,250}Steps 2 to 4'
has "req-009 AC3: orchestrator reports skipped migrations" "$ORCH_TEXT" 'Applies when|skipped migration|migration[^.]{0,40}skip'
has "req-009 AC3: orchestrator does not skip silently" "$ORCH_TEXT" '(not|never)[^.]{0,30}silent|reports?[^.]{0,60}skip'

if [ -f "$RECORD" ]; then
  echo "  PASS: req-009 AC3: this repo holds the rename migration record"
  ((PASS++)) || true
else
  echo "  FAIL: req-009 AC3: this repo holds the rename migration record at $RECORD"
  ((FAIL++)) || true
fi
fm_value() {
  awk -v key="$1" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    NR > 1 { i = index($0, ":"); if (i > 0 && substr($0, 1, i - 1) == key) {
      v = substr($0, i + 1); sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      gsub(/^"|"$/, "", v); print v; exit } }
  ' <<< "$RECORD_TEXT"
}
assert_equals "not applicable" "$(fm_value outcome)" "req-009 AC3: record outcome is not applicable"
assert_equals "$RENAME_STEM.md" "$(fm_value migration)" "req-009 AC3: record migration equals the file name"
DATE_V="$(fm_value date)"
if [[ "$DATE_V" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then R=ok; else R="bad: $DATE_V"; fi
assert_equals "ok" "$R" "req-009 AC3: record date is YYYY-MM-DD"
assert_equals "0" "$(fm_value corrections-applied)" "req-009 AC3: record corrections-applied is 0"
assert_equals "0" "$(fm_value corrections-skipped)" "req-009 AC3: record corrections-skipped is 0"

print_summary
