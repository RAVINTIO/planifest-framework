#!/usr/bin/env bash
# Tests for feature 0000037-green-ci-before-ship.
#
# req-002: GUTD reports the CI result of the last merged PR after the sync
#          steps (override custom-003, step 5).
#
# Verified by: integration
# REGRESSION-CANDIDATE: covers the GUTD CI check step text and its lookup commands, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OVR="$ROOT/planifest-overrides/instructions/custom-003-git-up-to-date-shorthand.md"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

TXT="$(cat "$OVR")"
STEP5="$(awk '/^5\. / { on = 1 } on && /^## / { exit } on { print }' "$OVR")"
WHY="$(awk '/^## Why/ { on = 1 } on { print }' "$OVR")"

echo "req-002: step 5 text"

assert_contains "5. " "$STEP5" "req-002: step 5 exists"
assert_contains "after the untracked-files report" "$STEP5" "req-002: step 5 runs after step 4"
assert_contains 'gh pr list --state merged --base main --limit 10 --json number,url,title,mergedAt' "$STEP5" "req-002: step 5 lists merged PRs"
assert_contains "newest \`mergedAt\`" "$STEP5" "req-002: step 5 picks the newest mergedAt"
assert_contains 'gh pr checks {number} --json name,bucket,link' "$STEP5" "req-002: step 5 reads the checks"
assert_contains 'never reads a `main` run' "$STEP5" "req-002: step 5 never reads a main run"
assert_contains "the last merged PR's checks" "$STEP5" "req-002: result wording names the last merged PR's checks"
assert_contains "PR number and URL" "$STEP5" "req-002: the report gives the PR number and URL"
assert_contains "main is green" "$STEP5" "req-002: step 5 bans the main-is-green wording"
assert_contains '`all passed`' "$STEP5" "req-002: result word all passed"
assert_contains '`{n} failed: {names with links}`' "$STEP5" "req-002: result word failed"
assert_contains '`pending`' "$STEP5" "req-002: result word pending"
assert_contains '`unknown: {names}`' "$STEP5" "req-002: result word unknown"
assert_contains '`cancel`' "$STEP5" "req-002: cancel reads as unknown"
assert_contains "Unknown never reads as a pass" "$STEP5" "req-002: unknown is never a pass"
assert_contains "no merged PR to check" "$STEP5" "req-002: empty list wording"
assert_contains "not from the exit status" "$STEP5" "req-002: judge from JSON"
assert_contains "exits 1" "$STEP5" "req-002: names exit 1"
assert_contains "exits 8" "$STEP5" "req-002: names exit 8"
assert_contains "CI status could not be read" "$STEP5" "req-002: unreadable wording"
assert_contains 'gh auth login' "$STEP5" "req-002: names gh auth login"
assert_contains "does not wait" "$STEP5" "req-002: step 5 does not wait"
assert_contains "does not undo the checkout or the pull" "$STEP5" "req-002: a failed check does not undo steps 1 to 4"
assert_contains "setup re-run" "$STEP5" "req-002: the generated copy refreshes on a setup re-run"
lacks 'gh run list' "$TXT" "req-002: the override never uses gh run list as a command"
assert_contains "PR #62" "$WHY" "req-002: Why records PR #62"
assert_contains "merged red" "$WHY" "req-002: Why records the red merge"
assert_contains "2026-10-24" "$WHY" "req-002: Why records the date of this change"

echo "req-002: stub gh execution"

LIST_CMD="$(grep -o 'gh pr list --state merged --base main --limit 10 --json number,url,title,mergedAt' "$OVR" | head -1)"
CHECKS_CMD="$(grep -o 'gh pr checks {number} --json name,bucket,link' "$OVR" | head -1)"

mkdir -p "$WORK/stub"
cat >"$WORK/stub/gh" <<'STUB'
#!/bin/sh
case "$1 $2" in
  "pr list")
    # An older PR (7) merged later than a newer PR (9). The list sorts by creation.
    printf '[{"number":9,"url":"https://example.test/9","title":"nine","mergedAt":"2026-10-01T10:00:00Z"},{"number":7,"url":"https://example.test/7","title":"seven","mergedAt":"2026-10-02T10:00:00Z"}]\n'
    exit 0 ;;
  "pr checks")
    printf '[{"name":"Test suite (windows-latest)","bucket":"fail","link":"https://example.test/c1"},{"name":"lint","bucket":"pass","link":"https://example.test/c2"}]\n'
    exit 1 ;;
esac
exit 0
STUB
chmod +x "$WORK/stub/gh"

LIST_OUT="$(PATH="$WORK/stub:$PATH" bash -c "$LIST_CMD" 2>&1)"
NEWEST="$(printf '%s' "$LIST_OUT" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const j=JSON.parse(d);j.sort((a,b)=>b.mergedAt.localeCompare(a.mergedAt));console.log(j[0].number);});")"
assert_equals "7" "$NEWEST" "req-002: an older PR merged later is the newest mergedAt"

CMD="${CHECKS_CMD//\{number\}/$NEWEST}"
OUT="$(PATH="$WORK/stub:$PATH" bash -c "$CMD" 2>&1)"
RC=$?
assert_equals "1" "$RC" "req-002: stub checks exit 1 with a fail bucket"
FAILED="$(printf '%s' "$OUT" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const j=JSON.parse(d);console.log(j.filter(c=>c.bucket==='fail').map(c=>c.name).join(','));});")"
assert_equals "Test suite (windows-latest)" "$FAILED" "req-002: valid JSON with a fail bucket reads as failed, not unreadable"

# A failing gh: not valid JSON, so the step reads "could not be read".
cat >"$WORK/stub/gh" <<'STUB'
#!/bin/sh
echo "gh: To get started with GitHub CLI, please run: gh auth login" >&2
exit 4
STUB
OUT="$(PATH="$WORK/stub:$PATH" bash -c "$LIST_CMD" 2>/dev/null)"
RC=$?
VALID="$(printf '%s' "$OUT" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{JSON.parse(d);console.log('json')}catch(e){console.log('not-json')}});")"
assert_equals "not-json" "$VALID" "req-002: a signed-out gh prints no JSON"
assert_equals "yes" "$([ "$RC" -ne 0 ] && echo yes || echo no)" "req-002: a signed-out gh exits non-zero"

# Real gh prints no JSON and "no checks reported" on stderr for a PR with no checks (P4).
assert_contains 'report "no checks reported" for that PR' "$STEP5" "req-002: step 5 reports no checks, not unreadable"

print_summary
