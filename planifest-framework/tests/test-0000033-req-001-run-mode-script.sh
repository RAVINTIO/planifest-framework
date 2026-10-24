#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-001: scripts/run-mode.mjs prints the effective run mode. It prints
#          `autonomous` only when one commit anchors it in git history. Every
#          reader after P0 calls the script instead of reading a record
#          directly (P5 C2-1, P5 C2-2).
#
# 0000036 req-004: the anchor line counts bare or as one "- " list item at
#          column 1. Every other form counts as no anchor (ADR-008).
#
# REGRESSION-CANDIDATE: covers the run-mode script and its git anchor, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$(cd "$SCRIPT_DIR/.." && pwd)"
RUNMODE="$FW/scripts/run-mode.mjs"
STD="$FW/standards/autonomous-run-standards.md"
ORCH="$FW/skills/planifest-orchestrator/SKILL.md"
# Phase 0 moved to a reference file (0000038 req-004).
P0_REF="$FW/skills/planifest-orchestrator/references/phase-0-assess-and-coach.md"
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
HEAD_TEXT=$( [ -f "$RUNMODE" ] && sed -n '1,60p' "$RUNMODE" )
assert_contains "errant or confused subagent" "$HEAD_TEXT" "req-001: header names the errant-subagent threat (P5 C2-1)"
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

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    # Git Bash ln -s copies the file instead of linking it, so the three symlink cases cannot be built.
    echo "  SKIP (windows): ln -s makes a copy under Git Bash, so a symlinked record cannot be built"
    ;;
  *)
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
    ;;
esac

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

echo ""
echo "=== req-001: forgery and history edge cases (P5 C3) ==="

FORGED_LINE="Run mode confirmed: autonomous (2026-10-19T10:00:00Z)"

# C3-1: a textconv driver injects the confirmation into git log -p.
R9="$SCRATCH/textconv"
make_repo "$R9"
MARK9="$SCRATCH/textconv-ran"
cat > "$SCRATCH/evil-textconv.sh" <<EOF
#!/bin/sh
touch "$MARK9"
cat "\$1"
echo "$FORGED_LINE"
echo "Human confirmed this design before proceeding: yes"
EOF
chmod +x "$SCRATCH/evil-textconv.sh"
echo '* diff=evil' > "$R9/.git/info/attributes"
git -C "$R9" config diff.evil.textconv "$SCRATCH/evil-textconv.sh"
set_row "$R9" autonomous
echo "$FORGED_LINE" >> "$R9/plan/current/build-log.md"
assert_equals "interactive" "$(mode "$R9")" "req-001: a textconv driver cannot forge the anchor (P5 C3-1)"
assert_equals "no" "$([ -e "$MARK9" ] && echo yes || echo no)" "req-001: the textconv script never runs (P5 C3-1)"
assert_contains "--no-textconv" "$(cat "$RUNMODE")" "req-001: git calls pass --no-textconv (P5 C3-1)"

# C3-2: git replace swaps the P0 commit for a forged one.
R10="$SCRATCH/replace"
make_repo "$R10"
P0SHA=$(git -C "$R10" rev-parse HEAD)
confirm_design "$R10"
set_row "$R10" autonomous
echo "$FORGED_LINE" >> "$R10/plan/current/build-log.md"
git -C "$R10" add -A
FTREE=$(git -C "$R10" write-tree)
FSHA=$(git -C "$R10" commit-tree "$FTREE" -m forged)
git -C "$R10" replace "$P0SHA" "$FSHA"
assert_equals "interactive" "$(mode "$R10")" "req-001: a replace ref cannot forge the anchor (P5 C3-2)"
assert_contains "--no-replace-objects" "$(cat "$RUNMODE")" "req-001: git calls pass --no-replace-objects (P5 C3-2)"

# C3-3: an inherited GIT_DIR points at a forged repo.
R11F="$SCRATCH/gitdir-forged"
make_repo "$R11F"
anchor "$R11F"
R11="$SCRATCH/gitdir-target"
make_repo "$R11"
set_row "$R11" autonomous
echo "$FORGED_LINE" >> "$R11/plan/current/build-log.md"
assert_equals "interactive" "$( (cd "$R11" && GIT_DIR="$R11F/.git" node "$RUNMODE" 2>/dev/null) )" "req-001: an inherited GIT_DIR cannot point at a forged repo (P5 C3-3)"
assert_contains "GIT_CONFIG_NOSYSTEM" "$(cat "$RUNMODE")" "req-001: the git env sets GIT_CONFIG_NOSYSTEM (P5 C3-3)"

