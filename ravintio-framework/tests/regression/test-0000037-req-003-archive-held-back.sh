#!/usr/bin/env bash
# Tests for feature 0000037-green-ci-before-ship.
#
# req-003 (P5 re-review 2 N-07 and N-08, re-review 3 N-09 to N-11): the script
#          decides which paths a commit may name. scan-then-commit passes the
#          safe list to git with --pathspec-from-file. A held-back file, tracked
#          or not, never reaches a commit.
#
# Verified by: integration
# REGRESSION-CANDIDATE: covers scan-then-commit over fixtures and a real archive run, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../helpers/assert.sh"

FW="$SCRIPT_DIR/../.."
SCAN="$FW/scripts/credential-scan.mjs"
ARCHIVE="$FW/scripts/archive-current.mjs"
STD="$FW/standards/autonomous-run-standards.md"
SHIP="$FW/skills/ravintio-ship-agent/SKILL.md"

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

echo "req-003: the standard defines scan-then-commit with the safe-paths mode"
PCS="$(awk 'index($0, "## Pre-commit credential scan") == 1 { on = 1; print; next } on && /^## / { exit } on { print }' "$STD")"
STC="$(step '### Scan-then-commit' "$STD")"
assert_contains "### Scan-then-commit" "$PCS" "req-003: the standard names the procedure"
assert_contains "Build the candidate list." "$STC" "req-003: step 1 builds the candidate list"
assert_contains "git diff --cached --name-only --no-renames -z" "$STC" "req-003: an index-based step lists both sides of a rename"
assert_contains "--safe-paths" "$STC" "req-003: step 2 runs the safe-paths mode"
assert_contains "On exit \`2\`, commit nothing" "$STC" "req-003: step 3 stops on exit 2"
assert_contains "exception item 7" "$STC" "req-003: step 3 stops under exception item 7"
assert_contains "Credential scan (P{N}): held back {path}" "$STC" "req-003: step 4 logs each held-back path"
assert_contains "Exception waiting (P{N}, 7)" "$STC" "req-003: step 4 logs the exception"
assert_contains "git restore --staged -- {path}" "$STC" "req-003: step 4 unstages a staged new file"
assert_contains "git rm --cached -- {path}" "$STC" "req-003: step 4 handles a repository with no commit"
assert_contains "tracked held-back file needs no unstage" "$STC" "req-003: step 4 leaves a tracked file alone"
assert_contains "If the out-file is empty, skip the commit." "$STC" "req-003: step 5 skips the commit on an empty list"
assert_contains "--pathspec-from-file" "$STC" "req-003: step 6 commits from the safe list"
assert_contains "--pathspec-file-nul" "$STC" "req-003: step 6 reads the safe list as NUL-separated"
assert_contains "git --literal-pathspecs commit" "$STC" "req-003 N-12: step 6 commits with literal pathspecs"
assert_contains "git --literal-pathspecs add" "$STC" "req-003 N-12: step 6 stages with literal pathspecs"
assert_contains "git --literal-pathspecs restore --staged -- {path}" "$STC" "req-003 N-12: step 4 unstages with literal pathspecs"
assert_contains "git --literal-pathspecs rm --cached -- {path}" "$STC" "req-003 N-12: step 4 handles no-commit with literal pathspecs"
assert_contains "glob" "$STC" "req-003 N-12: the standard gives the reason in one sentence"
assert_contains "other than \`0\` or \`1\`" "$STC" "req-003 N-14: any other scan exit counts as exit 2"
assert_contains "\`126\`" "$STC" "req-003 N-14: the example is exit 126"
assert_contains "mktemp -d" "$STC" "req-003 N-14: the out-file sits in a fresh mktemp -d folder"
assert_contains "outside the repository" "$STC" "req-003 N-14: the out-file sits outside the repository"
assert_contains "Remove the folder" "$STC" "req-003 N-14: the folder is removed after the commit or the skip"
lacks "Then scan again" "$STC" "req-003: the rescan loop is gone"
lacks "Unstage it once" "$STC" "req-003: the unstage-once text is gone"
assert_contains "no \`git commit\` and no \`git push\`" "$PCS" "req-003: the standard keeps the hold-back phrase"

