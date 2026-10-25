#!/usr/bin/env bash
# Tests for feature 0000039-ravintio-rebrand, req-006: consumer migration (ADR-005).
#
# REGRESSION-CANDIDATE: covers the one-off consumer rename helpers and their backup-never-delete rule, tagged by test-writer for human review at P7
#
# Verified by: integration
#
# The helpers under test are migrate-0.37.0-ravintio-rename.sh and .ps1 in
# ravintio-framework/migrations/. Each case builds a scratch git repo that
# looks like a 0.36.0 consumer and runs the helper from its project root.
#
# Acceptance criteria covered:
#   AC1 clean run                       cases (a) and (a2)
#   AC2 rerun and stop conditions       cases (b) to (g)
#   AC3 link refusals                   cases (h) to (k)
#   AC4 .ps1 parity                     the ps1 pass and case (p)
#   AC5 resume after any single step    case (m)
#   AC6 marker rename (P6 change)       cases (q1) to (q12), and parity (markers)
#
# AC6 messages the helpers must print (shared by .sh and .ps1):
#   step 7, a flags file whose "tool" setup accepts, one line per tool folder:
#     "Next step: run ravintio-framework/setup.sh {tool}{flags}, or setup.ps1
#      with the same arguments, before the next commit."
#     {flags} is " --include-full-skill-library" then " --strict-orchestrator",
#     each only when the file lists it, in that fixed order. No other flag.
#   step 7, no flags file with a tool setup accepts: the generic line
#     "Next step: run ravintio-framework/setup.sh claude-code, or setup.ps1,
#      or the tool this project uses, before the next commit."
#   dropped manifest entry  "WARNING: dropped manifest entry {entry as written}"
#   linked skills folder    "WARNING: {tool}/skills is a symlink", exit 0
#   marker clash            "Stopped at step 2", exit 1, names the new path
#
# Test hook (the implementer adds it to both helpers):
#   RAVINTIO_MIGRATE_STOP_AFTER=N, for N in 1..8. When set, the helper
#   finishes step N, prints "Stopped at step N" plus the files it already
#   moved, and exits 3. It runs no later step. When unset, it has no effect.
#
# Messages the helpers must print (shared by .sh and .ps1):
#   stop of any kind        "Stopped at step N" (N is the step), exit 1
#   rerun with all done     "Nothing to do", exit 0
#   step 7                  "Next step: run ravintio-framework/setup.sh claude-code"
#   step 6 backup           ".ravintio-backup/"
#   step 8                  "RAVINTIO Strict Pipeline" and "validate-branch keeps its name"
#   target appears late     "Stopped at step N", exit 1 (case (n), P5 finding L-001)
#   parent link skip        "WARNING: {folder} is a symlink", exit 0
#
# The old brand word is built from pieces so this file needs no brand-guard
# allowlist entry.
#
# The .ps1 pass runs on pwsh when present. Otherwise it prints SKIP with a
# reason. CI runs both PowerShell legs (Windows PowerShell 5.1 and 7).
# Junction cases need Windows and run in the CI Windows leg only.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FW_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

MIG_DIR="$FW_DIR/migrations"
SH_HELPER="$MIG_DIR/migrate-0.37.0-ravintio-rename.sh"
PS_HELPER="$MIG_DIR/migrate-0.37.0-ravintio-rename.ps1"
OLD="plan""ifest"
OLDU="PLAN""IFEST"
OLDC="Plan""ifest"
OLDPACK="$OLD-framework"
OLDOVR="$OLD-overrides"

WS=$(mktemp -d)
trap 'rm -rf "${WS:?}"' EXIT
# WSR is the real path of WS. On macOS /var is a link to /private/var.
WSR=$(cd "$WS" && pwd -P)

PACK_VARS="SHARD_INDEX SHARD_COUNT REGRESSION_DIR GATE TIER"

# make_repo NAME: scratch 0.36.0 consumer repo with the new pack copied in.
make_repo() {
  local d="$WS/$1" v
  mkdir -p "$d/ravintio-framework/migrations" "$d/$OLDPACK/sub" "$d/$OLDOVR/instructions" \
           "$d/.github/workflows" "$d/.claude/skills"
  echo "m" > "$d/ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.md"
  echo "s" > "$d/ravintio-framework/setup.sh"
  echo "mine" > "$d/$OLDOVR/instructions/a.md"
  echo "x" > "$d/$OLDPACK/file.md"
  echo "x" > "$d/$OLDPACK/setup.sh"
  echo "y" > "$d/$OLDPACK/sub/x.md"
  {
    printf 'name: %s Strict Pipeline\n' "$OLDC"
    printf 'run: bash %s/tests/run-tests.sh\nenv:\n' "$OLDPACK"
    for v in $PACK_VARS; do printf '  %s_%s: 1\n' "$OLDU" "$v"; done
    printf '  %s_GATE_EXTRA: keep\n' "$OLDU"
    printf '  TOKEN: ${{ secrets.%s_MY_SECRET }}\n' "$OLDU"
    printf '  Z: ${{ secrets.%s_NAME }}\n' "$OLDU"
    printf '  V: ${{ vars.%s_TIER }}\n' "$OLDU"
  } > "$d/.github/workflows/$OLD.yml"
  echo "x" > "$d/.claude/.$OLD-setup-flags"
  echo "x" > "$d/.claude/skills/.$OLD-manifest"
  echo "sess" > "$d/.claude/.$OLD-session"
  ( cd "$d" && git init -q . && git config user.email t@example.com && git config user.name t \
    && git add -A && git commit -q -m init )
  echo "$d"
}

# snapshot DIR: paths (links not followed), file contents, git status, exclude file.
snapshot() {
  ( cd "$1" && find . -path ./.git -prune -o -print | LC_ALL=C sort
    find . -path ./.git -prune -o -type f -print | LC_ALL=C sort | while IFS= read -r f; do
      [ -n "$f" ] && { echo "== $f"; cat "$f"; }
    done
    echo "== git status"; git status --porcelain --untracked-files=all 2>&1
    echo "== exclude"; cat .git/info/exclude 2>/dev/null )
}

