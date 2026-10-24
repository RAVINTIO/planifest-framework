#!/usr/bin/env bash
# Tests for feature 0000037-green-ci-before-ship.
#
# req-003 (P5 re-review 2, N-07 and N-08): a held-back file that the archive
#          script moves out of plan/current/ is caught at its archive path by
#          scan-then-commit, and never reaches the P7 or P9 marker commit.
#
# Verified by: integration
# REGRESSION-CANDIDATE: covers scan-then-commit over a real archive run, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$SCRIPT_DIR/.."
SCAN="$FW/scripts/credential-scan.mjs"
ARCHIVE="$FW/scripts/archive-current.mjs"
STD="$FW/standards/autonomous-run-standards.md"
SHIP="$FW/skills/planifest-ship-agent/SKILL.md"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The fixture credential is assembled at run time so this file holds no secret.
SECRET="AKIA""ABCDEFGHIJKLMNOP"

# step <heading-prefix> <file>: prints one heading's block, heading included.
step() {
  awk -v h="$1" 'index($0, h) == 1 { on = 1; print; next } on && /^##+ / { exit } on { print }' "$2"
}

lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

echo "req-003: the standard defines scan-then-commit"
PCS="$(awk 'index($0, "## Pre-commit credential scan") == 1 { on = 1; print; next } on && /^## / { exit } on { print }' "$STD")"
assert_contains "### Scan-then-commit" "$PCS" "req-003: the standard names the procedure"
assert_contains "Stage the commit's paths." "$PCS" "req-003: step 1 stages the paths"
assert_contains "over the index" "$PCS" "req-003: step 2 scans the index"
assert_contains '`{path}:{line} {rule}`' "$PCS" "req-003: step 3 reads the scan output lines"
assert_contains "Then scan again" "$PCS" "req-003: step 3 rescans"
assert_contains "Commit only when the scan exits" "$PCS" "req-003: step 4 commits on exit 0 only"
assert_contains "commit nothing" "$PCS" "req-003: step 5 stops on exit 2"

echo "req-003: each close-out commit cites scan-then-commit"
for h in '### Step 7' '### P8: Clean-tree check' '### P9 marker step' '### Step 10b' '### Step 10c' '### Step 11'; do
  assert_contains "scan-then-commit" "$(step "$h" "$SHIP")" "req-003: $h cites scan-then-commit"
done
STEP7="$(step '### Step 7' "$SHIP")"
lacks "{held-back-path}" "$STEP7" "req-003: Step 7 no longer unstages the old plan/current/ path"

echo "req-003: a real archive run, then scan-then-commit"
R="$WORK/repo"
mkdir -p "$R/plan/current/requirements"
(
  cd "$R" || exit 1
  git init -q
  git config user.email t@example.invalid
  git config user.name t
  git config commit.gpgsign false
  printf 'init\n' >README.md
  git add README.md
  git commit -q -m init
  printf 'design\n' >plan/current/design.md
  printf 'req\n' >plan/current/requirements/req-001.md
  printf 'key=%s\n' "$SECRET" >plan/current/.env.local
)

AOUT="$(cd "$R" && node "$ARCHIVE" --feature-id 0000001-x --date 2026-01-01 --root "$R" 2>&1)"
ARC=$?
assert_equals "0" "$ARC" "req-003: archive-current.mjs exits 0"
ADIR="plan/_archive/0000001-x-2026-01-01"
assert_contains "archive-dir: $ADIR" "$AOUT" "req-003: the script prints the archive directory"
assert_contains "$ADIR/.env.local" "$AOUT" "req-003: the script moved the held-back file"

# Stage (step 1 of scan-then-commit).
(cd "$R" && git add plan/current/ plan/_archive/)

# Scan (step 2).
SOUT="$(cd "$R" && node "$SCAN" 2>&1)"
SRC=$?
assert_equals "1" "$SRC" "req-003: the scan exits 1 over the staged archive"
assert_contains "$ADIR/.env.local:" "$SOUT" "req-003: the scan names the archive path"
lacks "$SECRET" "$SOUT" "req-003: the scan output prints no secret"

# Unstage every named path (step 3). Each line is {path}:{line} {rule}.
while IFS= read -r p; do
  [ -n "$p" ] || continue
  (cd "$R" && git restore --staged -- "$p")
  RRC=$?
  assert_equals "0" "$RRC" "req-003: the unstage of $p succeeds"
done <<<"$(printf '%s\n' "$SOUT" | grep -E '^plan/' | cut -d: -f1 | sort -u)"

# Rescan (step 3, then step 4).
SOUT2="$(cd "$R" && node "$SCAN" 2>&1)"
SRC2=$?
assert_equals "0" "$SRC2" "req-003: the rescan exits 0"

# Commit (step 4).
(cd "$R" && git commit -q -m "plan(p7): archive plan/current" -m "0000001-x")
CRC=$?
assert_equals "0" "$CRC" "req-003: the commit succeeds"
LOG="$(cd "$R" && git log --name-only --format= HEAD)"
assert_contains "$ADIR/design.md" "$LOG" "req-003: the commit holds the clean design file"
assert_contains "$ADIR/requirements/req-001.md" "$LOG" "req-003: the commit holds the clean requirement file"
lacks ".env.local" "$LOG" "req-003: the commit omits the key file"
assert_equals "yes" "$([ -f "$R/$ADIR/.env.local" ] && echo yes || echo no)" "req-003: the key file stays in the working tree"

echo "req-003: the marker step directory add stages the file again and the rescan holds it back"
(cd "$R" && git add -- "$ADIR")
SOUT3="$(cd "$R" && node "$SCAN" 2>&1)"
SRC3=$?
assert_equals "1" "$SRC3" "req-003: a directory add makes the scan exit 1 again"
assert_contains "$ADIR/.env.local:" "$SOUT3" "req-003: the scan names the archive path again"
(cd "$R" && git restore --staged -- "$ADIR/.env.local")
SOUT4="$(cd "$R" && node "$SCAN" 2>&1)"
SRC4=$?
assert_equals "0" "$SRC4" "req-003: the rescan after the unstage exits 0"
(cd "$R" && printf 'log\n' >"$ADIR/build-log.md" && git add -- "$ADIR" && git restore --staged -- "$ADIR/.env.local" && git commit -q -m "plan(p9): clear session markers" -m "0000001-x" -- "$ADIR")
LOG2="$(cd "$R" && git log --name-only --format= HEAD)"
assert_contains "$ADIR/build-log.md" "$LOG2" "req-003: the marker commit holds the clean log"
lacks ".env.local" "$LOG2" "req-003: the marker commit omits the key file"
ALL="$(cd "$R" && git log --name-only --format=)"
lacks ".env.local" "$ALL" "req-003: no commit in the history holds the key file"

print_summary
