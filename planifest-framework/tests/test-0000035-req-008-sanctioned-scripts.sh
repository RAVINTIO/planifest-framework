#!/usr/bin/env bash
# Tests for feature 0000035-write-gate-scope-and-path-hardening.
#
# req-008: Hard Limit 8 gains a narrow carve-out for fixed framework scripts
#          that a skill step runs to write files (ADR-011). Both boot
#          templates carry one `Sanctioned scripts:` sentence that names the
#          same seven scripts. set-product-release.mjs treats every argument
#          as untrusted. A rule break exits 2, writes nothing, names the
#          argument, and never echoes the raw value. A product.yml link that
#          resolves elsewhere exits 2 and leaves the link target unchanged.
#
# REGRESSION-CANDIDATE: covers the Hard Limit 8 sanctioned-script list and the set-product-release.mjs input rules, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
SET="$FRAMEWORK/scripts/set-product-release.mjs"
STANDARD_BOOT="$FRAMEWORK/templates/standard-boot.md"
CURSOR_BOOT="$FRAMEWORK/templates/cursor-boot.md"

ID="0000035-write-gate-scope-and-path-hardening"

SCRATCH=$(mktemp -d -t planifest_0000035_req008_XXXXXX)
trap 'rm -rf "$SCRATCH"' EXIT

lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

# make_root <dir>: a root that holds planifest-framework/, three components,
# and a max-component-version product.yml.
make_root() {
  local r="$1"
  mkdir -p "$r/planifest-framework" "$r/src/widget" "$r/src/gadget"
  printf 'id: planifest-framework\nversion: "0.33.0"\n' > "$r/planifest-framework/component.yml"
  printf 'id: widget\nversion: "0.2.0"\n' > "$r/src/widget/component.yml"
  printf 'id: gadget\nversion: "0.1.0"\n' > "$r/src/gadget/component.yml"
  cat > "$r/product.yml" <<'YAML'
id: "demo"
name: "Demo Product"
version: "0.30.0"
feature: "0000031-ci-test-and-powershell-coverage"
versionPolicy: "max-component-version"

components:
  - id: "planifest-framework"
    path: "planifest-framework/component.yml"
  - id: "widget"
    path: "src/widget/component.yml"
YAML
}

R="$SCRATCH/root"
make_root "$R"
cp "$R/product.yml" "$SCRATCH/before.yml"
mkdir -p "$SCRATCH/outside/comp"
printf 'id: outside\nversion: "9.9.9"\n' > "$SCRATCH/outside/comp/component.yml"

# reject <label> <argument> <raw-fragment> <args...>: runs the script in the
# fixture root and expects exit 2, a stderr reason that names the argument,
# no raw value on stderr, and a byte-identical product.yml.
reject() {
  local label="$1" arg="$2" raw="$3"; shift 3
  local err code
  err=$(cd "$R" && env -u CLAUDE_PROJECT_DIR node "$SET" "$@" 2>&1 >/dev/null)
  code=$?
  assert_equals "2" "$code" "req-008: $label exits 2"
  assert_contains "$arg" "$err" "req-008: $label names $arg on stderr"
  lacks "$raw" "$err" "req-008: $label never echoes the raw value"
  assert_equals "same" "$(cmp -s "$SCRATCH/before.yml" "$R/product.yml" && echo same || echo differs)" \
    "req-008: $label leaves product.yml byte-identical"
}

BASE=(--feature-id "$ID" --version "0.33.0")
CREATE=(--create --product-id "demo" --product-name "Demo Product"
  --component "planifest-framework=planifest-framework/component.yml"
  --component "widget=src/widget/component.yml")

echo "=== req-008: a valid call still passes ==="

(cd "$R" && env -u CLAUDE_PROJECT_DIR node "$SET" "${BASE[@]}" --root "$R" >/dev/null 2>&1)
assert_equals "0" "$?" "req-008: --root equal to the resolved root exits 0"
cp "$R/product.yml" "$SCRATCH/before.yml"

echo "=== req-008: --root ==="

reject "a --root subfolder" "--root" "$R/src" "${BASE[@]}" --root "$R/src"
reject "a --root outside the repo" "--root" "outside" "${BASE[@]}" --root "$SCRATCH/outside"
reject "a --root that does not exist" "--root" "nowhere-xyz" "${BASE[@]}" --root "$SCRATCH/nowhere-xyz"

G="$SCRATCH/gitonly"
mkdir -p "$G/.git"
cp "$SCRATCH/before.yml" "$G/product.yml"
ERR=$(cd "$G" && env -u CLAUDE_PROJECT_DIR node "$SET" "${BASE[@]}" 2>&1 >/dev/null)
assert_equals "2" "$?" "req-008: a root with no planifest-framework/ folder exits 2"
assert_contains "--root" "$ERR" "req-008: a root with no planifest-framework/ names --root"
assert_equals "same" "$(cmp -s "$SCRATCH/before.yml" "$G/product.yml" && echo same || echo differs)" \
  "req-008: a root with no planifest-framework/ leaves product.yml byte-identical"

