#!/usr/bin/env bash
# Tests for feature 0000033-human-on-the-loop-run-mode.
#
# req-012: a new scripts/archive-current.mjs archives plan/current/ with one
#          git mv or rename per item. It removes four sentinels by explicit
#          path, never deletes by glob, and resumes into the same archive
#          directory after a stop. The ship skill's P7 Step 6 calls it, and
#          the orchestrator's Resume Detection step 2a resumes a stopped
#          archive at P7 Step 6.
#
# REGRESSION-CANDIDATE: covers the P7 archive script and its resume rule, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
ARCHIVE="$FRAMEWORK/scripts/archive-current.mjs"
SHIP="$FRAMEWORK/skills/ravintio-ship-agent/SKILL.md"
ORCH="$FRAMEWORK/skills/ravintio-orchestrator/SKILL.md"

ID="0000099-sample-feature"
DATE="2026-10-19"

SCRATCH=$(mktemp -d -t ravintio_0000033_req012_XXXXXX)
trap 'rm -rf "$SCRATCH"' EXIT

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

# yes_if <label> <command...>: passes when the command exits zero.
yes_if() {
  local label="$1"; shift
  assert_equals "yes" "$("$@" >/dev/null 2>&1 && echo yes || echo no)" "$label"
}

# make_repo <dir>: a git repo with tracked and untracked plan/current/ items.
make_repo() {
  local r="$1"
  mkdir -p "$r"
  git -C "$r" init -q
  git -C "$r" config user.email test@example.com
  git -C "$r" config user.name test
  git -C "$r" config commit.gpgsign false
  mkdir -p "$r/plan/current/requirements" "$r/plan/current/adr" "$r/plan/current/capability-skills/x"
  echo "design" > "$r/plan/current/design.md"
  echo "req" > "$r/plan/current/requirements/req-001.md"
  echo "adr" > "$r/plan/current/adr/ADR-001.md"
  echo "plan" > "$r/plan/current/execution-plan.md"
  echo "skill" > "$r/plan/current/capability-skills/x/SKILL.md"
  echo "$ID" > "$r/plan/current/.feature-id"
  echo "P5 skipped" > "$r/plan/current/.skips"
  echo "$ID" > "$r/plan/.orchestrator-active"
  git -C "$r" add -A
  git -C "$r" commit -q -m init
  # Untracked items, written after the commit.
  echo "log" > "$r/plan/current/build-log.md"
  echo "session" > "$r/plan/current/.ravintio-session"
  echo "new" > "$r/plan/current/requirements/req-002.md"
}

run_archive() {
  local r="$1"; shift
  node "$ARCHIVE" --root "$r" "$@" 2>&1
}

echo "=== req-012: full archive in a fixture repo ==="

R1="$SCRATCH/r1"
make_repo "$R1"
OUT1=$(run_archive "$R1" --feature-id "$ID" --date "$DATE")
EXIT1=$?
A1="$R1/plan/_archive/$ID-$DATE"
assert_exit_zero "$EXIT1" "req-012: the script exits 0 on a complete archive"
assert_contains "archive-dir: plan/_archive/$ID-$DATE" "$(tail -1 <<< "$OUT1")" \
  "req-012: the last output line names the archive directory"
for f in design.md execution-plan.md requirements/req-001.md requirements/req-002.md adr/ADR-001.md build-log.md; do
  yes_if "req-012: archive holds $f" test -f "$A1/$f"
done
assert_contains "moved: plan/current/design.md -> plan/_archive/$ID-$DATE/design.md" "$OUT1" \
  "req-012: output prints a moved line per item"
assert_contains "removed: plan/current/.skips" "$OUT1" "req-012: output prints a removed line per sentinel"

PORC1=$(git -C "$R1" status --porcelain)
assert_contains "R  plan/current/design.md -> plan/_archive/$ID-$DATE/design.md" "$PORC1" \
  "req-012: git status shows the tracked design.md as a rename"
assert_contains "R  plan/current/adr/ADR-001.md -> plan/_archive/$ID-$DATE/adr/ADR-001.md" "$PORC1" \
  "req-012: git status shows the tracked ADR as a rename"
