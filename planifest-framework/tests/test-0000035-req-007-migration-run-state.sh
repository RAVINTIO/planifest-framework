#!/usr/bin/env bash
# Tests for feature 0000035-write-gate-scope-and-path-hardening.
#
# req-007: migration files never move. Each project records its runs in
#          plan/_migrations/{stem}.md, and a migration is pending when it has
#          no readable record (ADR-015 to ADR-018).
#
# Covers AC-007.1, AC-007.2, and AC-007.4, plus the FR-007.8 write-gate guard.
# The gate case runs in a mktemp -d fixture with no sentinel and no design.

set -uo pipefail

# The hooks prefer CLAUDE_PROJECT_DIR as the root. A Claude Code session sets
# it, so clear it here.
unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$FRAMEWORK/.." && pwd)"
MIGRATIONS="$FRAMEWORK/migrations"
MIGRATOR_FILE="$FRAMEWORK/skills/planifest-migrator/SKILL.md"
ORCH_FILE="$FRAMEWORK/skills/planifest-orchestrator/SKILL.md"
GATE_WRITE="$FRAMEWORK/hooks/enforcement/gate-write.mjs"
SELF="$(basename "$0")"

# The markers keep the 0000030 residue check off this migration file name.
# BEGIN retired-integrations
# 0000036 req-001 adds the 0.34.0 re-run-setup migration, so there were nine.
# 0000037 adds the 0.35.0 re-run-setup migration, so there were ten.
# 0000038 adds the 0.36.0 re-run-setup migration, so there are eleven.
NINE=(
  0001-date-format.md
  0002-british-english.md
  0003-archive-dirname.md
  migrate-0.31.0-rerun-setup-for-shell-write-guard.md
  migrate-0.34.0-rerun-setup.md
  migrate-0.35.0-rerun-setup.md
  migrate-0.36.0-rerun-setup.md
  migrate-adoption-mode-and-about-md.md
  migrate-product-yml-component-paths.md
  migrate-remove-context-mode-and-telemetry.md
  retroactive-release-tags.md
)
# END retired-integrations

WORK="$(mktemp -d -t planifest_0000035_req007_XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

# native <path>: a path Node reads the same way Bash does.
native() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

# yes_no <test args...>: prints yes when the test holds, otherwise no.
yes_no() {
  if "$@"; then echo yes; else echo no; fi
}

# section <file> <start heading> <next heading>: the text between two headings.
section() {
  local text
  text="$(cat "$1" 2>/dev/null || true)"
  text="${text#*"$2"}"
  printf '%s' "${text%%"$3"*}"
}

# =============================================================================
echo ""
echo "=== req-007 AC-007.1: migration files sit at the top level and never move ==="

assert_equals "no" "$(yes_no test -e "$MIGRATIONS/_done")" "req-007: migrations/_done/ no longer exists"

for f in "${NINE[@]}"; do
  assert_equals "yes" "$(yes_no test -f "$MIGRATIONS/$f")" "req-007: $f sits at the top level of migrations/"
done

TOP_COUNT="$(find "$MIGRATIONS" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
assert_equals "11" "$TOP_COUNT" "req-007: migrations/ holds exactly eleven top-level migration files"

for s in migrate-archive-dirname.sh migrate-archive-dirname.ps1; do
  assert_equals "yes" "$(yes_no test -f "$MIGRATIONS/$s")" "req-007: helper script $s stays beside 0003-archive-dirname.md"
done

COMPONENT="$(cat "$FRAMEWORK/component.yml")"
assert_contains 'migrationPath: "planifest-framework/migrations/"' "$COMPONENT" \
  "req-007: component.yml keeps migrationPath"

for f in "${NINE[@]}"; do
  SRC="$(cat "$MIGRATIONS/$f" 2>/dev/null || true)"
  assert_equals "no" "$(yes_no grep -q '_done' <<< "$SRC")" "req-007: $f carries no _done text"
  assert_equals "no" "$(yes_no grep -qiE 'move this file|mv planifest-framework/migrations' <<< "$SRC")" \
    "req-007: $f never tells an agent to move it"
  assert_equals "no" "$(yes_no grep -qiE 'archives? (this|it|the)|and archives?\b' <<< "$SRC")" \
    "req-007: $f never tells the migrator to archive it"
  assert_equals "no" "$(yes_no grep -q '^## Archive' <<< "$SRC")" "req-007: $f has no ## Archive section"
  assert_contains "plan/_migrations/" "$SRC" "req-007: $f tells the migrator to record the outcome in plan/_migrations/"
done

# No skill, doc, or other suite tells an agent to move a migration to _done/.
DONE_HITS="$(grep -rlE 'migrations/_done|_done/' \
  "$FRAMEWORK/skills" "$FRAMEWORK/migrations" "$FRAMEWORK"/*.md "$REPO/README.md" "$REPO/docs" \
  2>/dev/null || true)"
assert_equals "" "$DONE_HITS" "req-007: no skill, migration, or doc names _done/"

TEST_HITS="$(grep -rlE 'migrations/_done/|MIGRATIONS/_done/' "$FRAMEWORK/tests" 2>/dev/null | grep -v "/$SELF\$" || true)"
assert_equals "" "$TEST_HITS" "req-007: no other suite expects a migrations/_done path"

# =============================================================================
echo ""
echo "=== req-007 AC-007.2: resume detection lists only migrations with no readable record ==="

