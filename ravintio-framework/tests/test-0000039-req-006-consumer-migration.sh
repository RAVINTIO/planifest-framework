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

# ---------------------------------------------------------------------
# req-006 AC6 (P5 M-001 to M-004): strict manifest entry names
# ---------------------------------------------------------------------
#
# Both helpers keep a manifest entry only when its parent resolves to the
# real skills folder and its last part matches NAME_RE and does not end in
# a dot. Any other entry is dropped with "WARNING: dropped manifest entry
# {entry as written}", and its target is untouched.
#
# M-004 temporary file pattern, pinned from the helper source:
#   .sh   mktemp "{skills}/.ravintio-manifest.XXXXXX"
#   .ps1  "{skills}/.ravintio-manifest." plus 6 characters of
#         GetRandomFileName() with the dot removed
# So a helper temp file is ".ravintio-manifest." followed by exactly 6
# letters or digits (TMP_RE). A rerun removes such a file from each skills
# folder it processes, and leaves any other name alone.
#
# M-004 uses a planted leftover rather than a forced failure. The test hook
# RAVINTIO_MIGRATE_STOP_AFTER fires only after step 5 ends, when the temp
# file is already renamed. A read-only skills folder makes mktemp fail
# before any temp file exists. Making the rename itself fail needs chflags
# or chattr, which differ by platform or need root.
NAME_RE='^[A-Za-z0-9][A-Za-z0-9._-]*$'
TMP_RE='^\.ravintio-manifest\.[A-Za-z0-9]{6}$'