assert_contains "A  plan/_archive/$ID-$DATE/build-log.md" "$PORC1" \
  "req-012: the untracked build log is renamed and staged"
assert_contains "A  plan/_archive/$ID-$DATE/requirements/req-002.md" "$PORC1" \
  "req-012: an untracked file inside a tracked directory is staged"
DELETED=$(grep '^D ' <<< "$PORC1" | sed 's/^D  //' | LC_ALL=C sort | tr '\n' ' ')
assert_equals "plan/current/.feature-id plan/current/.skips plan/current/capability-skills/x/SKILL.md " "$DELETED" \
  "req-012: the only deletions are the explicit-path sentinels"
assert_equals "" "$(grep -v '^[RAD] ' <<< "$PORC1")" "req-012: nothing is left unstaged or untracked"

yes_if "req-012: plan/current/ still exists" test -d "$R1/plan/current"
assert_equals "" "$(ls -A "$R1/plan/current")" "req-012: plan/current/ is empty"
yes_if "req-012: git add plan/current/ exits 0 after the archive" git -C "$R1" add plan/current/

for s in .skips .ravintio-session .feature-id capability-skills .archive-target; do
  yes_if "req-012: $s is gone from plan/current/" test ! -e "$R1/plan/current/$s"
  yes_if "req-012: $s is not in the archive" test ! -e "$A1/$s"
done
assert_equals "$ID" "$(cat "$R1/plan/.orchestrator-active")" "req-012: plan/.orchestrator-active is untouched"
assert_equals "" "$(git -C "$R1" status --porcelain -- plan/.orchestrator-active)" \
  "req-012: git sees no change to plan/.orchestrator-active"

echo ""
echo "=== req-012: an existing archive directory gets a -2 suffix ==="

R2="$SCRATCH/r2"
make_repo "$R2"
mkdir -p "$R2/plan/_archive/$ID-$DATE"
echo "old" > "$R2/plan/_archive/$ID-$DATE/design.md"
OUT2=$(run_archive "$R2" --feature-id "$ID" --date "$DATE")
assert_exit_zero "$?" "req-012: the script exits 0 with a -2 suffix"
assert_contains "archive-dir: plan/_archive/$ID-$DATE-2" "$(tail -1 <<< "$OUT2")" "req-012: the script picks -2"
assert_equals "old" "$(cat "$R2/plan/_archive/$ID-$DATE/design.md")" "req-012: the existing archive stays untouched"

echo ""
echo "=== req-012: resume after a forced stop half-way ==="

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    # Node finds git.exe on Windows, never the extensionless git shim, so the third git mv is never forced to fail.
    echo "  SKIP (windows): the extensionless git shim is not found by Node on Windows, so the forced stop cannot be built"
    ;;
  *)
R3="$SCRATCH/r3"
make_repo "$R3"
SHIM="$SCRATCH/shim"
mkdir -p "$SHIM"
REAL_GIT="$(command -v git)"
COUNT="$SCRATCH/mv-count"
echo 0 > "$COUNT"
cat > "$SHIM/git" <<EOF
#!/usr/bin/env bash
# Fails the third git mv, to force a stop half-way through the archive.
for a in "\$@"; do
  if [ "\$a" = "mv" ]; then
    n=\$(( \$(cat "$COUNT") + 1 )); echo "\$n" > "$COUNT"
    if [ "\$n" -eq 3 ]; then echo "forced stop" >&2; exit 1; fi
    break
  fi
done
exec "$REAL_GIT" "\$@"
EOF
chmod +x "$SHIM/git"
OUT3A=$(PATH="$SHIM:$PATH" run_archive "$R3" --feature-id "$ID" --date "$DATE")
EXIT3A=$?
assert_equals "yes" "$([ "$EXIT3A" -ne 0 ] && echo yes || echo no)" "req-012: the forced stop exits non-zero"
assert_contains "forced stop" "$OUT3A" "req-012: the failed git command's message reaches stderr"
yes_if "req-012: the stopped run leaves .archive-target in place" test -f "$R3/plan/current/.archive-target"
MOVED_A=$(grep -c '^moved: ' <<< "$OUT3A")
OUT3B=$(run_archive "$R3" --feature-id "$ID" --date "$DATE")
assert_exit_zero "$?" "req-012: the rerun exits 0"
assert_equals "$MOVED_A" "$(grep -c '^skipped: .*(already archived)$' <<< "$OUT3B")" \
  "req-012: the rerun prints skipped for each item the first run moved"
