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
#   step 8                  "RAVINTIO Strict Pipeline"
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
OLDPACK="$OLD-framework"
OLDOVR="$OLD-overrides"

WS=$(mktemp -d)
trap 'rm -rf "${WS:?}"' EXIT

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
    printf 'run: bash %s/tests/run-tests.sh\nenv:\n' "$OLDPACK"
    for v in $PACK_VARS; do printf '  %s_%s: 1\n' "$OLDU" "$v"; done
    printf '  %s_GATE_EXTRA: keep\n' "$OLDU"
    printf '  TOKEN: ${{ secrets.%s_MY_SECRET }}\n' "$OLDU"
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
  assert_equals "2" "$(grep -c "${OLDU}_" "$R/.github/workflows/ravintio.yml" 2>/dev/null)" "$T: only the two consumer names keep the old prefix"
  assert_equals "no" "$(exists "$R/.claude/.$OLD-session")" "$T: session marker removed"
  assert_equals "yes" "$(exists "$R/.claude/.$OLD-setup-flags")" "$T: setup flags stay for setup"
  assert_equals "yes" "$(exists "$R/.claude/skills/.$OLD-manifest")" "$T: manifest stays for setup"
  assert_equals "no" "$(exists "$R/$OLDPACK")" "$T: old pack gone from the root"
  assert_equals "x" "$(cat "$R/.ravintio-backup/$OLDPACK/file.md" 2>/dev/null)" "$T: old pack moved to the backup"
  assert_equals "y" "$(cat "$R/.ravintio-backup/$OLDPACK/sub/x.md" 2>/dev/null)" "$T: nested backup content kept"
  assert_equals "yes" "$(exists "$R/ravintio-framework/setup.sh")" "$T: new pack kept"
  assert_equals "0" "$(cd "$R" && git ls-files -- "$OLDPACK" | grep -c .)" "$T: git stops tracking the old pack"
  assert_equals "1" "$(grep -cx '.ravintio-backup/' "$R/.git/info/exclude" 2>/dev/null)" "$T: backup added once to .git/info/exclude"
  assert_contains "Next step: run ravintio-framework/setup.sh claude-code" "$OUT" "$T: prints the setup command"
  assert_contains ".ravintio-backup/" "$OUT" "$T: names the backup folder"
  assert_contains "RAVINTIO Strict Pipeline" "$OUT" "$T: prints the branch protection warning"

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

echo "=== req-006: helper files exist ==="
assert_equals "yes" "$(exists "$SH_HELPER")" "req-006: migrate-0.37.0-ravintio-rename.sh exists"
assert_equals "yes" "$(exists "$PS_HELPER")" "req-006: migrate-0.37.0-ravintio-rename.ps1 exists"
assert_equals "yes" "$(exists "$MIG_DIR/migrate-0.37.0-ravintio-rename.md")" "req-006: migrate-0.37.0-ravintio-rename.md exists"

if [ -f "$SH_HELPER" ]; then
  run_suite sh
  check_early_stops sh
else
  echo "  FAIL: req-006: skipped the .sh cases because the helper is missing"; ((FAIL++)) || true
fi

echo "=== req-006 AC4: .ps1 helper ==="
if command -v pwsh >/dev/null 2>&1; then
  if [ -f "$PS_HELPER" ]; then
    run_suite ps1
    check_early_stops ps1
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
  else
    echo "  FAIL: req-006 AC4: the .ps1 helper is missing"; ((FAIL++)) || true
  fi
else
  echo "  SKIP: req-006 AC4: pwsh is not installed here. CI runs the Windows PowerShell 5.1 and PowerShell 7 legs."
fi

print_summary
