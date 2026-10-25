#!/usr/bin/env bash
# Tests for feature 0000037-green-ci-before-ship.
#
# req-004: the ship agent scans the PR title and body for credentials before
#          gh pr create, and PR text cites paths and results only.
#
# Verified by: integration
# REGRESSION-CANDIDATE: covers the PR text scan and the body-file send rule, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
SCAN="$FW/scripts/credential-scan.mjs"
SHIP="$FW/skills/ravintio-ship-agent/SKILL.md"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The fixture credential is assembled at run time so this file holds no secret.
SECRET="AKIA""ABCDEFGHIJKLMNOP"

step() {
  awk -v h="$1" 'index($0, h) == 1 { on = 1; print; next } on && /^##+ / { exit } on { print }' "$2"
}

lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

S10="$(step '### Step 10: Push/PR decision' "$SHIP")"

echo "req-004: --file mode of credential-scan.mjs"

printf '## Summary\nline two\nkey=%s\n' "$SECRET" >"$WORK/body-hit.md"
OUT="$(cd / && node "$SCAN" --file "$WORK/body-hit.md" 2>&1)"
RC=$?
assert_equals "1" "$RC" "req-004: a body with a credential exits 1"
assert_contains ":3 " "$OUT" "req-004: --file prints the line number"
lacks "$SECRET" "$OUT" "req-004: --file never prints the secret"

printf '## Summary\nPaths and results only.\n' >"$WORK/body-ok.md"
OUT="$(cd / && node "$SCAN" --file "$WORK/body-ok.md" 2>&1)"
RC=$?
assert_equals "0" "$RC" "req-004: a clean body exits 0"
assert_contains "scan mode:" "$OUT" "req-004: --file prints the scan mode"

OUT="$(cd / && node "$SCAN" --file "$WORK/missing.md" 2>&1)"
RC=$?
assert_equals "2" "$RC" "req-004: a missing body file exits 2"
assert_contains "scan could not run:" "$OUT" "req-004: exit 2 prints the reason"

echo "req-004: Step 10 scans and sends the same files"

assert_contains "outside the repository" "$S10" "req-004: PR text files live outside the repository"
assert_contains "Write tool" "$S10" "req-004: the agent writes the files with the Write tool"
assert_contains 'credential-scan.mjs --file {path}' "$S10" "req-004: Step 10 scans each file with --file"
assert_contains 'gh pr create' "$S10" "req-004: Step 10 still raises the PR"
assert_contains '--body-file "$PRTMP/pr-body.md"' "$S10" "req-004: Step 10 sends the scanned body file"
assert_contains '--title "$TITLE"' "$S10" "req-004: Step 10 sends the title from a variable"
assert_contains 'TITLE="$(cat "$PRTMP/pr-title.txt")"' "$S10" "req-004: the title is read from the scanned file"
lacks '--title "{title}"' "$S10" "req-004: no untrusted text interpolated into the title argument"
assert_contains 'PRTMP="$(mktemp -d)"' "$S10" "req-004: PR text files live in one mktemp -d folder"
assert_contains 'rm -rf "$PRTMP"' "$S10" "req-004: the temp folder is removed after the send"
assert_contains "PR comments and review replies" "$S10" "req-004: comments and replies follow the PR text rule"
lacks '--body "$(cat' "$S10" "req-004: the heredoc --body form is removed"
lacks "<<'EOF'" "$S10" "req-004: no heredoc remains in Step 10"
assert_contains "no edit between the scan and the send" "$S10" "req-004: no edit between scan and send"

echo "req-004: match handling"

assert_contains "regenerates the body once" "$S10" "req-004: a match regenerates the body once"
assert_contains "second scan" "$S10" "req-004: a second scan follows"
assert_contains 'exit `2`' "$S10" "req-004: exit 2 stops the PR"
assert_contains 'does not run `gh pr create`' "$S10" "req-004: no gh pr create after a held-back scan"
assert_contains 'Option [2] without the description' "$S10" "req-004: held-back PR takes Option [2]"
assert_contains 'Exception waiting (P9, 7): credential sighting in PR text at line {n}' "$S10" "req-004: exception line"
assert_contains "names the line, never the text" "$S10" "req-004: final report names the line only"
assert_contains 'Credential scan (P9): PR text clean ({scan mode})' "$S10" "req-004: clean log line"
assert_contains 'Credential scan (P9): PR text held back' "$S10" "req-004: held-back log line"
assert_contains "regex-only" "$S10" "req-004: a regex-only scan says so"

echo "req-004: PR text rule"

assert_contains "file paths, requirement IDs, ADR IDs, check names, counts, and result words" "$S10" "req-004: PR text cites paths and results"
assert_contains "pasted command output, log lines, file contents, diff hunks, or error text" "$S10" "req-004: PR text bans raw output"
assert_contains "by item number and path only" "$S10" "req-004: draft PR exceptions cite item number and path"
assert_contains "Option [2] output" "$S10" "req-004: Option [2] output follows the same scan"
assert_contains "name, bucket, and link" "$S10" "req-004: check lists use req-001 fields"
assert_contains "draft PR" "$S10" "req-004: the rule covers the P3 draft PR"

print_summary