echo "req-003: each close-out commit cites scan-then-commit and the safe list"
for h in '### Step 7' '### P8: Clean-tree check' '### P9 marker step' '### Step 10b' '### Step 10c' '### Step 11'; do
  B="$(step "$h" "$SHIP")"
  assert_contains "scan-then-commit" "$B" "req-003: $h cites scan-then-commit"
  assert_contains "--pathspec-from-file" "$B" "req-003: $h commits from the safe list"
  assert_contains "git --literal-pathspecs commit" "$B" "req-003 N-12: $h commits with literal pathspecs"
  # Every autonomous add or commit that reads the safe list is literal.
  assert_equals "0" "$(grep -E 'git (add|commit) .*--pathspec-from-file' <<<"$B" | grep -c -v -F 'git --literal-pathspecs')" "req-003 N-12: $h has no non-literal safe-list command"
done
P9B="$(step '### P9 marker step' "$SHIP")"
RMFIRST="$(grep -n -F 'rm -f plan/.orchestrator-active' <<<"$P9B" | head -1 | cut -d: -f1)"
assert_equals "#" "$(sed -n "$((RMFIRST + 2))p" <<<"$P9B" | cut -c1)" "req-003 N-13: the old path-list line in the block is a comment"
assert_contains "interactive and continuous reference" "$(sed -n "$((RMFIRST + 2))p" <<<"$P9B")" "req-003 N-13: the old path-list commit is labelled for interactive and continuous"
assert_contains "git --literal-pathspecs commit --pathspec-from-file=" "$(sed -n "$((RMFIRST + 3))p" <<<"$P9B")" "req-003 N-13: the command the block runs is the autonomous commit"
assert_equals "0" "$(sed -n "$((RMFIRST + 1)),\$p" <<<"$P9B" | grep -v '^#' | grep -c -F 'git ls-tree --name-only HEAD --')" "req-003 N-13: no executable line holds the old path-list form"
assert_contains "git --literal-pathspecs restore --staged -- {path}" "$P9B" "req-003 N-12: the marker step unstages with literal pathspecs"
assert_contains "git --literal-pathspecs restore --staged -- {path}" "$(step '### Step 7' "$SHIP")" "req-003 N-12: Step 7 unstages with literal pathspecs"
assert_contains "git --literal-pathspecs add" "$(step '### P8: Clean-tree check' "$SHIP")" "req-003 N-12: the P8 guard stages with literal pathspecs"
STEP7="$(step '### Step 7' "$SHIP")"
lacks "{held-back-path}" "$STEP7" "req-003: Step 7 no longer unstages the old plan/current/ path"
assert_contains "--safe-paths" "$STEP7" "req-003: Step 7 runs the safe-paths mode"
assert_contains "git diff --cached --name-only --no-renames -z" "$STEP7" "req-003: Step 7 lists both sides of a rename"
P8B="$(step '### P8: Clean-tree check' "$SHIP")"
assert_contains "staged" "$P8B" "req-003: the P8 guard unstages only staged paths (N-10)"
assert_contains "unstages only" "$P8B" "req-003: the P8 guard unstages only a path that is staged (N-10)"
assert_contains "not staged" "$P8B" "req-003: the P8 guard names the untracked, unstaged case (N-10)"

# --- the procedure, as a function the fixtures share --------------------------------

# scan_then_commit <repo> <message> [stage] <candidate>...
# Follows the standard step by step. Sets SOUT, SRC, and HELD (one parsed path per line).
# Returns 0 after a commit, 2 after a scan exit 2, 3 after an empty safe list.
# When the third argument is `stage`, the candidates are not yet staged, so it adds
# the safe list before the commit.
scan_then_commit() {
  local repo="$1" msg="$2" stage=no p
  shift 2
  if [ "${1:-}" = "stage" ]; then stage=yes; shift; fi
  local outf="$WORK/safe.$$.$RANDOM"
  SOUT="$(cd "$repo" && node "$SCAN" --safe-paths "$outf" -- "$@" 2>&1)"
  SRC=$?
  if [ "$SRC" -eq 2 ]; then return 2; fi
  HELD="$(printf '%s\n' "$SOUT" | grep -v '^scan mode:' | sed -E 's/:[0-9]+ [^ ]+$//' | sort -u)"
  if [ "$SRC" -eq 1 ]; then
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      # Unstage only a path that is staged as a new file. A tracked file needs no unstage.
      if (cd "$repo" && git --literal-pathspecs ls-files --error-unmatch -- "$p" >/dev/null 2>&1) \
         && ! (cd "$repo" && git cat-file -e "HEAD:$p" 2>/dev/null); then
        if (cd "$repo" && git rev-parse --verify -q HEAD >/dev/null); then
          (cd "$repo" && git --literal-pathspecs restore --staged -- "$p")
        else
          (cd "$repo" && git --literal-pathspecs rm -q --cached -- "$p")
        fi
      fi
    done <<<"$HELD"
  fi
  if [ ! -s "$outf" ]; then return 3; fi
  if [ "$stage" = "yes" ]; then
    (cd "$repo" && git --literal-pathspecs add --pathspec-from-file="$outf" --pathspec-file-nul) || return 4
  fi
  (cd "$repo" && git --literal-pathspecs commit -q -m "$msg" -m "0000001-x" --pathspec-from-file="$outf" --pathspec-file-nul) || return 5
  return 0
}