assert_contains "archive-dir: plan/_archive/$ID-$DATE" "$(tail -1 <<< "$OUT3B")" \
  "req-012: the rerun finishes into the same directory"
yes_if "req-012: the rerun creates no -2 directory" test ! -e "$R3/plan/_archive/$ID-$DATE-2"
assert_equals "" "$(ls -A "$R3/plan/current")" "req-012: plan/current/ is empty after the rerun"
for f in design.md execution-plan.md requirements/req-002.md adr/ADR-001.md build-log.md; do
  yes_if "req-012: resumed archive holds $f" test -f "$R3/plan/_archive/$ID-$DATE/$f"
done
    ;;
esac

echo ""
echo "=== req-012: a conflict exits 3 and changes nothing ==="

R4="$SCRATCH/r4"
make_repo "$R4"
mkdir -p "$R4/plan/_archive/$ID-$DATE"
echo "other" > "$R4/plan/_archive/$ID-$DATE/design.md"
printf 'plan/_archive/%s-%s\n' "$ID" "$DATE" > "$R4/plan/current/.archive-target"
BEFORE4="$(git -C "$R4" status --porcelain)|$(cd "$R4" && find plan | sort)"
OUT4=$(run_archive "$R4" --feature-id "$ID" --date "$DATE")
assert_equals "3" "$?" "req-012: a source and target both present exits 3"
assert_contains "design.md" "$OUT4" "req-012: the conflict names the entry"
AFTER4="$(git -C "$R4" status --porcelain)|$(cd "$R4" && find plan | sort)"
assert_equals "$BEFORE4" "$AFTER4" "req-012: a conflict changes nothing"

echo ""
echo "=== req-012: invalid input exits 2 ==="

R5="$SCRATCH/r5"
make_repo "$R5"
BEFORE5="$(cd "$R5" && find plan | sort)"
run_archive "$R5" --feature-id "Bad ID; rm" --date "$DATE" >/dev/null
assert_equals "2" "$?" "req-012: an invalid feature ID exits 2"
run_archive "$R5" --feature-id "$ID" --date "19-10-2026" >/dev/null
assert_equals "2" "$?" "req-012: an invalid date exits 2"
run_archive "$R5" --feature-id "0000099-$(printf 'a%.0s' $(seq 1 130))" --date "$DATE" >/dev/null
assert_equals "2" "$?" "req-012: a feature ID over 120 characters exits 2"
printf '../outside/%s-%s\n' "$ID" "$DATE" > "$R5/plan/current/.archive-target"
run_archive "$R5" --feature-id "$ID" --date "$DATE" >/dev/null
assert_equals "2" "$?" "req-012: an .archive-target outside plan/_archive/ exits 2"
printf 'plan/_archive/other-name\n' > "$R5/plan/current/.archive-target"
run_archive "$R5" --feature-id "$ID" --date "$DATE" >/dev/null
assert_equals "2" "$?" "req-012: an .archive-target that doesn't match the feature ID exits 2"
rm -f "$R5/plan/current/.archive-target"
assert_equals "$BEFORE5" "$(cd "$R5" && find plan | sort)" "req-012: invalid input moves nothing"

echo ""
echo "=== req-012: symlinks and hostile names (security review) ==="

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    # Git Bash ln -s copies the target instead of linking it, so no symlink fixture can be built.
    echo "  SKIP (windows): ln -s makes a copy under Git Bash, so the symlink cases cannot be built"
    ;;
  *)
