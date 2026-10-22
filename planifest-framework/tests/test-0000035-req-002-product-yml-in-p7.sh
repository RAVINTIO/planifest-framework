#!/usr/bin/env bash
# Tests for feature 0000035-write-gate-scope-and-path-hardening.
#
# req-002: the ship agent sets product.yml version and feature in P7, before
#          Step 6 archives design.md. A fixed script, set-product-release.mjs,
#          makes every write. It applies each versionPolicy, creates the file
#          with --create, and replaces components[] only through --component
#          (ADR-010). Step 7 stages product.yml. Step 9 only reads it.
#
# Each fixture repo runs the close-out order: the P7 product.yml update, the
# archive, the commit, then the Step 9 derivation of the tag.
#
# REGRESSION-CANDIDATE: covers the P7 product.yml step and its script, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
SET="$FRAMEWORK/scripts/set-product-release.mjs"
DERIVE="$FRAMEWORK/scripts/product-version.mjs"
ARCHIVE="$FRAMEWORK/scripts/archive-current.mjs"
SHIP="$FRAMEWORK/skills/planifest-ship-agent/SKILL.md"

ID="0000035-write-gate-scope-and-path-hardening"
DATE="2026-10-22"

SCRATCH=$(mktemp -d -t planifest_0000035_req002_XXXXXX)
trap 'rm -rf "$SCRATCH"' EXIT

lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

same_file() {
  assert_equals "same" "$(cmp -s "$1" "$2" && echo same || echo differs)" "$3"
}

# make_repo <dir> <policy> [with-product]: a git repo that holds
# planifest-framework/, two components, plan/current/, and product.yml.
make_repo() {
  local r="$1" policy="$2" product="${3:-yes}"
  mkdir -p "$r/planifest-framework" "$r/src/widget" "$r/src/gadget" "$r/plan/current"
  git -C "$r" init -q
  git -C "$r" config user.email test@example.com
  git -C "$r" config user.name test
  git -C "$r" config commit.gpgsign false
  printf 'id: planifest-framework\nversion: "0.33.0"\n' > "$r/planifest-framework/component.yml"
  printf 'id: widget\nversion: "0.2.0"\n' > "$r/src/widget/component.yml"
  printf 'id: gadget\nversion: "0.1.0"\n' > "$r/src/gadget/component.yml"
  echo "design" > "$r/plan/current/design.md"
  echo "$ID" > "$r/plan/current/.feature-id"
  if [ "$product" = "yes" ]; then
    cat > "$r/product.yml" <<YAML
# product.yml fixture
id: "demo"
name: "Demo Product"
version: "0.30.0"
feature: "0000031-ci-test-and-powershell-coverage"

# unrelated line, left alone
versionPolicy: "$policy"

components:
  - id: "planifest-framework"
    path: "planifest-framework/component.yml"
  - id: "widget"
    path: "src/widget/component.yml"
YAML
  fi
  git -C "$r" add -A
  git -C "$r" commit -q -m init
}

# set_release <repo> <args...>: runs the script from inside the repo, with
# no CLAUDE_PROJECT_DIR, so resolveRoot finds the fixture root.
set_release() {
  local r="$1"; shift
  (cd "$r" && env -u CLAUDE_PROJECT_DIR node "$SET" "$@")
}

# close_out <repo>: archive, commit, then derive the tag version.
close_out() {
  local r="$1"
  node "$ARCHIVE" --root "$r" --feature-id "$ID" --date "$DATE" >/dev/null 2>&1
  git -C "$r" add plan/current/ plan/_archive/ >/dev/null 2>&1
  [ -f "$r/product.yml" ] && git -C "$r" add product.yml
  git -C "$r" commit -q -m "plan(p7): archive $ID" >/dev/null 2>&1
  node "$DERIVE" --root "$r" 2>/dev/null
}

components_block() {
  sed -n '/^components:/,$p' "$1"
}

echo "=== req-002: max-component-version sets version and feature ==="

