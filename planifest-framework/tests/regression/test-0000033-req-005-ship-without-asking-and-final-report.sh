#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-005: in autonomous mode P7 to P9 ask nothing. The ship agent reads the
#          run mode from the build-log Run mode row, pushes and raises the PR
#          (as a draft while an exception waits) unless local-git-only
#          applies, and ends with one final report. No mode merges the PR.
#
# REGRESSION-CANDIDATE: covers the autonomous ship path and the final report format, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/../.." && pwd)"
SHIP="$FRAMEWORK/skills/planifest-ship-agent/SKILL.md"
ORCH="$FRAMEWORK/skills/planifest-orchestrator/SKILL.md"
STD="$FRAMEWORK/standards/autonomous-run-standards.md"
REF="$FRAMEWORK/pipeline-reference.md"

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

# before <a> <b> <label>: passes when both line numbers exist and a < b.
before() {
  assert_equals "yes" "$([ -n "$1" ] && [ -n "$2" ] && [ "$1" -lt "$2" ] && echo yes || echo no)" "$3"
}

echo "=== req-005: standards file ## Final report ==="

REPORT=$(sed -n '/^## Final report/,/^## /p' "$STD" 2>/dev/null)
assert_equals "yes" "$([ -n "$REPORT" ] && echo yes || echo no)" "req-005: standards file has a ## Final report heading"
for part in "What shipped" "\`Decision\`" "\`Deviation\`" "Step 9 tag" "PR URL" "CI result" "clean-tree result" "\`Exception waiting\`"; do
  assert_contains "$part" "$REPORT" "req-005: final report names $part"
done
assert_contains "gh pr checks" "$REPORT" "req-005: final report reads CI from gh pr checks"
assert_contains "\`pending\`" "$REPORT" "req-005: unfinished CI reads pending"
assert_contains "\`none\`" "$REPORT" "req-005: no waiting exception reads none"
assert_contains "the human on the loop reviews and merges the PR" "$REPORT" \
  "req-005: the report ends by saying the human on the loop merges"
assert_contains "only output of P7 to P9" "$REPORT" "req-005: the report is the only P7 to P9 output to the human"
assert_equals "6" "$(grep -c -E '^[1-6]\. ' <<< "$REPORT")" "req-005: the report lists six numbered parts"

echo ""
echo "=== req-005: ship skill reads the run mode from the build-log row ==="

RUNMODE=$(sed -n '/^## Run mode/,/^## /p' "$SHIP")
assert_contains "\`Run mode\` row" "$RUNMODE" "req-005: ship skill reads the build-log Run mode row"
assert_contains "plan/current/build-log.md" "$RUNMODE" "req-005: before Step 6 it reads the current build log"
assert_contains "{archive-dir}/build-log.md" "$RUNMODE" "req-005: after Step 6 it reads the archived build log"
TAG_LINE=$(grep -n '^### Step 9' "$SHIP" | head -1 | cut -d: -f1)
lacks ".run-mode" "$(sed -n "${TAG_LINE:-1},\$p" "$SHIP")" "req-005: no line after the marker step reads plan/.run-mode"

HL4=$(grep -E '^4\. ' <<< "$(sed -n '/^## Hard Limits/,/^## /p' "$SHIP")")
assert_contains "\`autonomous\`" "$HL4" "req-005: Hard Limit 4 names autonomous"
assert_contains "final report" "$HL4" "req-005: Hard Limit 4 names the final report"

STEP4=$(sed -n '/^### Step 4: Regression confirmation/,/^### Step 5/p' "$SHIP")
assert_contains "\`autonomous\`" "$STEP4" "req-005: Step 4 names autonomous"
assert_contains '"agent"' "$STEP4" "req-005: Step 4 passes agent as promoted-by"

echo ""
echo "=== req-005: Step 10 in autonomous ==="

S10=$(grep -n '^### Step 10: Push/PR decision' "$SHIP" | head -1 | cut -d: -f1)
S11=$(grep -n '^### Step 11' "$SHIP" | head -1 | cut -d: -f1)
S12=$(grep -n '^### Step 12' "$SHIP" | head -1 | cut -d: -f1)
STEP10=$(sed -n "${S10:-1},$(( ${S11:-2} - 1 ))p" "$SHIP")
LGO=$(grep -n 'local-git-only' <<< "$STEP10" | head -1 | cut -d: -f1)
AUTO=$(grep -n '`autonomous`' <<< "$STEP10" | head -1 | cut -d: -f1)
before "$LGO" "$AUTO" "req-005: Step 10 checks local-git-only before the autonomous rule"
assert_contains "**Option [1] (Agent pushes):**" "$STEP10" "req-005: Step 10 keeps the Option [1] heading"
assert_contains "**Option [2] (Human pushes):**" "$STEP10" "req-005: Step 10 keeps the Option [2] heading"
assert_contains "gh pr create --draft" "$STEP10" "req-005: Step 10 raises a draft PR while an exception waits"
assert_contains "lists every waiting exception" "$STEP10" "req-005: the draft PR description lists each exception"
AFTER_PR=$(grep -F '**After the PR:**' "$SHIP")
assert_contains "local-git-only" "$AFTER_PR" "req-005: the after-PR push rule names the local-git-only exception"
assert_contains "\`autonomous\`" "$AFTER_PR" "req-005: the after-PR push rule applies in autonomous"