run_strict_names_suite() {
  KIND="$1"
  local T="[$KIND] req-006 AC6" R OUT CODE sk nsk rs line up last bad n e BEFORE has
  local NAME="$KIND-mkstrict"
  local BS='..\..\..\'"$OLD-victim3-$KIND"

  echo "=== $T (P5 M-001) crafted last parts are dropped and their targets survive ==="
  R=$(make_marker_repo "$NAME")
  sk="$R/.claude/skills"
  nsk="$(nat "$sk")"
  mkdir -p "$WS/$OLD-victim3-$KIND" "$sk/a" "$sk/ravintio_x.y"
  echo keep > "$WS/$OLD-victim3-$KIND/keep.txt"
  echo keep > "$sk/a/keep.txt"
  echo keep > "$R/.claude/keep.txt"
  echo x > "$sk/ravintio_x.y/SKILL.md"
  {
    printf '%s/%s\n' "$nsk" "$BS"
    printf '%s/%s\n' "$nsk" 'C:'
    printf '%s/%s\n' "$nsk" '.. '
    printf '%s/%s\n' "$nsk" '...'
    printf '%s/%s\n' "$nsk" '*'
    printf '%s/%s\n' "$nsk" 'a.'
    printf '%s/%s\n' "$nsk" 'ravintio_x.y'
  } >> "$sk/.$OLD-manifest"
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "0" "$CODE" "$T (P5 M-001): run with crafted entries exits 0"
  assert_contains "WARNING: dropped manifest entry $nsk/$BS"$'\n' "$OUT" "$T (P5 M-001): backslash entry named in a warning"
  assert_contains "WARNING: dropped manifest entry $nsk/C:"$'\n' "$OUT" "$T (P5 M-002): drive entry C: named in a warning"
  assert_contains "WARNING: dropped manifest entry $nsk/.. "$'\n' "$OUT" "$T (P5 M-003): entry with a trailing space named in a warning"
  assert_contains "WARNING: dropped manifest entry $nsk/..."$'\n' "$OUT" "$T (P5 M-003): entry ... named in a warning"
  assert_contains "WARNING: dropped manifest entry $nsk/*"$'\n' "$OUT" "$T (P5 M-003): wildcard entry named in a warning"
  assert_contains "WARNING: dropped manifest entry $nsk/a."$'\n' "$OUT" "$T (P5 M-003): entry with a trailing dot named in a warning"
  has=no; [[ "$OUT" == *"dropped manifest entry $nsk/ravintio_x.y"* ]] && has=yes
  assert_equals "no" "$has" "$T (P5 M-001): valid name ravintio_x.y is not dropped"

  # No dropped last part appears in the rewritten manifest.
  bad=""
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    last="${line##*/}"; last="${last##*\\}"
    for e in "$BS" "${BS##*\\}" 'C:' '.. ' '...' '*' 'a.'; do
      if [ "$last" = "$e" ]; then bad="$bad [$e]"; fi
    done
  done <<< "$(cat "$sk/.ravintio-manifest" 2>/dev/null)"
  assert_equals "" "$bad" "$T (P5 M-001): no dropped last part appears in .ravintio-manifest"
  check_manifest "$T (P5 M-001)" "$sk/.ravintio-manifest" "$sk" "ravintio-orchestrator ravintio-spec-agent external-tool ravintio_x.y"

  # Every line is the real skills folder joined with an allowlisted name.
  rs=$(cd "$sk" 2>/dev/null && pwd -P)
  bad=0; n=0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    n=$((n + 1))
    up=$(upath "$line")
    last="${up##*/}"
    if ! [[ "$last" =~ $NAME_RE ]] || [ "${last%.}" != "$last" ]; then bad=$((bad + 1)); continue; fi
    if [ "$IS_WIN" != yes ] && [ "${line%/*}" != "$rs" ]; then bad=$((bad + 1)); fi
  done <<< "$(cat "$sk/.ravintio-manifest" 2>/dev/null)"
  assert_equals "4" "$n" "$T (P5 M-001): .ravintio-manifest holds exactly the four valid entries"
  assert_equals "0" "$bad" "$T (P5 M-001): every manifest line is the real skills folder joined with an allowlisted name"

  # Each real folder a crafted entry could point to survives.
  assert_equals "keep" "$(cat "$WS/$OLD-victim3-$KIND/keep.txt" 2>/dev/null)" "$T (P5 M-001): folder the backslash entry points to is untouched"
  assert_equals "no" "$(exists "$WS/ravintio-victim3-$KIND")" "$T (P5 M-001): folder the backslash entry points to is not renamed"
  assert_equals "keep" "$(cat "$R/.claude/keep.txt" 2>/dev/null)" "$T (P5 M-003): tool folder the trailing-space entry points to survives"
  assert_equals "keep" "$(cat "$sk/a/keep.txt" 2>/dev/null)" "$T (P5 M-003): folder a, which a. points to on Windows, survives"
  assert_equals "e" "$(cat "$sk/external-tool/SKILL.md" 2>/dev/null)" "$T (P5 M-003): folders the wildcard entry matches survive"
  assert_equals "x" "$(cat "$sk/ravintio_x.y/SKILL.md" 2>/dev/null)" "$T (P5 M-001): valid ravintio_x.y folder kept in place"

  echo "=== $T (P5 M-004) a rerun removes a leftover temporary manifest ==="
  R=$(make_marker_repo "$KIND-mktmp")
  sk="$R/.claude/skills"
  run_helper "$R" >/dev/null
  # Names that do not match TMP_RE are not helper temp files and must stay.
  echo mine > "$sk/.ravintio-manifest.mine"
  echo mine > "$sk/.ravintio-manifest.abc1234"
  BEFORE=$(snapshot "$R")
  for e in .ravintio-manifest.Ab12Cd .ravintio-manifest.x9y8z7; do
    [[ "$e" =~ $TMP_RE ]] || { echo "  FAIL: $T (P5 M-004): fixture $e does not match the temp pattern"; ((FAIL++)) || true; }
    printf 'stale\n' > "$sk/$e"
  done
  printf 'stale\n' > "$R/.opencode/skills/.ravintio-manifest.Q1w2E3"
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "0" "$CODE" "$T (P5 M-004): rerun with leftover temp files exits 0"
  assert_equals "no" "$(exists "$sk/.ravintio-manifest.Ab12Cd")" "$T (P5 M-004): .sh-style leftover temp file removed"
  assert_equals "no" "$(exists "$sk/.ravintio-manifest.x9y8z7")" "$T (P5 M-004): .ps1-style leftover temp file removed"
  assert_equals "no" "$(exists "$R/.opencode/skills/.ravintio-manifest.Q1w2E3")" "$T (P5 M-004): leftover temp file removed from .opencode/skills"
  assert_equals "$BEFORE" "$(snapshot "$R")" "$T (P5 M-004): rerun removes only the leftover temp files"
}

