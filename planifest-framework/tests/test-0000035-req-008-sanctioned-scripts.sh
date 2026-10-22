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
if ln -s "$R" "$SCRATCH/rootlink" 2>/dev/null; then
  (cd "$R" && env -u CLAUDE_PROJECT_DIR node "$SET" "${BASE[@]}" --root "$SCRATCH/rootlink" >/dev/null 2>&1)
  assert_equals "0" "$?" "req-008: a --root link whose real path is the resolved root exits 0"
fi
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

echo "=== req-008: P5 hardening of the product.yml write ==="

# inode <file> and mode <file>: portable through Node, not stat(1).
inode() { node -e 'console.log(require("fs").statSync(process.argv[1]).ino)' "$1"; }
mode() { node -e 'console.log((require("fs").statSync(process.argv[1]).mode & 0o777).toString(8))' "$1"; }
same() { cmp -s "$1" "$2" && echo same || echo differs; }

# P-S04: a hard link at product.yml looks like a regular file to lstat.
HL="$SCRATCH/hardroot"
make_root "$HL"
cp "$HL/product.yml" "$SCRATCH/outside/hard.yml"
rm "$HL/product.yml"
if ln "$SCRATCH/outside/hard.yml" "$HL/product.yml" 2>/dev/null; then
  cp "$SCRATCH/outside/hard.yml" "$SCRATCH/hard-before.yml"
  ERR=$(cd "$HL" && env -u CLAUDE_PROJECT_DIR node "$SET" "${BASE[@]}" 2>&1 >/dev/null)
  assert_equals "2" "$?" "req-008: a hard-linked product.yml exits 2"
  assert_contains "product.yml" "$ERR" "req-008: the hard-link case names product.yml"
  assert_equals "same" "$(same "$SCRATCH/hard-before.yml" "$SCRATCH/outside/hard.yml")" \
    "req-008: the hard-link case leaves the file outside the root unchanged"
fi

# P-S05: the script reads product.yml through the descriptor it checked.
SRC=$(cat "$SET")
lacks "readFileSync(target" "$SRC" "req-008: the script never reads product.yml by path after the check"
assert_contains "fstatSync" "$SRC" "req-008: the script checks the open descriptor with fstat"

# P-S06: the write goes to a temp file in the same folder, then a rename.
A="$SCRATCH/atomroot"
make_root "$A"
chmod 600 "$A/product.yml"
INODE_BEFORE=$(inode "$A/product.yml")
(cd "$A" && env -u CLAUDE_PROJECT_DIR node "$SET" "${BASE[@]}" >/dev/null 2>&1)
assert_equals "0" "$?" "req-008: the atomic-write case exits 0"
assert_contains 'feature: "0000035-write-gate-scope-and-path-hardening"' "$(cat "$A/product.yml")" \
  "req-008: the atomic write lands the new feature"
assert_equals "differs" "$([ "$INODE_BEFORE" = "$(inode "$A/product.yml")" ] && echo same || echo differs)" \
  "req-008: the write replaces product.yml by rename, not in place"
assert_equals "600" "$(mode "$A/product.yml")" "req-008: the rename keeps the mode of the old product.yml"
assert_equals "" "$(ls -A "$A" | grep -v -x -e planifest-framework -e src -e product.yml)" \
  "req-008: no temp file stays after a write"