# new_repo <name> [no-commit]: a repository with identity, and one commit unless told otherwise.
new_repo() {
  local d="$WORK/$1"
  mkdir -p "$d"
  (
    cd "$d" || exit 1
    git init -q
    git config user.email t@example.invalid
    git config user.name t
    git config commit.gpgsign false
    if [ "${2:-}" != "no-commit" ]; then
      printf 'init\n' >README.md
      git add README.md
      git commit -q -m init
    fi
  )
  printf '%s' "$d"
}

head_of() { (cd "$1" && git rev-parse -q --verify HEAD 2>/dev/null || echo none); }

# no_key_in_history <repo> <label>: no commit on any ref holds the key file or the secret.
no_key_in_history() {
  local names patch
  names="$(cd "$1" && git log --all --name-only --format= 2>/dev/null)"
  patch="$(cd "$1" && git log --all -p 2>/dev/null)"
  lacks "$SECRET" "$patch" "$2: no commit holds the secret text"
  lacks "$3" "$names" "$2: no commit lists the held-back path"
}

echo "req-003: a real archive run, then scan-then-commit over the index"
R="$(new_repo archive)"
mkdir -p "$R/plan/current/requirements"
(
  cd "$R" || exit 1
  printf 'design\n' >plan/current/design.md
  printf 'req\n' >plan/current/requirements/req-001.md
  printf 'on\n' >plan/.orchestrator-active
  git add plan
  git commit -q -m tracked
  printf 'key=%s\n' "$SECRET" >plan/current/.env.local
)
AOUT="$(cd "$R" && node "$ARCHIVE" --feature-id 0000001-x --date 2026-01-01 --root "$R" 2>&1)"
ARC=$?
assert_equals "0" "$ARC" "req-003: archive-current.mjs exits 0"
ADIR="plan/_archive/0000001-x-2026-01-01"
assert_contains "archive-dir: $ADIR" "$AOUT" "req-003: the script prints the archive directory"
assert_contains "$ADIR/.env.local" "$AOUT" "req-003: the script moved the held-back file"

# Step 1: stage, then list the candidates with both sides of each rename.
(cd "$R" && git add plan/current/ plan/_archive/)
CANDS=()
while IFS= read -r -d '' p; do CANDS+=("$p"); done < <(cd "$R" && git diff --cached --name-only --no-renames -z)
assert_contains "plan/current/design.md" "$(printf '%s\n' "${CANDS[@]}")" "req-003: the candidate list holds the old path of a rename"
assert_contains "$ADIR/design.md" "$(printf '%s\n' "${CANDS[@]}")" "req-003: the candidate list holds the new path of a rename"
scan_then_commit "$R" "plan(p7): archive plan/current" "${CANDS[@]}"
assert_equals "0" "$?" "req-003: the P7 commit succeeds"
assert_equals "1" "$SRC" "req-003: the scan exits 1 over the staged archive"
assert_equals "$ADIR/.env.local" "$HELD" "req-003: the scan names the archive path of the key file"
lacks "$SECRET" "$SOUT" "req-003: the scan output prints no secret"
HEADFILES="$(cd "$R" && git ls-tree -r --name-only HEAD)"
assert_contains "$ADIR/design.md" "$HEADFILES" "req-003: the commit holds the clean design file"
assert_contains "$ADIR/requirements/req-001.md" "$HEADFILES" "req-003: the commit holds the clean requirement file"
lacks "plan/current/design.md" "$HEADFILES" "req-003: the commit deleted the old design path"
lacks ".env.local" "$HEADFILES" "req-003: the commit omits the key file"
assert_equals "yes" "$([ -f "$R/$ADIR/.env.local" ] && echo yes || echo no)" "req-003: the key file stays in the working tree"
assert_equals "" "$(cd "$R" && git diff --cached --name-only)" "req-003: nothing is left staged after the P7 commit"