R1="$SCRATCH/r1"
make_repo "$R1" "max-component-version"
BEFORE_COMPONENTS=$(components_block "$R1/product.yml")
OUT=$(set_release "$R1" --feature-id "$ID" --version "0.33.0" 2>&1)
assert_equals "0" "$?" "req-002: max-component-version with the derived version exits 0"
P1=$(cat "$R1/product.yml")
assert_contains 'version: "0.33.0"' "$P1" "req-002: a stale version is corrected to 0.33.0"
assert_contains "feature: \"$ID\"" "$P1" "req-002: a stale feature is corrected to the feature ID"
lacks "0.30.0" "$P1" "req-002: the stale version is gone"
assert_contains "# unrelated line, left alone" "$P1" "req-002: an unrelated line is left alone"
assert_contains 'name: "Demo Product"' "$P1" "req-002: the name line is left alone"
assert_equals "$BEFORE_COMPONENTS" "$(components_block "$R1/product.yml")" \
  "req-002: without --component, components[] stays byte-identical"
assert_equals "1" "$(grep -c '^version:' "$R1/product.yml")" "req-002: the script never appends a version line"
assert_equals "1" "$(grep -c '^feature:' "$R1/product.yml")" "req-002: the script never appends a feature line"

cp "$R1/product.yml" "$SCRATCH/r1-first.yml"
set_release "$R1" --feature-id "$ID" --version "0.33.0" >/dev/null 2>&1
assert_equals "0" "$?" "req-002: a second run exits 0"
same_file "$SCRATCH/r1-first.yml" "$R1/product.yml" "req-002: a second run leaves product.yml byte-identical"

TAG1=$(close_out "$R1")
assert_equals "0.33.0" "$TAG1" "req-002: the Step 9 derivation after the archive matches the tag"
assert_equals "" "$(git -C "$R1" status --porcelain -- product.yml)" "req-002: the archive commit holds product.yml"
assert_contains 'version: "0.33.0"' "$(git -C "$R1" show HEAD:product.yml)" \
  "req-002: the committed product.yml names the released version"

echo "=== req-002: explicit sets version and feature ==="

R2="$SCRATCH/r2"
make_repo "$R2" "explicit"
set_release "$R2" --feature-id "$ID" --version "0.34.0" >/dev/null 2>&1
assert_equals "0" "$?" "req-002: explicit exits 0"
P2=$(cat "$R2/product.yml")
assert_contains 'version: "0.34.0"' "$P2" "req-002: explicit writes --version"
assert_contains "feature: \"$ID\"" "$P2" "req-002: explicit writes the feature ID"
cp "$R2/product.yml" "$SCRATCH/r2-first.yml"
set_release "$R2" --feature-id "$ID" --version "0.34.0" >/dev/null 2>&1
same_file "$SCRATCH/r2-first.yml" "$R2/product.yml" "req-002: an explicit second run leaves product.yml byte-identical"
assert_equals "0.34.0" "$(close_out "$R2")" "req-002: the explicit Step 9 derivation matches the tag"

echo "=== req-002: external changes only feature ==="

R3="$SCRATCH/r3"
make_repo "$R3" "external"
set_release "$R3" --feature-id "$ID" --version "0.33.0" >/dev/null 2>&1
assert_equals "5" "$?" "req-002: external exits 5"
P3=$(cat "$R3/product.yml")
assert_contains 'version: "0.30.0"' "$P3" "req-002: external leaves version as it is"
assert_contains "feature: \"$ID\"" "$P3" "req-002: external writes the feature ID"
TAG3=$(close_out "$R3")
assert_equals "5" "$?" "req-002: the external Step 9 derivation exits 5 for the human to supply the tag"
assert_equals "" "$TAG3" "req-002: the external Step 9 derivation prints no version"
assert_contains "feature: \"$ID\"" "$(git -C "$R3" show HEAD:product.yml)" \
  "req-002: the external archive commit holds the new feature"

echo "=== req-002: a version mismatch under max-component-version ==="

R4="$SCRATCH/r4"
make_repo "$R4" "max-component-version"
cp "$R4/product.yml" "$SCRATCH/r4-before.yml"
ERR=$(set_release "$R4" --feature-id "$ID" --version "0.40.0" 2>&1 >/dev/null)
assert_equals "2" "$?" "req-002: a --version that differs from the derived one exits 2"
same_file "$SCRATCH/r4-before.yml" "$R4/product.yml" "req-002: a mismatch leaves product.yml unchanged"
assert_contains "0.33.0" "$ERR" "req-002: the mismatch reason names the derived version"

echo "=== req-002: an invalid manifest ==="