exists() { [ -e "$1" ] || [ -L "$1" ] && echo yes || echo no; }

# LINKS_OK: yes when ln -s makes a real link here. Git Bash on Windows copies
# the target instead, so the link cases (h) to (k) print SKIP there.
LINKS_OK=no
mkdir -p "$WS/link-probe-target"
if ln -s "$WS/link-probe-target" "$WS/link-probe" 2>/dev/null && [ -L "$WS/link-probe" ]; then
  LINKS_OK=yes
fi

# run_helper DIR [ENV=VAL...]: run the helper for the current KIND from DIR.
# pwsh on Windows ends each line with CRLF, so the ps1 branch drops the CR.
# pipefail keeps the helper's exit code.
run_helper() {
  local d="$1"; shift
  if [ "$KIND" = ps1 ]; then
    ( cd "$d" && env GIT_CEILING_DIRECTORIES="$WS" "$@" pwsh -NoProfile -NonInteractive -File "$PS_HELPER" 2>&1 | tr -d '\r' )
  else
    ( cd "$d" && env GIT_CEILING_DIRECTORIES="$WS" "$@" bash "$SH_HELPER" 2>&1 )
  fi
}

run_suite() {
  KIND="$1"
  local T="[$KIND] req-006"
  local R OUT CODE BEFORE v

  echo "=== $T (a) clean run ==="
  R=$(make_repo "$KIND-clean")
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "0" "$CODE" "$T: clean run exits 0"
  assert_equals "mine" "$(cat "$R/ravintio-overrides/instructions/a.md" 2>/dev/null)" "$T: overrides moved with content"
  assert_equals "no" "$(exists "$R/$OLDOVR")" "$T: old overrides folder gone"
  assert_equals "yes" "$(exists "$R/.github/workflows/ravintio.yml")" "$T: workflow renamed"
  assert_equals "no" "$(exists "$R/.github/workflows/$OLD.yml")" "$T: old workflow gone"
  WF="$(cat "$R/.github/workflows/ravintio.yml" 2>/dev/null)"
  assert_contains "ravintio-framework/tests/run-tests.sh" "$WF" "$T: workflow pack path rewritten"
  for v in $PACK_VARS; do
    assert_equals "1" "$(grep -c "^  RAVINTIO_$v: 1\$" "$R/.github/workflows/ravintio.yml" 2>/dev/null)" "$T: pack variable $v rewritten"
  done
  assert_contains "secrets.${OLDU}_MY_SECRET" "$WF" "$T: consumer secret keeps its name"
  assert_contains "${OLDU}_GATE_EXTRA: keep" "$WF" "$T: a longer name that only starts with a pack name is left alone"
  assert_contains "secrets.${OLDU}_NAME }}" "$WF" "$T: a secret that shares a pack name keeps its name (M-001)"
  assert_contains "vars.${OLDU}_TIER }}" "$WF" "$T: a variable that shares a pack name keeps its name (M-001)"
  assert_equals "4" "$(grep -c "${OLDU}_" "$R/.github/workflows/ravintio.yml" 2>/dev/null)" "$T: only the four consumer names keep the old prefix"
  assert_equals "name: RAVINTIO Strict Pipeline" "$(head -n 1 "$R/.github/workflows/ravintio.yml" 2>/dev/null)" "$T: the workflow name line is rewritten (M-002)"
  assert_equals "0" "$(grep -c "$OLDC Strict Pipeline" "$R/.github/workflows/ravintio.yml" 2>/dev/null)" "$T: the old workflow name is gone (M-002)"
  assert_equals "no" "$(exists "$R/.claude/.$OLD-session")" "$T: session marker removed"
  # P6 change (AC6): step 5 now renames the markers instead of leaving them for setup.
  assert_equals "no" "$(exists "$R/.claude/.$OLD-setup-flags")" "$T: old setup flags renamed (AC6)"
  assert_equals "x" "$(cat "$R/.claude/.ravintio-setup-flags" 2>/dev/null)" "$T: setup flags renamed with content unchanged (AC6)"
  assert_equals "no" "$(exists "$R/.claude/skills/.$OLD-manifest")" "$T: old manifest renamed (AC6)"
  assert_equals "yes" "$(exists "$R/.claude/skills/.ravintio-manifest")" "$T: manifest renamed (AC6)"
  assert_equals "no" "$(exists "$R/$OLDPACK")" "$T: old pack gone from the root"
  assert_equals "x" "$(cat "$R/.ravintio-backup/$OLDPACK/file.md" 2>/dev/null)" "$T: old pack moved to the backup"
  assert_equals "y" "$(cat "$R/.ravintio-backup/$OLDPACK/sub/x.md" 2>/dev/null)" "$T: nested backup content kept"
  assert_equals "yes" "$(exists "$R/ravintio-framework/setup.sh")" "$T: new pack kept"
  assert_equals "0" "$(cd "$R" && git ls-files -- "$OLDPACK" | grep -c .)" "$T: git stops tracking the old pack"
  assert_equals "1" "$(grep -cx '.ravintio-backup/' "$R/.git/info/exclude" 2>/dev/null)" "$T: backup added once to .git/info/exclude"
  assert_contains "Next step: run ravintio-framework/setup.sh claude-code" "$OUT" "$T: prints the setup command"
  assert_contains ".ravintio-backup/" "$OUT" "$T: names the backup folder"
  assert_contains "git clean -x deletes it" "$OUT" "$T: warns that git clean -x deletes the backup (L-006)"
  assert_contains "RAVINTIO Strict Pipeline" "$OUT" "$T: prints the branch protection warning"
  assert_contains "The required check validate-branch keeps its name" "$OUT" "$T: the warning names the unchanged job check (M-002)"
  assert_contains "needs no change" "$OUT" "$T: the warning says a validate-branch rule needs no change (M-002)"

  echo "=== $T (b) rerun changes nothing ==="
  BEFORE=$(snapshot "$R")
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "0" "$CODE" "$T: rerun exits 0"
  assert_equals "$BEFORE" "$(snapshot "$R")" "$T: rerun changes nothing"
  assert_contains "Nothing to do" "$OUT" "$T: rerun says nothing to do"
  assert_equals "1" "$(grep -cx '.ravintio-backup/' "$R/.git/info/exclude" 2>/dev/null)" "$T: rerun adds no second exclude line"

  echo "=== $T (c) no ravintio-framework/ stops at step 1 ==="
  R=$(make_repo "$KIND-nopack")
  rm -rf "${R:?}/ravintio-framework"
  BEFORE=$(snapshot "$R")
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "1" "$CODE" "$T: missing new pack exits 1"
  assert_contains "Stopped at step 1" "$OUT" "$T: names step 1"
  assert_contains "ravintio-framework/" "$OUT" "$T: names the missing folder"
  assert_equals "$BEFORE" "$(snapshot "$R")" "$T: missing new pack moves nothing"

  echo "=== $T (d) both override folders stop before any move ==="
  R=$(make_repo "$KIND-both")
  mkdir -p "$R/ravintio-overrides"
  BEFORE=$(snapshot "$R")
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "1" "$CODE" "$T: both override folders exit 1"
  assert_contains "Stopped at step 2" "$OUT" "$T: names step 2"
  assert_equals "$BEFORE" "$(snapshot "$R")" "$T: both override folders move nothing"

  echo "=== $T (e) ravintio.yml beside the old workflow stops ==="
  R=$(make_repo "$KIND-wf")
  echo "new" > "$R/.github/workflows/ravintio.yml"
  BEFORE=$(snapshot "$R")
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "1" "$CODE" "$T: existing ravintio.yml exits 1"
  assert_contains "Stopped at step 2" "$OUT" "$T: names step 2"
  assert_equals "$BEFORE" "$(snapshot "$R")" "$T: existing ravintio.yml moves nothing"

  echo "=== $T (f) backup beside an old pack still in place stops ==="
  R=$(make_repo "$KIND-backup")
  mkdir -p "$R/.ravintio-backup/$OLDPACK"
  echo "older" > "$R/.ravintio-backup/$OLDPACK/old.md"
  BEFORE=$(snapshot "$R")
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "1" "$CODE" "$T: backup plus old pack exits 1"
  assert_contains "Stopped at step 2" "$OUT" "$T: names step 2"
  assert_equals "$BEFORE" "$(snapshot "$R")" "$T: backup plus old pack moves nothing"

  echo "=== $T (g) staged pack edit stops, staged deletion does not ==="
  R=$(make_repo "$KIND-staged-edit")
  echo "edited" >> "$R/$OLDPACK/file.md"
  ( cd "$R" && git add "$OLDPACK/file.md" )
  BEFORE=$(snapshot "$R")
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "1" "$CODE" "$T: staged pack edit exits 1"
  assert_contains "Stopped at step 2" "$OUT" "$T: names step 2"
  assert_equals "$BEFORE" "$(snapshot "$R")" "$T: staged pack edit moves nothing"
  R=$(make_repo "$KIND-staged-del")
  ( cd "$R" && git rm -q --cached "$OLDPACK/sub/x.md" )
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "0" "$CODE" "$T: staged pack deletion does not stop the run"
  assert_equals "yes" "$(exists "$R/.ravintio-backup/$OLDPACK/file.md")" "$T: staged deletion run still backs up the pack"

  echo "=== $T (g2) an old pack held as a git submodule stops at step 2 (L-007) ==="
  R=$(make_repo "$KIND-submodule")
  ( cd "$R" && git rm -r -q --cached "$OLDPACK" \
    && git update-index --add --cacheinfo "160000,$(git rev-parse HEAD),$OLDPACK" && git commit -q -m sub )
  BEFORE=$(snapshot "$R")
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "1" "$CODE" "$T: a submodule pack exits 1"
  assert_contains "Stopped at step 2" "$OUT" "$T: a submodule pack names step 2"
  assert_contains "git submodule deinit" "$OUT" "$T: a submodule pack names the fix"
  assert_equals "$BEFORE" "$(snapshot "$R")" "$T: a submodule pack moves nothing"

  local name wf kind TARGET OUTSIDE parent REAL REAL_BEFORE
  if [ "$LINKS_OK" != yes ]; then
    echo "  SKIP: $T (h) to (k): ln -s makes no real link on this platform (Git Bash on Windows copies the target)"
  else
  echo "=== $T (h) link refusals leave link and target alone ==="
  for name in "$OLDPACK" "$OLDOVR" "ravintio-overrides" ".ravintio-backup"; do
    R=$(make_repo "$KIND-link-$name")
    TARGET="$WS/target-$KIND-$name"
    mkdir -p "$TARGET"; echo "keep" > "$TARGET/keep.txt"
    if [ -e "$R/$name" ]; then rm -rf "${R:?}/${name:?}"; fi
    ln -s "$TARGET" "$R/$name"
    BEFORE=$(snapshot "$R")
    OUT=$(run_helper "$R"); CODE=$?
    assert_equals "1" "$CODE" "$T: link at $name exits 1"
    assert_contains "Stopped at step 2" "$OUT" "$T: link at $name names step 2"
    assert_equals "$BEFORE" "$(snapshot "$R")" "$T: link at $name moves nothing"
    assert_equals "yes" "$([ -L "$R/$name" ] && echo yes || echo no)" "$T: $name still a link"
    assert_equals "keep" "$(cat "$TARGET/keep.txt")" "$T: target of $name untouched"
  done
  for wf in "$OLD.yml" "ravintio.yml"; do
    for kind in live dangling; do
      R=$(make_repo "$KIND-wflink-$wf-$kind")
      TARGET="$WS/wftarget-$KIND-$wf-$kind.yml"
      if [ "$kind" = live ]; then printf 'keep %s/ x\n' "$OLDPACK" > "$TARGET"; fi
      rm -f "$R/.github/workflows/$wf"
      ln -s "$TARGET" "$R/.github/workflows/$wf"
      BEFORE=$(snapshot "$R")
      OUT=$(run_helper "$R"); CODE=$?
      assert_equals "1" "$CODE" "$T: $kind link at $wf exits 1"
      assert_contains "Stopped at step 2" "$OUT" "$T: $kind link at $wf names step 2"
      assert_equals "$BEFORE" "$(snapshot "$R")" "$T: $kind link at $wf moves nothing"
      if [ "$kind" = live ]; then
        assert_equals "keep $OLDPACK/ x" "$(cat "$TARGET")" "$T: target of $wf untouched"
      fi
    done
  done

  echo "=== $T (i) a nested link in the old pack moves as a link ==="
  R=$(make_repo "$KIND-nested")
  OUTSIDE="$WS/outside-$KIND"
  mkdir -p "$OUTSIDE"; echo "keep" > "$OUTSIDE/keep.txt"
  ln -s "$OUTSIDE" "$R/$OLDPACK/nested"
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "0" "$CODE" "$T: nested link run exits 0"
  assert_equals "yes" "$([ -L "$R/.ravintio-backup/$OLDPACK/nested" ] && echo yes || echo no)" "$T: nested link still a link in the backup"
  assert_equals "keep" "$(cat "$OUTSIDE/keep.txt" 2>/dev/null)" "$T: file behind the nested link survives"

  echo "=== $T (j) a linked parent folder skips only the step that writes through it ==="
  for parent in ".github" ".github/workflows" ".claude" ".claude/skills"; do
    R=$(make_repo "$KIND-parent-${parent//\//-}")
    REAL="$WS/real-$KIND-${parent//\//-}"
    mv "$R/$parent" "$REAL"
    ln -s "$REAL" "$R/$parent"
    REAL_BEFORE=$(snapshot "$REAL")
    OUT=$(run_helper "$R"); CODE=$?
    assert_equals "0" "$CODE" "$T: linked $parent exits 0"
    assert_contains "WARNING: $parent is a symlink" "$OUT" "$T: linked $parent is named in a warning"
    assert_equals "$REAL_BEFORE" "$(snapshot "$REAL")" "$T: target of linked $parent untouched"
    assert_equals "yes" "$(exists "$R/.ravintio-backup/$OLDPACK/file.md")" "$T: linked $parent still moves the old pack"
    assert_equals "mine" "$(cat "$R/ravintio-overrides/instructions/a.md" 2>/dev/null)" "$T: linked $parent still moves the overrides"
  done

  echo "=== $T (k) a linked .git/info/exclude is skipped with a warning ==="
  R=$(make_repo "$KIND-exclude-link")
  echo "keep" > "$WS/exclude-target-$KIND"
  rm -f "$R/.git/info/exclude"
  ln -s "$WS/exclude-target-$KIND" "$R/.git/info/exclude"
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "0" "$CODE" "$T: linked exclude file exits 0"
  assert_contains "WARNING:" "$OUT" "$T: linked exclude file warns"
  assert_equals "keep" "$(cat "$WS/exclude-target-$KIND")" "$T: exclude target untouched"
  assert_equals "yes" "$(exists "$R/.ravintio-backup/$OLDPACK/file.md")" "$T: linked exclude file still backs up the pack"
  fi

  echo "=== $T (l) a project below its git top level migrates ==="
  R=$(make_repo "$KIND-inner")
  rm -rf "${R:?}/.git"
  mkdir -p "$WS/outer-$KIND"
  mv "$R" "$WS/outer-$KIND/inner"
  ( cd "$WS/outer-$KIND" && git init -q . && git config user.email t@example.com && git config user.name t \
    && git add -A && git commit -q -m init )
  R="$WS/outer-$KIND/inner"
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "0" "$CODE" "$T: run below the top level exits 0"
  assert_equals "yes" "$(exists "$R/.ravintio-backup/$OLDPACK/setup.sh")" "$T: nested project pack moved to the backup"
  assert_equals "1" "$(grep -cx '.ravintio-backup/' "$WS/outer-$KIND/.git/info/exclude" 2>/dev/null)" "$T: backup excluded in the outer repo"
  assert_contains "secrets.${OLDU}_MY_SECRET" "$(cat "$R/.github/workflows/ravintio.yml" 2>/dev/null)" "$T: nested project keeps the consumer secret name"

  echo "=== $T (n) a target that appears after step 2 stops the move (L-001) ==="
  # A git shim plants the target when the helper asks git whether it tracks
  # the source, which happens after step 2 and before the move.
  case "$KIND-$(uname -s)" in
    ps1-MINGW*|ps1-MSYS*|ps1-CYGWIN*)
      echo "  SKIP (windows): $T (n): pwsh on Windows can't run the bash git shim"
      ;;
    *)
      local SHIM REAL_GIT
      SHIM="$WS/shim-$KIND"
      REAL_GIT="$(command -v git)"
      mkdir -p "$SHIM"
      {
        printf '#!/usr/bin/env bash\n'
        printf 'if [ "$1" = ls-files ] && [ "$3" = "$PLANT_ON" ]; then mkdir -p "$PLANT_DIR"; fi\n'
        printf 'exec "%s" "$@"\n' "$REAL_GIT"
      } > "$SHIM/git"
      chmod +x "$SHIM/git"
      R=$(make_repo "$KIND-late-3")
      OUT=$(run_helper "$R" "PATH=$SHIM:$PATH" "PLANT_ON=$OLDOVR" "PLANT_DIR=$R/ravintio-overrides"); CODE=$?
      assert_equals "1" "$CODE" "$T: a late overrides target exits 1"
      assert_contains "Stopped at step 3" "$OUT" "$T: a late overrides target names step 3"
      assert_equals "mine" "$(cat "$R/$OLDOVR/instructions/a.md" 2>/dev/null)" "$T: a late overrides target leaves the old overrides in place"
      assert_equals "no" "$(exists "$R/ravintio-overrides/$OLDOVR")" "$T: a late overrides target gets nothing moved into it"
      R=$(make_repo "$KIND-late-6")
      OUT=$(run_helper "$R" "PATH=$SHIM:$PATH" "PLANT_ON=$OLDPACK" "PLANT_DIR=$R/.ravintio-backup/$OLDPACK"); CODE=$?
      assert_equals "1" "$CODE" "$T: a late backup target exits 1"
      assert_contains "Stopped at step 6" "$OUT" "$T: a late backup target names step 6"
      assert_equals "x" "$(cat "$R/$OLDPACK/file.md" 2>/dev/null)" "$T: a late backup target leaves the old pack in place"
      assert_equals "no" "$(exists "$R/.ravintio-backup/$OLDPACK/$OLDPACK")" "$T: a late backup target gets nothing moved into it"
      ;;
  esac

  echo "=== $T (m) resume after any single step matches an uninterrupted run ==="
  local N REF RESUMED STOPOUT
  REF=$(make_repo "$KIND-ref")
  run_helper "$REF" >/dev/null
  local REF_SNAP; REF_SNAP=$(snapshot "$REF")
  for N in 1 2 3 4 5 6 7 8; do
    R=$(make_repo "$KIND-resume-$N")
    STOPOUT=$(run_helper "$R" "RAVINTIO_MIGRATE_STOP_AFTER=$N"); CODE=$?
    if [ "$CODE" -ne 0 ]; then
      echo "  PASS: $T: stop after step $N exits non-zero"; ((PASS++)) || true
    else
      echo "  FAIL: $T: stop after step $N exits non-zero (got 0)"; ((FAIL++)) || true
    fi
    assert_contains "Stopped at step $N" "$STOPOUT" "$T: stop after step $N names the step"
    OUT=$(run_helper "$R"); CODE=$?
    assert_equals "0" "$CODE" "$T: rerun after step $N exits 0"
    RESUMED=$(snapshot "$R")
    assert_equals "$REF_SNAP" "$RESUMED" "$T: end state after a stop at step $N matches an uninterrupted run"
  done
  R=$(make_repo "$KIND-resume-3-names")
  STOPOUT=$(run_helper "$R" "RAVINTIO_MIGRATE_STOP_AFTER=3")
  assert_contains "ravintio-overrides" "$STOPOUT" "$T: stop after step 3 names the moved overrides"
  R=$(make_repo "$KIND-resume-6-names")
  STOPOUT=$(run_helper "$R" "RAVINTIO_MIGRATE_STOP_AFTER=6")
  assert_contains ".ravintio-backup/$OLDPACK" "$STOPOUT" "$T: stop after step 6 names the backup"
  assert_equals "yes" "$(exists "$R/.ravintio-backup/$OLDPACK/file.md")" "$T: stop after step 6 leaves the pack in the backup"
  assert_contains "D  $OLDPACK/file.md" "$(cd "$R" && git status --porcelain)" "$T: stop after step 6 leaves the pack deletions staged"
}