echo "req-003: the marker step stages the directory again, and the key file is held back again"
printf 'log\n' >"$R/$ADIR/build-log.md"
(cd "$R" && git add -- "$ADIR")
MCANDS=()
while IFS= read -r -d '' p; do MCANDS+=("$p"); done < <(cd "$R" && git diff --cached --name-only --no-renames -z -- "$ADIR")
while IFS= read -r -d '' p; do MCANDS+=("$p"); done < <(cd "$R" && git ls-tree --name-only -z HEAD -- plan/.orchestrator-active plan/.orchestrator-ack plan/.run-mode)
rm -f "$R/plan/.orchestrator-active"
(cd "$R" && git rm --cached --ignore-unmatch -q plan/.orchestrator-active)
scan_then_commit "$R" "plan(p9): clear session markers" "${MCANDS[@]}"
assert_equals "0" "$?" "req-003: the marker commit succeeds"
assert_equals "$ADIR/.env.local" "$HELD" "req-003: the marker step holds the key file back again"
MLOG="$(cd "$R" && git show --name-status --format= HEAD)"
assert_contains "$ADIR/build-log.md" "$MLOG" "req-003: the marker commit holds the clean log"
assert_contains "plan/.orchestrator-active" "$MLOG" "req-003: the marker commit deletes the marker"
lacks ".env.local" "$MLOG" "req-003: the marker commit omits the key file"
no_key_in_history "$R" "req-003: archive run" ".env.local"
assert_equals "yes" "$([ -f "$R/$ADIR/.env.local" ] && echo yes || echo no)" "req-003: the key file still sits in the working tree"

echo "req-003: a tracked held-back src/app.js stays out of a fix-attempt commit (N-09)"
R="$(new_repo fixattempt)"
mkdir -p "$R/src"
printf 'const a = 1;\n' >"$R/src/app.js"
printf 'const b = 1;\n' >"$R/src/ok.js"
(cd "$R" && git add src && git commit -q -m "add src")
printf 'const a = 1;\nconst k = "%s";\n' "$SECRET" >"$R/src/app.js"
printf 'const b = 2;\n' >"$R/src/ok.js"
CANDS=()
while IFS= read -r -d '' p; do CANDS+=("$p"); done < <(cd "$R" && git diff --name-only -z)
scan_then_commit "$R" "fix(p9): repair the failing check" "${CANDS[@]}"
assert_equals "0" "$?" "req-003: the fix-attempt commit succeeds"
assert_equals "src/app.js" "$HELD" "req-003: the scan names src/app.js as held back"
assert_equals "src/ok.js" "$(cd "$R" && git show --name-only --format= HEAD)" "req-003: the commit names only the safe file"
assert_equals "const a = 1;" "$(cd "$R" && git show HEAD:src/app.js)" "req-003: HEAD holds the old src/app.js, not the key"
assert_equals "const b = 2;" "$(cd "$R" && git show HEAD:src/ok.js)" "req-003: HEAD holds the new src/ok.js"
assert_contains "$SECRET" "$(cat "$R/src/app.js")" "req-003: the key stays in the working-tree copy"
no_key_in_history "$R" "req-003: fix attempt" "zz-no-such-path"