# P-S06 and P-S07: a root folder the script can't write to.
if [ "$(id -u)" != "0" ]; then
  W="$SCRATCH/roroot"
  make_root "$W"
  cp "$W/product.yml" "$SCRATCH/ro-before.yml"
  chmod 555 "$W"
  ERR=$(cd "$W" && env -u CLAUDE_PROJECT_DIR node "$SET" "${BASE[@]}" 2>&1 >/dev/null)
  CODE=$?
  chmod 755 "$W"
  assert_equals "2" "$CODE" "req-008: a root the script can't write to exits 2"
  assert_contains "EACCES" "$ERR" "req-008: the write failure names the error code"
  lacks "$W" "$ERR" "req-008: the write failure never prints a path"
  lacks "    at " "$ERR" "req-008: the write failure prints no stack trace"
  assert_equals "same" "$(same "$SCRATCH/ro-before.yml" "$W/product.yml")" \
    "req-008: the write failure leaves product.yml unchanged"
  assert_equals "" "$(ls -A "$W" | grep -v -x -e planifest-framework -e src -e product.yml)" \
    "req-008: the write failure leaves no temp file"

  # P-S07: a product.yml the script can't read.
  U="$SCRATCH/unreadroot"
  make_root "$U"
  chmod 000 "$U/product.yml"
  ERR=$(cd "$U" && env -u CLAUDE_PROJECT_DIR node "$SET" "${BASE[@]}" 2>&1 >/dev/null)
  CODE=$?
  chmod 644 "$U/product.yml"
  assert_equals "2" "$CODE" "req-008: an unreadable product.yml exits 2"
  assert_contains "EACCES" "$ERR" "req-008: the read failure names the error code"
  lacks "$U" "$ERR" "req-008: the read failure never prints a path"
  lacks "    at " "$ERR" "req-008: the read failure prints no stack trace"
fi

# P-S08: components[].path read from product.yml meets the --component rules.
mkdir -p "$SCRATCH/evil"
printf 'id: evil\nversion: "9.9.9"\n' > "$SCRATCH/evil/component.yml"
manifest_path_case() {
  local label="$1" path="$2" m="$SCRATCH/mp-$3"
  make_root "$m"
  mkdir -p "$m/src"
  ln -s "$SCRATCH/evil" "$m/src/evil-link" 2>/dev/null
  cat > "$m/product.yml" <<YAML
id: "demo"
name: "Demo Product"
version: "0.30.0"
feature: "0000031-ci-test-and-powershell-coverage"
versionPolicy: "max-component-version"

components:
  - id: "planifest-framework"
    path: "planifest-framework/component.yml"
  - id: "evil"
    path: "$path"
YAML
  cp "$m/product.yml" "$SCRATCH/mp-before.yml"
  ERR=$(cd "$m" && env -u CLAUDE_PROJECT_DIR node "$SET" --feature-id "$ID" --version "9.9.9" 2>&1 >/dev/null)
  assert_equals "2" "$?" "req-008: a manifest path $label exits 2"
  assert_contains "component evil" "$ERR" "req-008: a manifest path $label names the component"
  lacks "$path" "$ERR" "req-008: a manifest path $label never echoes the path"
  assert_equals "same" "$(same "$SCRATCH/mp-before.yml" "$m/product.yml")" \
    "req-008: a manifest path $label leaves product.yml unchanged"
}
manifest_path_case "with a .. segment" "../evil/component.yml" dotdot
manifest_path_case "that starts with /" "$SCRATCH/evil/component.yml" abs
manifest_path_case "through a link outside the root" "src/evil-link/component.yml" link
manifest_path_case "that is not component.yml" "src/widget/other.yml" name

# P-N1: a component.yml hard-linked to a file outside the root passes the
# real-path check, so the script must check the link count it reads through.
HC="$SCRATCH/hardcomp"
make_root "$HC"
mkdir -p "$HC/src/hl"
if ln "$SCRATCH/evil/component.yml" "$HC/src/hl/component.yml" 2>/dev/null; then
  cat > "$HC/product.yml" <<'YAML'
id: "demo"
name: "Demo Product"
version: "0.30.0"
feature: "0000031-ci-test-and-powershell-coverage"
versionPolicy: "max-component-version"

components:
  - id: "planifest-framework"
    path: "planifest-framework/component.yml"
  - id: "hl"
    path: "src/hl/component.yml"
