#!/usr/bin/env bash
# Tests for feature 0000039-ravintio-rebrand, req-004: brand prose and repo links.
#
# Verified by: integration
# Verified by: execution
#
# AC1 (integration): the brand word "Planifest" (capital P) is gone from prose
#   outside history, reference documents, vendored text, plan/current/, and the
#   0000039 suites. The brand guard (req-007) covers every other case.
# AC2 (integration): `git grep 'github.com/planifest'` lists only `planifest-docs`
#   links and history. Every other repo link points to RAVINTIO/ravintio-framework.
# AC3 (execution): the setup.sh heredoc (lines 811 to 958) and line 1322 differ
#   from the pre-pass commit only in brand words. The mojibake bytes must match.
# Extra: "Ravintio" in title case never appears in prose outside code identifiers.
#
# Override the pre-pass commit with RAVINTIO_BASE_COMMIT. The default is the
# parent of the pass commit.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BASE="${RAVINTIO_BASE_COMMIT:-81287992^}"

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

PASS=0
FAIL=0
ok() { echo "PASS: $1"; PASS=$((PASS + 1)); }
bad() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

# Paths that are history, reference, vendored, or the 0000039 suites.
EXCLUDE_RE='^(plan/(_archive|changelog|_migrations|current)/|plan/backlog/[^/]+/_reference/|ravintio-framework/external-skills/|ravintio-framework/migrations/|ravintio-framework/tests/(regression/)?test-0000039-|ravintio-framework/tests/(regression/)?test-0000036-req-001)'

live_files() {
  local f
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -f "$ROOT/$f" ] || continue
    [[ "$f" =~ $EXCLUDE_RE ]] && continue
    printf '%s\n' "$f"
  done <<< "$(git -C "$ROOT" ls-files)"
}

LIVE="$(live_files)"

# --- AC1: no brand word "Planifest" in live prose ---
AC1_HITS=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  h="$(grep -nI 'Planifest' "$ROOT/$f" || true)"
  [ -n "$h" ] && AC1_HITS="${AC1_HITS}${f}: ${h}"$'\n'
done <<< "$LIVE"
if [ -z "$AC1_HITS" ]; then
  ok "req-004 AC1: no brand word 'Planifest' in live prose"
else
  bad "req-004 AC1: brand word 'Planifest' remains in live prose"
  printf '%s' "$AC1_HITS" | head -20
fi

# --- AC2: repo links ---
AC2_BAD=""
while IFS= read -r hit; do
  [ -n "$hit" ] || continue
  path="${hit%%:*}"
  [[ "$path" =~ $EXCLUDE_RE ]] && continue
  [[ "$hit" == *"github.com/planifest/planifest-docs"* ]] && continue
  AC2_BAD="${AC2_BAD}${hit}"$'\n'
done <<< "$(git -C "$ROOT" grep -nI 'github.com/planifest' || true)"
if [ -z "$AC2_BAD" ]; then
  ok "req-004 AC2: only planifest-docs links and history use github.com/planifest"
else
  bad "req-004 AC2: old repo links remain"
  printf '%s' "$AC2_BAD" | cut -c1-200 | head -20
fi

# Every other github.com/RAVINTIO link in live files names ravintio-framework.
AC2B_BAD=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  h="$(grep -nIE 'github\.com/RAVINTIO/' "$ROOT/$f" | grep -v 'github.com/RAVINTIO/ravintio-framework' || true)"
  [ -n "$h" ] && AC2B_BAD="${AC2B_BAD}${f}: ${h}"$'\n'
done <<< "$LIVE"
if [ -z "$AC2B_BAD" ]; then
  ok "req-004 AC2: every live RAVINTIO repo link points to RAVINTIO/ravintio-framework"
else
  bad "req-004 AC2: a live RAVINTIO link points elsewhere"
  printf '%s' "$AC2B_BAD" | cut -c1-200 | head -20
fi

# --- AC3: setup.sh heredoc and banner differ only in brand words ---
OLD="$SCRATCH/old-setup.sh"
if git -C "$ROOT" show "${BASE}:planifest-framework/setup.sh" > "$OLD" 2>/dev/null; then
  norm() {
    LC_ALL=C sed -e 's/Planifest Framework/@@/g' -e 's/RAVINTIO Framework/@@/g' \
      -e 's/PLANIFEST/@@/g' -e 's/Planifest/@@/g' -e 's/planifest/@@/g' \
      -e 's/RAVINTIO/@@/g' -e 's/Ravintio/@@/g' -e 's/ravintio/@@/g'
  }
  NEW="$ROOT/ravintio-framework/setup.sh"
  { sed -n '811,958p' "$OLD"; sed -n '1322p' "$OLD"; } | norm > "$SCRATCH/old.norm"
  { sed -n '811,958p' "$NEW"; sed -n '1322p' "$NEW"; } | norm > "$SCRATCH/new.norm"
  if [ -s "$SCRATCH/old.norm" ] && cmp -s "$SCRATCH/old.norm" "$SCRATCH/new.norm"; then
    ok "req-004 AC3: setup.sh heredoc 811-958 and line 1322 differ only in brand words"
  else
    bad "req-004 AC3: setup.sh heredoc or line 1322 differs beyond brand words"
    diff "$SCRATCH/old.norm" "$SCRATCH/new.norm" | cut -c1-160 | head -10
  fi
  # Mojibake bytes survive: count of the lead byte sequence matches.
  OLDM="$(sed -n '811,958p;1322p' "$OLD" | LC_ALL=C grep -o $'\xc3\xa2' | wc -l | tr -d ' ')"
  NEWM="$(sed -n '811,958p;1322p' "$NEW" | LC_ALL=C grep -o $'\xc3\xa2' | wc -l | tr -d ' ')"
  if [ "$OLDM" = "$NEWM" ]; then
    ok "req-004 AC3: mojibake byte count unchanged ($OLDM)"
  else
    bad "req-004 AC3: mojibake byte count changed ($OLDM vs $NEWM)"
  fi
else
  bad "req-004 AC3: cannot read planifest-framework/setup.sh at $BASE"
fi

# --- Extra: no title-case "Ravintio" in prose ---
TC_HITS=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  h="$(grep -nIE '(^|[^A-Za-z_-])Ravintio($|[^A-Za-z_])' "$ROOT/$f" || true)"
  [ -n "$h" ] && TC_HITS="${TC_HITS}${f}: ${h}"$'\n'
done <<< "$LIVE"
if [ -z "$TC_HITS" ]; then
  ok "req-004: RAVINTIO never appears in title case in prose"
else
  bad "req-004: title-case 'Ravintio' in prose"
  printf '%s' "$TC_HITS" | cut -c1-200 | head -20
fi

echo "req-004: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