# Finding 1: a symlinked archive directory named in .archive-target.
R6="$SCRATCH/r6"
make_repo "$R6"
mkdir -p "$R6/src/comp" "$R6/plan/_archive"
echo keep > "$R6/src/comp/keep"
ln -s ../../src/comp "$R6/plan/_archive/$ID-$DATE"
printf 'plan/_archive/%s-%s\n' "$ID" "$DATE" > "$R6/plan/current/.archive-target"
run_archive "$R6" --feature-id "$ID" --date "$DATE" >/dev/null
assert_equals "2" "$?" "req-012: a symlinked archive target directory exits 2"
assert_equals "keep" "$(ls -A "$R6/src/comp" | tr '\n' ' ' | sed 's/ $//')" \
  "req-012: a symlinked archive target moves nothing into its link target"
yes_if "req-012: a symlinked archive target leaves plan/current/ in place" test -f "$R6/plan/current/design.md"

# Finding 1: plan/_archive itself is a symlink, and the script picks the target.
R6B="$SCRATCH/r6b"
make_repo "$R6B"
mkdir -p "$R6B/src/comp"
echo keep > "$R6B/src/comp/keep"
ln -s ../src/comp "$R6B/plan/_archive"
run_archive "$R6B" --feature-id "$ID" --date "$DATE" >/dev/null
assert_equals "2" "$?" "req-012: a symlinked plan/_archive exits 2"
assert_equals "keep" "$(ls -A "$R6B/src/comp" | tr '\n' ' ' | sed 's/ $//')" \
  "req-012: a symlinked plan/_archive moves nothing into its link target"

# Finding 2: plan/current is a symlink into src/.
R7="$SCRATCH/r7"
make_repo "$R7"
mkdir -p "$R7/src/comp/capability-skills"
echo id > "$R7/src/comp/.feature-id"
echo skill > "$R7/src/comp/capability-skills/SKILL.md"
rm -rf "$R7/plan/current"
ln -s ../src/comp "$R7/plan/current"
run_archive "$R7" --feature-id "$ID" --date "$DATE" >/dev/null
assert_equals "2" "$?" "req-012: a symlinked plan/current exits 2"
yes_if "req-012: a symlinked plan/current deletes no .feature-id behind it" test -f "$R7/src/comp/.feature-id"
yes_if "req-012: a symlinked plan/current deletes no capability-skills/ behind it" \
  test -f "$R7/src/comp/capability-skills/SKILL.md"

# Finding 3: a dangling symlink at .archive-target.
R8="$SCRATCH/r8"
make_repo "$R8"
mkdir -p "$R8/src"
ln -s ../../src/planted "$R8/plan/current/.archive-target"
run_archive "$R8" --feature-id "$ID" --date "$DATE" >/dev/null
assert_equals "2" "$?" "req-012: a dangling symlink at .archive-target exits 2"
yes_if "req-012: a dangling .archive-target symlink creates no file behind it" test ! -e "$R8/src/planted"
    ;;
esac

# Finding 4: .archive-target values never reach error output.
R9="$SCRATCH/r9"
make_repo "$R9"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) ;;
  *)
echo "SECRET-TOKEN-0000" > "$SCRATCH/secret.txt"
ln -s "$SCRATCH/secret.txt" "$R9/plan/current/.archive-target"
OUT9=$(run_archive "$R9" --feature-id "$ID" --date "$DATE")
assert_equals "2" "$?" "req-012: a symlinked .archive-target exits 2"
lacks "SECRET-TOKEN" "$OUT9" "req-012: a symlinked .archive-target prints none of its link target"
rm -f "$R9/plan/current/.archive-target"
    ;;
esac
printf 'plan/_archive/LEAKED-VALUE\n' > "$R9/plan/current/.archive-target"
OUT9B=$(run_archive "$R9" --feature-id "$ID" --date "$DATE")
assert_equals "2" "$?" "req-012: an invalid regular .archive-target exits 2"
lacks "LEAKED-VALUE" "$OUT9B" "req-012: an invalid .archive-target value never reaches the error"