YAML
  cp "$HC/product.yml" "$SCRATCH/hc-before.yml"
  ERR=$(cd "$HC" && env -u CLAUDE_PROJECT_DIR node "$SET" --feature-id "$ID" --version "9.9.9" 2>&1 >/dev/null)
  assert_equals "2" "$?" "req-008: a hard-linked manifest component.yml exits 2"
  assert_contains "component hl" "$ERR" "req-008: the hard-linked component case names the component"
  lacks "src/hl" "$ERR" "req-008: the hard-linked component case never echoes the path"
  assert_equals "same" "$(same "$SCRATCH/hc-before.yml" "$HC/product.yml")" \
    "req-008: the hard-linked component case leaves product.yml unchanged"
  ERR=$(cd "$HC" && env -u CLAUDE_PROJECT_DIR node "$SET" --feature-id "$ID" --version "0.33.0" \
    --component "planifest-framework=planifest-framework/component.yml" --component "hl=src/hl/component.yml" 2>&1 >/dev/null)
  assert_equals "2" "$?" "req-008: a hard-linked --component path exits 2"
  assert_contains "--component 2" "$ERR" "req-008: the hard-linked --component case names the argument"
  lacks "src/hl" "$ERR" "req-008: the hard-linked --component case never echoes the path"
  assert_equals "same" "$(same "$SCRATCH/hc-before.yml" "$HC/product.yml")" \
    "req-008: the hard-linked --component case leaves product.yml unchanged"
fi
SRC=$(cat "$SET")
lacks "readFileSync(real" "$SRC" "req-008: the script never reads a component.yml by path after the check"

# P-N2: malformed product.yml content exits 2 with a fixed message. It never
# crashes with exit 1 and a stack trace that holds the absolute path.
malformed_case() {
  local label="$1" key="$2" line="$3" m="$SCRATCH/mf-$4"
  make_root "$m"
  node -e '
    const fs = require("fs");
    const [file, key, line] = process.argv.slice(1);
    const text = fs.readFileSync(file, "utf8").split("\n")
      .map((l) => (l.startsWith(key + ":") ? JSON.parse(line) : l)).join("\n");
    fs.writeFileSync(file, text);
  ' "$m/product.yml" "$key" "$line"
  cp "$m/product.yml" "$SCRATCH/mf-before.yml"
  ERR=$(cd "$m" && env -u CLAUDE_PROJECT_DIR node "$SET" "${BASE[@]}" 2>&1 >/dev/null)
  assert_equals "2" "$?" "req-008: $label exits 2"
  assert_contains "product.yml" "$ERR" "req-008: $label names product.yml"
  lacks "$m" "$ERR" "req-008: $label never prints a path"
  lacks "$FRAMEWORK" "$ERR" "req-008: $label never prints the script path"
  lacks "    at " "$ERR" "req-008: $label prints no stack trace"
  assert_equals "same" "$(same "$SCRATCH/mf-before.yml" "$m/product.yml")" \
    "req-008: $label leaves product.yml unchanged"
}
malformed_case "a lone CR in the version line" "version" '"version: \"0.30.0\"\r# note"' cr
malformed_case "a U+2028 in the feature line" "feature" '"feature: \"0000031-x\" # a b"' ls

# P-N2: a top-level key that shares a name with an Object.prototype member
# is an ordinary key, not a repeat.
PK="$SCRATCH/protokey"
make_root "$PK"
printf 'constructor: "x"\ntoString: "y"\n' >> "$PK/product.yml"
(cd "$PK" && env -u CLAUDE_PROJECT_DIR node "$SET" "${BASE[@]}" >/dev/null 2>&1)
assert_equals "0" "$?" "req-008: a top-level constructor or toString key exits 0"

# P-S03: CLAUDE_PROJECT_DIR never moves the write to another root.
P="$SCRATCH/projroot"
O="$SCRATCH/otherroot"
make_root "$P"
make_root "$O"
cp "$O/product.yml" "$SCRATCH/other-before.yml"
(cd "$P" && CLAUDE_PROJECT_DIR="$O" node "$SET" "${BASE[@]}" >/dev/null 2>&1)
assert_equals "0" "$?" "req-008: a call with CLAUDE_PROJECT_DIR set elsewhere exits 0"
assert_equals "same" "$(same "$SCRATCH/other-before.yml" "$O/product.yml")" \
  "req-008: CLAUDE_PROJECT_DIR never redirects the write"