# A stop after step 1 or 2 has moved nothing yet. Check it before any rerun.
check_early_stops() {
  KIND="$1"
  local T="[$KIND] req-006" N R
  for N in 1 2; do
    R=$(make_repo "$KIND-early-$N")
    run_helper "$R" "RAVINTIO_MIGRATE_STOP_AFTER=$N" >/dev/null
    assert_equals "yes" "$(exists "$R/$OLDOVR")" "$T: stop after step $N has not moved the overrides"
  done
}

# ---------------------------------------------------------------------
# req-006 AC6: step 5 renames the tool markers (P6 change, ADR-005)
# ---------------------------------------------------------------------

NEXT_TAIL=", or setup.ps1 with the same arguments, before the next commit."
GENERIC_NEXT="Next step: run ravintio-framework/setup.sh claude-code, or setup.ps1, or the tool this project uses, before the next commit."

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) IS_WIN=yes ;;
  *) IS_WIN=no ;;
esac

# nat PATH: the path in the form the helper under test reads. pwsh on
# Windows needs a native path, so the ps1 pass converts it there.
nat() {
  if [ "${KIND:-sh}" = ps1 ] && [ "$IS_WIN" = yes ] && command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    printf '%s' "$1"
  fi
}

# upath PATH: the path in the form this shell reads.
upath() {
  if [ "$IS_WIN" = yes ] && command -v cygpath >/dev/null 2>&1; then cygpath -u "$1"; else printf '%s' "$1"; fi
}

