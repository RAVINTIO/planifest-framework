#!/usr/bin/env bash
# Tests for feature 0000036-pipeline-friction-and-gate-fixes.
#
# req-002: scripts/skill-drift-check.mjs compares each source SKILL.md, after
#          setup's four path rewrites and one stripped leading byte order mark,
#          with the active tool's installed copy (ADR-005). It exits 0 when all
#          match, 1 on stale, missing, or not installed, and 2 when it can't
#          compare.
#
# Every fixture lives under mktemp -d. The script runs with --root <fixture>,
# except in the default-root case.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
DRIFT="$FRAMEWORK/scripts/skill-drift-check.mjs"
SKILLS_SRC="$FRAMEWORK/skills"
SETUP_SH="$FRAMEWORK/setup.sh"
SETUP_PS1="$FRAMEWORK/setup.ps1"
ORCH="$SKILLS_SRC/planifest-orchestrator/SKILL.md"

WORK="$(mktemp -d -t planifest_0000036_req002_XXXXXX)"
LOCKED=""
cleanup() {
  [ -n "$LOCKED" ] && chmod 644 "$LOCKED" 2>/dev/null
  rm -rf "$WORK"
}
trap cleanup EXIT

BOM=$'\xef\xbb\xbf'

native() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

now_ms() {
  if command -v perl >/dev/null 2>&1; then
    perl -MTime::HiRes=time -e 'printf "%d", time * 1000'
  else
    echo $(( $(date +%s%N) / 1000000 ))
  fi
}

# setup_rewrite <file>: applies the setup.sh copy_skills() sed rewrites in place.
setup_rewrite() {
  sed -i.bak \
    -e 's|\.\./templates/|./assets/templates/|g' \
    -e 's|\.\./standards/|./references/|g' \
    -e 's|\.\./standards/reference/|./references/reference/|g' \
    -e 's|\.\./schemas/|./assets/schemas/|g' \
    "$1" && rm -f "$1.bak"
}

# make_fixture <name>: an empty project root with planifest-framework/skills/.
make_fixture() {
  local dir="$WORK/$1"
  mkdir -p "$dir/planifest-framework/skills"
  printf '%s' "$dir"
}

# add_source <fixture> <skill> <text>: writes a source SKILL.md.
add_source() {
  mkdir -p "$1/planifest-framework/skills/$2"
  printf '%s' "$3" > "$1/planifest-framework/skills/$2/SKILL.md"
}

# add_installed <fixture> <skills-dir> <skill> <text>: writes an installed SKILL.md.
add_installed() {
  mkdir -p "$1/$2/$3"
  printf '%s' "$4" > "$1/$2/$3/SKILL.md"
}

# add_marker <fixture> <tool-dir> <tool>: writes a valid setup marker.
add_marker() {
  mkdir -p "$1/$2"
  printf '{\n  "tool": "%s",\n  "flags": [],\n  "writtenAt": "2026-10-22T00:00:00Z",\n  "attemptStatus": "completed"\n}\n' "$3" > "$1/$2/.planifest-setup-flags"
}

# run_drift [args...]: runs the script and sets CODE, OUT, and ERR.
run_drift() {
  node "$DRIFT" "$@" >"$WORK/stdout.txt" 2>"$WORK/stderr.txt"
  CODE=$?
  OUT=$(cat "$WORK/stdout.txt")
  ERR=$(cat "$WORK/stderr.txt")
}

assert_not_contains() {
  local needle="$1" haystack="$2" message="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "  PASS: $message"
    ((PASS++)) || true
  else
    echo "  FAIL: $message — found '$needle' in output"
    ((FAIL++)) || true
  fi
}

SOURCE_TEXT='---
name: demo
---
See ../templates/a.md, ../standards/b.md, ../standards/reference/c.md, and ../schemas/d.json.
'
INSTALLED_TEXT='---
name: demo
---
See ./assets/templates/a.md, ./references/b.md, ./references/reference/c.md, and ./assets/schemas/d.json.
'

# =============================================================================
echo ""
echo "=== req-002: the script exists ==="

[ -f "$DRIFT" ]
assert_exit_zero $? "req-002: scripts/skill-drift-check.mjs exists"

# =============================================================================
echo ""
echo "=== req-002: a match with rewrites, a BOM, and added folders ==="