# Finding 7: an entry named * is a literal path, not a git pathspec glob.
R10="$SCRATCH/r10"
make_repo "$R10"
echo star > "$R10/plan/current/*"
OUT10=$(run_archive "$R10" --feature-id "$ID" --date "$DATE")
assert_exit_zero "$?" "req-012: an entry named * archives with exit 0"
A10="$R10/plan/_archive/$ID-$DATE"
assert_equals "star" "$(cat "$A10/*" 2>/dev/null)" "req-012: an entry named * lands in the archive"
yes_if "req-012: an entry named * leaves design.md in the archive" test -f "$A10/design.md"
assert_equals "" "$(git -C "$R10" status --porcelain | grep -v '^[RAD] ')" \
  "req-012: an entry named * leaves nothing unstaged"
PORC10=$(git -C "$R10" status --porcelain)
assert_contains "R  plan/current/design.md -> plan/_archive/$ID-$DATE/design.md" "$PORC10" \
  "req-012: an entry named * keeps design.md a rename"

# Finding 8: control characters in entry names can't forge output lines.
R11="$SCRATCH/r11"
make_repo "$R11"
echo x > "$R11/plan/current/"$'evil\nmoved: forged'
echo x > "$R11/plan/current/"$'esc\e[31mred'
OUT11=$(run_archive "$R11" --feature-id "$ID" --date "$DATE")
assert_exit_zero "$?" "req-012: entries with control characters archive with exit 0"
assert_equals "0" "$(grep -c '^moved: forged' <<< "$OUT11")" \
  "req-012: a newline in an entry name forges no output line"
lacks $'\e' "$OUT11" "req-012: an ANSI escape in an entry name never reaches output"

echo ""
echo "=== req-012: script source never deletes by glob ==="

SRC=$(cat "$ARCHIVE" 2>/dev/null)
assert_equals "yes" "$([ -n "$SRC" ] && echo yes || echo no)" "req-012: archive-current.mjs exists"
lacks "rm -rf" "$SRC" "req-012: the script has no rm -rf"
lacks "shell: true" "$SRC" "req-012: the script has no shell: true"
assert_equals "0" "$(grep -E 'rmSync|unlinkSync|"rm"' <<< "$SRC" | grep -c -F '*')" \
  "req-012: no delete call names a * path"
assert_contains "Exit codes" "$SRC" "req-012: the header comment lists exit codes"

echo ""
echo "=== req-012: ship skill P7 Step 6 and later path references ==="

STEP6=$(sed -n '/^### Step 6: Archive plan\/current\//,/^### Step 6b/p' "$SHIP")
assert_contains "archive-current.mjs" "$STEP6" "req-012: Step 6 runs archive-current.mjs"
assert_contains "{archive-dir}" "$STEP6" "req-012: Step 6 records {archive-dir}"
assert_contains "archive-dir:" "$STEP6" "req-012: Step 6 reads the archive-dir: output line"
lacks "Copy-then-delete" "$STEP6" "req-012: Step 6 drops Copy-then-delete"
lacks "Recursively copy" "$STEP6" "req-012: Step 6 drops Recursively copy"
assert_contains "rm -rf plan/current/*" "$STEP6" "req-012: Step 6 names the banned glob-delete fallback"
assert_contains "Cross-reference check" "$STEP6" "req-012: Step 6 keeps its cross-reference check"
P8_P9=$(sed -n '/^## P8: Build Assessment/,$p' "$SHIP")
lacks "plan/_archive/{feature-id}-{YYYY-MM-DD}/" "$P8_P9" \
  "req-012: P8 and P9 no longer rebuild the archive path from the date"
assert_contains "{archive-dir}/build-log.md" "$P8_P9" "req-012: P8 and P9 build-log lines name {archive-dir}"

echo ""
echo "=== req-012: orchestrator Resume Detection step 2a ==="

STEP2A=$(sed -n '/^2a\. /,/^2b\. /p' "$ORCH")
assert_contains ".archive-target" "$STEP2A" "req-012: step 2a checks for .archive-target"
assert_contains "resume at P7 Step 6" "$STEP2A" "req-012: step 2a resumes a stopped archive at P7 Step 6"

print_summary
