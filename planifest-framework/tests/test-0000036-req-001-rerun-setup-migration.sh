#!/usr/bin/env bash
# Tests for feature 0000036-pipeline-friction-and-gate-fixes.
#
# req-001: one 0.34.0 migration re-runs setup for the setup-delivered changes
#          in 0.33.0 and 0.34.0 (ADR-006). Its Target line names the framework
#          source too, so this repo records an applied run (ADR-007). The
#          update policy defines setup-delivered files and requires such a
#          migration.
#
# Covers AC-001.1, AC-001.2, and the req-001 half of AC-001.3. The record
# check skips while plan/_migrations/migrate-0.34.0-rerun-setup.md is absent,
# because the end-of-P6 setup run writes it (FR-001.7, FR-001.8).

set -uo pipefail

# The hooks prefer CLAUDE_PROJECT_DIR as the root. A Claude Code session sets
# it, so clear it here.
unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$FRAMEWORK/.." && pwd)"
NAME="migrate-0.34.0-rerun-setup.md"
MIGRATION="$FRAMEWORK/migrations/$NAME"
POLICY="$FRAMEWORK/standards/framework-update-policy.md"
RECORD="$REPO/plan/_migrations/$NAME"

# yes_no <test args...>: prints yes when the test holds, otherwise no.
yes_no() {
  if "$@"; then echo yes; else echo no; fi
}

# section <text> <start heading> <next heading>: the text between two headings.
section() {
  local text="$1"
  text="${text#*"$2"}"
  printf '%s' "${text%%"$3"*}"
}

# heading_line <file> <heading>: the line number of an exact heading, or 0.
heading_line() {
  local n
  n="$(grep -nxF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1)"
  echo "${n:-0}"
}

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

# =============================================================================
echo ""
echo "=== req-001 FR-001.4: the migration file sits at the top level ==="

assert_equals "yes" "$(yes_no test -f "$MIGRATION")" "req-001: $NAME exists at the top level of migrations/"
assert_equals "no" "$(yes_no test -e "$FRAMEWORK/migrations/_done")" "req-001: no archive subfolder exists (0000035 req-007)"

SRC="$(cat "$MIGRATION" 2>/dev/null || true)"

# =============================================================================
echo ""
echo "=== req-001 FR-001.4: the header lines follow the 0.31.0 layout ==="

assert_contains "# Migration:" "$SRC" "req-001: the migration has a # Migration: title"
for key in "**Target:**" "**Scope:**" "**Safe to skip:**"; do
  assert_equals "1" "$(grep -c "^$(printf '%s' "$key" | sed 's/\*/\\*/g')" <<< "$SRC")" \
    "req-001: the header holds one $key line"
done
SAFE="$(grep -m1 '^\*\*Safe to skip:\*\*' <<< "$SRC" || true)"
assert_contains "**Safe to skip:** No." "$SAFE" "req-001: Safe to skip reads No"

TARGET="$(grep -m1 '^\*\*Target:\*\*' <<< "$SRC" || true)"
assert_contains "framework source" "$TARGET" "req-001: the Target line names the framework source (ADR-007)"
assert_contains "every project with an installed Planifest setup" "$TARGET" \
  "req-001: the Target line names every project with an installed setup"

# =============================================================================
echo ""
echo "=== req-001 FR-001.4: the five sections appear in order ==="

PREV=0
for heading in "## Background" "## What This Migration Does" "## Migrator Instructions" "## Present Findings" "## Record"; do
  LINE="$(heading_line "$MIGRATION" "$heading")"
  assert_equals "yes" "$([ "$LINE" -gt 0 ] && echo yes || echo no)" "req-001: the migration has the section: $heading"
  assert_equals "yes" "$([ "$LINE" -gt "$PREV" ] && echo yes || echo no)" "req-001: $heading follows the section before it"
  PREV="$LINE"
done

# =============================================================================
echo ""
echo "=== req-001 FR-001.8: the text names both versions, the re-run, and the record ==="

for needle in "0.33.0" "0.34.0" "Re-run setup" "planifest-refresh-setup" "plan/_migrations/"; do
  assert_contains "$needle" "$SRC" "req-001: the migration names $needle"
done

# =============================================================================
echo ""
echo "=== req-001 FR-001.2 and FR-001.3: the Background lists the setup-delivered files ==="

BACKGROUND="$(section "$SRC" "## Background" "## What This Migration Does")"
assert_contains "0.33.0" "$BACKGROUND" "req-001: the Background names 0.33.0"
assert_contains "0.34.0" "$BACKGROUND" "req-001: the Background names 0.34.0"

# FR-001.2: the 0.33.0 files, from git diff --name-only 2253e80 5c7859a.
for f in \
  hooks/enforcement/path-rules.mjs \
  hooks/enforcement/gate-write.mjs \
  hooks/enforcement/shell-write-guard.mjs \
  hooks/enforcement/ratchet-check.mjs \
  templates/standard-boot.md \
  templates/cursor-boot.md \
  skills/planifest-migrator/SKILL.md \
  skills/planifest-orchestrator/SKILL.md \
  skills/planifest-ship-agent/SKILL.md \
  templates/feature-brief.template.md \
  templates/product.template.yml \
  workflows/fast-path.md; do
  assert_contains "$f" "$BACKGROUND" "req-001: the Background names 0.33.0 file $f"
