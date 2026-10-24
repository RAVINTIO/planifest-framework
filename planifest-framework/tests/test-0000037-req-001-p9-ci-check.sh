#!/usr/bin/env bash
# Tests for feature 0000037-green-ci-before-ship.
#
# req-001: P9 reads the PR's CI checks after it raises the PR and reports the
#          result before the final report (ship skill Step 10c).
#
# Verified by: integration
# REGRESSION-CANDIDATE: covers the P9 CI check step and its result mapping, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
SHIP="$FW/skills/planifest-ship-agent/SKILL.md"
STD="$FW/standards/autonomous-run-standards.md"
ORCH="$FW/skills/planifest-orchestrator/SKILL.md"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# step <heading-prefix> <file>: prints one `### ` step, heading included.
step() {
  awk -v h="$1" 'index($0, h) == 1 { on = 1; print; next } on && /^##+ / { exit } on { print }' "$2"
}

# section <heading-prefix> <file>: prints one `## ` section, heading included.
section() {
  awk -v h="$1" 'index($0, h) == 1 { on = 1; print; next } on && /^## / { exit } on { print }' "$2"
}

lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

line_of() {
  grep -n -m1 -F -e "$1" "$2" | cut -d: -f1
}

S10="$(step '### Step 10: Push/PR decision' "$SHIP")"
S10C="$(step '### Step 10c' "$SHIP")"
S11="$(step '### Step 11' "$SHIP")"
S9="$(step '### Step 9' "$SHIP")"

echo "req-001: Step 10c position"

L10B="$(line_of '### Step 10b' "$SHIP")"
L10C="$(line_of '### Step 10c' "$SHIP")"
L11="$(line_of '### Step 11' "$SHIP")"
assert_equals "yes" "$([ -n "$L10C" ] && [ -n "$L10B" ] && [ "$L10C" -gt "$L10B" ] && [ "$L10C" -lt "$L11" ] && echo yes || echo no)" "req-001: Step 10c sits between Step 10b and Step 11"

echo "req-001: Step 10 PR record and existing-PR path"

assert_contains 'PR: #{n} {url}' "$S10" "req-001: Step 10 records the PR line"
assert_contains "before any wait" "$S10" "req-001: the PR line lands before the wait"
assert_contains 'gh pr view --json number,url,isDraft' "$S10" "req-001: Step 10 looks for an open PR"
assert_contains 'gh pr edit' "$S10" "req-001: Step 10 edits an existing PR"
assert_contains '--body-file' "$S10" "req-001: the edit sends a body file"
assert_contains 'gh pr ready' "$S10" "req-001: Step 10 marks a reused PR ready"
assert_contains 'no `Exception waiting` line' "$S10" "req-001: ready only with no waiting exception"
assert_contains "never raises a second PR" "$S10" "req-001: no second PR"

echo "req-001: tag push after Step 10c"

assert_contains "pushes the branch only" "$S10" "req-001: Step 10 pushes the branch only"
assert_contains 'git push origin v{version}' "$S10C" "req-001: Step 10c pushes the tag"
assert_contains "delete the local tag" "$S10C" "req-001: fix commits recreate the tag"
assert_contains "no force push" "$S10C" "req-001: the tag push never forces"
assert_equals "0" "$(grep -c '^git push origin v{version}' <<< "$S10")" "req-001: Step 10 runs no tag push command"
lacks 'git push origin v{version}' "$S9" "req-001: Step 9 no longer pushes the tag"

echo "req-001: polling and mapping"