FX="$(make_fixture match)"
add_source "$FX" demo "$SOURCE_TEXT"
add_installed "$FX" .claude/skills demo "$BOM$INSTALLED_TEXT"
mkdir -p "$FX/.claude/skills/demo/assets/templates" "$FX/.claude/skills/demo/references"
printf 'old template\n' > "$FX/.claude/skills/demo/assets/templates/a.md"
printf 'old standard\n' > "$FX/.claude/skills/demo/references/b.md"
add_installed "$FX" .claude/skills external-skill "not a planifest skill"
printf 'manifest\n' > "$FX/.claude/skills/.planifest-manifest"
add_marker "$FX" .claude claude-code
run_drift --root "$FX"
assert_equals "0" "$CODE" "req-002: rewritten copy with a BOM and extra folders matches"
assert_contains "claude-code" "$OUT" "req-002: stdout names the tool checked"
assert_contains "1" "$OUT" "req-002: stdout gives the skill count"
assert_equals "" "$ERR" "req-002: a match writes nothing to stderr"

# =============================================================================
echo ""
echo "=== req-002: byte order mark cases ==="

FX="$(make_fixture bom-both)"
add_source "$FX" demo "$BOM$SOURCE_TEXT"
add_installed "$FX" .claude/skills demo "$BOM$INSTALLED_TEXT"
add_marker "$FX" .claude claude-code
run_drift --root "$FX"
assert_equals "0" "$CODE" "req-002: source BOM kept in the installed copy matches"

FX="$(make_fixture bom-source-only)"
add_source "$FX" demo "$BOM$SOURCE_TEXT"
add_installed "$FX" .claude/skills demo "$INSTALLED_TEXT"
add_marker "$FX" .claude claude-code
run_drift --root "$FX"
assert_equals "0" "$CODE" "req-002: source BOM with no installed BOM matches"

FX="$(make_fixture bom-double)"
add_source "$FX" demo "$SOURCE_TEXT"
add_installed "$FX" .claude/skills demo "$BOM$BOM$INSTALLED_TEXT"
add_marker "$FX" .claude claude-code
run_drift --root "$FX"
assert_equals "1" "$CODE" "req-002: a second BOM is content, so the copy is stale"
assert_contains "stale: claude-code: demo" "$ERR" "req-002: the double-BOM copy is named stale"

FX="$(make_fixture real-orchestrator)"
mkdir -p "$FX/planifest-framework/skills/planifest-orchestrator" "$FX/.claude/skills/planifest-orchestrator"
cp "$ORCH" "$FX/planifest-framework/skills/planifest-orchestrator/SKILL.md"
cp "$ORCH" "$FX/.claude/skills/planifest-orchestrator/SKILL.md"
setup_rewrite "$FX/.claude/skills/planifest-orchestrator/SKILL.md"
add_marker "$FX" .claude claude-code
run_drift --root "$FX"
assert_equals "0" "$CODE" "req-002: the real orchestrator SKILL.md, copied as setup.sh does, matches"

# =============================================================================
echo ""
echo "=== req-002: timed full fixture install (NFR-002) ==="

