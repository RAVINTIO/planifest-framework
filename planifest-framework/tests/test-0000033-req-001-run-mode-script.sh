#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-001: scripts/run-mode.mjs prints the effective run mode. It prints
#          `autonomous` only when one commit anchors it in git history. Every
#          reader after P0 calls the script instead of reading a record
#          directly (P5 C2-1, P5 C2-2).
#
# REGRESSION-CANDIDATE: covers the run-mode script and its git anchor, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$(cd "$SCRIPT_DIR/.." && pwd)"
RUNMODE="$FW/scripts/run-mode.mjs"
STD="$FW/standards/autonomous-run-standards.md"
ORCH="$FW/skills/planifest-orchestrator/SKILL.md"
SHIP="$FW/skills/planifest-ship-agent/SKILL.md"
BA="$FW/skills/planifest-build-assessment-agent/SKILL.md"
DISPATCH="$FW/standards/agent-dispatch-standards.md"
CALL="node planifest-framework/scripts/run-mode.mjs"

SCRATCH=$(mktemp -d -t planifest_0000033_req001_XXXXXX)
trap 'rm -rf "$SCRATCH"' EXIT

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

# section <heading-prefix> <file>: prints one `## ` section, heading included.
section() {
  awk -v h="$1" 'index($0, h) == 1 { on = 1; print; next } on && /^## / { exit } on { print }' "$2"
}

# make_repo <dir>: a git repo with an unconfirmed design and an interactive build log.
make_repo() {
  local r="$1"
  mkdir -p "$r/plan/current"
  git -C "$r" init -q
  git -C "$r" config user.email test@example.com
  git -C "$r" config user.name test
  git -C "$r" config commit.gpgsign false
  printf '# Design\n\n## Confirmation\nHuman confirmed this design before proceeding: no // Date and Time confirmed: -\n' \
    > "$r/plan/current/design.md"
  printf '# Build log\n\n| Field | Value |\n|-------|-------|\n| Run mode | `interactive` |\n\n## P0\n' \
    > "$r/plan/current/build-log.md"
  git -C "$r" add -A
  git -C "$r" commit -q -m init
}

# set_row <dir> <mode>: rewrites the build-log Run mode row.
set_row() {
  sed -i.bak "s/^| Run mode | .*|\$/| Run mode | \`$2\` |/" "$1/plan/current/build-log.md"
  rm -f "$1/plan/current/build-log.md.bak"
}

# confirm_design <dir>: sets the design Confirmation line to yes.
confirm_design() {
  sed -i.bak 's/^Human confirmed this design before proceeding: no/Human confirmed this design before proceeding: yes/' \
    "$1/plan/current/design.md"
  rm -f "$1/plan/current/design.md.bak"
}

# anchor <dir>: one commit confirms the design and adds the autonomous line.
anchor() {
  confirm_design "$1"
  set_row "$1" autonomous
  echo "Run mode confirmed: autonomous (2026-10-19T10:00:00Z)" >> "$1/plan/current/build-log.md"
  echo autonomous > "$1/plan/.run-mode"
  git -C "$1" add -A
  git -C "$1" commit -q -m "plan(p0): confirm design"
}

# mode <dir> [args...]: prints stdout only.
mode() {
  local r="$1"; shift
  (cd "$r" && node "$RUNMODE" "$@" 2>/dev/null)
}

# reason <dir> [args...]: prints stderr only.
reason() {
  local r="$1"; shift
  (cd "$r" && node "$RUNMODE" "$@" 2>&1 >/dev/null)
}

echo "=== req-001: run-mode.mjs exists (P5 C2-1) ==="

assert_equals "yes" "$([ -f "$RUNMODE" ] && echo yes || echo no)" "req-001: scripts/run-mode.mjs exists (P5 C2-1)"
HEAD_TEXT=$( [ -f "$RUNMODE" ] && sed -n '1,40p' "$RUNMODE" )
assert_contains "errant subagent" "$HEAD_TEXT" "req-001: header names the errant-subagent threat (P5 C2-1)"
assert_contains "forge" "$HEAD_TEXT" "req-001: header states an agent that can commit can forge an anchor (P5 C2-1)"
assert_contains "never depend on the run mode" "$HEAD_TEXT" "req-001: header says the standing rules never depend on the run mode (P5 C2-1)"
lacks "shell: true" "$( [ -f "$RUNMODE" ] && cat "$RUNMODE" )" "req-001: the script never spawns a shell (P5 C2-1)"
assert_contains "GIT_LITERAL_PATHSPECS" "$( [ -f "$RUNMODE" ] && cat "$RUNMODE" )" "req-001: git calls use literal pathspecs (P5 C2-1)"