assert_contains 'feature: "0000035-write-gate-scope-and-path-hardening"' "$(cat "$P/product.yml")" \
  "req-008: the write lands in the root for the working directory"

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
  # P-S10: setup counts only with a tool name and the two refresh flags.
  assert_contains "--include-full-skill-library" "$HL8" "req-008: $NAME names the setup flags it sanctions"
  assert_contains "--strict-orchestrator" "$HL8" "req-008: $NAME names --strict-orchestrator"
  assert_contains '`add-skill` and every other subcommand or flag are not sanctioned' "$HL8" \
    "req-008: $NAME says add-skill and any other subcommand are not sanctioned"
  lacks "with arguments to write files" "$HL8" "req-008: $NAME no longer sanctions any arguments"
done
assert_equals "$(sanctioned "$STANDARD_BOOT")" "$(sanctioned "$CURSOR_BOOT")" \
  "req-008: both templates name the same scripts"
echo "=== req-008: promote-to-regression.sh binds its source and destination ==="

# P-S09: a fixture framework tree that holds a copy of the script, so
# SCRIPT_DIR-relative paths resolve inside the fixture.
FX="$SCRATCH/promote"
mkdir -p "$FX/planifest-framework/scripts" "$FX/planifest-framework/tests/regression" \
  "$FX/planifest-framework/tests/helpers" "$FX/outside" "$FX/elsewhere"
cp "$FRAMEWORK/scripts/promote-to-regression.sh" "$FX/planifest-framework/scripts/"
PROMOTE_FX="$FX/planifest-framework/scripts/promote-to-regression.sh"
FXT="$FX/planifest-framework/tests"
printf '{"tests":[]}\n' > "$FXT/regression/regression-manifest.json"
printf '{"tests":[]}\n' > "$FX/elsewhere/regression-manifest.json"
printf 'secret\n' > "$FX/outside/test-secret.sh"
printf '#!/usr/bin/env bash\necho ok\n' > "$FXT/test-ok.sh"
cp "$FXT/test-ok.sh" "$FXT/test-ok2.sh"
cp "$FXT/test-ok.sh" "$FXT/notatest.sh"
cp "$FXT/test-ok.sh" "$FXT/helpers/test-helper.sh"
ln -s "$FX/outside/test-secret.sh" "$FXT/test-link.sh"
ln "$FX/outside/test-secret.sh" "$FXT/test-hard.sh" 2>/dev/null
cp "$FX/outside/test-secret.sh" "$SCRATCH/secret-before.sh"

# refuse_promote <label> <source>: exit 1 and no new file in regression/.
refuse_promote() {
  local before after
  before=$(ls -A "$FXT/regression" | sort)
  (cd "$FX" && env -u PLANIFEST_REGRESSION_DIR bash "$PROMOTE_FX" "$2" "0000035-x" "agent" >/dev/null 2>&1)
  assert_equals "1" "$?" "req-008: promote refuses $1"
  after=$(ls -A "$FXT/regression" | sort)
  assert_equals "$before" "$after" "req-008: promote of $1 adds nothing to regression/"
}

refuse_promote "a source outside tests/" "$FX/outside/test-secret.sh"
refuse_promote "a source that is not test-*.sh" "$FXT/notatest.sh"
refuse_promote "a source in a tests/ subfolder" "$FXT/helpers/test-helper.sh"
refuse_promote "a source that is a link" "$FXT/test-link.sh"
[ -f "$FXT/test-hard.sh" ] && refuse_promote "a source with a second hard link" "$FXT/test-hard.sh"

