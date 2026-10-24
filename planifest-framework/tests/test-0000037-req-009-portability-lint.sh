#!/usr/bin/env bash
# Verified by: integration
# test-0000037-req-009-portability-lint.sh
# req-009: portable suites and the portability lint (ADR-011).
# The lint flags GNU and BSD differences in command position. A line carries
# `# portable-ok: {reason}` when the unportable form is deliberate (FR-009.4).
# `# portable-ok:` silences the lint only. It does not replace the
# `SKIP (windows):` run-time guard from req-010 (FR-009.4a).
# Run from any directory: bash planifest-framework/tests/test-0000037-req-009-portability-lint.sh

set -o pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_DIR="$SCRIPT_DIR"
if [ "$(basename "$SCRIPT_DIR")" = "regression" ]; then
  TESTS_DIR="$(dirname "$SCRIPT_DIR")"
fi
source "$TESTS_DIR/helpers/assert.sh"

SELF_NAME="test-0000037-req-009-portability-lint.sh"

# ---------------------------------------------------------------------------
# The lint. A tool name matches only in command position (ADR-011 decision 2).
# ---------------------------------------------------------------------------

Q="'"
DQ='"'
BT='`'
PFX="(^|[|;&(${BT}${Q}${DQ}])[[:space:]]*"
RE_COMMENT='^[[:space:]]*#'
RE_MARKER='#[[:space:]]*portable-ok:[[:space:]]*[^[:space:]]'
RE_PATH="^[[:space:]]*((local|export|readonly)[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*=[${DQ}${Q}]?planifest-framework/"

FINDINGS=()
SUPPRESSED=0
SCANNED=0
SEGS=()
RULES=()

# Fill SEGS with the argument text that follows each command-position use of $1 in $2.
segments_after() {
  local tool="$1" rest="$2" seg
  local re="${PFX}${tool}[[:space:]]+(.*)\$"
  SEGS=()
  while [[ $rest =~ $re ]]; do
    rest="${BASH_REMATCH[2]}"
    seg="${rest%%[|;&]*}"
    SEGS+=("$seg")
  done
}

# True when any word in $2 matches the ERE $1.
any_token() {
  local re="$1" tok
  local -a toks
  read -ra toks <<< "$2"
  for tok in ${toks[@]+"${toks[@]}"}; do
    if [[ $tok =~ $re ]]; then return 0; fi
  done
  return 1
}

# Fill RULES with the rule name for each unportable form on the line.
# $2 is 1 when the file holds a sha256sum command.
line_rules() {
  local line="$1" has_sha="$2" seg
  RULES=()

  segments_after grep "$line"
  for seg in ${SEGS[@]+"${SEGS[@]}"}; do
    if any_token '^(-[A-Za-z]*[rR][A-Za-z]*|--recursive)$' "$seg" \
       && ! any_token '^(-[A-Za-z]*[HlLc][A-Za-z]*|--with-filename|--files-with-matches|--files-without-match|--count)$' "$seg"; then
      RULES+=("grep-recursive")
    fi
    if any_token '^-[A-Za-z]*P[A-Za-z]*$' "$seg"; then RULES+=("gnu-grep-P"); fi
  done

  segments_after sed "$line"
  for seg in ${SEGS[@]+"${SEGS[@]}"}; do
    if any_token '^-i$' "$seg"; then RULES+=("sed-inplace"); fi
  done

  if [ "$has_sha" -eq 0 ]; then
    segments_after shasum "$line"
    if [ "${#SEGS[@]}" -gt 0 ]; then RULES+=("shasum-no-fallback"); fi
  fi

  if [[ $line =~ $RE_PATH ]]; then RULES+=("path-literal"); fi

  segments_after timeout "$line"
  if [ "${#SEGS[@]}" -gt 0 ]; then RULES+=("gnu-timeout"); fi
  segments_after readlink "$line"
  for seg in ${SEGS[@]+"${SEGS[@]}"}; do
    if any_token '^-f$' "$seg"; then RULES+=("gnu-readlink-f"); fi
  done
  segments_after stat "$line"
  for seg in ${SEGS[@]+"${SEGS[@]}"}; do
    if any_token '^-c$' "$seg"; then RULES+=("gnu-stat-c"); fi
  done
  segments_after date "$line"
  for seg in ${SEGS[@]+"${SEGS[@]}"}; do
    if any_token '^-d$' "$seg"; then RULES+=("gnu-date-d"); fi
  done
  segments_after xargs "$line"
  for seg in ${SEGS[@]+"${SEGS[@]}"}; do
    if any_token '^-r$' "$seg"; then RULES+=("gnu-xargs-r"); fi
  done
}