echo ""
echo "=== req-001: anchored autonomous (P5 C2-1) ==="

R1="$SCRATCH/anchored"
make_repo "$R1"
anchor "$R1"
OUT1=$(mode "$R1"); EXIT1=$?
assert_equals "autonomous" "$OUT1" "req-001: an anchored autonomous run prints autonomous (P5 C2-1)"
assert_exit_zero "$EXIT1" "req-001: the script exits 0 (P5 C2-1)"
rm -f "$R1/plan/.run-mode"
assert_equals "autonomous" "$(mode "$R1")" "req-001: the build-log row alone still reads anchored autonomous (P5 C2-1)"

echo ""
echo "=== req-001: archived build log after P7 Step 6 (P5 C2-1) ==="

ARCH="plan/_archive/0000099-x-2026-10-19"
mkdir -p "$R1/$ARCH"
git -C "$R1" mv plan/current/build-log.md "$ARCH/build-log.md"
git -C "$R1" mv plan/current/design.md "$ARCH/design.md"
echo "## P7" >> "$R1/$ARCH/build-log.md"
git -C "$R1" add -A
git -C "$R1" commit -q -m "plan(p7): archive"
assert_equals "autonomous" "$(mode "$R1" "$ARCH/build-log.md")" "req-001: an archived build-log path keeps the anchor (P5 C2-1)"

echo ""
echo "=== req-001: row-only edit (P5 C2-1) ==="

R2="$SCRATCH/row-only"
make_repo "$R2"
set_row "$R2" autonomous
echo "Run mode confirmed: autonomous (2026-10-19T10:00:00Z)" >> "$R2/plan/current/build-log.md"
assert_equals "interactive" "$(mode "$R2")" "req-001: an uncommitted row and line read interactive (P5 C2-1)"
assert_equals "1" "$(reason "$R2" | grep -c .)" "req-001: a refused autonomous writes one reason line (P5 C2-1)"
git -C "$R2" add -A
git -C "$R2" commit -q -m "edit row"
assert_equals "interactive" "$(mode "$R2")" "req-001: a committed row without a design confirmation reads interactive (P5 C2-1)"

echo ""
echo "=== req-001: file-only edit (P5 C2-1) ==="

R3="$SCRATCH/file-only"
make_repo "$R3"
echo autonomous > "$R3/plan/.run-mode"
assert_equals "interactive" "$(mode "$R3")" "req-001: plan/.run-mode alone reads interactive (P5 C2-1)"
assert_equals "1" "$(reason "$R3" | grep -c .)" "req-001: file-only edit writes one reason line (P5 C2-1)"

echo ""
echo "=== req-001: line added in a later commit (P5 C2-1) ==="

R4="$SCRATCH/later"
make_repo "$R4"
confirm_design "$R4"
git -C "$R4" add -A
git -C "$R4" commit -q -m "plan(p0): confirm design"
set_row "$R4" autonomous
echo "Run mode confirmed: autonomous (2026-10-19T10:00:00Z)" >> "$R4/plan/current/build-log.md"
git -C "$R4" add -A
git -C "$R4" commit -q -m "later"
assert_equals "interactive" "$(mode "$R4")" "req-001: a line added apart from the design confirmation reads interactive (P5 C2-1)"

echo ""
echo "=== req-001: line edited after the anchor (P5 C2-1) ==="

R5="$SCRATCH/edited"
make_repo "$R5"
anchor "$R5"
sed -i.bak 's/^Run mode confirmed: autonomous.*/Run mode confirmed: autonomous (2026-10-20T10:00:00Z)/' "$R5/plan/current/build-log.md"
rm -f "$R5/plan/current/build-log.md.bak"
assert_equals "interactive" "$(mode "$R5")" "req-001: a working-tree edit to the line reads interactive (P5 C2-1)"
git -C "$R5" add -A
git -C "$R5" commit -q -m "edit line"
assert_equals "interactive" "$(mode "$R5")" "req-001: a later commit that edits the line reads interactive (P5 C2-1)"

R5B="$SCRATCH/duplicated"
make_repo "$R5B"
anchor "$R5B"
echo "Run mode confirmed: autonomous (2026-10-19T11:00:00Z)" >> "$R5B/plan/current/build-log.md"
git -C "$R5B" add -A
git -C "$R5B" commit -q -m "second line"
assert_equals "interactive" "$(mode "$R5B")" "req-001: a second commit adding the line reads interactive (P5 C2-1)"

echo ""
echo "=== req-001: symlinked records (P5 C2-1) ==="