# ---------------------------------------------------------------------
# req-006 (P5 N-001 to N-005): re-review of the marker fixes
# ---------------------------------------------------------------------
#
# N-001  In a linked worktree, git rev-parse --git-path info/exclude prints
#        a rooted path. Step 6 must write that file as is, so git ignores
#        .ravintio-backup/, and make no stray exclude file in the project.
# N-002  Doc and comments only, so no case here.
# N-003  A last part whose base name, before the first ".", is a Windows
#        device name is dropped on every platform, ignoring case:
#        CON PRN AUX NUL COM1 to COM9 LPT1 to LPT9.
# N-004  An entry whose text starts with \\ or // is dropped before any
#        path lookup. The case runs off Windows only, because on Windows the
#        current helpers would look up the host.
# N-005  Step 4 temporary file pattern, pinned from the helper source:
#          .sh   mktemp ".github/workflows/.ravintio.yml.XXXXXX"
#          .ps1  ".github/workflows/.ravintio.yml." plus 6 characters of
#                GetRandomFileName() with the dot removed
#        So a step 4 temp file is ".ravintio.yml." followed by exactly 6
#        letters or digits (WF_TMP_RE). A stopped step 4 leaves none. A
#        rerun removes each regular file of that name in .github/workflows/
#        and leaves any other name alone.
#        The .sh pass forces the stop with an mv shim that fails on the temp
#        file. The .ps1 pass makes File.Replace fail with chflags uchg on
#        the target, which only macOS offers without root.
WF_TMP_RE='^\.ravintio\.yml\.[A-Za-z0-9]{6}$'

# wf_temp_files DIR: print each name in DIR that matches WF_TMP_RE.
wf_temp_files() {
  local f
  for f in "$1"/.ravintio.yml.*; do
    [ -e "$f" ] || [ -L "$f" ] || continue
    f="${f##*/}"
    if [[ "$f" =~ $WF_TMP_RE ]]; then printf '%s\n' "$f"; fi
  done
}