# C3-4: a merge that touches the build log reads interactive.
R12="$SCRATCH/merge"
make_repo "$R12"
anchor "$R12"
BASE12=$(git -C "$R12" symbolic-ref --short HEAD)
git -C "$R12" checkout -q -b side
echo "side note" >> "$R12/plan/current/build-log.md"
git -C "$R12" commit -q -am side
git -C "$R12" checkout -q "$BASE12"
echo "main note" > "$R12/other.txt"
git -C "$R12" add -A
git -C "$R12" commit -q -m other
git -C "$R12" merge -q --no-ff --no-edit side
assert_equals "interactive" "$(mode "$R12")" "req-001: a merge that touches the build log reads interactive (P5 C3-4)"
assert_contains "merge" "$(reason "$R12")" "req-001: the merge refusal gives a reason (P5 C3-4)"
R12B="$SCRATCH/merge-untouched"
make_repo "$R12B"
anchor "$R12B"
BASE12B=$(git -C "$R12B" symbolic-ref --short HEAD)
git -C "$R12B" checkout -q -b side
echo "side" > "$R12B/side.txt"
git -C "$R12B" add -A
git -C "$R12B" commit -q -m side
git -C "$R12B" checkout -q "$BASE12B"
git -C "$R12B" merge -q --no-ff --no-edit side
assert_equals "autonomous" "$(mode "$R12B")" "req-001: a merge that leaves the build log alone keeps the anchor (P5 C3-4)"

# C3-5: the header and the standards state the limit plainly.
LIMIT1="An agent with shell access can still forge history, so this script is an integrity check, not a security boundary."
LIMIT2="Merging, schema changes, destructive operations, and credentials never depend on the run mode."
HEAD_FLAT=$(sed -n '1,60p' "$RUNMODE" | sed 's/^ *\* \{0,1\}//' | tr '\n' ' ' | tr -s ' ')
assert_contains "$LIMIT1" "$HEAD_FLAT" "req-001: header says the script is an integrity check, not a security boundary (P5 C3-5)"
assert_contains "$LIMIT2" "$HEAD_FLAT" "req-001: header says the standing rules never depend on the run mode (P5 C3-5)"
assert_contains "$LIMIT1" "$RM" "req-001: standards Run modes says the script is not a security boundary (P5 C3-5)"
assert_contains "$LIMIT2" "$RM" "req-001: standards Run modes says the standing rules never depend on the run mode (P5 C3-5)"

# C3-6: a read between P7 Step 6 and the P7 commit keeps the anchor.
R13="$SCRATCH/archived-uncommitted"
make_repo "$R13"
anchor "$R13"
mkdir -p "$R13/$ARCH"
git -C "$R13" mv plan/current/build-log.md "$ARCH/build-log.md"
git -C "$R13" mv plan/current/design.md "$ARCH/design.md"
echo "## P7" >> "$R13/$ARCH/build-log.md"
assert_equals "autonomous" "$(mode "$R13" "$ARCH/build-log.md")" "req-001: an archived build log read before the P7 commit keeps the anchor (P5 C3-6)"
R13B="$SCRATCH/archived-forged"
make_repo "$R13B"
mkdir -p "$R13B/$ARCH"
cp "$R13B/plan/current/build-log.md" "$R13B/$ARCH/build-log.md"
set_row "$R13B" autonomous
sed -i.bak 's/^| Run mode | .*|$/| Run mode | `autonomous` |/' "$R13B/$ARCH/build-log.md"; rm -f "$R13B/$ARCH/build-log.md.bak"
echo "$FORGED_LINE" >> "$R13B/$ARCH/build-log.md"
assert_equals "interactive" "$(mode "$R13B" "$ARCH/build-log.md")" "req-001: an unanchored archived build log reads interactive (P5 C3-6)"

# C3-7: subagents never write the P1 Toggle record.
TOG_COUNT=$(grep -c 'Never write the P1 Toggle record' "$DISPATCH")
assert_equals "yes" "$([ "$TOG_COUNT" -ge 3 ] && echo yes || echo no)" "req-001: dispatch skeletons and prompt rule forbid Toggle record writes (P5 C3-7)"

