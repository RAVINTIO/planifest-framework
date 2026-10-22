#!/usr/bin/env bash
# Tests for feature 0000035-write-gate-scope-and-path-hardening.
#
# req-009: path-rules.mjs exports FAST_PATH_ENFORCEMENT_PATHS. The gate checks
#          it before the Fast Path scope record, matches it case-insensitively,
#          and never lets a record admit a listed path (ADR-004). The
#          fast-path.md prerequisites name the same entries.
#
# Every fixture lives under mktemp -d. The suite uses git to build fixtures.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
ENF="$FRAMEWORK/hooks/enforcement"
GATE_WRITE="$ENF/gate-write.mjs"
SHELL_GUARD="$ENF/shell-write-guard.mjs"
PATH_RULES="$ENF/path-rules.mjs"
FAST_PATH_MD="$FRAMEWORK/workflows/fast-path.md"

WORK="$(mktemp -d -t planifest_0000035_req009_XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

native() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

GIT=(git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c init.defaultBranch=main)

FX="$WORK/repo"
mkdir -p "$FX/plan/current" "$FX/src"
"${GIT[@]}" init -q "$FX" >/dev/null 2>&1
"${GIT[@]}" -C "$FX" commit -q --allow-empty -m init --no-verify >/dev/null 2>&1
BRANCH="$(git -C "$FX" rev-parse --abbrev-ref HEAD)"
HEAD_ID="$(git -C "$FX" rev-parse HEAD)"

# record <path>...: a current scope record that lists each path.
record() {
  {
    printf 'branch: %s\nhead: %s\npaths:\n' "$BRANCH" "$HEAD_ID"
    for p in "$@"; do printf -- '- %s\n' "$p"; done
  } > "$FX/plan/.fast-path-scope"
}

# run_gate <target>: runs gate-write from the fixture and sets CODE and ERR.
run_gate() {
  local errfile="$WORK/stderr.txt"
  node "$GATE_WRITE" >/dev/null 2>"$errfile" <<< "{\"cwd\":\"$(native "$FX")\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$1\"}}"
  CODE=$?
  ERR=$(cat "$errfile")
}

# run_guard <command>: runs the shell-write guard from the fixture and sets CODE and ERR.
run_guard() {
  local errfile="$WORK/stderr.txt"
  node "$SHELL_GUARD" >/dev/null 2>"$errfile" <<< "{\"cwd\":\"$(native "$FX")\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$1\"}}"
  CODE=$?
  ERR=$(cat "$errfile")
}

# never_admits <listed> <target>: a record listing <listed> still blocks <target> in both gates.
never_admits() {
  record "$1"
  run_gate "$2"
  assert_equals "2" "$CODE" "req-009: a record listing $1 never admits $2 in gate-write"
  assert_contains "0000033 ADR 009" "$ERR" "req-009: the gate-write reason for $2 names 0000033 ADR 009"
  assert_contains "Change or Feature Pipeline" "$ERR" "req-009: the gate-write reason for $2 points to the Change or Feature Pipeline"
  run_guard "touch $2"
  assert_equals "2" "$CODE" "req-009: a record listing $1 never admits $2 in the shell guard"
}

# =============================================================================
echo ""
echo "=== req-009: the acceptance criteria cases ==="

never_admits "planifest-framework/" "planifest-framework/hooks/enforcement/gate-write.mjs"
never_admits "planifest-framework/hooks/" "planifest-framework/hooks/enforcement/gate-write.mjs"
never_admits ".claude/settings.json" ".claude/settings.json"
never_admits ".claude/settings.local.json" ".claude/settings.local.json"
never_admits "planifest-framework/setup/claude-code.sh" "planifest-framework/setup/claude-code.sh"
never_admits "Planifest-Framework/Hooks/x.mjs" "Planifest-Framework/Hooks/x.mjs"

# Control: the same record still admits a path off the list.
record "planifest-framework/"
run_gate "planifest-framework/workflows/x.md"
assert_equals "0" "$CODE" "req-009: a record listing planifest-framework/ still admits planifest-framework/workflows/x.md"

# =============================================================================
echo ""
echo "=== req-009: every group on the list ==="

for target in \
  "planifest-framework/scripts/run-mode.mjs" \
  "planifest-framework/standards/autonomous-run-standards.md" \
  "setup.sh" \
  "tools/setup.ps1" \
  ".claude/hooks/enforcement/gate-write.mjs" \
  ".cursor/hooks/adapters/cursor.mjs" \
  ".git/hooks/pre-commit" \
  ".git/config" \
  ".cursor/settings.json" \
  ".clinerules/hooks.json" \
  ".windsurf/hooks.json" \
  ".github/hooks/planifest.json" \
  ".codex/config.toml" \
  "opencode.json" \
  "opencode.jsonc" \
  ".opencode/plugins/@planifest/opencode-hooks/index.js" \
  ".CLAUDE/Settings.Local.JSON"; do
  record "$target"
  run_gate "$target"
  assert_equals "2" "$CODE" "req-009: a record never admits $target in gate-write"
  run_guard "touch $target"
  assert_equals "2" "$CODE" "req-009: a record never admits $target in the shell guard"
done

# A setup.sh-like name that isn't setup.sh stays off the list.
record "tools/setup.sh.md"
run_gate "tools/setup.sh.md"
assert_equals "0" "$CODE" "req-009: tools/setup.sh.md is not an enforcement path"
record "docs-site/hooks/x.md"
run_gate "docs-site/hooks/x.md"
assert_equals "0" "$CODE" "req-009: a hooks/ folder without enforcement/ or adapters/ is not on the list"

# =============================================================================
echo ""
echo "=== req-009: fast-path.md and FAST_PATH_ENFORCEMENT_PATHS name the same entries ==="

CODE_LIST=$(node --input-type=module -e "
import { FAST_PATH_ENFORCEMENT_PATHS } from '$(native "$PATH_RULES")';
process.stdout.write([...FAST_PATH_ENFORCEMENT_PATHS].sort().join('\n'));
")
assert_equals "yes" "$([ -n "$CODE_LIST" ] && echo yes || echo no)" "req-009: path-rules.mjs exports FAST_PATH_ENFORCEMENT_PATHS"

# The doc list runs from the "enforcement paths" bullet to the line that
# routes a match to the Change or Feature Pipeline. Each entry is a bullet
# that starts with the entry in code font.
DOC_LIST=$(awk '/touches none of these enforcement paths/{on=1; next} /A change to any of them/{on=0} on' "$FAST_PATH_MD" \
  | sed -n 's/^[[:space:]]*- `\([^`]*\)`.*/\1/p' | sort)
assert_equals "yes" "$([ -n "$DOC_LIST" ] && echo yes || echo no)" "req-009: fast-path.md lists enforcement entries"

while IFS= read -r entry; do
  [ -z "$entry" ] && continue
  assert_equals "yes" "$(grep -qxF -- "$entry" <<< "$CODE_LIST" && echo yes || echo no)" "req-009: doc entry $entry is in FAST_PATH_ENFORCEMENT_PATHS"
done <<< "$DOC_LIST"
while IFS= read -r entry; do
  [ -z "$entry" ] && continue
  assert_equals "yes" "$(grep -qxF -- "$entry" <<< "$DOC_LIST" && echo yes || echo no)" "req-009: constant entry $entry is in the fast-path.md prerequisites"
done <<< "$CODE_LIST"

print_summary
