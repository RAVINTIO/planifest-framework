#!/usr/bin/env bash
# Tests for feature 0000039-ravintio-rebrand.
#
# req-001: pack paths and identifiers carry the RAVINTIO name (pack-paths-and-identifiers).
#          AC1: no tracked path contains the old brand outside the protected history paths,
#               and every renamed path exists under its new name.
#          AC2: each skill name: equals its folder, and product.yml, component.yml and the
#               OpenCode package.json carry the new id, name and scope.
#          AC3: the pass commit records the moves as renames. Set RAVINTIO_PASS_COMMIT to
#               the pass commit to run this check. Otherwise AC3 reports SKIP.
#
# The old brand string appears below only where this test checks that it is gone.
#
# Verified by: execution
# Verified by: integration

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
ROOT="$FW/.."
cd "$ROOT" || exit 2

OLD="planif""est"

SKILLS="adr-agent build-assessment-agent change-agent codegen-agent design-critic docs-agent implementer loop-runner migrator optimise-agent orchestrator refactor refresh-setup reversal-assessor scope-lock-agent security-agent ship-agent spec-agent test-writer validate-agent verify-by-execution"

TRACKED="$(git ls-files)"

# has_tracked <prefix>: succeeds when git tracks at least one path under the prefix.
has_tracked() {
  printf '%s\n' "$TRACKED" | grep -qE "^$1"
}

# yaml_top <file> <key>: prints the top-level scalar value, unquoted.
yaml_top() {
  grep -E "^$2:" "$1" | head -1 | sed -E "s/^$2:[[:space:]]*//; s/^\"(.*)\"[[:space:]]*\$/\1/"
}

echo "=== req-001 AC1: no old-brand path outside the protected list ==="

PROTECTED_RE='^plan/(_archive|changelog|_migrations)/|^plan/backlog/[^/]+/_reference/'
leftover=""
while IFS= read -r p; do
  [ -z "$p" ] && continue
  if printf '%s\n' "$p" | grep -qiE "$OLD"; then
    if ! printf '%s\n' "$p" | grep -qE "$PROTECTED_RE"; then
      leftover="$leftover$p"$'\n'
    fi
  fi
done <<< "$TRACKED"
count=0
[ -n "$leftover" ] && count="$(printf '%s' "$leftover" | grep -c .)"
assert_equals "0" "$count" "req-001 AC1: no tracked path carries the old brand outside protected paths ($count found)"
if [ "$count" != "0" ]; then
  printf '%s' "$leftover" | head -5 | while IFS= read -r l; do echo "    leftover: $l"; done
fi

for d in ravintio-framework/ ravintio-overrides/ ravintio-framework/hooks/adapters/opencode/; do
  if has_tracked "$d"; then
    assert_equals "yes" "yes" "req-001 AC1: $d exists"
  else
    assert_equals "yes" "no" "req-001 AC1: $d exists"
  fi
done

for f in .github/workflows/ravintio.yml ravintio-framework/hooks/ravintio.yml refresh-ravintio-framework-dir.ps1; do
  if printf '%s\n' "$TRACKED" | grep -qxF "$f"; then
    assert_equals "yes" "yes" "req-001 AC1: $f exists"
  else
    assert_equals "yes" "no" "req-001 AC1: $f exists"
  fi
done

skill_count=0
for s in $SKILLS; do
  if printf '%s\n' "$TRACKED" | grep -qxF "ravintio-framework/skills/ravintio-$s/SKILL.md"; then
    skill_count=$((skill_count + 1))
  else
    assert_equals "yes" "no" "req-001 AC1: ravintio-framework/skills/ravintio-$s/SKILL.md exists"
  fi
done
assert_equals "21" "$skill_count" "req-001 AC1: 21 ravintio-* skill folders exist"

echo ""
echo "=== req-001 AC2: identifiers carry the new id, name, and scope ==="

bad_names=0
for s in $SKILLS; do
  f="$FW/skills/ravintio-$s/SKILL.md"
  if [ -f "$f" ]; then
    actual="$(awk 'NR==1 && /^---/ {fm=1; next} fm && /^---/ {exit} fm && /^name:/ {sub(/^name:[ \t]*/, ""); gsub(/^"|"[ \t]*$/, ""); print; exit}' "$f")"
  else
    actual="(missing file)"
  fi
  if [ "$actual" != "ravintio-$s" ]; then
    bad_names=$((bad_names + 1))
    echo "    skill name mismatch: ravintio-$s has name: '$actual'"
  fi
done
assert_equals "0" "$bad_names" "req-001 AC2: every SKILL.md name: equals its folder ($bad_names mismatched)"

PY="$ROOT/product.yml"
CY="$FW/component.yml"
PJ="$FW/hooks/adapters/opencode/package.json"

assert_equals "ravintio-framework" "$(yaml_top "$PY" id 2>/dev/null)" "req-001 AC2: product.yml id"
assert_contains "$(yaml_top "$PY" name 2>/dev/null)" "RAVINTIO" "req-001 AC2: product.yml name carries RAVINTIO"
assert_equals "ravintio-framework" "$(yaml_top "$CY" id 2>/dev/null)" "req-001 AC2: component.yml id"
assert_contains "$(yaml_top "$CY" name 2>/dev/null)" "RAVINTIO" "req-001 AC2: component.yml name carries RAVINTIO"

