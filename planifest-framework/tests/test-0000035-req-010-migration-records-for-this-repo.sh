#!/usr/bin/env bash
# Tests for feature 0000035-write-gate-scope-and-path-hardening.
#
# req-010: this repo holds a readable run record in plan/_migrations/ for each
#          of its nine migrations, from a scan run here (ADR-019). The two
#          downstream-only migrations hold `not applicable`, and each body names
#          the reason. A migration whose scan has findings holds no record, and
#          the build log holds an `Exception waiting (P3, human review)` line.
#
# These are facts about the framework source repo, so the suite skips in a
# project that doesn't hold feature 0000035's plan.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$FRAMEWORK/.." && pwd)"
MIGRATIONS="$FRAMEWORK/migrations"
RECORDS="$REPO/plan/_migrations"

# The markers keep the 0000030 residue check off this migration file name.
# BEGIN retired-integrations
DOWNSTREAM_ONLY=(
  migrate-0.31.0-rerun-setup-for-shell-write-guard.md
  migrate-remove-context-mode-and-telemetry.md
)
# END retired-integrations

# 0000036 req-001: the end-of-P6 setup run writes this record (ADR-007). Until
# then the migration has no record and no exception line, so the check skips.
RUN_AT_END_OF_P6="migrate-0.34.0-rerun-setup.md"

# The build log moves to plan/_archive/ at P7, so read whichever exists.
BUILD_LOGS=()
[ -f "$REPO/plan/current/build-log.md" ] && grep -q '0000035-write-gate-scope-and-path-hardening' "$REPO/plan/current/build-log.md" \
  && BUILD_LOGS+=("$REPO/plan/current/build-log.md")
for f in "$REPO"/plan/_archive/0000035-write-gate-scope-and-path-hardening*/build-log.md; do
  [ -f "$f" ] && BUILD_LOGS+=("$f")
done

if [ "${#BUILD_LOGS[@]}" -eq 0 ]; then
  echo "  SKIP: req-010: no feature 0000035 build log, so this isn't the framework source repo"
  print_summary
fi

BUILD_LOG_TEXT="$(cat "${BUILD_LOGS[@]}")"

# frontmatter_value <file> <key>: the unquoted value of a frontmatter key, or empty.
frontmatter_value() {
  awk -v key="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    NR > 1 {
      i = index($0, ":")
      if (i > 0 && substr($0, 1, i - 1) == key) {
        v = substr($0, i + 1)
        sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
        if (v ~ /^".*"$/) v = substr(v, 2, length(v) - 2)
        print v
        exit
      }
    }' "$1"
}

# frontmatter_closed <file>: yes when the file opens and closes a frontmatter block.
frontmatter_closed() {
  awk 'NR == 1 && $0 != "---" { exit }
       NR > 1 && $0 == "---" { closed = 1; exit }
       END { print (closed ? "yes" : "no") }' "$1"
}

# is_downstream_only <name>: yes when the migration is one of the two.
is_downstream_only() {
  local d
  for d in "${DOWNSTREAM_ONLY[@]}"; do
    [ "$d" = "$1" ] && { echo yes; return; }
  done
  echo no
}

# =============================================================================
echo ""
echo "=== req-010 AC-010.1 and AC-010.3: each migration holds a readable record or a waiting exception ==="

COUNT=0
for path in "$MIGRATIONS"/*.md; do
  [ -f "$path" ] || continue
  COUNT=$((COUNT + 1))
  name="$(basename "$path")"
  stem="${name%.md}"
  record="$RECORDS/$stem.md"
  exception_line="Exception waiting (P3, human review): $name:"

  if [ -f "$record" ]; then
    assert_equals "yes" "$(frontmatter_closed "$record")" "req-010: $stem.md has a closed YAML frontmatter block"
    assert_equals "$name" "$(frontmatter_value "$record" migration)" "req-010: $stem.md names its migration"
    outcome="$(frontmatter_value "$record" outcome)"
    case "$outcome" in
      applied|"not applicable"|skipped) assert_equals "ok" "ok" "req-010: $stem.md holds a valid outcome ($outcome)" ;;
      *) assert_equals "applied, not applicable, or skipped" "$outcome" "req-010: $stem.md holds a valid outcome" ;;
    esac
    date_value="$(frontmatter_value "$record" date)"
    assert_equals "yes" "$([[ "$date_value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && echo yes || echo no)" \
      "req-010: $stem.md holds a YYYY-MM-DD date"
    assert_equals "yes" "$([[ "$(frontmatter_value "$record" framework-version)" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && echo yes || echo no)" \
      "req-010: $stem.md holds a framework-version"
    for count_key in corrections-applied corrections-skipped; do
      assert_equals "yes" "$([[ "$(frontmatter_value "$record" "$count_key")" =~ ^[0-9]+$ ]] && echo yes || echo no)" \
        "req-010: $stem.md holds a whole-number $count_key"
    done
  elif [ "$name" = "$RUN_AT_END_OF_P6" ]; then
    echo "  SKIP: req-010: $name has no record yet, because the end-of-P6 setup run writes it (0000036 ADR-007)"
  elif [ "$(is_downstream_only "$name")" = "yes" ]; then
    assert_equals "record" "missing" "req-010: downstream-only $name holds a record"
  else
    assert_contains "$exception_line" "$BUILD_LOG_TEXT" \
      "req-010: $name has no record, so the build log holds its Exception waiting line"
    assert_equals "1" "$(grep -cF -- "$exception_line" <<< "$BUILD_LOG_TEXT")" \
      "req-010: the build log holds exactly one Exception waiting line for $name"
  fi
done
assert_equals "9" "$COUNT" "req-010: the repo has nine migrations to account for"

# =============================================================================
echo ""
echo "=== req-010 AC-010.2: the two downstream-only migrations are not applicable here ==="

for name in "${DOWNSTREAM_ONLY[@]}"; do
  stem="${name%.md}"
  record="$RECORDS/$stem.md"
  TARGET="$(grep -m1 '^\*\*Target:\*\*' "$MIGRATIONS/$name" || true)"
  assert_contains "downstream project" "$TARGET" "req-010: $name targets a downstream project"
  assert_equals "not applicable" "$( [ -f "$record" ] && frontmatter_value "$record" outcome)" \
    "req-010: $stem.md holds outcome not applicable"
  BODY="$( [ -f "$record" ] && awk 'f >= 2 { print } /^---$/ { f++ }' "$record")"
  assert_contains "framework source" "$BODY" "req-010: the $stem.md body says this repo is the framework source"
done

print_summary