FX="$(make_fixture full)"
SKILL_COUNT=0
for skill_dir in "$SKILLS_SRC"/*; do
  [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ] || continue
  name="$(basename "$skill_dir")"
  mkdir -p "$FX/.claude/skills/$name"
  cp "$skill_dir/SKILL.md" "$FX/.claude/skills/$name/SKILL.md"
  setup_rewrite "$FX/.claude/skills/$name/SKILL.md"
  SKILL_COUNT=$((SKILL_COUNT + 1))
done
add_marker "$FX" .claude claude-code
rm -rf "$FX/planifest-framework/skills"
cp -R "$SKILLS_SRC" "$FX/planifest-framework/skills"
START=$(now_ms)
run_drift --root "$FX"
END=$(now_ms)
ELAPSED=$((END - START))
echo "  INFO: full fixture of $SKILL_COUNT skills checked in ${ELAPSED} ms"
assert_equals "0" "$CODE" "req-002: a full fixture install of every source skill matches"
assert_contains "$SKILL_COUNT" "$OUT" "req-002: stdout counts every source skill"
[ "$ELAPSED" -lt 1000 ]
assert_exit_zero $? "req-002: the full comparison finishes in under 1 s (NFR-002)"

# =============================================================================
echo ""
echo "=== req-002: default root ==="

run_drift
[ "$CODE" = "0" ] || [ "$CODE" = "1" ]
assert_exit_zero $? "req-002: a run against this repo with no --root exits 0 or 1, never 2 (got $CODE)"

# =============================================================================
echo ""
echo "=== req-002: stale and missing copies ==="

FX="$(make_fixture stale)"
add_source "$FX" demo "$SOURCE_TEXT"
add_source "$FX" other "other text"
add_installed "$FX" .claude/skills demo "$INSTALLED_TEXT"
add_installed "$FX" .claude/skills other "other text, edited"
add_marker "$FX" .claude claude-code
run_drift --root "$FX"
assert_equals "1" "$CODE" "req-002: a stale copy exits 1"
assert_contains "stale: claude-code: other" "$ERR" "req-002: stderr names the stale skill"
assert_not_contains "stale: claude-code: demo" "$ERR" "req-002: a matching skill isn't named stale"
LAST_LINE="$(printf '%s\n' "$ERR" | tail -n 1)"
assert_contains "planifest-refresh-setup" "$LAST_LINE" "req-002: the last stderr line recommends planifest-refresh-setup"

FX="$(make_fixture missing)"
add_source "$FX" demo "$SOURCE_TEXT"
add_source "$FX" absent "absent text"
add_installed "$FX" .claude/skills demo "$INSTALLED_TEXT"
add_marker "$FX" .claude claude-code
run_drift --root "$FX"
assert_equals "1" "$CODE" "req-002: a missing copy exits 1"
assert_contains "missing: claude-code: absent" "$ERR" "req-002: stderr names the missing skill"
LAST_LINE="$(printf '%s\n' "$ERR" | tail -n 1)"
assert_contains "planifest-refresh-setup" "$LAST_LINE" "req-002: the missing case ends with the refresh recommendation"

# A source folder with no SKILL.md is not a source skill.
FX="$(make_fixture no-skill-md)"
add_source "$FX" demo "$SOURCE_TEXT"
mkdir -p "$FX/planifest-framework/skills/helpers-only"
add_installed "$FX" .claude/skills demo "$INSTALLED_TEXT"
add_marker "$FX" .claude claude-code
run_drift --root "$FX"
assert_equals "0" "$CODE" "req-002: a source folder with no SKILL.md is not a source skill"

# =============================================================================
echo ""
echo "=== req-002: nothing installed ==="

FX="$(make_fixture none)"
add_source "$FX" demo "$SOURCE_TEXT"
run_drift --root "$FX"
assert_equals "1" "$CODE" "req-002: no installed copies exits 1"
assert_contains "not installed" "$ERR" "req-002: stderr says not installed"
assert_contains "setup.sh" "$ERR" "req-002: not installed recommends setup.sh"
assert_contains "setup.ps1" "$ERR" "req-002: not installed recommends setup.ps1"

FX="$(make_fixture marker-no-folder)"
add_source "$FX" demo "$SOURCE_TEXT"
add_marker "$FX" .cursor cursor
run_drift --root "$FX"
assert_equals "1" "$CODE" "req-002: an active tool with no skills folder exits 1"
assert_contains "not installed" "$ERR" "req-002: an active tool with no skills folder is not installed"

# =============================================================================
echo ""
echo "=== req-002: finding the active tool ==="

# No valid marker: every skills folder from the map that exists is checked.
FX="$(make_fixture no-marker)"
add_source "$FX" demo "$SOURCE_TEXT"
add_installed "$FX" .cursor/skills demo "$INSTALLED_TEXT"
add_installed "$FX" .agents/skills demo "stale text"
mkdir -p "$FX/.cursor"
printf 'not json' > "$FX/.cursor/.planifest-setup-flags"
mkdir -p "$FX/.agents"
printf '{"tool": "no-such-tool"}' > "$FX/.agents/.planifest-setup-flags"
run_drift --root "$FX"
assert_equals "1" "$CODE" "req-002: with no valid marker the script checks every skills folder"
assert_contains "stale: codex: demo" "$ERR" "req-002: the fallback checks the codex folder"
assert_not_contains "cursor: demo" "$ERR" "req-002: the fallback finds the cursor copy matches"

FX="$(make_fixture no-marker-match)"
add_source "$FX" demo "$SOURCE_TEXT"
add_installed "$FX" .cursor/skills demo "$INSTALLED_TEXT"
add_installed "$FX" .windsurf/skills demo "$INSTALLED_TEXT"
run_drift --root "$FX"
assert_equals "0" "$CODE" "req-002: the fallback with every copy matching exits 0"
assert_contains "cursor" "$OUT" "req-002: the fallback names cursor"
assert_contains "windsurf" "$OUT" "req-002: the fallback names windsurf"

# A valid marker narrows the check to that tool.
FX="$(make_fixture one-marker)"
add_source "$FX" demo "$SOURCE_TEXT"
add_installed "$FX" .claude/skills demo "$INSTALLED_TEXT"
add_installed "$FX" .cursor/skills demo "stale text"
add_marker "$FX" .claude claude-code
run_drift --root "$FX"
assert_equals "0" "$CODE" "req-002: a valid marker limits the check to its tool"

# Two valid markers: both tools are checked.
FX="$(make_fixture two-markers)"
add_source "$FX" demo "$SOURCE_TEXT"
add_installed "$FX" .claude/skills demo "$INSTALLED_TEXT"
add_installed "$FX" .cursor/skills demo "stale text"
add_marker "$FX" .claude claude-code
add_marker "$FX" .cursor cursor
run_drift --root "$FX"
assert_equals "1" "$CODE" "req-002: two valid markers check both tools"
assert_contains "stale: cursor: demo" "$ERR" "req-002: the second tool's stale copy is named"

# opencode installs no skills.
FX="$(make_fixture opencode)"
add_source "$FX" demo "$SOURCE_TEXT"
add_marker "$FX" .opencode opencode
run_drift --root "$FX"
assert_equals "0" "$CODE" "req-002: opencode as the only active tool exits 0"
assert_contains "no skills" "$OUT" "req-002: opencode reports that it installs no skills"

# =============================================================================
echo ""
echo "=== req-002: can't compare ==="

FX="$WORK/no-source"
mkdir -p "$FX/.claude/skills/demo"
printf 'x' > "$FX/.claude/skills/demo/SKILL.md"
add_marker "$FX" .claude claude-code
run_drift --root "$FX"
assert_equals "2" "$CODE" "req-002: a missing source skills folder exits 2"
assert_contains "planifest-framework" "$ERR" "req-002: the exit-2 reason names the source folder"

if [ "$(id -u)" != "0" ] && [ -z "${WINDIR:-}" ]; then
  FX="$(make_fixture unreadable)"
  add_source "$FX" demo "$SOURCE_TEXT"
  add_installed "$FX" .claude/skills demo "$INSTALLED_TEXT"
  add_marker "$FX" .claude claude-code
  LOCKED="$FX/.claude/skills/demo/SKILL.md"
  chmod 000 "$LOCKED"
  run_drift --root "$FX"
  chmod 644 "$LOCKED"
  LOCKED=""
  assert_equals "2" "$CODE" "req-002: an unreadable installed copy exits 2"
else
  echo "  SKIP: unreadable-file case needs a non-root POSIX user"
fi

run_drift --root
assert_equals "2" "$CODE" "req-002: --root with no value exits 2"

# =============================================================================
echo ""
echo "=== req-002: escaped names ==="

FX="$(make_fixture escape)"
EVIL=$'evil\nstale: claude-code: forged'
add_source "$FX" "$EVIL" "text"
add_marker "$FX" .claude claude-code
mkdir -p "$FX/.claude/skills"
run_drift --root "$FX"
assert_equals "1" "$CODE" "req-002: a crafted missing name exits 1"
assert_contains 'evil\nstale' "$ERR" "req-002: the newline in a name prints escaped"
if grep -qx 'stale: claude-code: forged' <<<"$ERR"; then
  FORGED=1
else
  FORGED=0
fi
assert_equals "0" "$FORGED" "req-002: a crafted name can't forge an output line"

# =============================================================================
echo ""
echo "=== req-002: the script never writes ==="

FX="$(make_fixture readonly)"
add_source "$FX" demo "$SOURCE_TEXT"
add_installed "$FX" .claude/skills demo "stale"
add_marker "$FX" .claude claude-code
BEFORE="$(cd "$FX" && find . | LC_ALL=C sort)"
run_drift --root "$FX"
AFTER="$(cd "$FX" && find . | LC_ALL=C sort)"
assert_equals "$BEFORE" "$AFTER" "req-002: a run leaves the fixture tree unchanged"
if grep -Eq "writeFile|appendFile|unlink|rmSync|renameSync|mkdirSync|copyFile|child_process" "$DRIFT"; then
  NO_WRITE=1
else
  NO_WRITE=0
fi
assert_equals "0" "$NO_WRITE" "req-002: the script names no write call and no child process"
if grep -E "^import" "$DRIFT" | grep -Ev "from \"node:|from \"\.\./hooks/enforcement/path-rules\.mjs\"" | grep -q .; then
  BUILTINS=1
else
  BUILTINS=0
fi
assert_equals "0" "$BUILTINS" "req-002: the script imports Node built-ins and path-rules.mjs only"

# =============================================================================
echo ""
echo "=== req-002: the rewrite list matches setup.sh and setup.ps1 (R-012) ==="

# unescape_regex: turns '\.' into '.' so a sed or -replace pattern reads as text.
unescape_regex() { sed 's|\\\.|.|g'; }

SH_PAIRS="$(awk '/^copy_skills\(\) \{/{f=1} f&&/^\}/{exit} f' "$SETUP_SH" \
  | grep -oE "s\|[^|]+\|[^|]+\|g" \
  | sed -E 's/^s\|([^|]+)\|([^|]+)\|g$/\1 -> \2/' | unescape_regex | LC_ALL=C sort)"
PS1_PAIRS="$(awk '/^function Copy-PlanifestSkills/{f=1} f&&/^\}/{exit} f' "$SETUP_PS1" \
  | grep -E "skillContent -replace" \
  | sed -E "s/.*-replace '([^']+)', '([^']+)'.*/\1 -> \2/" | unescape_regex | LC_ALL=C sort)"
