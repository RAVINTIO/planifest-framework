#!/usr/bin/env bash
# Tests for feature 0000039-ravintio-rebrand, req-007: the brand guard (ADR-007).
#
# REGRESSION-CANDIDATE: guards the standing rule that the retired brand word stays out of live tracked paths and lines, tagged by test-writer for human review at P7
#
# Verified by: integration
#
# This suite is the guard. It reads `git ls-files`, drops history paths, and
# searches the rest for the retired brand word in any case. It checks paths and
# lines. A path or line passes only when an allowlist entry covers it.
#
# Each allowlist entry is `path_regex|line_regex|reason`. Both regexes must
# match a line. A path check uses the path regex alone. The path regex holds no
# `|`. The line regex may hold `|`, because the parser takes the text before the
# first `|` as the path regex and the text after the last `|` as the reason.
# All regexes are extended regular expressions and case-sensitive.
#
# A stale entry that matches no path and no line fails the suite.
#
# Case (d) plants the word in a scratch copy of README.md and expects a flag
# with the file and line number. Case (e) feeds the path check a path with the
# word. Case (f) proves the stale check catches an entry that matches nothing.
#
# Every loop reads lines with `done <<< "$(...)"` and skips empty lines. The
# `done < <(...)` form drops lines on macOS Bash 3.2.
#
# Paths use the post-rename names, built from $SCRIPT_DIR. This file's own path
# is allowlisted, so it may name the word.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
ROOT="$(cd "$FW/.." && pwd)"

WORD="planifest"

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

# History paths. A path that starts with one of these is a past record.
EXCLUDED_PREFIXES=(
  "plan/_archive/"      # archived features
  "plan/changelog/"     # release notes
  "plan/_migrations/"   # applied migration records
  "plan/current/"       # quotes the old name to describe the rename until ship archives it
)

# Bodies of migrations shipped before 0.37.0 are history. The 0.37.0 rename
# migration and its helpers stay in scope and carry allowlist entries.
HISTORY_MIGRATIONS_DIR="ravintio-framework/migrations/" # portable-ok: repo-relative path literal that matches git ls-files output
LIVE_MIGRATION_RE='^ravintio-framework/migrations/migrate-0\.37\.0-ravintio-rename\.'

