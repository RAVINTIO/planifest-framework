#!/usr/bin/env bash
# Tests for feature 0000039-ravintio-rebrand.
#
# req-010: the rename release carries a 0.37 version, and no live file names
#          1.0.0 as the current release (ADR-003).
#   AC1: product.yml, ravintio-framework/component.yml and docs/about.md
#        (frontmatter and table) read the same 0.37.x version, and
#        product-version.mjs prints it. A patch release keeps the 0.37 minor.
#   AC2: every `git grep` hit for 1.0.0 names it as the removal point for
#        old-name reads, or sits in a third-party or non-release version field.
#
# Verified by: integration
# Verified by: execution

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$FRAMEWORK/.." && pwd)"

# --- AC1 ---------------------------------------------------------------
PRODUCT_V="$(sed -n 's/^version: *"\{0,1\}\([0-9.]*\)"\{0,1\} *$/\1/p' "$REPO/product.yml" | head -n 1)"
COMP_V="$(sed -n 's/^version: *"\{0,1\}\([0-9.]*\)"\{0,1\} *$/\1/p' "$FRAMEWORK/component.yml" | head -n 1)"
# The component version sets the release, and it must be a 0.37 patch.
WANT="$COMP_V"
if [[ "$COMP_V" =~ ^0\.37\.[0-9]+$ ]]; then R=ok; else R="not a 0.37 version: $COMP_V"; fi
assert_equals "ok" "$R" "req-010 AC1: ravintio-framework/component.yml version is a 0.37 release"
ABOUT_FM_V="$(awk 'NR==1 && /^---$/ {fm=1; next} fm && /^---$/ {exit} fm && /^version:/ {gsub(/^version: *"?|"? *$/, ""); print; exit}' "$REPO/docs/about.md")"
ABOUT_TABLE_V="$(sed -n 's/^| Version | `\([0-9.]*\)` |.*$/\1/p' "$REPO/docs/about.md" | head -n 1)"

assert_equals "$WANT" "$PRODUCT_V" "req-010 AC1: product.yml version reads $WANT"
assert_equals "$WANT" "$COMP_V" "req-010 AC1: ravintio-framework/component.yml version reads $WANT"
assert_equals "$WANT" "$ABOUT_FM_V" "req-010 AC1: docs/about.md frontmatter version reads $WANT"
assert_equals "$WANT" "$ABOUT_TABLE_V" "req-010 AC1: docs/about.md table Version cell reads $WANT"

PV_OUT="$(cd "$REPO" && env -u CLAUDE_PROJECT_DIR node "$FRAMEWORK/scripts/product-version.mjs" 2>&1 || true)"
assert_equals "$WANT" "$PV_OUT" "req-010 AC1: product-version.mjs prints $WANT"

# --- AC2 ---------------------------------------------------------------
HITS="$(cd "$REPO" && git grep -n '1\.0\.0' -- . ':!plan/_archive' ':!plan/changelog' ':!plan/_migrations' ':!plan/current' ':!ravintio-framework/tests/test-0000039-req-010-version-bump.sh' ':!ravintio-framework/tests/regression/test-0000039-req-010-version-bump.sh' 2>/dev/null || true)"

# A removal-point line pairs 1.0.0 with a form of "remove" or "go", in either order,
# such as "removed at 1.0.0", "1.0.0 removes them", or "upgrades straight to 1.0.0"
# in a note about the removal.
REMOVAL_RE='((removed?|removes|removal|remove at|go at|goes at|gone at|until|through 0\.x).*1\.0\.0|1\.0\.0.*(remov|go(es)? |release notes)|skips the 0\.x window)'
THIRD_PARTY_RE='^(package(-lock)?\.json|[^:]*/package(-lock)?\.json|[^:]*/external-skills/)'
# Non-release uses: a document or template version field, and semver examples
# or rejection fixtures that never name the framework release.
OTHER_RE_PATH='^[^:]*/(standards|templates)/[^:]*:[0-9]+:[[:space:]]*(version|templateVersion): *"?1\.0\.0"?'
OTHER_RE_COMP='^ravintio-framework/component\.yml:[0-9]+:[[:space:]]*templateVersion: *"1\.0\.0"'
OTHER_RE_SCHEMA='(schemaVersion|templateVersion): *"1\.0\.0"|Schema Version:\*\* 1\.0\.0|schema version stays 1\.0\.0'
OTHER_RE_TEST='^ravintio-framework/tests/(regression/)?test-0000035-req-008-sanctioned-scripts\.sh:'
OTHER_RE_EXAMPLE='^ravintio-framework/skills/ravintio-orchestrator/references/phase-0-assess-and-coach\.md:[0-9]+:.*Breaking change'

BAD=""
TOTAL=0
while IFS= read -r hit; do
  [ -z "$hit" ] && continue
  TOTAL=$((TOTAL + 1))
  if grep -Eq "$REMOVAL_RE" <<< "$hit"; then continue; fi
  if grep -Eq "$THIRD_PARTY_RE" <<< "$hit"; then continue; fi
  if grep -Eq "$OTHER_RE_PATH" <<< "$hit"; then continue; fi
  if grep -Eq "$OTHER_RE_COMP" <<< "$hit"; then continue; fi
  if grep -Eq "$OTHER_RE_SCHEMA" <<< "$hit"; then continue; fi
  if grep -Eq "$OTHER_RE_TEST" <<< "$hit"; then continue; fi
  if grep -Eq "$OTHER_RE_EXAMPLE" <<< "$hit"; then continue; fi
  BAD+="$hit"$'\n'
  echo "FAIL hit names 1.0.0 outside the allowed cases: $hit"
done <<< "$HITS"

if [ "$TOTAL" -gt 0 ]; then R=ok; else R="no hits found"; fi
assert_equals "ok" "$R" "req-010 AC2: git grep for 1.0.0 returned hits to classify"
assert_equals "" "$BAD" "req-010 AC2: no hit names 1.0.0 as the current release"

# A live file must also not claim 1.0.0 as the release in the three manifests.
assert_equals "0" "$(grep -c '1\.0\.0' <<< "$PRODUCT_V$COMP_V$ABOUT_FM_V$ABOUT_TABLE_V" || true)" \
  "req-010 AC2: no manifest or about page reads 1.0.0 as the version"

print_summary
