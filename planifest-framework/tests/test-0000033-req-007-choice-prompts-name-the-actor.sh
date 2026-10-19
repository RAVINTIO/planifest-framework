#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-007: every choice prompt in the phase skills names who acts in each
#          option, in every run mode. Options never use "I", "me", or "my".
#          formatting-standards.md states the rule.
#
# REGRESSION-CANDIDATE: covers actor naming in choice prompts across the phase skills, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
SHIP="$FRAMEWORK/skills/planifest-ship-agent/SKILL.md"
ORCH="$FRAMEWORK/skills/planifest-orchestrator/SKILL.md"
FMT="$FRAMEWORK/standards/formatting-standards.md"
OPTION_RE="^\s*\[[0-9]\].*\b(I|I'll|me|my)\b"

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

echo "=== req-007: formatting-standards.md states the rule ==="

RULE=$(sed -n '/^## 5\. Choice Prompts/,/^## /p' "$FMT")
assert_equals "yes" "$([ -n "$RULE" ] && echo yes || echo no)" "req-007: formatting-standards.md has ## 5. Choice Prompts"
for w in '"I"' '"me"' '"my"'; do
  assert_contains "$w" "$RULE" "req-007: the rule bans $w in options"
done
assert_contains '"the agent"' "$RULE" "req-007: the rule names the agent as the agent"
assert_contains '"you"' "$RULE" "req-007: the rule names the human on the loop as you"

echo ""
echo "=== req-007: ship Step 10 names the actor ==="

STEP10=$(sed -n '/^### Step 10: Push\/PR decision/,/^### Step 1[01]/p' "$SHIP")
assert_contains "Who pushes the branch and raises the PR?" "$STEP10" "req-007: Step 10 question names who pushes"
lacks "Should I push" "$STEP10" "req-007: Step 10 drops Should I push"
OPT1=$(grep -E '^\s*\[1\] ' <<< "$STEP10" | head -1)
OPT2=$(grep -E '^\s*\[2\] ' <<< "$STEP10" | head -1)
assert_contains "[1] Agent pushes and creates the PR (git push + gh pr create)" "$OPT1" "req-007: option [1] starts with Agent"
assert_contains "[2] Human pushes and creates the PR: the agent gives the PR title and description" "$OPT2" \
  "req-007: option [2] starts with Human"
assert_equals "0" "$(printf '%s\n%s\n' "$OPT1" "$OPT2" | grep -c -E "\b(I'll|me)\b")" \
  "req-007: neither Step 10 option uses I'll or me"
assert_contains "**Option [1] (Agent pushes):**" "$STEP10" "req-007: the Option [1] heading stays"
assert_contains "**Option [2] (Human pushes):**" "$STEP10" "req-007: the Option [2] heading stays"

echo ""
echo "=== req-007: orchestrator prompts name the agent ==="

HYGIENE=$(sed -n '/^## Context Hygiene/,/^## Phase 0/p' "$ORCH")
COMPACT=$(grep 'Dynamic compaction' <<< "$HYGIENE")
assert_equals "yes" "$([ -n "$COMPACT" ] && echo yes || echo no)" "req-007: compaction prompt found"
lacks "Want me to" "$COMPACT" "req-007: compaction prompt drops Want me to"
assert_contains "Should the agent compact" "$COMPACT" "req-007: compaction prompt names the agent"

FALLBACK=$(sed -n '/^\*\*Partial-failure fallback/,/^\*\*After each answer/p' "$ORCH")
assert_equals "yes" "$([ -n "$FALLBACK" ] && echo yes || echo no)" "req-007: Scope Lock fallback found"
lacks "Want me to" "$FALLBACK" "req-007: Scope Lock fallback offer drops Want me to"
assert_contains "Should the agent suggest an answer first? (agent suggests / human answers)" "$FALLBACK" \
  "req-007: Scope Lock fallback offer names the agent"

RUNMODE=$(grep -E '^\s*\[[1-3]\] (Interactive|Continuous|Autonomous):' "$ORCH")
assert_equals "3" "$(grep -c . <<< "$RUNMODE")" "req-007: run-mode prompt has three options"
assert_equals "3" "$(grep -c 'the agent' <<< "$RUNMODE")" "req-007: each run-mode option names the agent"
assert_equals "0" "$(grep -c -E "\b(I|me)\b" <<< "$RUNMODE")" "req-007: no run-mode option uses I or me"

echo ""
echo "=== req-007: sweep of skills and workflows ==="

HITS=$(grep -n -E "$OPTION_RE" "$FRAMEWORK"/skills/*/SKILL.md "$FRAMEWORK"/workflows/*.md 2>/dev/null)
assert_equals "" "$HITS" "req-007: no option line in a skill or workflow uses I, I'll, me, or my"

print_summary