ALLOWLIST=(
  # --- This guard ---
  # One entry covers the suite and its regression copy, before and after P7 promotion. They must name the word to match it.
  '^ravintio-framework/tests/(regression/)?test-0000039-req-007-brand-guard\.sh$|.|The guard and its regression copy name the word to match it.'

  # --- Legacy reads that stay through 0.x ---
  # The OpenCode adapter reads the old session variable as a fallback.
  '^ravintio-framework/hooks/adapters/opencode/index\.ts$|PLANIFEST_SESSION_ID|Legacy fallback for the old session variable, removed at 1.0.0.'

  # --- Tests that simulate a consumer who holds the retired name (req-003) ---
  '^ravintio-framework/tests/test-0000030-req-00[34]-[a-z-]+\.sh$|PLANIFEST_TELEMETRY|They simulate a consumer who holds the retired telemetry variable.'

  # --- Tests that protect split names (req-005) ---
  '^ravintio-framework/tests/test-0000036-req-001[^/]*\.sh$|.|The protected needles test split names.'

  # --- The 0.37.0 rename migration, its helpers, and its tests (req-006) ---
  '^ravintio-framework/migrations/migrate-0\.37\.0-ravintio-rename\.[a-z0-9]+$|.|The migration and its helpers name the old pack on purpose.'
  # The 0000039 suites plant old-name fixtures and assert the old name is gone, so they name it.
  '^ravintio-framework/tests/(regression/)?test-0000039-req-00[2-9][^/]*\.sh$|.|The 0000039 suites plant old-name fixtures and assert the old name is gone.'
  '^ravintio-framework/tests/fixtures/0000039-rename-exceptions\.txt$|^planifest-framework/|Old paths of the delete-plus-add files.'

  # --- Documents that stay as written ---
  # Backlog reference documents are frozen source material.
  '^plan/backlog/[^/]+/_reference/|.|Reference documents stay as written.'
  # Vendored third-party text is not ours to edit.
  '^ravintio-framework/external-skills/|.|Vendored text stays as written.'

  # --- Sibling repo links ---
  '^README\.md$|planifest-docs|Sibling documentation repo keeps its name.'
  '^ravintio-framework/standards/reference/|planifest|Reference files keep the sibling docs repo file names.'
  '^plan/backlog/[^/]+/entry\.md$|planifest-zero|Sibling repo name in a backlog entry.'
  '^plan/backlog/0000215-[^/]+/entry\.md$|feat/planifest-framework-v0\.7|Old branch name quoted from a past command.'

  # =====================================================================
  # STAGE 3 ADDS ENTRIES BELOW THIS LINE. Pin each to a real post-pass path
  # and an exact line pattern, and give a reason. Keep the list closed.
  # Expected from req-007: setup lines for old-folder detection and marker
  # clean-up, the mojibake heredoc lines, history-reading suites, old-marker
  # fixtures (req-002, req-008), migrator mapping lines (req-009), and live
  # backlog lines that quote the old name.
  # =====================================================================

  # The old marker stays ignored through 0.x.
  '^\.gitignore$|^\.planifest-setup-flags$|Old flags marker stays ignored through 0.x.'

  # Old-name reads in setup, kept through 0.x and removed at 1.0.0 (ADR-004).
  '^ravintio-framework/setup\.[a-z0-9]+$|planifest-(framework|overrides)|Old pack folder stop check.'
  '^ravintio-framework/setup\.[a-z0-9]+$|planifest-overrides:instructions:(start|end)|Old boot marker strip.'
  '^ravintio-framework/setup\.[a-z0-9]+$|Planifest - (Token Reduction|Indexing Exclusions)|Old ignore header strip.'
  '^ravintio-framework/setup\.[a-z0-9]+$|\.planifest-(setup-flags|manifest)|Old marker read.'
  '^ravintio-framework/setup\.[a-z0-9]+$|planifest-\*|Old skill folder match.'
  '^ravintio-framework/hooks/enforcement/em-dash-guard\.mjs$|planifest-em-dash-allow|Old sentinel read.'
  '^ravintio-framework/scripts/archive-current\.mjs$|\.planifest-session|Old marker delete.'
  '^ravintio-framework/hooks/enforcement/path-rules\.mjs$|old-name read, removed at 1\.0\.0|Old plugin and workflow stay enforcement paths through 0.x (P5 S-02).'
  '^ravintio-framework/workflows/fast-path\.md$|kept until 1\.0\.0|The doc mirrors the old enforcement paths through 0.x (P5 S-02).'
  '^ravintio-framework/skills/ravintio-migrator/SKILL\.md$|planifest-|Old-path mapping for pre-0.37.0 migrations.'
  '^ravintio-framework/skills/ravintio-refresh-setup/SKILL\.md$|\.planifest-setup-flags|Old marker read note.'
  # The test reads a migration shipped before 0.37.0, whose body is history.
  '^ravintio-framework/tests/test-0000032-req-011-rerun-setup-migration\.sh$|planifest-refresh-setup|Asserts text of a past migration.'

  # The refresh script keeps the old local checkout path.
  '^refresh-ravintio-framework-dir\.ps1$|C:.d.planifest.framework|Local checkout path on the maintainer machine keeps the old text.'
)

# One counter per entry, used by the stale-entry check.
HITS=()
for _i in "${!ALLOWLIST[@]}"; do HITS[$_i]=0; done
COUNT_HITS=1

entry_path_re() { printf '%s' "${1%%|*}"; }
entry_line_re() { local rest="${1#*|}"; printf '%s' "${rest%|*}"; }

# line_allowed <path> <text>: returns 0 when an entry covers the line.
# Counts every covering entry while COUNT_HITS is 1.
line_allowed() {
  local path="$1" text="$2" i p l found=1
  for i in "${!ALLOWLIST[@]}"; do
    p="$(entry_path_re "${ALLOWLIST[$i]}")"
    l="$(entry_line_re "${ALLOWLIST[$i]}")"
    if [[ "$path" =~ $p ]] && [[ "$text" =~ $l ]]; then
      found=0
      [ "$COUNT_HITS" -eq 1 ] && HITS[$i]=$(( ${HITS[$i]} + 1 ))
    fi
  done
  return "$found"
}

# path_allowed <path>: returns 0 when an entry's path regex covers the path.
path_allowed() {
  local path="$1" i p found=1
  for i in "${!ALLOWLIST[@]}"; do
    p="$(entry_path_re "${ALLOWLIST[$i]}")"
    if [[ "$path" =~ $p ]]; then
      found=0
      [ "$COUNT_HITS" -eq 1 ] && HITS[$i]=$(( ${HITS[$i]} + 1 ))
    fi
  done
  return "$found"
}

# check_file <root> <path>: appends "path:line: text" to LINE_FAILS for each
# matching line that no entry covers.
LINE_FAILS=""
check_file() {
  local root="$1" path="$2" hit num text
  [ -f "$root/$path" ] || return 0
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    num="${hit%%:*}"
    text="${hit#*:}"
    line_allowed "$path" "$text" || LINE_FAILS="${LINE_FAILS}${path}:${num}: ${text}"$'\n'
  done <<< "$(grep -inI -- "$WORD" "$root/$path" 2>/dev/null)"
}

