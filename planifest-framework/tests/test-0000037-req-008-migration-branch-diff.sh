#!/usr/bin/env bash
# Verified by: integration
# test-0000037-req-008-migration-branch-diff.sh
# req-008 (ADR-010): compare the unreleased re-run-setup migration's file list
# with the setup-delivered files in the release diff.
# AC-008.3 (the positive path against this repository) verifies by execution in
# the post-P6 revalidation, as a local run with the v* tags present. Until
# migrate-0.35.0-rerun-setup.md exists, the real-repository check skips and the
# fixture checks below prove the comparison (FR-008.8).
# Run from any directory: bash planifest-framework/tests/test-0000037-req-008-migration-branch-diff.sh

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ "$(basename "$SCRIPT_DIR")" = "regression" ]; then SCRIPT_DIR="$(dirname "$SCRIPT_DIR")"; fi
source "$SCRIPT_DIR/helpers/assert.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

yes_no() { if "$@"; then echo "yes"; else echo "no"; fi; }

CHECK_OUT=""

RE_VERSION='^([0-9]+)\.([0-9]+)\.([0-9]+)$'
RE_TICK='`([^`]+)`'

# ver_gt A B: true when version A is higher than version B (numeric, per part).
ver_gt() {
  local -a a b
  local i
  IFS=. read -ra a <<< "$1"
  IFS=. read -ra b <<< "$2"
  for i in 0 1 2; do
    if [ "${a[$i]:-0}" -gt "${b[$i]:-0}" ]; then return 0; fi
    if [ "${a[$i]:-0}" -lt "${b[$i]:-0}" ]; then return 1; fi
  done
  return 1
}