# lint_file BASE FILE: append findings as "{file}:{line}: {rule}: {text}".
lint_file() {
  local base="$1" file="$2" rel n=0 line prev="" prev_marker=0 has_sha=0 rule
  rel="${file#"$base"/}"
  SCANNED=$((SCANNED + 1))
  if grep -qE "${PFX}sha256sum([[:space:]]|\$)" "$file"; then has_sha=1; fi
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    if [[ $line =~ $RE_COMMENT ]]; then
      prev_marker=0
      if [[ $line =~ $RE_MARKER ]]; then prev_marker=1; fi
      continue
    fi
    line_rules "$line" "$has_sha"
    if [ "${#RULES[@]}" -gt 0 ]; then
      if [[ $line =~ $RE_MARKER ]] || [ "$prev_marker" -eq 1 ]; then
        SUPPRESSED=$((SUPPRESSED + 1))
      else
        for rule in "${RULES[@]}"; do
          FINDINGS+=("$rel:$n: $rule: $line")
        done
      fi
    fi
    prev_marker=0
  done < "$file"
}

# lint_dir DIR: scan test-*.sh, regression/test-*.sh, helpers/*.sh, and run-tests.sh.
# The scan skips any file named like this suite, by basename (ADR-011 decision 8).
lint_dir() {
  local dir="$1" f
  FINDINGS=()
  SUPPRESSED=0
  SCANNED=0
  for f in "$dir"/test-*.sh "$dir"/regression/test-*.sh "$dir"/helpers/*.sh "$dir"/run-tests.sh; do
    [ -f "$f" ] || continue
    [ "$(basename "$f")" = "$SELF_NAME" ] && continue
    lint_file "$dir" "$f"
  done
}

print_findings() {
  local f
  for f in ${FINDINGS[@]+"${FINDINGS[@]}"}; do echo "        $f"; done
}

has_finding() {
  # has_finding PREFIX: yes when a finding starts with PREFIX
  local f
  for f in ${FINDINGS[@]+"${FINDINGS[@]}"}; do
    if [[ "$f" == "$1"* ]]; then echo "yes"; return; fi
  done
  echo "no"
}

TMP="$(mktemp -d "${TMPDIR:-/tmp}/portlint.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# req-009 AC-009.2 / FR-009.7: fixture self-test
# ---------------------------------------------------------------------------

echo "req-009 AC-009.2: lint flags one line per rule in a fixture"

FX="$TMP/fx-bad"
mkdir -p "$FX/helpers" "$FX/regression"
cat > "$FX/test-bad.sh" <<'FIXTURE'
#!/usr/bin/env bash
grep -rn pattern dir
sed -i 's/a/b/' file
sed -i '' 's/a/b/' file
shasum file
SRC=planifest-framework/templates/a.md
timeout 5 cmd
x | readlink -f path
stat -c %s file
date -d yesterday
echo list | xargs -r echo
grep -P 'a+' file
FIXTURE
lint_dir "$FX"
assert_equals "11" "${#FINDINGS[@]}" "req-009 FR-009.7: fixture yields 11 findings (one per flagged line)"
assert_equals "yes" "$(has_finding 'test-bad.sh:2: grep-recursive: ')" "req-009 AC-009.2: grep -r without -H/-l/-L/-c is flagged"
assert_equals "yes" "$(has_finding 'test-bad.sh:3: sed-inplace: ')" "req-009 AC-009.2: sed -i with no suffix is flagged"
assert_equals "yes" "$(has_finding 'test-bad.sh:4: sed-inplace: ')" "req-009 AC-009.2: sed -i '' is flagged"
assert_equals "yes" "$(has_finding 'test-bad.sh:5: shasum-no-fallback: ')" "req-009 AC-009.2: shasum with no sha256sum fallback is flagged"
assert_equals "yes" "$(has_finding 'test-bad.sh:6: path-literal: ')" "req-009 AC-009.2: bare planifest-framework/ assignment is flagged"
assert_equals "yes" "$(has_finding 'test-bad.sh:7: gnu-timeout: ')" "req-009 AC-009.2: timeout is flagged"
assert_equals "yes" "$(has_finding 'test-bad.sh:8: gnu-readlink-f: ')" "req-009 AC-009.2: readlink -f after a pipe is flagged"
assert_equals "yes" "$(has_finding 'test-bad.sh:9: gnu-stat-c: ')" "req-009 AC-009.2: stat -c is flagged"
assert_equals "yes" "$(has_finding 'test-bad.sh:10: gnu-date-d: ')" "req-009 AC-009.2: date -d is flagged"
assert_equals "yes" "$(has_finding 'test-bad.sh:11: gnu-xargs-r: ')" "req-009 AC-009.2: xargs -r is flagged"
assert_equals "yes" "$(has_finding 'test-bad.sh:12: gnu-grep-P: ')" "req-009 AC-009.2: grep -P is flagged"

echo "req-009 AC-009.2: lint flags no portable form"

FX2="$TMP/fx-good"
mkdir -p "$FX2/helpers" "$FX2/regression"
cat > "$FX2/test-good.sh" <<'FIXTURE'
#!/usr/bin/env bash
# grep -rn in a comment is not a command
grep -rlE pattern dir
grep -rnHE pattern dir
grep -rc pattern dir
sed -i.bak 's/a/b/' file
sha256sum file
shasum -a 256 file
echo "timeout-minutes: 5"
echo '{"timeout": 5}'
echo "the timeout is long and a stat is a number"
dir=$(mktemp -d -t prefix)
cd "$dir" && cat planifest-framework/templates/a.md
FIXTURE
lint_dir "$FX2"
assert_equals "0" "${#FINDINGS[@]}" "req-009 AC-009.2: portable forms and prose raise no finding"
print_findings

echo "req-009 AC-009.2: the portable-ok marker silences a line"

FX3="$TMP/fx-marker"
mkdir -p "$FX3"
cat > "$FX3/test-marker.sh" <<'FIXTURE'
#!/usr/bin/env bash
grep -rn pattern dir # portable-ok: payload string
# portable-ok: payload string
echo "sed -i 's/a/b/' f"
echo "grep -rn x d" # portable-ok:
grep -rn other dir
FIXTURE
lint_dir "$FX3"
assert_equals "2" "${#FINDINGS[@]}" "req-009 FR-009.4: trailing marker and line-above marker silence, empty reason and unmarked do not"
assert_equals "yes" "$(has_finding 'test-marker.sh:5: ')" "req-009 FR-009.4: a marker with no reason does not silence"
assert_equals "yes" "$(has_finding 'test-marker.sh:6: ')" "req-009 FR-009.4: an unmarked line is flagged"
assert_equals "2" "$SUPPRESSED" "req-009 FR-009.4: two lines count as suppressed"

echo "req-009 FR-009.6: finding format"
assert_equals "test-marker.sh:6: grep-recursive: grep -rn other dir" "${FINDINGS[1]}" \
  "req-009 FR-009.6: finding reads {file}:{line}: {rule}: {text}"

echo "req-009 FR-009.3: the scan skips its own file by basename"
FX4="$TMP/fx-self"
mkdir -p "$FX4/regression"
printf 'grep -rn pattern dir\n' > "$FX4/$SELF_NAME"
printf 'grep -rn pattern dir\n' > "$FX4/regression/$SELF_NAME"
lint_dir "$FX4"
assert_equals "0" "${#FINDINGS[@]}" "req-009 FR-009.3: the suite and its regression copy are not scanned"
assert_equals "0" "$SCANNED" "req-009 FR-009.3: skipped files are not counted as scanned"

# ---------------------------------------------------------------------------
# req-009 FR-009.5: sha256_of helper
# ---------------------------------------------------------------------------

echo "req-009 FR-009.5: sha256_of helper"
printf 'abc' > "$TMP/abc.txt"
assert_equals "yes" "$(type -t sha256_of >/dev/null 2>&1 && echo yes || echo no)" "req-009 FR-009.5: helpers/assert.sh defines sha256_of"
assert_equals "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" "$(sha256_of "$TMP/abc.txt" 2>/dev/null)" \
  "req-009 FR-009.5: sha256_of prints the bare SHA-256 digest"
assert_equals "yes" "$(grep -q 'sha256sum' "$TESTS_DIR/helpers/assert.sh" && grep -q 'shasum -a 256' "$TESTS_DIR/helpers/assert.sh" && echo yes || echo no)" \
  "req-009 FR-009.5: helper tries sha256sum and falls back to shasum -a 256"
assert_equals "yes" "$(grep -q 'sha256_of' "$TESTS_DIR/test-0000023-req-003-copilot-setup-self-copy.sh" && echo yes || echo no)" \
  "req-009 FR-009.5: 0000023 req-003 suite uses sha256_of"
assert_equals "yes" "$(grep -q 'sha256_of' "$TESTS_DIR/test-0000030-req-004-install-clean-up-and-retired-flags.sh" && echo yes || echo no)" \
  "req-009 FR-009.5: 0000030 req-004 suite uses sha256_of"

# ---------------------------------------------------------------------------
# req-009 AC-009.3: the real suites report 0 findings
# ---------------------------------------------------------------------------

echo "req-009 AC-009.3: lint over the real suites"
lint_dir "$TESTS_DIR"
echo "  info: scanned $SCANNED files, ${#FINDINGS[@]} findings, $SUPPRESSED marked lines"
assert_equals "0" "${#FINDINGS[@]}" "req-009 AC-009.3: real suites report 0 findings"
print_findings

echo "req-009 AC-009.3: re-adding a bare grep -rn line fails the lint and names file and line"
FX5="$TMP/fx-readd"
mkdir -p "$FX5"
cp "$TESTS_DIR/test-0000031-req-004-setup-flags-marker-check.sh" "$FX5/"
before_lines=$(wc -l < "$FX5/test-0000031-req-004-setup-flags-marker-check.sh" | tr -d ' ')
printf 'grep -rn pattern dir\n' >> "$FX5/test-0000031-req-004-setup-flags-marker-check.sh"
lint_dir "$FX5"
assert_equals "1" "${#FINDINGS[@]}" "req-009 AC-009.3: one finding after re-adding the line"
assert_equals "yes" "$(has_finding "test-0000031-req-004-setup-flags-marker-check.sh:$((before_lines + 1)): grep-recursive: ")" \
  "req-009 AC-009.3: finding names the file and line"

# ---------------------------------------------------------------------------
# req-009 AC-009.1 / FR-009.1, FR-009.2: suite runs from any directory
# ---------------------------------------------------------------------------

echo "req-009 AC-009.1: test-0000010 passes from a temporary directory and from the tests directory"
mkdir -p "$TMP/elsewhere"
( cd "$TMP/elsewhere" && bash "$TESTS_DIR/test-0000010-framework-quality-improvements.sh" >"$TMP/t10-tmp.log" 2>&1 )
assert_exit_zero "$?" "req-009 AC-009.1: test-0000010 exits 0 from a temporary directory"
( cd "$TESTS_DIR" && bash "$TESTS_DIR/test-0000010-framework-quality-improvements.sh" >"$TMP/t10-tests.log" 2>&1 )
assert_exit_zero "$?" "req-009 AC-009.1: test-0000010 exits 0 from the tests directory"

print_summary