SCRIPT_PAIRS="$(node --input-type=module -e "
  import { pathToFileURL } from 'node:url';
  const m = await import(pathToFileURL(process.argv[1]).href);
  for (const [from, to] of m.REWRITES) console.log(from + ' -> ' + to);
" "$(native "$DRIFT")" 2>/dev/null | LC_ALL=C sort)"

SH_COUNT="$(printf '%s\n' "$SH_PAIRS" | grep -c . || true)"
assert_equals "4" "$SH_COUNT" "req-002: the suite reads four rewrites from setup.sh copy_skills()"
PS1_COUNT="$(printf '%s\n' "$PS1_PAIRS" | grep -c . || true)"
assert_equals "4" "$PS1_COUNT" "req-002: the suite reads four rewrites from setup.ps1 Copy-PlanifestSkills"
assert_equals "$SH_PAIRS" "$SCRIPT_PAIRS" "req-002: the script's rewrite set matches setup.sh"
assert_equals "$PS1_PAIRS" "$SCRIPT_PAIRS" "req-002: the script's rewrite set matches setup.ps1"

# =============================================================================
echo ""
echo "=== req-002: the tool map matches setup/{tool}.sh ==="

SCRIPT_MAP="$(node --input-type=module -e "
  import { pathToFileURL } from 'node:url';
  const m = await import(pathToFileURL(process.argv[1]).href);
  for (const [tool, dir] of Object.entries(m.TOOL_SKILLS_DIRS)) console.log(tool + ' ' + (dir ?? 'none'));