assert_contains 'gh pr checks {n} --json name,bucket,link' "$S10C" "req-001: Step 10c reads checks as JSON"
assert_contains "every 30 seconds" "$S10C" "req-001: 30 second poll"
assert_contains "20 minutes" "$S10C" "req-001: 20 minute window"
assert_contains "30 minutes" "$S10C" "req-001: 30 minute window in the ADR-014 branch"
assert_contains "ADR-014" "$S10C" "req-001: Step 10c cites ADR-014"
assert_contains "rereads once" "$S10C" "req-001: one reread after the first non-empty list"
assert_contains "not from the exit status" "$S10C" "req-001: judge from JSON"
assert_contains "exits 1" "$S10C" "req-001: names exit 1"
assert_contains "exits 8" "$S10C" "req-001: names exit 8"
assert_contains '`fail` is red' "$S10C" "req-001: fail maps to red"
assert_contains '`pending` is pending' "$S10C" "req-001: pending maps to pending"
assert_contains '`skipping` is skipped' "$S10C" "req-001: skipping maps to skipped"
assert_contains '`cancel`' "$S10C" "req-001: cancel reads as unknown"
assert_contains "Unknown never counts as a pass" "$S10C" "req-001: unknown is never a pass"
assert_contains "no checks reported" "$S10C" "req-001: empty list note"
assert_contains 'CI checks (P9): {all passed | {n} failed: {names} | pending after {window} minutes | unknown: {names}}' "$S10C" "req-001: CI checks log line"
# portable-ok: search string, not a command
lacks 'timeout 1' "$S10C" "req-001: no timeout command"
assert_contains "does not use the \`timeout\` command" "$S10C" "req-001: states the timeout command is not used"

echo "req-001: build-log commit, fix loop, and results"

assert_contains "explicit path" "$S10C" "req-001: Step 10c stages the build log by explicit path"
assert_contains "before Step 11" "$S10C" "req-001: the build-log commit lands before Step 11"
assert_contains "3 attempts" "$S10C" "req-001: three fix attempts"
assert_contains "credential scan" "$S10C" "req-001: fix commits run the credential scan"
assert_contains 'Exception waiting (P9, 6): CI check {name} still red after 3 fix attempts' "$S10C" "req-001: exception line"
assert_contains 'gh pr ready --undo {n}' "$S10C" "req-001: PR returns to draft"
assert_contains "interactive" "$S10C" "req-001: names interactive handling"
assert_contains "continuous" "$S10C" "req-001: names continuous handling"
assert_contains "CI status could not be read" "$S10C" "req-001: unreadable status wording"
assert_contains 'Progress: P9 blocked at {End}: CI {result}' "$S10C" "req-001: blocked progress line"
assert_contains 'never writes `P9 done`' "$S10C" "req-001: never done on a non-pass"
assert_contains 'CI checks (P9): not run, no PR raised' "$S10C" "req-001: local-git-only line"
assert_contains "the head that P9 read" "$S10C" "req-001: coverage wording"

echo "req-001: Step 11, standards, resume"

assert_contains 'CI:' "$S11" "req-001: Step 11 gains a CI line"
FR="$(section '## Final report' "$STD")"
assert_contains "name and link" "$FR" "req-001: report part 4 names each non-passing check and link"
assert_contains "unknown" "$FR" "req-001: report part 4 states result words"
assert_contains "the head that P9 read" "$FR" "req-001: report states the coverage wording"
RES="$(section '## Resume Detection' "$ORCH")"
assert_contains 'PR: #{n}' "$RES" "req-001: Resume Detection reads the PR line"
assert_contains 'never runs `gh pr create`' "$RES" "req-001: Resume Detection never raises a second PR"
assert_contains 'rereads the checks' "$RES" "req-001: Resume Detection rereads the checks"

echo "req-001: stub gh execution"

# The command comes from the skill text. A stub gh exits 1 with valid JSON.
CMD="$(grep -o 'gh pr checks {n} --json name,bucket,link' "$SHIP" | head -1)"
CMD="${CMD//\{n\}/42}"
mkdir -p "$WORK/stub"
cat >"$WORK/stub/gh" <<'STUB'
#!/bin/sh
if [ "$1" = "pr" ] && [ "$2" = "checks" ]; then
  printf '[{"name":"Test suite (ubuntu-latest)","bucket":"fail","link":"https://example.test/1"},{"name":"lint","bucket":"pass","link":"https://example.test/2"}]\n'
  exit 1
fi
exit 0
STUB
chmod +x "$WORK/stub/gh"
OUT="$(PATH="$WORK/stub:$PATH" bash -c "$CMD" 2>&1)"
RC=$?
assert_equals "1" "$RC" "req-001: stub gh exits 1 with a failing check"
assert_contains '"bucket":"fail"' "$OUT" "req-001: data still prints on exit 1"
BUCKET="$(printf '%s' "$OUT" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const j=JSON.parse(d);console.log(j.filter(c=>c.bucket==='fail').map(c=>c.name).join(','));});")"
assert_equals "Test suite (ubuntu-latest)" "$BUCKET" "req-001: valid JSON with a fail bucket reads as red"

print_summary