# is_delivered FRAMEWORK_DIR PATH: true when PATH (relative to planifest-framework/)
# is a setup-delivered file per standards/framework-update-policy.md. The test
# never filters by bundle_templates or bundle_standards, except for the
# sub-path files that a bundle_standards entry names.
is_delivered() {
  local fw="$1" p="$2" rest
  case "$p" in
    skills/*/SKILL.md) return 0 ;;
    skills/*/scripts/*|skills/*/assets/*|skills/*/references/*) return 0 ;;
    templates/*|schemas/*) return 0 ;;
    standards/reference/*) return 1 ;;
    standards/*/*)
      rest="${p#standards/}"
      grep -h '^bundle_standards:' "$fw"/skills/*/SKILL.md 2>/dev/null | grep -qF -- "$rest"
      return $? ;;
    standards/*) return 0 ;;
    hooks/enforcement/*|hooks/adapters/*|workflows/*) return 0 ;;
  esac
  return 1
}

# is_delivered_prefix PATH: true when PATH starts with a setup-delivered folder name.
is_delivered_prefix() {
  case "$1" in
    skills/*|templates/*|schemas/*|standards/*|hooks/enforcement/*|hooks/adapters/*|workflows/*) return 0 ;;
  esac
  return 1
}

# mig_check REPO: print PASS, FAIL, or SKIP lines into CHECK_OUT. Return 1 on FAIL.
mig_check() {
  local repo="$1" fw="$1/planifest-framework"
  local f v tag tv target_file="" target_ver="" max_ver="" base="" base_ver=""
  CHECK_OUT=""

  if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    CHECK_OUT="SKIP: $repo is not a git work tree"
    return 0
  fi

  # FR-008.1: highest-version re-run-setup migration.
  for f in "$fw"/migrations/migrate-*-rerun-setup*.md; do
    [ -f "$f" ] || continue
    v="$(basename "$f")"; v="${v#migrate-}"; v="${v%%-rerun-setup*}"
    [[ $v =~ $RE_VERSION ]] || continue
    if [ -z "$target_ver" ] || ver_gt "$v" "$target_ver"; then target_ver="$v"; target_file="$f"; fi
  done
  if [ -z "$target_file" ]; then
    CHECK_OUT="SKIP: no re-run-setup migration found"
    return 0
  fi

  # FR-008.5a: no v* tag at all.
  while IFS= read -r tag; do
    [[ $tag =~ ^v([0-9]+\.[0-9]+\.[0-9]+)$ ]] || continue
    tv="${BASH_REMATCH[1]}"
    if [ -z "$max_ver" ] || ver_gt "$tv" "$max_ver"; then max_ver="$tv"; fi
    if ver_gt "$target_ver" "$tv" && { [ -z "$base_ver" ] || ver_gt "$tv" "$base_ver"; }; then base_ver="$tv"; fi
  done < <(git -C "$repo" tag -l 'v*')
  if [ -z "$max_ver" ]; then
    CHECK_OUT="SKIP: no v* tags fetched"
    return 0
  fi

  # FR-008.2: compare only an unreleased migration.
  if ! ver_gt "$target_ver" "$max_ver"; then
    CHECK_OUT="SKIP: $(basename "$target_file") is frozen: version $target_ver is not higher than the highest v* tag v$max_ver"
    return 0
  fi

  # FR-008.3 and FR-008.5: the base is the highest tag below the target and must resolve.
  base="v$base_ver"
  if [ -z "$base_ver" ] || ! git -C "$repo" rev-parse -q --verify "refs/tags/$base^{commit}" >/dev/null 2>&1; then
    CHECK_OUT="SKIP: base tag ${base} is absent (shallow clone or missing tag)"
    return 0
  fi

  # FR-008.4: filter the diff to setup-delivered files.
  local diff_list="" p
  while IFS= read -r p; do
    p="${p#planifest-framework/}"
    if is_delivered "$fw" "$p"; then diff_list="$diff_list$p"$'\n'; fi
  done < <(git -C "$repo" diff --name-only "$base..HEAD" -- planifest-framework | grep '^planifest-framework/')

  # FR-008.6: backticked setup-delivered paths in the Background section.
  local list="" line in_bg=0 span
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ $line == "## "* ]]; then
      if [[ $line == "## Background"* ]]; then in_bg=1; else in_bg=0; fi
      continue
    fi
    [ "$in_bg" -eq 1 ] || continue
    while [[ $line =~ $RE_TICK ]]; do
      span="${BASH_REMATCH[1]}"
      line="${line#*"${BASH_REMATCH[0]}"}"
      if is_delivered_prefix "$span"; then list="$list$span"$'\n'; fi
    done
  done < "$target_file"

  diff_list="$(printf '%s' "$diff_list" | LC_ALL=C sort -u)"
  list="$(printf '%s' "$list" | LC_ALL=C sort -u)"

  # FR-008.7: compare in both directions.
  local missing_from_list missing_from_diff
  missing_from_list="$(LC_ALL=C comm -23 <(printf '%s\n' "$diff_list") <(printf '%s\n' "$list") | grep -v '^$')"
  missing_from_diff="$(LC_ALL=C comm -13 <(printf '%s\n' "$diff_list") <(printf '%s\n' "$list") | grep -v '^$')"
  if [ -z "$missing_from_list" ] && [ -z "$missing_from_diff" ]; then
    CHECK_OUT="PASS: $(basename "$target_file") matches $base..HEAD ($(printf '%s\n' "$list" | grep -c .) setup-delivered files)"
    return 0
  fi
  CHECK_OUT="FAIL: $(basename "$target_file") does not match $base..HEAD"
  while IFS= read -r p; do
    [ -n "$p" ] && CHECK_OUT="$CHECK_OUT"$'\n'"  in the diff but not in the list: $p"
  done <<< "$missing_from_list"
  while IFS= read -r p; do
    [ -n "$p" ] && CHECK_OUT="$CHECK_OUT"$'\n'"  in the list but not in the diff: $p"
  done <<< "$missing_from_diff"
  return 1
}

TMP="$(mktemp -d "${TMPDIR:-/tmp}/planifest_0000037_req008_XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# make_fixture DIR LIST_TEXT
# Builds a git repository with tag v0.1.0 on the base commit, a release change set,
# and migrate-0.2.0-rerun-setup.md whose Background section holds LIST_TEXT.
make_fixture() {
  local dir="$1" list="$2"
  mkdir -p "$dir"
  (
    cd "$dir" || exit 1
    git init -q .
    git config user.email t@example.com
    git config user.name t
    git config commit.gpgsign false
    mkdir -p planifest-framework/{skills/alpha/scripts,skills/beta,templates,schemas,standards/reference,standards/lib,hooks/enforcement,hooks/adapters,workflows,migrations}
    printf -- '---\nbundle_standards: [lib/_v.md]\n---\nalpha\n' > planifest-framework/skills/alpha/SKILL.md
    printf 'beta\n' > planifest-framework/skills/beta/SKILL.md
    printf 'one\n' > planifest-framework/skills/alpha/scripts/s.sh
    printf 'one\n' > planifest-framework/templates/t.md
    printf 'one\n' > planifest-framework/schemas/x.json
    printf 'one\n' > planifest-framework/standards/s.md
    printf 'one\n' > planifest-framework/standards/reference/r.md
    printf 'one\n' > planifest-framework/standards/lib/_v.md
    printf 'one\n' > planifest-framework/standards/lib/other.md
    printf 'one\n' > planifest-framework/hooks/enforcement/e.mjs
    printf 'one\n' > planifest-framework/hooks/pre-commit
    printf 'one\n' > planifest-framework/workflows/w.md
    printf '# old\n\n## Background\n\n`skills/beta/SKILL.md` stale.\n' > planifest-framework/migrations/migrate-0.1.5-rerun-setup-for-x.md
    git add -A && git commit -q -m base && git tag v0.1.0
    printf 'two\n' >> planifest-framework/skills/alpha/SKILL.md
    printf 'two\n' >> planifest-framework/skills/alpha/scripts/s.sh
    printf 'two\n' >> planifest-framework/templates/t.md
    printf 'two\n' >> planifest-framework/schemas/x.json
    printf 'two\n' >> planifest-framework/standards/s.md
    printf 'two\n' >> planifest-framework/standards/reference/r.md
    printf 'two\n' >> planifest-framework/standards/lib/_v.md
    printf 'two\n' >> planifest-framework/standards/lib/other.md
    printf 'two\n' >> planifest-framework/hooks/enforcement/e.mjs
    printf 'two\n' >> planifest-framework/hooks/pre-commit
    printf 'two\n' >> planifest-framework/workflows/w.md
    printf 'new\n' > planifest-framework/hooks/adapters/a.mjs
    printf '# Migration\n\n## Background\n\n%s\n\n## What This Migration Does\n\nIgnored `skills/beta/SKILL.md` text.\n' "$list" > planifest-framework/migrations/migrate-0.2.0-rerun-setup.md
    git add -A && git commit -q -m release
  )
}

# The exact list of setup-delivered files that the fixture release changed.
GOOD_LIST='Changed files: `skills/alpha/SKILL.md`, `skills/alpha/scripts/s.sh`, `templates/t.md`, `schemas/x.json`, `standards/s.md`, `standards/lib/_v.md`, `hooks/enforcement/e.mjs`, `hooks/adapters/a.mjs`, and `workflows/w.md`. The update policy is `planifest-framework/standards/framework-update-policy.md`.'
OMIT_LIST="${GOOD_LIST/\`skills\/alpha\/SKILL.md\`, /}"
EXTRA_LIST="$GOOD_LIST Also \`skills/beta/SKILL.md\`."

echo "req-008 AC-008.1: fixture repository, list matches the diff"
make_fixture "$TMP/pass" "$GOOD_LIST"
mig_check "$TMP/pass"; rc=$?
assert_equals "0" "$rc" "req-008 AC-008.1: exact list passes"
assert_contains "PASS" "$CHECK_OUT" "req-008 AC-008.1: output says PASS"

echo "req-008 AC-008.1: fixture repository, list omits a changed skill"
make_fixture "$TMP/omit" "$OMIT_LIST"
mig_check "$TMP/omit"; rc=$?
assert_equals "1" "$rc" "req-008 AC-008.1: omitted skill fails"
assert_contains "skills/alpha/SKILL.md" "$CHECK_OUT" "req-008 FR-008.7: failure names the omitted path"
assert_contains "in the diff but not in the list" "$CHECK_OUT" "req-008 FR-008.7: failure says the path is missing from the list"

echo "req-008 AC-008.1: fixture repository, list names an unchanged file"
make_fixture "$TMP/extra" "$EXTRA_LIST"
mig_check "$TMP/extra"; rc=$?
assert_equals "1" "$rc" "req-008 AC-008.1: extra path fails"
assert_contains "skills/beta/SKILL.md" "$CHECK_OUT" "req-008 FR-008.7: failure names the unchanged path"
assert_contains "in the list but not in the diff" "$CHECK_OUT" "req-008 FR-008.7: failure says the path is missing from the diff"

echo "req-008 FR-008.4: the filter drops reference standards, git hooks, and unnamed sub-paths"
assert_equals "no" "$([[ "$CHECK_OUT" == *"standards/reference/r.md"* ]] && echo yes || echo no)" "req-008 FR-008.4: standards/reference is never required in the list"
mig_check "$TMP/pass"
assert_equals "no" "$([[ "$CHECK_OUT" == *"hooks/pre-commit"* ]] && echo yes || echo no)" "req-008 FR-008.4: git hooks are never required in the list"
assert_equals "no" "$([[ "$CHECK_OUT" == *"standards/lib/other.md"* ]] && echo yes || echo no)" "req-008 FR-008.4: unnamed standards sub-paths are not required"

echo "req-008 AC-008.2: base tag absent"
make_fixture "$TMP/nobase" "$GOOD_LIST"
printf '1111111111111111111111111111111111111111\n' > "$TMP/nobase/.git/refs/tags/v0.1.0"
mig_check "$TMP/nobase"; rc=$?
assert_equals "0" "$rc" "req-008 AC-008.2: absent base tag exits 0"
assert_contains "SKIP" "$CHECK_OUT" "req-008 FR-008.5: absent base tag prints SKIP"
assert_contains "v0.1.0" "$CHECK_OUT" "req-008 FR-008.5: SKIP names the tag"

echo "req-008 AC-008.2: target migration already has its release tag"
make_fixture "$TMP/frozen" "$GOOD_LIST"
git -C "$TMP/frozen" tag v0.2.0
mig_check "$TMP/frozen"; rc=$?
assert_equals "0" "$rc" "req-008 AC-008.2: frozen migration exits 0"
assert_contains "SKIP" "$CHECK_OUT" "req-008 FR-008.2: frozen migration prints SKIP"
assert_contains "frozen" "$CHECK_OUT" "req-008 FR-008.2: SKIP states the reason"

echo "req-008 FR-008.5a: no v* tag at all"
make_fixture "$TMP/notags" "$GOOD_LIST"
git -C "$TMP/notags" tag -d v0.1.0 >/dev/null 2>&1
mig_check "$TMP/notags"; rc=$?
assert_equals "0" "$rc" "req-008 AC-008.2: no tags exits 0"
assert_contains "SKIP: no v* tags fetched" "$CHECK_OUT" "req-008 FR-008.5a: SKIP says no v* tags fetched"

echo "req-008 FR-008.1: this repository"
mig_check "$REPO_ROOT"; rc=$?
echo "  info: $CHECK_OUT"
assert_equals "0" "$rc" "req-008 AC-008.3: the check passes or skips against this repository"

print_summary