ERR=$(cd "$FX" && PLANIFEST_REGRESSION_DIR="$FX/elsewhere" bash "$PROMOTE_FX" "$FXT/test-ok.sh" "0000035-x" "agent" 2>&1)
assert_equals "1" "$?" "req-008: promote refuses a PLANIFEST_REGRESSION_DIR outside tests/regression/"
assert_equals "regression-manifest.json" "$(ls -A "$FX/elsewhere")" \
  "req-008: the redirected destination stays unchanged"

ln -s "$FX/outside/test-secret.sh" "$FXT/regression/test-ok2.sh"
refuse_promote "a destination that is a link" "$FXT/test-ok2.sh"
assert_equals "same" "$(same "$SCRATCH/secret-before.sh" "$FX/outside/test-secret.sh")" \
  "req-008: the destination link target stays unchanged"
rm "$FXT/regression/test-ok2.sh"

# P-N3: a hard link at the destination would let cp overwrite the file
# outside tests/regression/.
printf 'victim\n' > "$FX/outside/victim-hl.sh"
cp "$FX/outside/victim-hl.sh" "$SCRATCH/victim-hl-before.sh"
cp "$FXT/test-ok.sh" "$FXT/test-hl.sh"
if ln "$FX/outside/victim-hl.sh" "$FXT/regression/test-hl.sh" 2>/dev/null; then
  refuse_promote "a destination with a second hard link" "$FXT/test-hl.sh"
  assert_equals "same" "$(same "$SCRATCH/victim-hl-before.sh" "$FX/outside/victim-hl.sh")" \
    "req-008: the hard-linked destination target stays unchanged"
  rm "$FXT/regression/test-hl.sh"
fi
rm "$FXT/test-hl.sh"

# P-N3 (backlog 0000147): a link at the old $DEST.tmp path is never written
# through, and never installed as the destination.
printf 'victim\n' > "$FX/outside/victim-tmp.sh"
cp "$FX/outside/victim-tmp.sh" "$SCRATCH/victim-tmp-before.sh"
cp "$FXT/test-ok.sh" "$FXT/test-tmp.sh"
ln -s "$FX/outside/victim-tmp.sh" "$FXT/regression/test-tmp.sh.tmp"
(cd "$FX" && env -u PLANIFEST_REGRESSION_DIR bash "$PROMOTE_FX" "$FXT/test-tmp.sh" "0000035-x" "agent" >/dev/null 2>&1)
assert_equals "same" "$(same "$SCRATCH/victim-tmp-before.sh" "$FX/outside/victim-tmp.sh")" \
  "req-008: a link at the temp path leaves its target unchanged"
assert_equals "absent" "$([ -L "$FXT/regression/test-tmp.sh" ] && echo present || echo absent)" \
  "req-008: a link at the temp path never becomes the destination"
rm -f "$FXT/regression/test-tmp.sh.tmp"

# promote_fixture <dir>: a fresh framework tree with one test-ok.sh source.
promote_fixture() {
  mkdir -p "$1/planifest-framework/scripts" "$1/planifest-framework/tests/regression" "$1/outside"
  cp "$FRAMEWORK/scripts/promote-to-regression.sh" "$1/planifest-framework/scripts/"
  cp "$FXT/test-ok.sh" "$1/planifest-framework/tests/test-ok.sh"
}
promote_in() {
  (cd "$1" && env -u PLANIFEST_REGRESSION_DIR bash "$1/planifest-framework/scripts/promote-to-regression.sh" \
    "$1/planifest-framework/tests/test-ok.sh" "0000035-x" "agent" >/dev/null 2>&1)
}

# P-N3: a manifest that is a symlink or a hard link would carry the
# manifest write outside tests/regression/.
for KIND in sym hard; do
  FM="$SCRATCH/promote-manifest-$KIND"
  promote_fixture "$FM"
  printf '{"tests":[]}\n' > "$FM/outside/manifest.json"
  cp "$FM/outside/manifest.json" "$SCRATCH/manifest-before.json"
  if [ "$KIND" = sym ]; then
    ln -s "$FM/outside/manifest.json" "$FM/planifest-framework/tests/regression/regression-manifest.json"
  else
    ln "$FM/outside/manifest.json" "$FM/planifest-framework/tests/regression/regression-manifest.json" 2>/dev/null || continue
  fi
  promote_in "$FM"
  assert_equals "1" "$?" "req-008: promote refuses a $KIND-linked manifest"
  assert_equals "same" "$(same "$SCRATCH/manifest-before.json" "$FM/outside/manifest.json")" \
    "req-008: the $KIND-linked manifest target stays unchanged"
  assert_equals "regression-manifest.json" "$(ls -A "$FM/planifest-framework/tests/regression")" \
    "req-008: promote with a $KIND-linked manifest adds nothing to regression/"
