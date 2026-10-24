#!/usr/bin/env bash
# Tests for feature 0000036-pipeline-friction-and-gate-fixes
# req-007: story-split-step (ADR-011)
#
# Covers:
#   (a) each of the spec agent, design critic, and loop runner skills carries
#       one `Split step:` marker, the fourth-criterion trigger, and the
#       two-concerns question
#   (b) the spec agent and loop runner state the no-move-during-loop rule,
#       the `.ratchet-approve` condition, and the keep-answer log format
#   (c) the design critic row names the `Split step: keep` note and the build log
#   (d) ratchet-check.mjs passes a split (new requirement file) and blocks a move

set -uo pipefail

# ratchet-check finds the root through path-rules.mjs, which prefers
# CLAUDE_PROJECT_DIR. Clear it so the fixture is the root.
unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
RATCHET="$FRAMEWORK/hooks/enforcement/ratchet-check.mjs"
SPEC="$FRAMEWORK/skills/planifest-spec-agent/SKILL.md"
CRITIC="$FRAMEWORK/skills/planifest-design-critic/SKILL.md"
LOOP="$FRAMEWORK/skills/planifest-loop-runner/SKILL.md"

# Node reads the Git Bash path /tmp/x as C:\tmp\x, so use the Windows form where pwd -W exists.
TMP="$(cd "$(mktemp -d)" && { pwd -W 2>/dev/null || pwd; })"
trap 'rm -rf "$TMP"' EXIT

has() { grep -qF -- "$2" "$1" 2>/dev/null && echo yes || echo no; }

# Counts markers that are not quoted in backticks.
marker_count() { grep -oE '(^|[^`])Split step:' "$1" 2>/dev/null | wc -l | tr -d ' '; }

check_common() {
  local file="$1" label="$2"
  assert_equals "1" "$(marker_count "$file")" "$label: exactly one Split step: marker"
  assert_equals "yes" "$(has "$file" "fourth acceptance criterion")" "$label: fourth-criterion trigger"
  assert_equals "yes" "$(has "$file" "Does this requirement hold two concerns?")" "$label: two-concerns question"
}

check_rules() {
  local file="$1" label="$2"
  assert_equals "yes" "$(has "$file" "never moves or removes an existing")" "$label: no-move rule"
  assert_equals "yes" "$(has "$file" ".ratchet-approve")" "$label: .ratchet-approve condition"
  assert_equals "yes" "$(has "$file" "split step for req-NNN: keep")" "$label: keep-answer log format"
}

echo ""
echo "=== req-007: spec agent ==="
check_common "$SPEC" "spec-agent"
check_rules "$SPEC" "spec-agent"

echo ""
echo "=== req-007: loop runner ==="
check_common "$LOOP" "loop-runner"
check_rules "$LOOP" "loop-runner"

echo ""
echo "=== req-007: design critic ==="
check_common "$CRITIC" "design-critic"
assert_equals "yes" "$(has "$CRITIC" '`Split step: keep`')" "design-critic: names the Split step: keep note"
assert_equals "yes" "$(has "$CRITIC" "build log")" "design-critic: names the build log"

echo ""
echo "=== req-007: ratchet fixture ==="
PROJ="$TMP/proj"
mkdir -p "$PROJ/plan/current/requirements"
cat > "$PROJ/plan/current/loop-state-design_critic.md" <<'MD'
---
status: "active"
---
# Loop State: design_critic
MD
cat > "$PROJ/plan/current/requirements/req-001-demo.md" <<'MD'
# Requirement: req-001 - Demo
## Acceptance Criteria
- [ ] criterion alpha holds
- [ ] criterion beta holds
- [ ] criterion gamma holds
MD

run_write() {
  local fp="$1" content="$2" payload
  payload=$(node -e '
    const [fp, content] = process.argv.slice(1);
    process.stdout.write(JSON.stringify({tool_name:"Write",tool_input:{file_path:fp,content}}));
  ' "$fp" "$content")
  (cd "$PROJ" && printf '%s' "$payload" | node "$RATCHET" >/dev/null 2>&1)
  echo $?
}

NEW=$'# Requirement: req-002 - Split\n## Acceptance Criteria\n- [ ] criterion delta holds'
MOVED=$'# Requirement: req-001 - Demo\n## Acceptance Criteria\n- [ ] criterion alpha holds\n- [ ] criterion beta holds'

assert_equals "0" "$(run_write "$PROJ/plan/current/requirements/req-002-split.md" "$NEW")" \
  "ratchet: adding a new requirement file exits 0"
assert_equals "2" "$(run_write "$PROJ/plan/current/requirements/req-001-demo.md" "$MOVED")" \
  "ratchet: removing an existing criterion exits 2"

print_summary
