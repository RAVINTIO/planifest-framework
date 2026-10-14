#!/usr/bin/env bash
# Tests for feature 0000030, req-005: refresh-setup stops offering the retired
# integrations, the downstream migration exists, and this repository's own
# install references no missing hook file.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT="$(cd "$FRAMEWORK/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

SKILL="$FRAMEWORK/skills/planifest-refresh-setup/SKILL.md"
MIGRATION="$FRAMEWORK/migrations/migrate-remove-context-mode-and-telemetry.md"

echo "=== req-005: refresh-setup no longer detects either integration ==="
outside_fence=$(awk '/BEGIN retired-integrations/{f=1} /END retired-integrations/{f=0;next} !f' "$SKILL" \
  | grep -ciE 'context-mode|structured-telemetry|backend-url|backendUrl' || true)
assert_equals "0" "$outside_fence" "req-005: refresh-setup names no retired flag outside its fenced note"
assert_contains "BEGIN retired-integrations (0000030)" "$(cat "$SKILL")" "req-005: refresh-setup carries the fenced retired-flag note"

echo "=== req-005: downstream migration exists ==="
if [ -f "$MIGRATION" ]; then present=yes; else present=no; fi
assert_equals "yes" "$present" "req-005: migrate-remove-context-mode-and-telemetry.md exists"
assert_contains "Nothing to migrate" "$(cat "$MIGRATION" 2>/dev/null)" "req-005: migration archives itself when no stale state exists"

echo "=== req-005: this repo's own install references no missing hook ==="
SETTINGS="$ROOT/.claude/settings.json"
if [ -f "$SETTINGS" ]; then
  missing=$(cd "$ROOT" && node -e '
    const fs=require("fs");const s=JSON.parse(fs.readFileSync(".claude/settings.json","utf8"));const out=[];
    for(const groups of Object.values(s.hooks||{}))for(const g of groups)for(const h of g.hooks||[]){
      const m=(h.command||"").match(/(\.claude\/hooks\/[^" ]+\.mjs)/);if(m&&!fs.existsSync(m[1]))out.push(m[1]);}
    console.log(out.length);')
  assert_equals "0" "$missing" "req-005: every hook file named in .claude/settings.json exists"
  stale=$(grep -ciE 'hooks/telemetry/|hooks/context-mode/|check-telemetry-' "$SETTINGS" || true)
  assert_equals "0" "$stale" "req-005: .claude/settings.json has no retired hook entry"
else
  echo "  SKIP: no .claude/settings.json in this checkout"
fi

print_summary