STEP1="$(section "$ORCH_FILE" "1. **Scan for pending migrations**" "1a. **Detect")"
assert_contains "plan/_migrations/{stem}.md" "$STEP1" "req-007: Resume Detection step 1 reads plan/_migrations/{stem}.md"
assert_contains "top-level" "$STEP1" "req-007: step 1 lists top-level migration files only"
assert_contains "subfolder" "$STEP1" "req-007: step 1 says a subfolder is never a migration"
assert_contains "readable record" "$STEP1" "req-007: step 1 makes pending mean no readable record"
assert_contains "file-name order" "$STEP1" "req-007: step 1 runs pending migrations in file-name order"
assert_contains "names the record file" "$STEP1" "req-007: step 1 names an unreadable record"
assert_contains "never writes" "$STEP1" "req-007: step 1 is read-only on records (ADR-017)"
assert_equals "no" "$(yes_no grep -q '_done' <<< "$STEP1")" "req-007: step 1 never reads _done/"

MIGRATOR="$(cat "$MIGRATOR_FILE")"
for label in "orchestrator step 1:$STEP1" "migrator:$MIGRATOR"; do
  name="${label%%:*}"
  text="${label#*:}"
  for needle in '`applied`' '`not applicable`' '`skipped`' '`migration`' '`outcome`' '`date`' 'YYYY-MM-DD' '{stem}.md' 'frontmatter'; do
    assert_contains "$needle" "$text" "req-007: the $name states $needle"
  done
done
assert_contains "can't be read" "$MIGRATOR" "req-007: the migrator states the unreadable-record rule"
assert_contains "can't be read" "$STEP1" "req-007: step 1 states the unreadable-record rule"
assert_contains "no matching migration" "$MIGRATOR" "req-007: the migrator says an orphan record is ignored"

PIPE="$(section "$FRAMEWORK/pipeline-reference.md" "### Check for pending migrations" "## What to Commit")"
assert_contains "plan/_migrations/" "$PIPE" "req-007: pipeline-reference.md describes the record rule"
assert_equals "no" "$(yes_no grep -q '_done' <<< "$PIPE")" "req-007: pipeline-reference.md drops the _done filters"

OPS="$(cat "$FRAMEWORK/project-operations.md")"
assert_contains "plan/_migrations/" "$OPS" "req-007: project-operations.md defines pending by plan/_migrations/"

README_ROW="$(grep -E '^\| \[migrations/\]' "$REPO/README.md" || true)"
assert_contains "plan/_migrations/" "$README_ROW" "req-007: README.md names plan/_migrations/ for run state"

INDEX_ROW="$(grep -E '^\| ADR-005 \| Markdown migration files' "$REPO/docs/decisions-index.md" || true)"
assert_equals "yes" "$(yes_no test -n "$INDEX_ROW")" "req-007: decisions-index.md keeps the 0000005 ADR-005 row"
assert_equals "no" "$(yes_no grep -q '_done' <<< "$INDEX_ROW")" "req-007: the ADR-005 row no longer sends migrations to _done/"

# =============================================================================
echo ""
echo "=== req-007 AC-007.4: the migrator's Record step ==="

FRONT="$(section "$MIGRATOR_FILE" "---" "---")"
assert_contains "records" "$FRONT" "req-007: the migrator description says it records the migration"
assert_equals "no" "$(yes_no grep -q 'archives' <<< "$FRONT")" "req-007: the migrator description no longer says it archives"

assert_contains "### Step 5: Record" "$MIGRATOR" "req-007: Step 5 is the Record step"
assert_equals "no" "$(yes_no grep -q '### Step 5: Archive' <<< "$MIGRATOR")" "req-007: the Archive step is gone"
RECORD="$(section "$MIGRATOR_FILE" "### Step 5: Record" "## Exclusions")"
assert_contains "plan/_migrations/{stem}.md" "$RECORD" "req-007: the Record step writes plan/_migrations/{stem}.md"
assert_contains "**Write**" "$RECORD" "req-007: the Record step writes through Write"
assert_contains "first record" "$RECORD" "req-007: the Record step creates plan/_migrations/ on its first record"
for field in migration outcome date framework-version corrections-applied corrections-skipped; do
  assert_contains "$field:" "$RECORD" "req-007: the record format holds $field"
done
assert_contains "unchanged" "$RECORD" "req-007: a re-run with the same outcome leaves the record unchanged"
assert_contains "Recorded at plan/_migrations/{stem}.md" "$RECORD" "req-007: the completion report names the record path"
assert_contains "never moves, renames, or deletes" "$MIGRATOR" "req-007: the migrator never moves a migration file"
assert_contains "writes no record" "$MIGRATOR" "req-007: a scan with findings writes no record until every batch is answered"

# =============================================================================
echo ""
echo "=== req-007 FR-007.8: the gate admits a record write with no sentinel and no design ==="

FIX="$WORK/fixture"
mkdir -p "$FIX/plan" "$FIX/planifest-framework"
git init "$FIX" >/dev/null 2>&1

run_gate() {
  local errfile="$WORK/stderr.txt"
  node "$GATE_WRITE" >/dev/null 2>"$errfile" <<< "{\"cwd\":\"$(native "$FIX")\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$1\"}}"
  CODE=$?
  ERR=$(cat "$errfile")
}

assert_equals "no" "$(yes_no test -e "$FIX/plan/.orchestrator-active")" "req-007: the fixture has no sentinel"
assert_equals "no" "$(yes_no test -e "$FIX/plan/current/design.md")" "req-007: the fixture has no design"

run_gate "plan/_migrations/x.md"
assert_equals "0" "$CODE" "req-007: a Write to plan/_migrations/x.md exits 0"
assert_equals "" "$ERR" "req-007: a Write to plan/_migrations/x.md prints no block reason"

run_gate "$(native "$FIX/plan/_migrations/x.md")"
assert_equals "0" "$CODE" "req-007: an absolute Write to plan/_migrations/x.md exits 0"

# Control: the same fixture still gates src/.
run_gate "src/a.js"
assert_equals "2" "$CODE" "req-007: control, the fixture still blocks src/a.js with no design"

print_summary