echo "req-003: a held-back docs/ file (tracked) and a held-back staged new docs/ file"
R="$(new_repo docsfiles)"
mkdir -p "$R/docs"
printf 'guide\n' >"$R/docs/guide.md"
(cd "$R" && git add docs && git commit -q -m "add docs")
printf 'guide\nkey=%s\n' "$SECRET" >"$R/docs/guide.md"
printf 'fresh\n' >"$R/docs/new.md"
printf 'key=%s\n' "$SECRET" >"$R/docs/leak.md"
(cd "$R" && git add docs/new.md docs/leak.md)
scan_then_commit "$R" "docs(p9): update docs" docs/guide.md docs/new.md docs/leak.md
assert_equals "0" "$?" "req-003: the docs commit succeeds"
assert_equals "$(printf 'docs/guide.md\ndocs/leak.md')" "$HELD" "req-003: both held-back docs paths are parsed from the scan output"
assert_equals "docs/new.md" "$(cd "$R" && git show --name-only --format= HEAD)" "req-003: the commit names only the clean docs file"
assert_equals "" "$(cd "$R" && git diff --cached --name-only)" "req-003: the new held-back docs file left the index"
assert_contains "?? docs/leak.md" "$(cd "$R" && git status --porcelain)" "req-003: the held-back new file is untracked again"
no_key_in_history "$R" "req-003: docs" "leak.md"

echo "req-003: two held-back files in one commit"
R="$(new_repo twoheld)"
mkdir -p "$R/docs"
printf 'a\n' >"$R/docs/ok.md"
printf 'key=%s\n' "$SECRET" >"$R/docs/one.md"
printf 'x\n' >"$R/docs/.env"
(cd "$R" && git add -f docs)
scan_then_commit "$R" "docs(p8): commit close-out leftovers" docs/ok.md docs/one.md docs/.env
assert_equals "0" "$?" "req-003: the two-held-back commit succeeds"
assert_equals "$(printf 'docs/.env\ndocs/one.md')" "$HELD" "req-003: both held-back paths come from the scan output"
assert_equals "docs/ok.md" "$(cd "$R" && git show --name-only --format= HEAD)" "req-003: the commit names only the clean file"
assert_equals "" "$(cd "$R" && git diff --cached --name-only)" "req-003: neither held-back file stays staged"
no_key_in_history "$R" "req-003: two held back" "docs/.env"

echo "req-003: a repository with no commit (git rm --cached path)"
R="$(new_repo nocommit no-commit)"
printf 'clean\n' >"$R/clean.txt"
printf 'key=%s\n' "$SECRET" >"$R/leak.txt"
(cd "$R" && git add clean.txt leak.txt)
assert_equals "none" "$(head_of "$R")" "req-003: the fixture repository has no commit"
scan_then_commit "$R" "docs(p8): first commit" clean.txt leak.txt
assert_equals "0" "$?" "req-003: the first commit succeeds"
assert_equals "leak.txt" "$HELD" "req-003: the held-back path comes from the scan output"
assert_equals "clean.txt" "$(cd "$R" && git show --name-only --format= HEAD)" "req-003: the root commit names only the clean file"
assert_equals "" "$(cd "$R" && git ls-files --cached | grep leak.txt)" "req-003: the held-back file left the index"
no_key_in_history "$R" "req-003: no commit" "leak.txt"

echo "req-003: an unstaged, untracked held-back file needs no unstage (N-10)"
R="$(new_repo unstaged)"
mkdir -p "$R/docs"
printf 'ok\n' >"$R/docs/ok.md"
printf 'key=%s\n' "$SECRET" >"$R/docs/.env.local"
(cd "$R" && git restore --staged -- docs/.env.local >/dev/null 2>&1)
assert_equals "nonzero" "$([ $? -eq 0 ] && echo zero || echo nonzero)" "req-003: restoring an untracked, unstaged file fails"
scan_then_commit "$R" "docs(p8): commit close-out leftovers" stage docs/ok.md docs/.env.local
assert_equals "0" "$?" "req-003: the leftover commit succeeds without a restore"
assert_equals "docs/.env.local" "$HELD" "req-003: the unstaged key file is parsed as held back"
assert_equals "docs/ok.md" "$(cd "$R" && git show --name-only --format= HEAD)" "req-003: the commit names only the clean leftover"
assert_contains "?? docs/.env.local" "$(cd "$R" && git status --porcelain --untracked-files=all)" "req-003: the key file stays untracked"
no_key_in_history "$R" "req-003: unstaged" ".env.local"

IS_WIN=no
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) IS_WIN=yes ;; esac

# key_fragments <repo> <rev:path>: counts lines of a committed file that hold part of the key.
# It prints a number only, never the key.
key_fragments() { (cd "$1" && git show "$2" 2>/dev/null | grep -c -F "${SECRET:4:8}"); }