STEP11=$(sed -n "${S11:-1},$(( ${S12:-2} - 1 ))p" "$SHIP")
assert_contains "final report" "$STEP11" "req-005: Step 11 names the final report"
assert_contains "\`autonomous\`" "$STEP11" "req-005: Step 11 names autonomous"
assert_contains "autonomous-run-standards.md" "$STEP11" "req-005: Step 11 links the final report format"
before "$S11" "$S12" "req-005: Step 12 still follows Step 11"
lacks "gh pr merge" "$(cat "$SHIP")" "req-005: the ship skill never runs gh pr merge"

echo ""
echo "=== req-005: orchestrator and pipeline reference ==="

P7_GATE=$(sed -n '/^## Phase 7 - Archive/,/^## Phase 8/p' "$ORCH" | grep '^\*\*Gate:\*\*')
assert_contains "always a confirmation stop" "$P7_GATE" "req-005: Phase 7 gate keeps always a confirmation stop"
assert_contains "\`autonomous\`" "$P7_GATE" "req-005: Phase 7 gate names autonomous"
P9_ORCH=$(sed -n '/^## Phase 9 - Ship/,/^## /p' "$ORCH")
assert_contains "\`autonomous\`" "$(grep 'What P9 produces' <<< "$P9_ORCH")" "req-005: What P9 produces names autonomous"
assert_contains "final report" "$(grep '^\*\*Gate:\*\*' <<< "$P9_ORCH")" "req-005: Phase 9 gate names the final report"
P9_STOP=$(grep -A2 'P9 always stops' "$REF")
assert_contains "\`autonomous\`" "$P9_STOP" "req-005: pipeline-reference names autonomous next to the P9 stop rule"
assert_contains "still merges" "$P9_STOP" "req-005: pipeline-reference says the human on the loop still merges"

echo ""
echo "=== req-005: P5 fixes for branch check, push lines, and the final report file ==="

OPT1=$(sed -n '/^\*\*Option \[1\] (Agent pushes):\*\*/,/^\*\*Option \[2\]/p' "$SHIP")
BRANCH_LINE=$(grep -n 'git branch --show-current' <<< "$STEP10" | head -1 | cut -d: -f1)
PUSH_LINE=$(grep -n -F 'git push -u origin HEAD' <<< "$STEP10" | head -1 | cut -d: -f1)
before "$BRANCH_LINE" "$PUSH_LINE" "req-005: Step 10 checks the branch before the push (P5 G3)"
assert_contains "\`feat/\`" "$STEP10" "req-005: Step 10 requires a feat/ branch in autonomous (P5 G3)"
assert_contains "default branch" "$STEP10" "req-005: Step 10 refuses to push from the default branch (P5 G3)"
assert_contains "exception item" "$(grep -F 'git branch --show-current' -A3 <<< "$STEP10")" \
  "req-005: a refused branch push becomes an exception item (P5 G3)"
assert_contains "git push -u origin HEAD" "$OPT1" "req-005: Option [1] pushes with git push -u origin HEAD (P5 G9)"
assert_contains "git push origin v{version}" "$OPT1" "req-005: Option [1] pushes only the release tag (P5 G9)"
lacks "--tags" "$(cat "$SHIP")" "req-005: the ship skill never runs git push --tags (P5 G9)"
assert_equals "0" "$(grep -c -E 'git push .*(--force|-f( |$))' "$SHIP")" "req-005: no ship skill push uses --force or --force-with-lease (P5 G9)"
assert_contains "No step in any mode uses \`--force\` or \`--force-with-lease\`" "$STEP10" \
  "req-005: Step 10 states the no-force rule (P5 G9)"
assert_contains "{archive-dir}/final-report.md" "$STEP11" "req-005: Step 11 writes the final report to a file (P5 G7)"
assert_contains 'git commit -m "plan(p9): add final report for {feature-id}" -- "{archive-dir}/final-report.md"' "$STEP11" \
  "req-005: Step 11 commits the final report by explicit path (P5 G7)"
assert_contains "after-PR push rule" "$STEP11" "req-005: Step 11 pushes the report under the after-PR rule (P5 G7)"
assert_contains "points to" "$STEP11" "req-005: the chat message points to the report file (P5 G7)"

print_summary