R5="$SCRATCH/r5"
make_repo "$R5" "max-component-version"
rm "$R5/src/widget/component.yml"
cp "$R5/product.yml" "$SCRATCH/r5-before.yml"
set_release "$R5" --feature-id "$ID" --version "0.33.0" >/dev/null 2>&1
assert_equals "2" "$?" "req-002: a components[] entry with no component.yml exits 2"
same_file "$SCRATCH/r5-before.yml" "$R5/product.yml" "req-002: an invalid manifest leaves product.yml unchanged"

R5B="$SCRATCH/r5b"
make_repo "$R5B" "newest-wins"
cp "$R5B/product.yml" "$SCRATCH/r5b-before.yml"
set_release "$R5B" --feature-id "$ID" --version "0.33.0" >/dev/null 2>&1
assert_equals "2" "$?" "req-002: an unknown versionPolicy exits 2"
same_file "$SCRATCH/r5b-before.yml" "$R5B/product.yml" "req-002: an unknown policy leaves product.yml unchanged"

echo "=== req-002: no product.yml ==="

R6="$SCRATCH/r6"
make_repo "$R6" "max-component-version" no
set_release "$R6" --feature-id "$ID" --version "0.33.0" >/dev/null 2>&1
assert_equals "4" "$?" "req-002: no product.yml and no --create exits 4"
assert_equals "absent" "$([ -e "$R6/product.yml" ] && echo present || echo absent)" \
  "req-002: exit 4 writes nothing"

set_release "$R6" --feature-id "$ID" --version "0.33.0" --create \
  --product-id "demo" --product-name "Demo Product" \
  --component "planifest-framework=planifest-framework/component.yml" >/dev/null 2>&1
assert_equals "2" "$?" "req-002: --create with one component exits 2"
assert_equals "absent" "$([ -e "$R6/product.yml" ] && echo present || echo absent)" \
  "req-002: --create with one component writes nothing"

set_release "$R6" --feature-id "$ID" --version "0.33.0" --create \
  --product-name "Demo Product" \
  --component "planifest-framework=planifest-framework/component.yml" \
  --component "widget=src/widget/component.yml" >/dev/null 2>&1
assert_equals "2" "$?" "req-002: --create without --product-id exits 2"

set_release "$R6" --feature-id "$ID" --version "0.34.0" --create \
  --product-id "demo" --product-name "Demo Product" \
  --component "planifest-framework=planifest-framework/component.yml" \
  --component "widget=src/widget/component.yml" >/dev/null 2>&1
assert_equals "2" "$?" "req-002: --create with a version that differs from the derived one exits 2"
assert_equals "absent" "$([ -e "$R6/product.yml" ] && echo present || echo absent)" \
  "req-002: a --create mismatch writes nothing"

set_release "$R6" --feature-id "$ID" --version "0.33.0" --create \
  --product-id "demo" --product-name "Demo Product" \
  --component "planifest-framework=planifest-framework/component.yml" \
  --component "widget=src/widget/component.yml" >/dev/null 2>&1
assert_equals "0" "$?" "req-002: --create with two components exits 0"
P6=$(cat "$R6/product.yml" 2>/dev/null)
assert_contains 'id: "demo"' "$P6" "req-002: --create sets id"
assert_contains 'name: "Demo Product"' "$P6" "req-002: --create sets name"
assert_contains 'version: "0.33.0"' "$P6" "req-002: --create sets version"
assert_contains "feature: \"$ID\"" "$P6" "req-002: --create sets feature"
assert_contains 'versionPolicy: "max-component-version"' "$P6" "req-002: --create sets max-component-version"
assert_contains '  - id: "planifest-framework"' "$P6" "req-002: --create writes the first components[] entry"
assert_contains '    path: "src/widget/component.yml"' "$P6" "req-002: --create writes the second components[] entry"
lacks "{{" "$P6" "req-002: --create leaves no template placeholder"
assert_equals "2" "$(grep -c '^  - id:' "$R6/product.yml")" "req-002: --create writes exactly two components[] entries"
assert_equals "0.33.0" "$(close_out "$R6")" "req-002: the created file derives the tag version at Step 9"

echo "=== req-002: --component replaces components[] ==="

R7="$SCRATCH/r7"
make_repo "$R7" "max-component-version"
set_release "$R7" --feature-id "$ID" --version "0.33.0" \
  --component "planifest-framework=planifest-framework/component.yml" \
  --component "gadget=src/gadget/component.yml" >/dev/null 2>&1