done

# P-N3: a tests/ folder that is a link moves the whole binding elsewhere.
FT="$SCRATCH/promote-linked-tests"
mkdir -p "$FT/planifest-framework/scripts" "$FT/realtests/regression"
cp "$FRAMEWORK/scripts/promote-to-regression.sh" "$FT/planifest-framework/scripts/"
printf '{"tests":[]}\n' > "$FT/realtests/regression/regression-manifest.json"
cp "$FXT/test-ok.sh" "$FT/realtests/test-ok.sh"
ln -s "$FT/realtests" "$FT/planifest-framework/tests"
promote_in "$FT"
assert_equals "1" "$?" "req-008: promote refuses a tests/ folder that is a link"
assert_equals "regression-manifest.json" "$(ls -A "$FT/realtests/regression")" \
  "req-008: the linked tests/ folder stays unchanged"

# P-N3: the manifest write goes through a temp file and a rename.
PSRC=$(cat "$FRAMEWORK/scripts/promote-to-regression.sh")
lacks '"$DEST.tmp"' "$PSRC" "req-008: promote never writes a fixed temp path"
lacks "fs.writeFileSync('regression-manifest.json'" "$PSRC" "req-008: promote never writes the manifest in place"

(cd "$FX" && env -u PLANIFEST_REGRESSION_DIR bash "$PROMOTE_FX" "$FXT/test-ok.sh" "0000035-x" "agent" >/dev/null 2>&1)
assert_equals "0" "$?" "req-008: promote of a test-*.sh in tests/ exits 0"
assert_equals "present" "$([ -f "$FXT/regression/test-ok.sh" ] && echo present || echo absent)" \
  "req-008: promote copies the test into regression/"
assert_equals "" "$(ls -A "$FXT/regression" | grep -e '^\.promote-' -e '^\.regression-manifest-')" \
  "req-008: promote leaves no temp file in regression/"
assert_contains '"test-ok.sh"' "$(cat "$FXT/regression/regression-manifest.json")" \
  "req-008: promote records the test in the manifest"

FL="$SCRATCH/promote-linked"
mkdir -p "$FL/planifest-framework/scripts" "$FL/planifest-framework/tests" "$FL/realreg"
cp "$PROMOTE_FX" "$FL/planifest-framework/scripts/"
printf '{"tests":[]}\n' > "$FL/realreg/regression-manifest.json"
ln -s "$FL/realreg" "$FL/planifest-framework/tests/regression"
cp "$FXT/test-ok.sh" "$FL/planifest-framework/tests/test-ok.sh"
(cd "$FL" && env -u PLANIFEST_REGRESSION_DIR bash "$FL/planifest-framework/scripts/promote-to-regression.sh" \
  "$FL/planifest-framework/tests/test-ok.sh" "0000035-x" "agent" >/dev/null 2>&1)
assert_equals "1" "$?" "req-008: promote refuses a tests/regression/ that is a link"
assert_equals "regression-manifest.json" "$(ls -A "$FL/realreg")" \
  "req-008: the linked regression folder stays unchanged"

SENT_STD=$(grep -o 'Sanctioned scripts:.*' "$STANDARD_BOOT")
SENT_CUR=$(grep -o 'Sanctioned scripts:.*' "$CURSOR_BOOT")
assert_equals "$SENT_STD" "$SENT_CUR" "req-008: both templates carry the same sentence"

print_summary