# norm TEXT NAME: replace the scratch folder and the fixture name, so two
# fixtures with different names compare equal.
norm() {
  local s="$1"
  s="${s//$WSR/WS}"; s="${s//$WS/WS}"; s="${s//$2/NAME}"
  printf '%s' "$s"
}

# flags_json TOOL FLAG...: print a flags marker the way setup writes it.
flags_json() {
  local tool="$1" list="" f; shift
  for f in "$@"; do list="$list\"$f\","; done
  list="[${list%,}]"
  printf '{\n  "tool": "%s",\n  "flags": %s,\n  "writtenAt": "2026-10-01T00:00:00Z",\n  "attemptStatus": "completed"\n}\n' "$tool" "$list"
}

# make_marker_repo NAME: a consumer repo with real markers in .claude/ and
# .opencode/. The .claude manifest lists two old skill folders, one external
# skill, and these stray entries, each of which the helper must drop:
#   an absolute path outside the skills folder
#   a .. path that leaves the skills folder
#   the skills folder itself, written with a last part of . and of ..
#   (when links work) an entry under a linked folder inside skills/
# Each stray target holds keep.txt. The .claude markers are tracked by git.
# The .opencode markers are not.
make_marker_repo() {
  local d sk osk
  d=$(make_repo "$1")
  sk="$d/.claude/skills"; osk="$d/.opencode/skills"
  mkdir -p "$sk/$OLD-orchestrator" "$sk/$OLD-spec-agent" "$sk/external-tool" "$osk/$OLD-orchestrator" \
           "$WS/stray-$1/$OLD-victim" "$d/.claude/$OLD-victim2"
  echo o > "$sk/$OLD-orchestrator/SKILL.md"
  echo s > "$sk/$OLD-spec-agent/SKILL.md"
  echo e > "$sk/external-tool/SKILL.md"
  echo p > "$osk/$OLD-orchestrator/SKILL.md"
  echo keep > "$WS/stray-$1/$OLD-victim/keep.txt"
  echo keep > "$d/.claude/$OLD-victim2/keep.txt"
  flags_json claude-code --strict-orchestrator --evil-flag > "$d/.claude/.$OLD-setup-flags"
  flags_json opencode --include-full-skill-library --strict-orchestrator > "$d/.opencode/.$OLD-setup-flags"
  {
    nat "$sk/$OLD-orchestrator"; echo
    nat "$sk/$OLD-spec-agent"; echo
    nat "$sk/external-tool"; echo
    nat "$WS/stray-$1/$OLD-victim"; echo
    nat "$sk/../$OLD-victim2"; echo
    nat "$sk/."; echo
    nat "$sk/.."; echo
    if [ "$LINKS_OK" = yes ]; then nat "$sk/linkdir/$OLD-linked"; echo; fi
  } > "$sk/.$OLD-manifest"
  { nat "$osk/$OLD-orchestrator"; echo; } > "$osk/.$OLD-manifest"
  if [ "$LINKS_OK" = yes ]; then
    mkdir -p "$WS/linked-$1/$OLD-linked"
    echo keep > "$WS/linked-$1/$OLD-linked/keep.txt"
    ln -s "$WS/linked-$1" "$sk/linkdir"
  fi
  echo "$d"
}