# glob_fixture <label> <held-back tracked name> <safe untracked name>
# The safe name is a glob that also matches the held-back tracked file (N-12).
glob_fixture() {
  local label="$1" held="$2" safe="$3"
  R="$(new_repo "$label")"
  printf 'const h = 1;\n' >"$R/$held"
  (cd "$R" && git add -- "$held" && git commit -q -m "add held")
  printf 'const h = 1;\nconst k = "%s";\n' "$SECRET" >"$R/$held"
  printf 'const s = 1;\n' >"$R/$safe"
  CANDS=("$held" "$safe")
  scan_then_commit "$R" "fix(p9): glob names" stage "${CANDS[@]}"
  assert_equals "0" "$?" "req-003 N-12: the $label commit succeeds"
  assert_equals "$held" "$HELD" "req-003 N-12: the scan holds back $held"
  assert_equals "$safe" "$(cd "$R" && git show --name-only --format= HEAD)" "req-003 N-12: the $label commit names only $safe"
  assert_equals "0" "$(key_fragments "$R" "HEAD:$held")" "req-003 N-12: HEAD:$held holds no key"
  assert_equals "0" "$(cd "$R" && git log --all -p | grep -c -F "${SECRET:4:8}")" "req-003 N-12: no commit in the $label history holds a key fragment"
  assert_contains "$SECRET" "$(cat "$R/$held")" "req-003 N-12: the key stays in the working-tree copy of $held"
}

echo "req-003 N-12: a safe glob name must not commit a held-back tracked file"
if [ "$IS_WIN" = "yes" ]; then
  echo "  SKIP (windows): a Windows file name cannot hold an asterisk, so the a*.js fixture cannot be built"
else
  glob_fixture globstar ab.js 'a*.js'
fi
glob_fixture globbracket pagesi.js 'pages[id].js'

echo "req-003: a scan exit 2 commits nothing"
R="$(new_repo scanerr)"
mkdir -p "$R/adir"
printf 'x\n' >"$R/adir/f.txt"
printf 'ok\n' >"$R/ok.txt"
(cd "$R" && git add ok.txt)
BEFORE="$(head_of "$R")"
scan_then_commit "$R" "docs(p9): never" ok.txt adir
assert_equals "2" "$?" "req-003: the procedure stops on scan exit 2"
assert_equals "2" "$SRC" "req-003: the scan exits 2 for a path it cannot read"
assert_equals "$BEFORE" "$(head_of "$R")" "req-003: no commit was made after exit 2"
assert_equals "ok.txt" "$(cd "$R" && git diff --cached --name-only)" "req-003: the index is untouched after exit 2"

echo "req-003: an empty safe list commits nothing"
R="$(new_repo emptysafe)"
printf 'clean\n' >"$R/other.txt"
printf 'key=%s\n' "$SECRET" >"$R/only.txt"
(cd "$R" && git add other.txt only.txt)
BEFORE="$(head_of "$R")"
scan_then_commit "$R" "docs(p9): never" only.txt
assert_equals "3" "$?" "req-003: the procedure skips the commit on an empty safe list"
assert_equals "$BEFORE" "$(head_of "$R")" "req-003: an empty safe list made no commit, so git did not commit the whole index"
assert_equals "other.txt" "$(cd "$R" && git diff --cached --name-only)" "req-003: the unrelated staged file stays staged"

echo "req-003: every pathspec commit line guards an empty safe list (P5 N-15)"
# An empty pathspec file makes git commit the whole index, so each command
# line repeats the step 5 skip with [ -s "{out-file}" ].
UNGUARDED="$(cat "$SHIP" "$STD" | grep -F 'git --literal-pathspecs commit' | grep -F -- '--pathspec-from-file' | grep -c -v -F '[ -s "{out-file}" ] &&')"
assert_equals "0" "$UNGUARDED" "req-003: no pathspec commit line lacks the empty-list guard"
GUARDED="$(cat "$SHIP" "$STD" | grep -c -F '[ -s "{out-file}" ] && git --literal-pathspecs commit')"
assert_equals "yes" "$([ "$GUARDED" -ge 8 ] && echo yes || echo no)" "req-003: the guard sits on all eight pathspec commit lines"

print_summary