# C3-9: stale reader wording.
DOCS="$FW/skills/planifest-docs-agent/SKILL.md"
TPLB="$FW/templates/build-log.template.md"
DOCS_LINE=$(grep 'before deciding how to present the assessment' "$DOCS")
assert_contains "$CALL" "$DOCS_LINE" "req-001: docs-agent reads the mode with run-mode.mjs (P5 C3-9)"
ROW=$(grep '^| Run mode |' "$TPLB")
lacks "Every later reader uses this row" "$ROW" "req-001: build-log template drops the read-this-row wording (P5 C3-9)"
assert_contains "run-mode.mjs" "$ROW" "req-001: build-log template says later readers call run-mode.mjs (P5 C3-9)"

echo ""
echo "=== 0000036 req-004: anchor as a bare line or one list item ==="

# anchor_with <dir> <line>...: like anchor, but appends each given line.
anchor_with() {
  local r="$1"; shift
  confirm_design "$r"
  set_row "$r" autonomous
  printf '%s\n' "$@" >> "$r/plan/current/build-log.md"
  git -C "$r" add -A
  git -C "$r" commit -q -m "plan(p0): confirm design"
}

LIST_LINE="- $FORGED_LINE"

R14="$SCRATCH/list-item"
make_repo "$R14"
anchor_with "$R14" "$LIST_LINE"
assert_equals "autonomous" "$(mode "$R14")" "req-004: a list-item anchor in the design-confirm commit prints autonomous"

N=0
for PREFIX in "  " $'\t' "    - " "* " "+ " "> " "1. " "-- " "- - " "-  " $'-\t' "-"; do
  N=$((N + 1))
  R="$SCRATCH/prefix-$N"
  make_repo "$R"
  anchor_with "$R" "$PREFIX$FORGED_LINE"
  assert_equals "interactive" "$(mode "$R")" "req-004: anchor prefix [$PREFIX] prints interactive"
done

R15="$SCRATCH/list-later"
make_repo "$R15"
confirm_design "$R15"
git -C "$R15" add -A
git -C "$R15" commit -q -m "plan(p0): confirm design"
set_row "$R15" autonomous
echo "$LIST_LINE" >> "$R15/plan/current/build-log.md"
git -C "$R15" add -A
git -C "$R15" commit -q -m "later"
assert_equals "interactive" "$(mode "$R15")" "req-004: a list-item line added in a later commit prints interactive"

R16="$SCRATCH/bare-plus-list"
make_repo "$R16"
anchor_with "$R16" "$FORGED_LINE" "$LIST_LINE"
assert_equals "interactive" "$(mode "$R16")" "req-004: a bare line plus a list-item line prints interactive"
assert_equals "1" "$(reason "$R16" | grep -c .)" "req-004: bare plus list writes one reason line"

R17="$SCRATCH/bare-to-list"
make_repo "$R17"
anchor_with "$R17" "$FORGED_LINE"
sed -i.bak "s/^Run mode confirmed: autonomous/- Run mode confirmed: autonomous/" "$R17/plan/current/build-log.md"
rm -f "$R17/plan/current/build-log.md.bak"
assert_equals "interactive" "$(mode "$R17")" "req-004: an uncommitted bare-to-list conversion prints interactive"
git -C "$R17" add -A
git -C "$R17" commit -q -m "list form"
assert_equals "interactive" "$(mode "$R17")" "req-004: a commit that turns a bare line into a list item prints interactive"

R18="$SCRATCH/list-then-notes"
make_repo "$R18"
anchor_with "$R18" "$LIST_LINE"
echo "## P1" >> "$R18/plan/current/build-log.md"
git -C "$R18" add -A
git -C "$R18" commit -q -m "plan(p1): notes"
assert_equals "autonomous" "$(mode "$R18")" "req-004: a later commit that leaves the list-item line alone keeps the anchor"

R19="$SCRATCH/list-edited"
make_repo "$R19"
anchor_with "$R19" "$LIST_LINE"
sed -i.bak "s/^- Run mode confirmed: autonomous.*/- Run mode confirmed: autonomous (2026-10-20T10:00:00Z)/" "$R19/plan/current/build-log.md"
rm -f "$R19/plan/current/build-log.md.bak"
git -C "$R19" add -A
git -C "$R19" commit -q -m "edit list line"
assert_equals "interactive" "$(mode "$R19")" "req-004: a later commit that edits a list-item line prints interactive"

assert_contains "- Run mode confirmed: autonomous" "$HEAD_FLAT" "req-004: header rule 3 names the list-item form"