assert_equals "0" "$?" "req-002: --component on an existing file exits 0"
C7=$(components_block "$R7/product.yml")
assert_contains '  - id: "gadget"' "$C7" "req-002: components[] holds the new --component entry"
assert_contains '    path: "src/gadget/component.yml"' "$C7" "req-002: components[] holds the new entry's path"
lacks "widget" "$C7" "req-002: components[] drops the entry --component left out"
assert_equals "2" "$(grep -c '^  - id:' "$R7/product.yml")" "req-002: components[] holds exactly the --component entries"
cp "$R7/product.yml" "$SCRATCH/r7-first.yml"
set_release "$R7" --feature-id "$ID" --version "0.33.0" \
  --component "planifest-framework=planifest-framework/component.yml" \
  --component "gadget=src/gadget/component.yml" >/dev/null 2>&1
same_file "$SCRATCH/r7-first.yml" "$R7/product.yml" "req-002: a second --component run leaves product.yml byte-identical"
assert_equals "0.33.0" "$(close_out "$R7")" "req-002: the --component Step 9 derivation matches the tag"
assert_equals "2" "$(git -C "$R7" show HEAD:product.yml | grep -c '^  - id:')" \
  "req-002: the --component archive commit holds exactly the --component entries"

R8="$SCRATCH/r8"
make_repo "$R8" "max-component-version"
set_release "$R8" --feature-id "$ID" --version "0.33.0" --create \
  --product-id "other" --product-name "Other" \
  --component "planifest-framework=planifest-framework/component.yml" \
  --component "widget=src/widget/component.yml" >/dev/null 2>&1
assert_equals "0" "$?" "req-002: --create with an existing product.yml exits 0"
assert_contains 'id: "demo"' "$(cat "$R8/product.yml")" "req-002: --create has no effect on an existing id"

echo "=== req-002: ship skill source ==="

STEP5_LINE=$(grep -n '^### Step 5:' "$SHIP" | head -1 | cut -d: -f1)
STEP6_LINE=$(grep -n '^### Step 6:' "$SHIP" | head -1 | cut -d: -f1)
SET_LINE=$(grep -n 'set-product-release.mjs' "$SHIP" | head -1 | cut -d: -f1)
assert_equals "yes" "$([ -n "$SET_LINE" ] && [ -n "$STEP6_LINE" ] && [ "$SET_LINE" -lt "$STEP6_LINE" ] && echo yes || echo no)" \
  "req-002: the product.yml step comes before Step 6"
assert_equals "yes" "$([ -n "$SET_LINE" ] && [ -n "$STEP5_LINE" ] && [ "$SET_LINE" -gt "$STEP5_LINE" ] && echo yes || echo no)" \
  "req-002: the product.yml step comes after Step 5"
PSTEP=$(sed -n '/^### Step 5b:/,/^### Step 6:/p' "$SHIP")
assert_contains "set-product-release.mjs --feature-id" "$PSTEP" "req-002: the P7 step runs set-product-release.mjs"
assert_contains "--create" "$PSTEP" "req-002: the P7 step covers the --create rerun"
assert_contains "--component" "$PSTEP" "req-002: the P7 step covers --component"
assert_contains "Exit 4" "$PSTEP" "req-002: the P7 step handles exit 4"
assert_contains "Exit 5" "$PSTEP" "req-002: the P7 step handles exit 5"
assert_contains "Exit 2" "$PSTEP" "req-002: the P7 step handles exit 2"
assert_contains "never through **Write** or **Edit**" "$PSTEP" "req-002: the ship agent never writes product.yml through Write or Edit"

STEP7=$(sed -n '/^### Step 7: Commit archive/,/^## P8/p' "$SHIP")
assert_contains "git add product.yml" "$STEP7" "req-002: Step 7 stages product.yml"

STEP9=$(sed -n '/^### Step 9: Create git tag/,/^### Step 10:/p' "$SHIP")
assert_contains "product-version.mjs" "$STEP9" "req-002: Step 9 reads the version through product-version.mjs"
assert_equals "0" "$(grep -Eic '(update|edit|create|populate)[^.]*`product\.yml`' <<< "$STEP9")" \
  "req-002: Step 9 holds no instruction to edit product.yml"
lacks "Only update" "$STEP9" "req-002: Step 9 drops the old update instruction"
assert_contains "stop and report" "$STEP9" "req-002: Step 9 stops and reports on a version mismatch"

print_summary