# check_manifest T FILE SKILLS_DIR NAMES: FILE lists exactly NAMES (space
# separated, in order), each written as the real SKILLS_DIR joined with the
# name, and each entry exists.
check_manifest() {
  local T="$1" file="$2" dir="$3" names="$4" rs expect="" n line missing=0 got_names="" bad_dir=0 up
  local label="${dir%/skills}"
  label="${label##*/}/skills/.ravintio-manifest"
  rs=$(cd "$dir" 2>/dev/null && pwd -P)
  if [ "$IS_WIN" != yes ]; then
    for n in $names; do expect="$expect$rs/$n"$'\n'; done
    assert_equals "${expect%$'\n'}" "$(cat "$file" 2>/dev/null)" "$T: $label lists the real skills folder joined with each kept name"
  fi
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    up=$(upath "$line")
    if [ ! -e "$up" ] && [ ! -L "$up" ]; then missing=$((missing + 1)); fi
    got_names="$got_names ${up##*/}"
    if [ "$(cd "${up%/*}" 2>/dev/null && pwd -P)" != "$rs" ]; then bad_dir=$((bad_dir + 1)); fi
  done <<< "$(cat "$file" 2>/dev/null)"
  assert_equals " $names" "$got_names" "$T: $label keeps exactly the expected names in order"
  assert_equals "0" "$missing" "$T: every entry in $label exists"
  assert_equals "0" "$bad_dir" "$T: every entry in $label sits in the real skills folder"
}

run_marker_suite() {
  KIND="$1"
  local T="[$KIND] req-006 AC6" R OUT CODE BEFORE tool sk N REF REF_SNAP STOPOUT TARGET TSNAP has
  local NAME="$KIND-mk"

  echo "=== $T (q1) a clean run renames the markers in .claude/ and .opencode/ ==="
  R=$(make_marker_repo "$NAME")
  sk="$R/.claude/skills"
  flags_json claude-code --strict-orchestrator --evil-flag > "$WS/$NAME-claude-flags"
  flags_json opencode --include-full-skill-library --strict-orchestrator > "$WS/$NAME-opencode-flags"
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "0" "$CODE" "$T: marker run exits 0"
  for tool in .claude .opencode; do
    assert_equals "no" "$(exists "$R/$tool/.$OLD-setup-flags")" "$T: $tool old flags file gone"
    assert_equals "yes" "$(exists "$R/$tool/.ravintio-setup-flags")" "$T: $tool has .ravintio-setup-flags"
    assert_equals "no" "$(exists "$R/$tool/skills/.$OLD-manifest")" "$T: $tool old manifest gone"
    assert_equals "yes" "$(exists "$R/$tool/skills/.ravintio-manifest")" "$T: $tool has .ravintio-manifest"
  done
  assert_equals "no" "$(exists "$R/.claude/.$OLD-session")" "$T: session marker still removed"

  echo "=== $T (q2) the flags files are byte-identical ==="
  assert_equals "same" "$(cmp -s "$WS/$NAME-claude-flags" "$R/.claude/.ravintio-setup-flags" && echo same || echo differ)" "$T: .claude flags byte-identical"
  assert_equals "same" "$(cmp -s "$WS/$NAME-opencode-flags" "$R/.opencode/.ravintio-setup-flags" && echo same || echo differ)" "$T: .opencode flags byte-identical"

  echo "=== $T (q3) each manifest is rewritten and every entry exists ==="
  check_manifest "$T" "$sk/.ravintio-manifest" "$sk" "ravintio-orchestrator ravintio-spec-agent external-tool"
  check_manifest "$T" "$R/.opencode/skills/.ravintio-manifest" "$R/.opencode/skills" "ravintio-orchestrator"

  echo "=== $T (q4) listed old skill folders are renamed ==="
  assert_equals "no" "$(exists "$sk/$OLD-orchestrator")" "$T: .claude old orchestrator folder gone"
  assert_equals "o" "$(cat "$sk/ravintio-orchestrator/SKILL.md" 2>/dev/null)" "$T: .claude orchestrator renamed with content"
  assert_equals "no" "$(exists "$sk/$OLD-spec-agent")" "$T: .claude old spec-agent folder gone"
  assert_equals "s" "$(cat "$sk/ravintio-spec-agent/SKILL.md" 2>/dev/null)" "$T: .claude spec-agent renamed with content"
  assert_equals "no" "$(exists "$R/.opencode/skills/$OLD-orchestrator")" "$T: .opencode old orchestrator folder gone"
  assert_equals "p" "$(cat "$R/.opencode/skills/ravintio-orchestrator/SKILL.md" 2>/dev/null)" "$T: .opencode orchestrator renamed with content"

  echo "=== $T (q5) an external skill entry keeps its name ==="
  assert_equals "e" "$(cat "$sk/external-tool/SKILL.md" 2>/dev/null)" "$T: external skill folder kept in place"

  echo "=== $T (q6) stray entries are dropped with a warning and their targets survive ==="
  assert_contains "WARNING: dropped manifest entry $(nat "$WS/stray-$NAME/$OLD-victim")" "$OUT" "$T: absolute outside entry named in a warning"
  assert_contains "WARNING: dropped manifest entry $(nat "$sk/../$OLD-victim2")" "$OUT" "$T: .. entry named in a warning"
  assert_contains "WARNING: dropped manifest entry $(nat "$sk/.")" "$OUT" "$T: entry ending in . named in a warning"
  assert_contains "WARNING: dropped manifest entry $(nat "$sk/..")" "$OUT" "$T: entry ending in .. named in a warning"
  assert_equals "keep" "$(cat "$WS/stray-$NAME/$OLD-victim/keep.txt" 2>/dev/null)" "$T: absolute outside target untouched"
  assert_equals "no" "$(exists "$WS/stray-$NAME/ravintio-victim")" "$T: absolute outside target not renamed"
  assert_equals "keep" "$(cat "$R/.claude/$OLD-victim2/keep.txt" 2>/dev/null)" "$T: .. target untouched"
  assert_equals "no" "$(exists "$R/.claude/ravintio-victim2")" "$T: .. target not renamed"
  assert_equals "yes" "$([ -d "$sk" ] && [ ! -L "$sk" ] && echo yes || echo no)" "$T: the skills folder itself stays in place"
  if [ "$LINKS_OK" = yes ]; then
    assert_contains "WARNING: dropped manifest entry $sk/linkdir/$OLD-linked" "$OUT" "$T: linked-parent entry named in a warning"
    assert_equals "keep" "$(cat "$WS/linked-$NAME/$OLD-linked/keep.txt" 2>/dev/null)" "$T: linked-parent target untouched"
    assert_equals "no" "$(exists "$WS/linked-$NAME/ravintio-linked")" "$T: linked-parent target not renamed"
    assert_equals "yes" "$([ -L "$sk/linkdir" ] && echo yes || echo no)" "$T: the linked folder is still a link"
  else
    echo "  SKIP: $T (q6) linked-parent entry: ln -s makes no real link on this platform"
  fi

  echo "=== $T (q7) step 7 prints the setup command with the saved flags ==="
  assert_contains "Next step: run ravintio-framework/setup.sh claude-code --strict-orchestrator$NEXT_TAIL" "$OUT" "$T: claude-code command carries --strict-orchestrator"
  assert_contains "Next step: run ravintio-framework/setup.sh opencode --include-full-skill-library --strict-orchestrator$NEXT_TAIL" "$OUT" "$T: opencode command carries both flags in setup order"
  has=no; [[ "$OUT" == *"--evil-flag"* ]] && has=yes
  assert_equals "no" "$has" "$T: an unknown saved flag is not passed on"

  echo "=== $T (q8) a rerun changes nothing ==="
  BEFORE=$(snapshot "$R")
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "0" "$CODE" "$T: marker rerun exits 0"
  assert_equals "$BEFORE" "$(snapshot "$R")" "$T: marker rerun changes nothing"
  assert_contains "Nothing to do" "$OUT" "$T: marker rerun says nothing to do"
  assert_contains "Next step: run ravintio-framework/setup.sh claude-code --strict-orchestrator$NEXT_TAIL" "$OUT" "$T: marker rerun still prints the saved command"

  echo "=== $T (q9) marker clashes stop at step 2 before any move ==="
  R=$(make_marker_repo "$KIND-mkclash-flags")
  echo "new" > "$R/.claude/.ravintio-setup-flags"
  BEFORE=$(snapshot "$R")
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "1" "$CODE" "$T: old and new flags file exits 1"
  assert_contains "Stopped at step 2" "$OUT" "$T: old and new flags file names step 2"
  assert_contains ".claude/.ravintio-setup-flags" "$OUT" "$T: old and new flags file names the clash"
  assert_equals "$BEFORE" "$(snapshot "$R")" "$T: old and new flags file moves nothing"
  R=$(make_marker_repo "$KIND-mkclash-manifest")
  echo "new" > "$R/.opencode/skills/.ravintio-manifest"
  BEFORE=$(snapshot "$R")
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "1" "$CODE" "$T: old and new manifest exits 1"
  assert_contains "Stopped at step 2" "$OUT" "$T: old and new manifest names step 2"
  assert_contains ".opencode/skills/.ravintio-manifest" "$OUT" "$T: old and new manifest names the clash"
  assert_equals "$BEFORE" "$(snapshot "$R")" "$T: old and new manifest moves nothing"
  R=$(make_marker_repo "$KIND-mkclash-skill")
  mkdir -p "$R/.claude/skills/ravintio-orchestrator"
  echo "mine" > "$R/.claude/skills/ravintio-orchestrator/SKILL.md"
  BEFORE=$(snapshot "$R")
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "1" "$CODE" "$T: old and new skill folder exits 1"
  assert_contains "Stopped at step 2" "$OUT" "$T: old and new skill folder names step 2"
  assert_contains ".claude/skills/ravintio-orchestrator" "$OUT" "$T: old and new skill folder names the clash"
  assert_equals "$BEFORE" "$(snapshot "$R")" "$T: old and new skill folder moves nothing"

  echo "=== $T (q10) a link at .cursor/skills skips .cursor with a warning ==="
  if [ "$LINKS_OK" != yes ]; then
    echo "  SKIP: $T (q10): ln -s makes no real link on this platform"
  else
    R=$(make_marker_repo "$KIND-mkcursor")
    TARGET="$WS/cursor-skills-$KIND"
    mkdir -p "$R/.cursor" "$TARGET/$OLD-orchestrator"
    echo c > "$TARGET/$OLD-orchestrator/SKILL.md"
    echo "$R/.cursor/skills/$OLD-orchestrator" > "$TARGET/.$OLD-manifest"
    flags_json cursor > "$R/.cursor/.$OLD-setup-flags"
    ln -s "$TARGET" "$R/.cursor/skills"
    TSNAP=$(snapshot "$TARGET")
    OUT=$(run_helper "$R"); CODE=$?
    assert_equals "0" "$CODE" "$T: linked .cursor/skills exits 0"
    assert_contains "WARNING: .cursor/skills is a symlink" "$OUT" "$T: linked .cursor/skills is named in a warning"
    assert_equals "$TSNAP" "$(snapshot "$TARGET")" "$T: target of linked .cursor/skills untouched"
    assert_equals "yes" "$(exists "$R/.cursor/.$OLD-setup-flags")" "$T: linked .cursor/skills leaves the .cursor flags file in place"
    assert_equals "no" "$(exists "$R/.cursor/.ravintio-setup-flags")" "$T: linked .cursor/skills writes no new .cursor flags file"
    assert_equals "yes" "$(exists "$R/.claude/.ravintio-setup-flags")" "$T: linked .cursor/skills still renames the .claude markers"
  fi

  echo "=== $T (q11) resume after a stop at step 4 or 5 matches an uninterrupted run ==="
  REF=$(make_marker_repo "$KIND-mkref")
  run_helper "$REF" >/dev/null
  REF_SNAP=$(norm "$(snapshot "$REF")" "$KIND-mkref")
  for N in 4 5; do
    R=$(make_marker_repo "$KIND-mkres-$N")
    STOPOUT=$(run_helper "$R" "RAVINTIO_MIGRATE_STOP_AFTER=$N"); CODE=$?
    assert_equals "3" "$CODE" "$T: stop after step $N exits 3"
    assert_contains "Stopped at step $N" "$STOPOUT" "$T: stop after step $N names the step"
    OUT=$(run_helper "$R"); CODE=$?
    assert_equals "0" "$CODE" "$T: rerun after step $N exits 0"
    assert_equals "$REF_SNAP" "$(norm "$(snapshot "$R")" "$KIND-mkres-$N")" "$T: end state after a stop at step $N matches an uninterrupted run"
  done

  echo "=== $T (q12) an unknown tool value falls back to the generic command ==="
  R=$(make_marker_repo "$KIND-mkbogus")
  flags_json bogus-tool --strict-orchestrator > "$R/.claude/.$OLD-setup-flags"
  flags_json bogus-tool --strict-orchestrator > "$WS/$KIND-mkbogus-flags"
  rm -f "$R/.opencode/.$OLD-setup-flags"
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "0" "$CODE" "$T: unknown tool run exits 0"
  assert_contains "$GENERIC_NEXT" "$OUT" "$T: unknown tool prints the generic command"
  has=no; [[ "$OUT" == *"setup.sh bogus-tool"* ]] && has=yes
  assert_equals "no" "$has" "$T: unknown tool value is not printed as a command"
  assert_equals "same" "$(cmp -s "$WS/$KIND-mkbogus-flags" "$R/.claude/.ravintio-setup-flags" && echo same || echo differ)" "$T: unknown tool flags file still renamed byte-identical"
}

echo "=== req-006: helper files exist ==="
assert_equals "yes" "$(exists "$SH_HELPER")" "req-006: migrate-0.37.0-ravintio-rename.sh exists"
assert_equals "yes" "$(exists "$PS_HELPER")" "req-006: migrate-0.37.0-ravintio-rename.ps1 exists"
assert_equals "yes" "$(exists "$MIG_DIR/migrate-0.37.0-ravintio-rename.md")" "req-006: migrate-0.37.0-ravintio-rename.md exists"

if [ -f "$SH_HELPER" ]; then
  run_suite sh
  check_early_stops sh
  run_marker_suite sh
else
  echo "  FAIL: req-006: skipped the .sh cases because the helper is missing"; ((FAIL++)) || true
fi

echo "=== req-006 AC4: .ps1 helper ==="
if command -v pwsh >/dev/null 2>&1; then
  if [ -f "$PS_HELPER" ]; then
    run_suite ps1
    check_early_stops ps1
    run_marker_suite ps1
    # (p) parity: same output and exit code for the same scenario.
    for scenario in clean rerun nopack bothoverrides; do
      A=$(make_repo "parity-sh-$scenario"); B=$(make_repo "parity-ps-$scenario")
      case "$scenario" in
        rerun) KIND=sh; run_helper "$A" >/dev/null; KIND=ps1; run_helper "$B" >/dev/null ;;
        nopack) rm -rf "${A:?}/ravintio-framework" "${B:?}/ravintio-framework" ;;
        bothoverrides) mkdir -p "$A/ravintio-overrides" "$B/ravintio-overrides" ;;
      esac
      KIND=sh; SOUT=$(run_helper "$A"; echo "exit=$?")
      KIND=ps1; POUT=$(run_helper "$B"; echo "exit=$?")
      assert_equals "$SOUT" "$POUT" "req-006 AC4: .sh and .ps1 print the same text and exit code ($scenario)"
    done
    # AC6 parity: the marker run prints the same text once paths are normalised.
    # On Windows the two shells write paths in different forms, so it skips there.
    if [ "$IS_WIN" = yes ]; then
      echo "  SKIP (windows): req-006 AC6 parity (markers): Git Bash and pwsh print paths in different forms"
    else
      KIND=sh; A=$(make_marker_repo "parity-sh-markers")
      KIND=ps1; B=$(make_marker_repo "parity-ps-markers")
      KIND=sh; SOUT=$(run_helper "$A"; echo "exit=$?")
      KIND=ps1; POUT=$(run_helper "$B"; echo "exit=$?")
      assert_equals "$(norm "$SOUT" "parity-sh-markers")" "$(norm "$POUT" "parity-ps-markers")" "req-006 AC6: .sh and .ps1 print the same text and exit code (markers)"
    fi
  else
    echo "  FAIL: req-006 AC4: the .ps1 helper is missing"; ((FAIL++)) || true
  fi
else
  echo "  SKIP: req-006 AC4: pwsh is not installed here. CI runs the Windows PowerShell 5.1 and PowerShell 7 legs."
fi

print_summary
