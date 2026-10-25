#!/usr/bin/env bash
# Tests for feature 0000038-token-efficiency-windows-shard.
#
# req-002: Claude Code model values are sonnet, opus, haiku, or fable (ADR-003).
#          The Claude Code tier-table cells, every model: and recommended_model:
#          line in skills and standards, and pipeline-reference.md pass an allowlist.
#
# Verified by: unit

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# bad_cells <file>: prints each Claude Code table cell outside the allowlist.
bad_cells() {
  awk -F'|' '/^\| *Claude Code *\|/ {
    for (i = 3; i <= 4; i++) {
      v = $i; gsub(/^[ \t]+|[ \t]+$/, "", v)
      if (v != "sonnet" && v != "opus" && v != "haiku" && v != "fable") print v
    }
  }' "$1"
}

# bad_lines <file>...: prints each model: or recommended_model: value outside the allowlist.
bad_lines() {
  grep -hE '^[[:space:]]*(recommended_)?model:' "$@" 2>/dev/null \
    | sed -E 's/^[[:space:]]*(recommended_)?model:[[:space:]]*//; s/[[:space:]]*,?[[:space:]]*$//; s/^"(.*)"$/\1/' \
    | grep -vxE 'sonnet|opus|haiku|fable'
}

# bad_skeleton <file>: prints each model: "x" argument in an Agent( call outside the allowlist.
bad_skeleton() {
  grep -oE 'Agent\(.*model: *"[^"]*"' "$1" \
    | sed -E 's/.*model: *"([^"]*)"/\1/' \
    | grep -vxE 'sonnet|opus|haiku|fable'
}

STD="$FW/standards/agent-dispatch-standards.md"
REF="$FW/pipeline-reference.md"

echo "req-002: real files pass the allowlist"
assert_equals "" "$(bad_cells "$STD")" "req-002: standard tier table Claude Code cells"
assert_equals "" "$(bad_cells "$REF")" "req-002: pipeline-reference Claude Code cells"
assert_equals "" "$(bad_skeleton "$STD")" "req-002: dispatch skeleton model values"
assert_equals "" "$(bad_lines "$FW"/skills/*/SKILL.md "$FW"/standards/*.md "$REF")" "req-002: model: lines in skills, standards, reference"
assert_contains 'model: "haiku"' "$(cat "$STD")" "req-002: skeleton passes haiku"
assert_contains '| Claude Code | sonnet | haiku |' "$(cat "$STD")" "req-002: tier table keeps primary sonnet, cheaper haiku"
assert_contains '| Windsurf | claude-sonnet-4-6 | claude-haiku-4-5 |' "$(cat "$STD")" "req-002: other tool rows keep their ids"

echo "req-002: fixtures with claude-haiku-4-5 fail"
printf '| Claude Code | sonnet | claude-haiku-4-5 |\n' > "$WORK/cell.md"
assert_equals "claude-haiku-4-5" "$(bad_cells "$WORK/cell.md")" "req-002: table cell fixture fails"
printf '| Claude Code | claude-sonnet-4-6 (or latest Sonnet) | haiku |\n' > "$WORK/cell2.md"
assert_equals "claude-sonnet-4-6 (or latest Sonnet)" "$(bad_cells "$WORK/cell2.md")" "req-002: or-latest cell fixture fails"
printf 'Agent({ description: "x", model: "claude-haiku-4-5",\n' > "$WORK/skel.md"
assert_equals "claude-haiku-4-5" "$(bad_skeleton "$WORK/skel.md")" "req-002: skeleton fixture fails"
printf 'name: x\nmodel: claude-haiku-4-5\n' > "$WORK/skill.md"
assert_equals "claude-haiku-4-5" "$(bad_lines "$WORK/skill.md")" "req-002: skill model line fixture fails"
printf '```\n   model: "claude-haiku-4-5",\n```\nrecommended_model: gpt-4o\n' > "$WORK/indent.md"
assert_equals "$(printf 'claude-haiku-4-5\ngpt-4o')" "$(bad_lines "$WORK/indent.md")" "req-002: indented and recommended_model fixtures fail"
printf 'model: fable\n  model: "opus"\nrecommended_model: haiku\n' > "$WORK/ok.md"
assert_equals "" "$(bad_lines "$WORK/ok.md")" "req-002: allowed values pass"

print_summary