# check_path <path>: appends the path to PATH_FAILS when it names the word and
# no entry covers it.
PATH_FAILS=""
check_path() {
  local path="$1"
  case "$(printf '%s' "$path" | tr '[:upper:]' '[:lower:]')" in
    *"$WORD"*) ;;
    *) return 0 ;;
  esac
  path_allowed "$path" || PATH_FAILS="${PATH_FAILS}${path}:0: path names the old brand"$'\n'
}

in_scope() {
  local path="$1" prefix
  for prefix in "${EXCLUDED_PREFIXES[@]}"; do
    case "$path" in "$prefix"*) return 1 ;; esac
  done
  case "$path" in
    "$HISTORY_MIGRATIONS_DIR"*)
      [[ "$path" =~ $LIVE_MIGRATION_RE ]] || return 1 ;;
  esac
  return 0
}

SCOPE=""
while IFS= read -r path; do
  [ -n "$path" ] || continue
  in_scope "$path" && SCOPE="${SCOPE}${path}"$'\n'
done <<< "$(git -C "$ROOT" ls-files)"

# One scan: paths first, then lines. Hits count toward the stale check.
while IFS= read -r path; do
  [ -n "$path" ] || continue
  check_path "$path"
  check_file "$ROOT" "$path"
done <<< "$SCOPE"
COUNT_HITS=0

# stale_entries: prints each entry that matched no path and no line.
stale_entries() {
  local i out=""
  for i in "${!ALLOWLIST[@]}"; do
    [ "${HITS[$i]}" -eq 0 ] && out="${out}stale entry $i: $(entry_path_re "${ALLOWLIST[$i]}") | $(entry_line_re "${ALLOWLIST[$i]}")"$'\n'
  done
  printf '%s' "$out"
}

print_lines() {
  local l
  while IFS= read -r l; do
    [ -n "$l" ] || continue
    printf '    %s\n' "$l"
  done <<< "$1"
}

count_lines() {
  local l n=0
  while IFS= read -r l; do
    [ -n "$l" ] && n=$(( n + 1 ))
  done <<< "$1"
  echo "$n"
}

LINE_TOTAL="$(count_lines "$LINE_FAILS")"
PATH_TOTAL="$(count_lines "$PATH_FAILS")"
STALE="$(stale_entries)"
STALE_TOTAL="$(count_lines "$STALE")"

echo ""
echo "=== req-007 (a): no tracked line outside the allowlist uses the old brand ==="
[ -n "$LINE_FAILS" ] && print_lines "$LINE_FAILS"
assert_equals "" "$LINE_FAILS" "req-007 (a): every tracked line that names the old brand has an allowlist entry"

echo ""
echo "=== req-007 (b): no tracked path outside the allowlist names the old brand ==="
[ -n "$PATH_FAILS" ] && print_lines "$PATH_FAILS"
assert_equals "" "$PATH_FAILS" "req-007 (b): every tracked path that names the old brand has an allowlist entry"

echo ""
echo "=== req-007 (c): every allowlist entry matches a path or a line ==="
[ -n "$STALE" ] && print_lines "$STALE"
assert_equals "" "$STALE" "req-007 (c): no allowlist entry is stale"

echo ""
echo "=== req-007 (d): a planted line in a scratch README.md fails the line check ==="
cp "$ROOT/README.md" "$SCRATCH/README.md"
echo "Planifest was the old name" >> "$SCRATCH/README.md"
PLANTED_NUM="$(wc -l < "$SCRATCH/README.md" | tr -d ' ')"
LINE_FAILS=""
check_file "$SCRATCH" "README.md"
assert_contains "README.md:$PLANTED_NUM: Planifest was the old name" "$LINE_FAILS" \
  "req-007 (d): the check flags the planted line with its file and line number"

echo ""
echo "=== req-007 (e): a path that names the old brand fails the path check ==="
PATH_FAILS=""
check_path "docs/Planifest-notes.md"
assert_contains "docs/Planifest-notes.md" "$PATH_FAILS" \
  "req-007 (e): the path check flags a path outside the allowlist"

echo ""
echo "=== req-007 (f): a stale allowlist entry is reported ==="
ALLOWLIST+=('^no/such/path$|no such line|Probe entry that matches nothing.')
HITS[$(( ${#ALLOWLIST[@]} - 1 ))]=0
PROBE_STALE="$(stale_entries)"
assert_contains "^no/such/path\$" "$PROBE_STALE" \
  "req-007 (f): the stale check reports an entry that matches nothing"

echo ""
echo "Total offences: $(( LINE_TOTAL + PATH_TOTAL + STALE_TOTAL )) (lines $LINE_TOTAL, paths $PATH_TOTAL, stale entries $STALE_TOTAL)"
print_summary