done

# FR-001.3: the 0.34.0 files that the requirement set names.
for f in \
  hooks/enforcement/em-dash-guard.mjs \
  templates/loop-toggles.template.yml \
  templates/build-log.template.md \
  standards/framework-update-policy.md \
  skills/planifest-spec-agent/SKILL.md \
  skills/planifest-loop-runner/SKILL.md \
  skills/planifest-design-critic/SKILL.md; do
  assert_contains "$f" "$BACKGROUND" "req-001: the Background names 0.34.0 file $f"
done

# =============================================================================
echo ""
echo "=== req-001 FR-001.5: the Migrator Instructions hold the six steps ==="

INSTRUCTIONS="$(section "$SRC" "## Migrator Instructions" "## Present Findings")"
assert_contains "planifest-framework/component.yml" "$INSTRUCTIONS" "req-001: step 1 reads component.yml"
assert_contains "0.34.0" "$INSTRUCTIONS" "req-001: step 1 requires 0.34.0 or later"
assert_contains "Re-run setup" "$INSTRUCTIONS" "req-001: step 2 re-runs setup"
assert_contains "planifest-refresh-setup" "$INSTRUCTIONS" "req-001: step 2 points to planifest-refresh-setup"
assert_contains "node planifest-framework/scripts/skill-drift-check.mjs" "$INSTRUCTIONS" "req-001: step 3 runs the drift check"
assert_contains "planifest-framework/hooks/enforcement/" "$INSTRUCTIONS" "req-001: step 4 compares installed hooks with source"
assert_contains "sanctioned-scripts" "$INSTRUCTIONS" "req-001: step 5 checks the sanctioned-scripts sentence"
assert_contains "Write-or-Edit rule" "$INSTRUCTIONS" "req-001: step 5 checks the boot file names the Write-or-Edit rule"
assert_contains "malformed" "$INSTRUCTIONS" "req-001: step 6 reports malformed settings JSON"
assert_contains "Node" "$INSTRUCTIONS" "req-001: step 6 reports missing Node"

RECORD_SECTION="${SRC#*## Record}"
assert_contains "plan/_migrations/$NAME" "$RECORD_SECTION" "req-001: the Record section names the record path"

# S-6: a failed run never records, so the migration stays pending.
assert_contains "A completed run meets every one of these conditions:" "$INSTRUCTIONS" \
  "req-001: the Migrator Instructions define a completed run"
assert_contains "Setup exits 0 for each tool." "$INSTRUCTIONS" "req-001: a completed run needs setup to exit 0"
assert_contains "The drift check exits 0." "$INSTRUCTIONS" "req-001: a completed run needs the drift check to exit 0"
assert_contains "Every installed enforcement hook matches its source." "$INSTRUCTIONS" \
  "req-001: a completed run needs every installed hook to match its source"
# N-2: setup exits 0 even when it skips hook wiring for a malformed settings file.
assert_contains "Setup reported no malformed settings file and no missing Node." "$INSTRUCTIONS" \
  "req-001: a completed run needs setup to report no malformed settings file and no missing Node"
for text in "$INSTRUCTIONS" "$RECORD_SECTION"; do
  assert_contains "On any other result, the migrator records nothing, so the migration stays pending." "$text" \
    "req-001: any other result records nothing and leaves the migration pending"
  assert_contains "It reports the failure to the human on the loop." "$text" \
    "req-001: any other result reports the failure to the human on the loop"
done

# =============================================================================
echo ""
echo "=== req-001 FR-001.6: the update policy defines setup-delivered files ==="

POLICY_SRC="$(cat "$POLICY" 2>/dev/null || true)"
assert_contains "A release that changes a setup-delivered file ships a re-run-setup migration." "$POLICY_SRC" \
  "req-001: the policy holds the re-run-setup sentence"
assert_contains "setup-delivered" "$POLICY_SRC" "req-001: the policy defines setup-delivered files"
assert_contains "bundle_templates" "$POLICY_SRC" "req-001: the policy names the bundle_templates fallback"
assert_contains "bundle_standards" "$POLICY_SRC" "req-001: the policy names the bundle_standards fallback"
assert_contains "standards/library-standards/_version-policy.md" "$POLICY_SRC" \
  "req-001: the policy names the sub-path standard that setup copies"
assert_contains "core.hooksPath" "$POLICY_SRC" "req-001: the policy excludes git hooks"
assert_contains "several releases" "$POLICY_SRC" "req-001: the policy lets one migration cover several releases"

# =============================================================================
echo ""
echo "=== req-001 FR-001.7: this repo records an applied run ==="

if [ -f "$RECORD" ]; then
  assert_equals "$NAME" "$(frontmatter_value "$RECORD" migration)" "req-001: the record names its migration"
  assert_equals "applied" "$(frontmatter_value "$RECORD" outcome)" "req-001: the record holds outcome applied"
  assert_equals "0.34.0" "$(frontmatter_value "$RECORD" framework-version)" "req-001: the record holds framework-version 0.34.0"
else
  echo "  SKIP: req-001: plan/_migrations/$NAME is absent, so the end-of-P6 setup run hasn't happened yet"
fi

print_summary