ERR=$(D="$SCRATCH/gone"; mkdir "$D" && cd "$D" && rmdir "$D" && env -u CLAUDE_PROJECT_DIR node "$SET" "${BASE[@]}" 2>&1 >/dev/null)
assert_equals "2" "$?" "req-008: a null resolveRoot result exits 2"
assert_contains "--root" "$ERR" "req-008: a null resolveRoot result names --root"

echo "=== req-008: --feature-id ==="

reject "a newline in --feature-id" "--feature-id" "versionPolicy" \
  --feature-id $'0000035-x\nversionPolicy: "explicit"' --version "0.33.0"
assert_equals "0" "$(grep -c 'explicit' "$R/product.yml")" "req-008: the newline injection adds no key"
reject "a --feature-id past 80 characters" "--feature-id" "aaaaaaaaaa" \
  --feature-id "0000035-$(printf 'a%.0s' {1..73})" --version "0.33.0"
reject "a --feature-id that breaks the pattern" "--feature-id" "35-short" \
  --feature-id "35-short" --version "0.33.0"

echo "=== req-008: --version ==="

reject "a prerelease --version" "--version" "rc.1" --feature-id "$ID" --version "1.0.0-rc.1"
reject "a build suffix on --version" "--version" "build7" --feature-id "$ID" --version "1.0.0+build7"
reject "a leading zero in --version" "--version" "01.2.3" --feature-id "$ID" --version "01.2.3"
reject "a --version past 32 characters" "--version" "12345678901" \
  --feature-id "$ID" --version "12345678901.1234567890.1234567890"

echo "=== req-008: --product-id and --product-name ==="

reject "a --product-id that breaks the pattern" "--product-id" "Demo_X" \
  "${BASE[@]}" --create --product-id "Demo_X" --product-name "Demo"
reject "a --product-id past 64 characters" "--product-id" "pppppppppp" \
  "${BASE[@]}" --create --product-id "$(printf 'p%.0s' {1..65})" --product-name "Demo"
reject "a quote in --product-name" "--product-name" 'Demo"Name' \
  "${BASE[@]}" --create --product-id "demo" --product-name 'Demo"Name'
reject "a --product-name past 80 characters" "--product-name" "NNNNNNNNNN" \
  "${BASE[@]}" --create --product-id "demo" --product-name "$(printf 'N%.0s' {1..81})"
reject "an empty --product-name" "--product-name" "zzz-none" \
  "${BASE[@]}" --create --product-id "demo" --product-name ""

echo "=== req-008: --component ==="

reject "a --component id that breaks the pattern" "--component" "Bad_ID" \
  "${BASE[@]}" --component "Bad_ID=planifest-framework/component.yml"
reject "a --component id past 64 characters" "--component" "cccccccccc" \
  "${BASE[@]}" --component "$(printf 'c%.0s' {1..65})=planifest-framework/component.yml"
reject "a --component with no =" "--component" "noequals-xyz" \
  "${BASE[@]}" --component "noequals-xyz"
reject "a --component path with a space" "--component" "a b" \
  "${BASE[@]}" --component "widget=a b/component.yml"
reject "a --component path past 256 characters" "--component" "xxxxxxxxxx" \
  "${BASE[@]}" --component "widget=$(printf 'x%.0s' {1..250})/component.yml"
reject "a --component path that is not component.yml" "--component" "other.yml" \
  "${BASE[@]}" --component "widget=src/widget/other.yml"
reject "a --component path that starts with /" "--component" "/etc" \
  "${BASE[@]}" --component "widget=/etc/component.yml"
reject "a --component path with a .. segment" "--component" "src/.." \
  "${BASE[@]}" --component "widget=src/../planifest-framework/component.yml"
reject "a --component path with an empty segment" "--component" "src//widget" \
  "${BASE[@]}" --component "widget=src//widget/component.yml"
reject "a --component path with no file" "--component" "missing" \
  "${BASE[@]}" --component "widget=src/missing/component.yml"
ln -s "$SCRATCH/outside/comp" "$R/src/link"
reject "a --component path that resolves outside the root" "--component" "src/link" \
  "${BASE[@]}" --component "widget=src/link/component.yml"

echo "=== req-008: counts and unknown arguments ==="

MANY=()
for n in $(seq 1 65); do MANY+=(--component "c$n=planifest-framework/component.yml"); done
reject "more than 64 --component arguments" "--component" "c65=" "${BASE[@]}" "${MANY[@]}"
reject "two --component arguments that share an id" "--component" "widget=" \
  "${BASE[@]}" --component "widget=src/widget/component.yml" --component "widget=src/gadget/component.yml"