" "$(native "$DRIFT")" 2>/dev/null | LC_ALL=C sort)"
SETUP_MAP=""
for tool_sh in "$FRAMEWORK"/setup/*.sh; do
  tool="$(basename "$tool_sh" .sh)"
  dir="$(sed -nE 's/^TOOL_SKILLS_DIR="([^"]*)".*/\1/p' "$tool_sh" | head -n 1)"
  if [ -n "$dir" ]; then
    SETUP_MAP="$SETUP_MAP$tool $dir"$'\n'
  elif [ "$tool" = "opencode" ]; then
    SETUP_MAP="${SETUP_MAP}opencode none"$'\n'
  fi
done
SETUP_MAP="$(printf '%s' "$SETUP_MAP" | LC_ALL=C sort)"
assert_equals "$SETUP_MAP" "$SCRIPT_MAP" "req-002: every tool map entry matches TOOL_SKILLS_DIR in its setup/{tool}.sh"

# =============================================================================
echo ""
echo "=== req-002: orchestrator Resume Detection runs the check ==="

RESUME="$(awk '/^## Resume Detection/{f=1; next} f&&/^## /{exit} f' "$ORCH")"
assert_contains "skill-drift-check.mjs" "$RESUME" "req-002: Resume Detection names the drift script"
assert_contains "planifest-refresh-setup" "$RESUME" "req-002: Resume Detection recommends planifest-refresh-setup"

print_summary