pj_name="$(grep -E '"name"' "$PJ" 2>/dev/null | head -1 | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')"
assert_equals "@ravintio/opencode-hooks" "$pj_name" "req-001 AC2: OpenCode package.json name"

assert_contains "$(cat "$PY" 2>/dev/null)" 'path: "ravintio-framework/component.yml"' "req-001 AC2: product.yml components[] points at ravintio-framework/component.yml"
assert_contains "$(cat "$PY" 2>/dev/null)" '  - id: "ravintio-framework"' "req-001 AC2: product.yml components[] id"

# The brandless component keeps its id (req-001 functional requirement).
SH="$ROOT/src/setup-hook-integration/component.yml"
assert_equals "setup-hook-integration" "$(yaml_top "$SH" id 2>/dev/null)" "req-001 AC2: setup-hook-integration id unchanged"

echo ""
echo "=== req-001 AC3: the pass commit records renames ==="

COMMIT="${RAVINTIO_PASS_COMMIT:-}"
if [ -z "$COMMIT" ]; then
  echo "  SKIP: req-001 AC3: RAVINTIO_PASS_COMMIT is not set. P4 runs this check with the pass commit."
elif ! git rev-parse --verify --quiet "$COMMIT^{commit}" >/dev/null || ! git rev-parse --verify --quiet "$COMMIT^" >/dev/null; then
  assert_equals "valid" "invalid" "req-001 AC3: RAVINTIO_PASS_COMMIT '$COMMIT' resolves to a commit with a parent"
else
  NS="$(git diff -M --name-status "$COMMIT^" "$COMMIT")"
  EXC_FILE="$SCRIPT_DIR/fixtures/0000039-rename-exceptions.txt"
  EXC=""
  if [ -f "$EXC_FILE" ]; then
    EXC="$(grep -vE '^[[:space:]]*(#|$)' "$EXC_FILE" || true)"
  fi

  # is_exception <old path>: succeeds when the path is on the exception list.
  is_exception() {
    [ -n "$EXC" ] && printf '%s\n' "$EXC" | grep -qxF "$1"
  }

  # r_pair <old> <new>: succeeds when an R entry maps old to new.
  r_pair() {
    printf '%s\n' "$NS" | awk -F'\t' -v o="$1" -v n="$2" '$1 ~ /^R/ && $2 == o && $3 == n {f=1} END {exit f ? 0 : 1}'
  }

  # r_prefix <old prefix> <new prefix>: succeeds when an R entry moves a path under old to new.
  r_prefix() {
    printf '%s\n' "$NS" | awk -F'\t' -v o="$1" -v n="$2" '$1 ~ /^R/ && index($2, o) == 1 && index($3, n) == 1 {f=1} END {exit f ? 0 : 1}'
  }

  check_r() {
    local label="$1"; shift
    if "$@"; then
      assert_equals "R" "R" "req-001 AC3: $label reports R"
    elif is_exception "$label"; then
      echo "  PASS: req-001 AC3: $label is on the exception list"
      ((PASS++)) || true
    else
      assert_equals "R" "not R" "req-001 AC3: $label reports R"
    fi
  }

  check_r "${OLD}-framework/" r_prefix "${OLD}-framework/" "ravintio-framework/"
  check_r "${OLD}-overrides/" r_prefix "${OLD}-overrides/" "ravintio-overrides/"
  for s in $SKILLS; do
    check_r "${OLD}-framework/skills/${OLD}-$s/" r_prefix "${OLD}-framework/skills/${OLD}-$s/" "ravintio-framework/skills/ravintio-$s/"
  done
  check_r ".github/workflows/${OLD}.yml" r_pair ".github/workflows/${OLD}.yml" ".github/workflows/ravintio.yml"
  check_r "${OLD}-framework/hooks/${OLD}.yml" r_pair "${OLD}-framework/hooks/${OLD}.yml" "ravintio-framework/hooks/ravintio.yml"
  check_r "refresh-${OLD}-framework-dir.ps1" r_pair "refresh-${OLD}-framework-dir.ps1" "refresh-ravintio-framework-dir.ps1"

  # No D entry for an old-brand path outside the exception list.
  deleted=""
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    st="${line%%$'\t'*}"
    path="${line#*$'\t'}"
    [ "$st" = "D" ] || continue
    printf '%s\n' "$path" | grep -qiE "$OLD" || continue
    is_exception "$path" && continue
    deleted="$deleted$path"$'\n'
  done <<< "$NS"
  dcount=0
  [ -n "$deleted" ] && dcount="$(printf '%s' "$deleted" | grep -c .)"
  assert_equals "0" "$dcount" "req-001 AC3: no D entry for an old-brand path outside the exception list ($dcount found)"
  if [ "$dcount" != "0" ]; then
    printf '%s' "$deleted" | head -5 | while IFS= read -r l; do echo "    D entry: $l"; done
  fi
fi

print_summary