reject "a repeated --version" "--version" "0.33.0" "${BASE[@]}" --version "0.33.0"
reject "a repeated --feature-id" "--feature-id" "$ID" "${BASE[@]}" --feature-id "$ID"
reject "a repeated --create" "--create" "zzz-none" "${BASE[@]}" "${CREATE[@]}" --create
reject "a repeated --root" "--root" "$R" "${BASE[@]}" --root "$R" --root "$R"
reject "a repeated --product-id" "--product-id" "demo-twice" \
  "${BASE[@]}" --create --product-id "demo-twice" --product-id "demo-twice" --product-name "Demo"
reject "a repeated --product-name" "--product-name" "Twice Name" \
  "${BASE[@]}" --create --product-id "demo" --product-name "Twice Name" --product-name "Twice Name"
reject "a missing --component value" "--component" "zzz-none" "${BASE[@]}" --component
mkdir -p "$R/src/dir/component.yml"
reject "a --component path that is a folder" "--component" "src/dir" \
  "${BASE[@]}" --component "widget=src/dir/component.yml"
reject "an unknown argument" "argument" "evil-flag" "${BASE[@]}" --evil-flag
reject "a missing --version value" "--version" "zzz-none" --feature-id "$ID" --version
reject "an absent --feature-id" "--feature-id" "zzz-none" --version "0.33.0"

echo "=== req-008: product.yml link ==="

L="$SCRATCH/linkroot"
make_root "$L"
cp "$L/product.yml" "$SCRATCH/outside/product.yml"
rm "$L/product.yml"
ln -s "$SCRATCH/outside/product.yml" "$L/product.yml"
cp "$SCRATCH/outside/product.yml" "$SCRATCH/outside-before.yml"
ERR=$(cd "$L" && env -u CLAUDE_PROJECT_DIR node "$SET" "${BASE[@]}" 2>&1 >/dev/null)
assert_equals "2" "$?" "req-008: a product.yml link to a file outside the root exits 2"
assert_contains "product.yml" "$ERR" "req-008: the link case names product.yml"
assert_equals "same" "$(cmp -s "$SCRATCH/outside-before.yml" "$SCRATCH/outside/product.yml" && echo same || echo differs)" \
  "req-008: the link target stays unchanged"
assert_equals "link" "$([ -L "$L/product.yml" ] && echo link || echo other)" "req-008: the link itself stays in place"

D="$SCRATCH/dangleroot"
make_root "$D"
rm "$D/product.yml"
ln -s "$SCRATCH/outside/nothing.yml" "$D/product.yml"
(cd "$D" && env -u CLAUDE_PROJECT_DIR node "$SET" "${BASE[@]}" "${CREATE[@]}" >/dev/null 2>&1)
assert_equals "2" "$?" "req-008: a dangling product.yml link exits 2"
assert_equals "absent" "$([ -e "$SCRATCH/outside/nothing.yml" ] && echo present || echo absent)" \
  "req-008: a dangling link creates no target"

echo "=== req-008: Hard Limit 8 sanctioned scripts in both boot templates ==="

EXPECTED=$(printf '%s\n' \
  planifest-framework/scripts/archive-current.mjs \
  planifest-framework/scripts/set-product-release.mjs \
  planifest-framework/scripts/promote-to-regression.sh \
  planifest-framework/scripts/refresh-delete-boot-files.sh \
  planifest-framework/scripts/refresh-delete-boot-files.ps1 \
  planifest-framework/setup.sh \
  planifest-framework/setup.ps1 | sort)

# sanctioned <template>: the sorted script paths in its Sanctioned sentence.
sanctioned() {
  grep '^8\. \*\*Code changes go through Write or Edit' "$1" \
    | sed -n 's/.*Sanctioned scripts:\(.*\)/\1/p' \
    | grep -o '`planifest-framework/[^`]*`' | tr -d '`' | sort -u
}

for T in "$STANDARD_BOOT" "$CURSOR_BOOT"; do
  NAME=$(basename "$T")
  HL8=$(grep '^8\. \*\*Code changes go through Write or Edit' "$T")
  assert_equals "1" "$(grep -c 'Sanctioned scripts:' "$T")" "req-008: $NAME holds one Sanctioned scripts: sentence"
  assert_contains "Sanctioned scripts:" "$HL8" "req-008: $NAME puts the sentence inside Hard Limit 8"
  assert_contains "no other script counts" "$HL8" "req-008: $NAME says no other script counts"
  assert_contains "skill step" "$HL8" "req-008: $NAME says a named script counts only when a skill step runs it"
  assert_equals "$EXPECTED" "$(sanctioned "$T")" "req-008: $NAME names exactly the seven sanctioned scripts"
done
assert_equals "$(sanctioned "$STANDARD_BOOT")" "$(sanctioned "$CURSOR_BOOT")" \
  "req-008: both templates name the same scripts"
SENT_STD=$(grep -o 'Sanctioned scripts:.*' "$STANDARD_BOOT")
SENT_CUR=$(grep -o 'Sanctioned scripts:.*' "$CURSOR_BOOT")
assert_equals "$SENT_STD" "$SENT_CUR" "req-008: both templates carry the same sentence"

print_summary