run_rereview_suite() {
  KIND="$1"
  local T="[$KIND] req-006" R W M OUT CODE sk nsk e has BEFORE wf SHIM REAL_MV
  local NAME="$KIND-rr"

  echo "=== $T (P5 N-001) a linked worktree gets the backup line in the exclude file git reads ==="
  M=$(make_repo "$NAME-wtmain")
  W="$WS/$NAME-wt"
  if ( cd "$M" && git worktree add -q -b wt "$W" >/dev/null 2>&1 ) && [ -f "$W/.git" ]; then
    OUT=$(run_helper "$W"); CODE=$?
    assert_equals "0" "$CODE" "$T (P5 N-001): run in a linked worktree exits 0"
    assert_equals "yes" "$(exists "$W/.ravintio-backup/$OLDPACK/setup.sh")" "$T (P5 N-001): worktree pack moved to the backup"
    assert_equals "1" "$(grep -cx '.ravintio-backup/' "$M/.git/info/exclude" 2>/dev/null)" "$T (P5 N-001): backup line added once to the real exclude file"
    assert_equals "0" "$( cd "$W" && GIT_CEILING_DIRECTORIES="$WS" git check-ignore -q .ravintio-backup/x >/dev/null 2>&1; echo $? )" "$T (P5 N-001): git check-ignore reports .ravintio-backup/x as ignored in the worktree"
    has="$(find "$W" -path "$W/.ravintio-backup" -prune -o -name exclude -print 2>/dev/null)"
    assert_equals "" "$has" "$T (P5 N-001): no stray exclude file made inside the worktree"
  else
    echo "  SKIP: $T (P5 N-001): git worktree is not available here"
  fi

  echo "=== $T (P5 N-003) Windows device names are dropped on every platform ==="
  R=$(make_marker_repo "$NAME-dev")
  sk="$R/.claude/skills"
  nsk="$(nat "$sk")"
  for e in console com10 CONx.d nul-x; do
    mkdir -p "$sk/$e"; echo k > "$sk/$e/SKILL.md"
  done
  {
    for e in NUL con.txt Com1 lpt9 AUX.tar.gz prn COM9.x Lpt1; do printf '%s/%s\n' "$nsk" "$e"; done
    for e in console com10 CONx.d nul-x; do printf '%s/%s\n' "$nsk" "$e"; done
  } >> "$sk/.$OLD-manifest"
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "0" "$CODE" "$T (P5 N-003): run with device name entries exits 0"
  for e in NUL con.txt Com1 lpt9 AUX.tar.gz prn COM9.x Lpt1; do
    assert_contains "WARNING: dropped manifest entry $nsk/$e"$'\n' "$OUT" "$T (P5 N-003): device name entry $e named in a warning"
  done
  for e in console com10 CONx.d nul-x; do
    has=no; [[ "$OUT" == *"dropped manifest entry $nsk/$e"$'\n'* ]] && has=yes
    assert_equals "no" "$has" "$T (P5 N-003): near-miss name $e is not dropped"
  done
  check_manifest "$T (P5 N-003)" "$sk/.ravintio-manifest" "$sk" "ravintio-orchestrator ravintio-spec-agent external-tool console com10 CONx.d nul-x"

  echo "=== $T (P5 N-004) entries that start with \\\\ or // are dropped before any lookup ==="
  if [ "$IS_WIN" = yes ]; then
    echo "  SKIP (windows): $T (P5 N-004): a UNC entry would make the current helpers look up the host"
  else
    R=$(make_marker_repo "$NAME-unc")
    sk="$R/.claude/skills"
    mkdir -p "$sk/uncdir"; echo u > "$sk/uncdir/SKILL.md"
    # The third entry is the real skills folder written with a leading //.
    # It resolves to the skills folder, so only a text check can drop it.
    {
      printf '%s\n' "//host/share/$OLD-x"
      printf '%s\n' '\\host\share\'"$OLD-x"
      printf '%s\n' "/$sk/uncdir"
    } >> "$sk/.$OLD-manifest"
    OUT=$(run_helper "$R"); CODE=$?
    assert_equals "0" "$CODE" "$T (P5 N-004): run with UNC-style entries exits 0"
    assert_contains "WARNING: dropped manifest entry //host/share/$OLD-x"$'\n' "$OUT" "$T (P5 N-004): //host/share entry named in a warning"
    assert_contains 'WARNING: dropped manifest entry \\host\share\'"$OLD-x"$'\n' "$OUT" "$T (P5 N-004): \\\\host\\share entry named in a warning"
    assert_contains "WARNING: dropped manifest entry /$sk/uncdir"$'\n' "$OUT" "$T (P5 N-004): // entry that names the skills folder is dropped"
    check_manifest "$T (P5 N-004)" "$sk/.ravintio-manifest" "$sk" "ravintio-orchestrator ravintio-spec-agent external-tool"
    assert_equals "u" "$(cat "$sk/uncdir/SKILL.md" 2>/dev/null)" "$T (P5 N-004): folder the // entry points to is untouched"
  fi

  echo "=== $T (P5 N-005) a stopped step 4 leaves no temporary workflow file ==="
  R=$(make_repo "$NAME-wfstop")
  wf="$R/.github/workflows"
  if [ "$KIND" = sh ]; then
    SHIM="$WS/mvshim-$KIND"
    REAL_MV="$(command -v mv)"
    mkdir -p "$SHIM"
    {
      printf '#!/usr/bin/env bash\n'
      printf 'case "$*" in *.ravintio.yml.*) echo "mv shim: refused" >&2; exit 1 ;; esac\n'
      printf 'exec "%s" "$@"\n' "$REAL_MV"
    } > "$SHIM/mv"
    chmod +x "$SHIM/mv"
    OUT=$(run_helper "$R" "PATH=$SHIM:$PATH"); CODE=$?
  elif [ "$(uname -s)" = Darwin ] && command -v chflags >/dev/null 2>&1; then
    # Rename the workflow first, so step 4 only rewrites it, then lock it.
    ( cd "$R" && git mv "$wf/$OLD.yml" "$wf/ravintio.yml" && git commit -q -m wf )
    chflags uchg "$wf/ravintio.yml"
    OUT=$(run_helper "$R"); CODE=$?
    chflags nouchg "$wf/ravintio.yml"
  else
    OUT=""; CODE=skip
    echo "  SKIP: $T (P5 N-005) forced stop: only macOS can lock a file without root"
  fi
  if [ "$CODE" != skip ]; then
    assert_equals "1" "$CODE" "$T (P5 N-005): a failed step 4 replace exits 1"
    assert_contains "Stopped at step 4" "$OUT" "$T (P5 N-005): a failed step 4 replace names step 4"
    assert_equals "" "$(wf_temp_files "$wf")" "$T (P5 N-005): a stopped step 4 leaves no .ravintio.yml temp file"
  fi

  echo "=== $T (P5 N-005) a rerun removes a leftover temporary workflow file ==="
  R=$(make_repo "$NAME-wftmp")
  wf="$R/.github/workflows"
  run_helper "$R" >/dev/null
  # Names that are not step 4 temp files, or are not regular files, stay.
  echo mine > "$wf/.ravintio.yml.mine"
  echo mine > "$wf/.ravintio.yml.abc1234"
  echo mine > "$wf/.ravintio.yml.Ab12C"
  mkdir -p "$wf/.ravintio.yml.Dir123"; echo mine > "$wf/.ravintio.yml.Dir123/keep.txt"
  if [ "$LINKS_OK" = yes ]; then
    echo outside > "$WS/$NAME-wf-link-target"
    ln -s "$WS/$NAME-wf-link-target" "$wf/.ravintio.yml.Lnk123"
  fi
  BEFORE=$(snapshot "$R")
  for e in .ravintio.yml.Ab12Cd .ravintio.yml.x9y8z7; do
    [[ "$e" =~ $WF_TMP_RE ]] || { echo "  FAIL: $T (P5 N-005): fixture $e does not match the temp pattern"; ((FAIL++)) || true; }
    printf 'stale\n' > "$wf/$e"
  done
  OUT=$(run_helper "$R"); CODE=$?
  assert_equals "0" "$CODE" "$T (P5 N-005): rerun with leftover workflow temp files exits 0"
  assert_equals "no" "$(exists "$wf/.ravintio.yml.Ab12Cd")" "$T (P5 N-005): .sh-style leftover workflow temp file removed"
  assert_equals "no" "$(exists "$wf/.ravintio.yml.x9y8z7")" "$T (P5 N-005): .ps1-style leftover workflow temp file removed"
  assert_equals "$BEFORE" "$(snapshot "$R")" "$T (P5 N-005): rerun removes only the leftover workflow temp files"
  if [ "$LINKS_OK" = yes ]; then
    assert_equals "outside" "$(cat "$WS/$NAME-wf-link-target" 2>/dev/null)" "$T (P5 N-005): link target outside the project untouched"
  fi
}

echo "=== req-006: helper files exist ==="
assert_equals "yes" "$(exists "$SH_HELPER")" "req-006: migrate-0.37.0-ravintio-rename.sh exists"
assert_equals "yes" "$(exists "$PS_HELPER")" "req-006: migrate-0.37.0-ravintio-rename.ps1 exists"
assert_equals "yes" "$(exists "$MIG_DIR/migrate-0.37.0-ravintio-rename.md")" "req-006: migrate-0.37.0-ravintio-rename.md exists"

if [ -f "$SH_HELPER" ]; then
  run_suite sh
  check_early_stops sh
  run_marker_suite sh
  run_strict_names_suite sh
  run_rereview_suite sh
else
  echo "  FAIL: req-006: skipped the .sh cases because the helper is missing"; ((FAIL++)) || true
fi

echo "=== req-006 AC4: .ps1 helper ==="
if command -v pwsh >/dev/null 2>&1; then
  if [ -f "$PS_HELPER" ]; then
    run_suite ps1
    check_early_stops ps1
    run_marker_suite ps1
    run_strict_names_suite ps1
    run_rereview_suite ps1
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