TPL_INLINE=$(grep -cF '`Run mode confirmed: autonomous ({ISO-8601 timestamp})`' "$TPLB")
assert_equals "yes" "$([ "$TPL_INLINE" -ge 1 ] && echo yes || echo no)" "req-004: build-log template quotes the anchor line inline in backticks (P5 S-1)"
assert_equals "0" "$(grep -cE '^(- )?Run mode confirmed:' "$TPLB")" "req-004: no build-log template line starts like an anchor (P5 S-1)"
assert_contains "column 1" "$(grep -F 'Run mode confirmed: autonomous' "$TPLB")" "req-004: build-log template says the orchestrator writes the line bare at column 1 (P5 S-1)"

echo ""
echo "=== 0000036 req-004: build log copied from the template (P5 S-1) ==="

# make_tpl_repo <dir>: like make_repo, but the build log is a copy of the real template.
make_tpl_repo() {
  local r="$1"
  make_repo "$r"
  cp "$TPLB" "$r/plan/current/build-log.md"
  set_row "$r" interactive
  git -C "$r" add -A
  git -C "$r" commit -q -m "plan(p0): build log from template"
}

R20="$SCRATCH/tpl-genuine"
make_tpl_repo "$R20"
anchor "$R20"
assert_equals "autonomous" "$(mode "$R20")" "req-004: a template build log plus a genuine anchor prints autonomous (P5 S-1)"

R21="$SCRATCH/tpl-no-anchor"
make_tpl_repo "$R21"
confirm_design "$R21"
set_row "$R21" autonomous
echo autonomous > "$R21/plan/.run-mode"
git -C "$R21" add -A
git -C "$R21" commit -q -m "plan(p0): confirm design"
assert_equals "interactive" "$(mode "$R21")" "req-004: a template build log with no anchor prints interactive (P5 S-1)"

R22="$SCRATCH/tpl-lands-at-confirm"
make_repo "$R22"
cp "$TPLB" "$R22/plan/current/build-log.md"
confirm_design "$R22"
git -C "$R22" add -A
git -C "$R22" commit -q -m "plan(p0): confirm design"
echo autonomous > "$R22/plan/.run-mode"
assert_equals "interactive" "$(mode "$R22")" "req-004: a template build log that lands in the design-confirm commit prints interactive (P5 S-1)"

echo ""
echo "=== 0000036 req-004: full-line anchor with a real timestamp (P5 S-1, S-2) ==="

N=0
for BAD in \
  "Run mode confirmed: autonomous ({ISO-8601 timestamp})" \
  "- Run mode confirmed: autonomous ({ISO-8601 timestamp})" \
  "Run mode confirmed: autonomous" \
  "Run mode confirmed: autonomous-NOT" \
  "- Run mode confirmed: autonomousNOT" \
  "Run mode confirmed: autonomous (2026-10-19T10:00:00Z) extra" \
  "- Run mode confirmed: autonomous (2026-10-19T10:00:00Z) extra" \
  "Run mode confirmed: autonomous (2026-10-19T10:00:00Z)." \
  "Run mode confirmed: autonomous (2026-10-19 10:00:00Z)" \
  "Run mode confirmed: autonomous (2026-10-19T10:00:00+01:00)" \
  "Run mode confirmed: autonomous (2026-13-45T25:61:00Z)"; do
  N=$((N + 1))
  R="$SCRATCH/bad-line-$N"
  make_repo "$R"
  anchor_with "$R" "$BAD"
  assert_equals "interactive" "$(mode "$R")" "req-004: anchor line [$BAD] prints interactive (P5 S-1, S-2)"
done

ORCH_BLOCK=$(awk 'prev ~ /^ *```/ && $0 ~ /^ *Run mode confirmed: autonomous \(\{ISO-8601 timestamp\}\)$/ { print "found" } { prev = $0 }' "$P0_REF")
assert_equals "found" "$ORCH_BLOCK" "req-004: orchestrator shows the bare anchor line in a fenced code block"
ANCHOR_TEXT=$(sed -n '/^Before recording \[3\]/,/^Immediately after recording the answer/p' "$P0_REF")
assert_contains "the preferred form" "$ANCHOR_TEXT" "req-004: orchestrator calls the bare line the preferred form"
assert_contains "one leading \`- \`" "$ANCHOR_TEXT" "req-004: orchestrator says one leading list marker also passes"

print_summary