R6="$SCRATCH/symlink-log"
make_repo "$R6"
anchor "$R6"
cp "$R6/plan/current/build-log.md" "$SCRATCH/real-log.md"
rm "$R6/plan/current/build-log.md"
ln -s "$SCRATCH/real-log.md" "$R6/plan/current/build-log.md"
assert_equals "interactive" "$(mode "$R6")" "req-001: a symlinked build log reads interactive (P5 C2-1)"

R6B="$SCRATCH/symlink-runmode"
make_repo "$R6B"
echo continuous > "$SCRATCH/real-run-mode"
ln -s "$SCRATCH/real-run-mode" "$R6B/plan/.run-mode"
assert_equals "interactive" "$(mode "$R6B")" "req-001: a symlinked plan/.run-mode reads interactive (P5 C2-1)"

R6C="$SCRATCH/symlink-current"
make_repo "$R6C"
mv "$R6C/plan/current" "$SCRATCH/real-current"
ln -s "$SCRATCH/real-current" "$R6C/plan/current"
echo continuous > "$R6C/plan/.run-mode"
assert_equals "interactive" "$(mode "$R6C")" "req-001: a symlinked plan/current/ reads interactive (P5 C2-1)"

echo ""
echo "=== req-001: continuous, interactive, unknown, and missing (P5 C2-1) ==="

R7="$SCRATCH/continuous"
make_repo "$R7"
echo continuous > "$R7/plan/.run-mode"
assert_equals "continuous" "$(mode "$R7")" "req-001: plan/.run-mode continuous prints continuous (P5 C2-1)"
rm "$R7/plan/.run-mode"
set_row "$R7" continuous
assert_equals "continuous" "$(mode "$R7")" "req-001: a continuous build-log row prints continuous (P5 C2-1)"
echo bogus > "$R7/plan/.run-mode"
assert_equals "interactive" "$(mode "$R7")" "req-001: an unknown value prints interactive (P5 C2-1)"

R8="$SCRATCH/missing"
mkdir -p "$R8"
OUT8=$(mode "$R8"); EXIT8=$?
assert_equals "interactive" "$OUT8" "req-001: missing files print interactive (P5 C2-1)"
assert_exit_zero "$EXIT8" "req-001: missing files still exit 0 (P5 C2-1)"
assert_equals "interactive" "$(mode "$R8" plan/_archive/none/build-log.md)" "req-001: a missing build-log argument prints interactive (P5 C2-1)"

echo ""
echo "=== req-001: every reader after P0 calls the script (P5 C2-2) ==="

STEP6=$(grep -E '^6\. ' "$ORCH" | grep -i 'run mode')
assert_contains "$CALL" "$STEP6" "req-001: Resume step 6 calls run-mode.mjs (P5 C2-2)"
lacks "three sources" "$STEP6" "req-001: Resume step 6 drops the three-record check (P5 C2-2)"
RM=$(section "## Run modes" "$STD")
assert_contains "$CALL" "$RM" "req-001: standards Run modes names run-mode.mjs (P5 C2-2)"
lacks "three sources agree" "$RM" "req-001: standards Run modes drops the three-source check (P5 C2-2)"
SHIP_RM=$(section "## Run mode" "$SHIP")
assert_contains "$CALL" "$SHIP_RM" "req-001: ship-agent Run mode calls run-mode.mjs (P5 C2-2)"
assert_contains "$CALL {archive-dir}/build-log.md" "$SHIP_RM" "req-001: ship-agent passes the archived build log after Step 6 (P5 C2-2)"
assert_contains "$CALL" "$(cat "$BA")" "req-001: build-assessment calls run-mode.mjs (P5 C2-2)"
VIS=$(section "## Visibility" "$STD")
assert_contains "$CALL" "$(grep 'Run mode source' <<< "$VIS")" "req-001: Visibility run-mode source names run-mode.mjs (P5 C2-2)"

echo ""
echo "=== req-001: only the orchestrator writes run-mode records (P5 C2-2) ==="

EXC=$(section "## Exception list" "$STD")
WRITER=$(grep 'Only the orchestrator writes' <<< "$EXC")
assert_contains "\`plan/.run-mode\`" "$WRITER" "req-001: standing rule names plan/.run-mode (P5 C2-2)"
assert_contains "\`Run mode\` row" "$WRITER" "req-001: standing rule names the build-log Run mode row (P5 C2-2)"
assert_contains "\`Run mode confirmed:\`" "$WRITER" "req-001: standing rule names the confirmation line (P5 C2-2)"
SKEL_COUNT=$(grep -c 'Never write `plan/.run-mode`, the build-log `Run mode` row, or a `Run mode confirmed:` line' "$DISPATCH")
assert_equals "yes" "$([ "$SKEL_COUNT" -ge 1 ] && echo yes || echo no)" "req-001: dispatch skeleton prompt forbids run-mode writes (P5 C2-2)"

print_summary
