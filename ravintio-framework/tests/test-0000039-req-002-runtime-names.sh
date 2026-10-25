#!/usr/bin/env bash
# Verified by: integration
# test-0000039-req-002-runtime-names.sh
# Feature 0000039-ravintio-rebrand, req-002-runtime-names (ADR-004, ADR-010).
# Setup writes only .ravintio-* markers and RAVINTIO blocks. It reads no old
# .planifest-* marker, and it stops while an old pack folder or an old marker
# file exists (P6 change, 2026-10-25).
# Each case builds a scratch consumer repo in a temp folder and never writes in ROOT.
# Run from any directory: bash ravintio-framework/tests/test-0000039-req-002-runtime-names.sh

set -o pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_DIR="$SCRIPT_DIR"
if [ "$(basename "$SCRIPT_DIR")" = "regression" ]; then
  TESTS_DIR="$(dirname "$SCRIPT_DIR")"
fi
source "$TESTS_DIR/helpers/assert.sh"

FW="$(cd "$TESTS_DIR/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export PATH="/opt/homebrew/bin:$PATH"

MIGRATION_ID="migrate-0.37.0-ravintio-rename"
OLD_START="<!-- planifest-overrides:instructions:start -->"
OLD_END="<!-- planifest-overrides:instructions:end -->"
NEW_START="<!-- ravintio-overrides:instructions:start -->"
NEW_END="<!-- ravintio-overrides:instructions:end -->"

# Build a scratch consumer repo with a copy of the pack. Echo its path.
make_repo() {
  local name="$1" repo="$TMP/$1/repo"
  mkdir -p "$repo"
  cp -R "$FW" "$repo/ravintio-framework"
  rm -rf "$repo/ravintio-framework/tests"
  (cd "$repo" && git init -q . >/dev/null 2>&1)
  echo "$repo"
}

# Run setup.sh in a repo, passing any extra arguments as flags. Sets OUT and RC.
run_setup() {
  local repo="$1"
  shift
  OUT="$(cd "$repo" && bash ravintio-framework/setup.sh claude-code "$@" 2>&1)"
  RC=$?
}

# Run setup.ps1 in a repo. Sets OUT and RC.
run_setup_ps1() {
  local repo="$1"
  OUT="$(cd "$repo" && pwsh -NoProfile -File ravintio-framework/setup.ps1 claude-code 2>&1)"
  RC=$?
}

# Count occurrences of a fixed string in a file (0 when the file is missing).
count_in() {
  local needle="$1" file="$2"
  if [ ! -f "$file" ]; then echo 0; return; fi
  grep -cF -- "$needle" "$file" || true
}

# List files under a repo except the pack copy and the git folder.
snapshot() {
  (cd "$1" && find . -path ./ravintio-framework -prune -o -path ./.git -prune -o -print | sort)
}

# AC1 (P6 change): the fixture reads as a repo the migration helper already
# renamed. It holds .ravintio-setup-flags and a .ravintio-manifest that lists
# ravintio-* folders as absolute paths, one per line.
echo "=== req-002 AC1: a helper-migrated repo gets fresh copies and the passed flags ==="
R1="$(make_repo ac1)"
mkdir -p "$R1/.claude/skills/ravintio-orchestrator" "$R1/.claude/skills/ravintio-spec-agent"
echo "# stale copy" > "$R1/.claude/skills/ravintio-orchestrator/SKILL.md"
echo "stale" > "$R1/.claude/skills/ravintio-orchestrator/stale.txt"
echo "stale" > "$R1/.claude/skills/ravintio-spec-agent/stale.txt"
{
  printf '%s\n' "$R1/.claude/skills/ravintio-orchestrator"
  printf '%s\n' "$R1/.claude/skills/ravintio-spec-agent"
} > "$R1/.claude/skills/.ravintio-manifest"
cat > "$R1/.claude/.ravintio-setup-flags" <<'EOF'
{
  "tool": "claude-code",
  "flags": [],
  "writtenAt": "2026-10-01T00:00:00Z",
  "attemptStatus": "completed"
}
EOF
run_setup "$R1" --strict-orchestrator
assert_exit_zero "$RC" "req-002 AC1: setup exits 0 on a helper-migrated repo"
for skill in ravintio-orchestrator ravintio-spec-agent; do
  if [ -f "$R1/.claude/skills/$skill/stale.txt" ]; then STALE="present"; else STALE="gone"; fi
  assert_equals "gone" "$STALE" "req-002 AC1: listed folder $skill holds a fresh copy"
done
assert_equals "0" "$(count_in "# stale copy" "$R1/.claude/skills/ravintio-orchestrator/SKILL.md")" "req-002 AC1: ravintio-orchestrator SKILL.md is the fresh copy"
if [ -f "$R1/.claude/skills/ravintio-orchestrator/SKILL.md" ]; then SKILL_OK="yes"; else SKILL_OK="no"; fi
assert_equals "yes" "$SKILL_OK" "req-002 AC1: ravintio-orchestrator SKILL.md exists"
OLD_LEFT="$(cd "$R1" && find . -path ./ravintio-framework -prune -o -name '.planifest-*' -print)"
assert_equals "" "$OLD_LEFT" "req-002 AC1: no .planifest-* marker is left"
if [ -f "$R1/.claude/.ravintio-setup-flags" ]; then
  FLAGS_BODY="$(cat "$R1/.claude/.ravintio-setup-flags")"
else
  FLAGS_BODY="(missing)"
fi
assert_contains '"--strict-orchestrator"' "$FLAGS_BODY" "req-002 AC1: new flags marker records the passed flag"
if [ -f "$R1/.claude/skills/.ravintio-manifest" ]; then MANIFEST_OK="yes"; else MANIFEST_OK="no"; fi
assert_equals "yes" "$MANIFEST_OK" "req-002 AC1: .ravintio-manifest exists"

# AC new (P6 change): an old marker file in any tool folder stops setup before
# any write. Pinned stop text: "Error: found the old marker file {path}." with
# {path} relative to the project root, in the style of the old-folder stop.
echo "=== req-002 old markers: an old marker file stops setup before any write ==="
OLD_MARKERS=".claude/.planifest-setup-flags .cursor/skills/.planifest-manifest .opencode/.planifest-setup-flags"
_i=0
for marker in $OLD_MARKERS; do
  _i=$((_i + 1))
  RM="$(make_repo "old-marker-$_i")"
  mkdir -p "$RM/$(dirname "$marker")"
  echo '{"flags": []}' > "$RM/$marker"
  BEFORE="$(snapshot "$RM")"
  run_setup "$RM"
  AFTER="$(snapshot "$RM")"
  if [ "$RC" -ne 0 ]; then STOPPED="nonzero"; else STOPPED="zero"; fi
  assert_equals "nonzero" "$STOPPED" "req-002 old markers: setup.sh exits non-zero with $marker present"
  assert_equals "$BEFORE" "$AFTER" "req-002 old markers: setup.sh writes nothing with $marker present"
  assert_contains "Error: found the old marker file $marker." "$OUT" "req-002 old markers: setup.sh names $marker in the stop message"
  assert_contains "$MIGRATION_ID" "$OUT" "req-002 old markers: setup.sh names the migration with $marker present"
done

if command -v pwsh >/dev/null 2>&1; then
  _i=0
  for marker in $OLD_MARKERS; do
    _i=$((_i + 1))
    RMP="$(make_repo "old-marker-ps-$_i")"
    mkdir -p "$RMP/$(dirname "$marker")"
    echo '{"flags": []}' > "$RMP/$marker"
    BEFORE="$(snapshot "$RMP")"
    run_setup_ps1 "$RMP"
    AFTER="$(snapshot "$RMP")"
    if [ "$RC" -ne 0 ]; then STOPPED="nonzero"; else STOPPED="zero"; fi
    assert_equals "nonzero" "$STOPPED" "req-002 old markers: setup.ps1 exits non-zero with $marker present"
    assert_equals "$BEFORE" "$AFTER" "req-002 old markers: setup.ps1 writes nothing with $marker present"
    assert_contains "Error: found the old marker file $marker." "$OUT" "req-002 old markers: setup.ps1 names $marker in the stop message"
    assert_contains "$MIGRATION_ID" "$OUT" "req-002 old markers: setup.ps1 names the migration with $marker present"
  done
else
  echo "  SKIP: req-002 old markers setup.ps1 half, pwsh is not on PATH"
fi

# Setup holds no read of either old marker. The one-time read functions, their
# setup.ps1 variables, and the messages they printed must all be gone.
echo "=== req-002 old markers: setup holds no read of an old marker ==="
for needle in migrate_old_flags_marker migrate_old_manifest "carried old setup flags" "removed old skill"; do
  assert_equals "0" "$(count_in "$needle" "$FW/setup.sh")" "req-002 old markers: setup.sh holds no '$needle'"
done
for needle in oldFlagsPath oldManifest oldFlagsRaw "carried old setup flags" "removed old skill"; do
  assert_equals "0" "$(count_in "$needle" "$FW/setup.ps1")" "req-002 old markers: setup.ps1 holds no '$needle'"
done

echo "=== req-002 AC2: old blocks are replaced once, twice-run stays single ==="
R2="$(make_repo ac2)"
mkdir -p "$R2/ravintio-overrides/instructions"
echo "Local rule for req-002." > "$R2/ravintio-overrides/instructions/local.md"
printf 'Boot text\n%s\nLocal rule for req-002.\n%s\n' "$OLD_START" "$OLD_END" > "$R2/CLAUDE.md"
for f in .claudeignore .cursorignore .windsurfignore .clineignore; do
  printf '# Planifest - Token Reduction (keeps agent semantic search from bloating context)\nplan/_archive/\nnode_modules/\n' > "$R2/$f"
done
printf '# Planifest - Indexing Exclusions (files accessible via @ mention but excluded from search)\n*-guide.md\n' > "$R2/.cursorindexingignore"
run_setup "$R2"
run_setup "$R2"
assert_exit_zero "$RC" "req-002 AC2: second setup run exits 0"
assert_equals "1" "$(count_in "$NEW_START" "$R2/CLAUDE.md")" "req-002 AC2: boot file has one RAVINTIO start marker"
assert_equals "1" "$(count_in "$NEW_END" "$R2/CLAUDE.md")" "req-002 AC2: boot file has one RAVINTIO end marker"
assert_equals "0" "$(count_in "$OLD_START" "$R2/CLAUDE.md")" "req-002 AC2: boot file has no old start marker"
assert_equals "0" "$(count_in "$OLD_END" "$R2/CLAUDE.md")" "req-002 AC2: boot file has no old end marker"
for f in .claudeignore .cursorignore .windsurfignore .clineignore; do
  assert_equals "1" "$(count_in "RAVINTIO - Token Reduction" "$R2/$f")" "req-002 AC2: $f has one RAVINTIO token block"
  assert_equals "0" "$(count_in "Planifest - Token Reduction" "$R2/$f")" "req-002 AC2: $f has no old token header"
done
assert_equals "1" "$(count_in "RAVINTIO - Indexing Exclusions" "$R2/.cursorindexingignore")" "req-002 AC2: .cursorindexingignore has one RAVINTIO block"
assert_equals "0" "$(count_in "Planifest - Indexing Exclusions" "$R2/.cursorindexingignore")" "req-002 AC2: .cursorindexingignore has no old header"

echo "=== req-002 AC3: an old pack folder stops setup before any write ==="
for old in planifest-framework planifest-overrides; do
  R3="$(make_repo "ac3-$old")"
  mkdir -p "$R3/$old"
  echo "old" > "$R3/$old/keep.txt"
  BEFORE="$(snapshot "$R3")"
  run_setup "$R3"
  AFTER="$(snapshot "$R3")"
  if [ "$RC" -ne 0 ]; then STOPPED="nonzero"; else STOPPED="zero"; fi
  assert_equals "nonzero" "$STOPPED" "req-002 AC3: setup.sh exits non-zero with $old present"
  assert_equals "$BEFORE" "$AFTER" "req-002 AC3: setup.sh writes nothing with $old present"
  assert_contains "$MIGRATION_ID" "$OUT" "req-002 AC3: setup.sh names the migration with $old present"
done

if command -v pwsh >/dev/null 2>&1; then
  for old in planifest-framework planifest-overrides; do
    R3P="$(make_repo "ac3p-$old")"
    mkdir -p "$R3P/$old"
    BEFORE="$(snapshot "$R3P")"
    run_setup_ps1 "$R3P"
    AFTER="$(snapshot "$R3P")"
    if [ "$RC" -ne 0 ]; then STOPPED="nonzero"; else STOPPED="zero"; fi
    assert_equals "nonzero" "$STOPPED" "req-002 AC3: setup.ps1 exits non-zero with $old present"
    assert_equals "$BEFORE" "$AFTER" "req-002 AC3: setup.ps1 writes nothing with $old present"
    assert_contains "$MIGRATION_ID" "$OUT" "req-002 AC3: setup.ps1 names the migration with $old present"
  done
else
  echo "  SKIP: req-002 AC3 setup.ps1 half, pwsh is not on PATH"
fi

echo "=== req-002 AC4: a fresh repo gets only RAVINTIO state ==="
R4="$(make_repo ac4)"
run_setup "$R4"
assert_exit_zero "$RC" "req-002 AC4: setup exits 0 on a fresh repo"
if [[ "$OUT" == *"migrate-0.37.0"* ]]; then MSG="printed"; else MSG="absent"; fi
assert_equals "absent" "$MSG" "req-002 AC4: no migration message is printed"
OLD_LEFT="$(cd "$R4" && find . -path ./ravintio-framework -prune -o -name '.planifest-*' -print)"
assert_equals "" "$OLD_LEFT" "req-002 AC4: no .planifest-* marker exists"
NEW_FOUND="$(cd "$R4" && find . -path ./ravintio-framework -prune -o -name '.ravintio-*' -print | sort)"
assert_contains ".claude/.ravintio-setup-flags" "$NEW_FOUND" "req-002 AC4: .ravintio-setup-flags exists"
assert_contains ".claude/skills/.ravintio-manifest" "$NEW_FOUND" "req-002 AC4: .ravintio-manifest exists"
assert_equals "1" "$(count_in "RAVINTIO - Token Reduction" "$R4/.claudeignore")" "req-002 AC4: .claudeignore has one RAVINTIO token block"
assert_equals "0" "$(count_in "Planifest" "$R4/.claudeignore")" "req-002 AC4: .claudeignore has no old name"
assert_equals "1" "$(count_in "RAVINTIO - Indexing Exclusions" "$R4/.cursorindexingignore")" "req-002 AC4: .cursorindexingignore has one RAVINTIO block"

# D-1 (P4 defect, 2026-10-25): setup.sh writes each manifest entry as the real
# skills folder joined with the folder name, as setup.ps1 and the migration
# helper do. A helper rerun after setup then leaves the manifest unchanged,
# which req-006 "A rerun changes nothing" needs.
echo "=== req-002 AC1 (D-1) and req-006 rerun: manifest entries use the real path ==="
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    # Git Bash ln -s copies the folder instead of linking it, so no linked project path can be built.
    echo "  SKIP (windows): ln -s makes a copy under Git Bash, so a linked project path cannot be built"
    ;;
  *)
    RD1="$(make_repo d1)"
    LINK_D1="$TMP/d1/link"
    ln -s "$RD1" "$LINK_D1"
    REAL_SKILLS="$(cd -P "$RD1" && pwd -P)/.claude/skills"
    OUT="$(cd "$LINK_D1" && bash ravintio-framework/setup.sh claude-code 2>&1)" # portable-ok: repo-relative pack path
    RC=$?
    assert_exit_zero "$RC" "req-002 AC1 (D-1): setup exits 0 from a linked project path"
    MAN_D1="$RD1/.claude/skills/.ravintio-manifest"
    if [ -f "$MAN_D1" ]; then MAN_D1_OK="yes"; else MAN_D1_OK="no"; fi
    assert_equals "yes" "$MAN_D1_OK" "req-002 AC1 (D-1): .ravintio-manifest exists"
    BAD_LINES=0
    TOTAL_LINES=0
    if [ -f "$MAN_D1" ]; then
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        TOTAL_LINES=$((TOTAL_LINES + 1))
        case "$line" in
          "$REAL_SKILLS"/*) ;;
          *) BAD_LINES=$((BAD_LINES + 1)) ;;
        esac
      done <<< "$(cat "$MAN_D1")"
    fi
    if [ "$TOTAL_LINES" -gt 0 ]; then HAS_LINES="yes"; else HAS_LINES="no"; fi
    assert_equals "yes" "$HAS_LINES" "req-002 AC1 (D-1): manifest lists at least one entry"
    assert_equals "0" "$BAD_LINES" "req-002 AC1 (D-1): every manifest entry starts with the real skills folder $REAL_SKILLS"
    MAN_COPY="$TMP/d1/manifest.before"
    cp "$MAN_D1" "$MAN_COPY" 2>/dev/null
    OUT="$(cd "$LINK_D1" && bash ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.sh 2>&1)" # portable-ok: repo-relative helper path
    RC=$?
    assert_exit_zero "$RC" "req-006 rerun (D-1): the helper exits 0 after setup"
    if cmp -s "$MAN_COPY" "$MAN_D1"; then SAME="identical"; else SAME="changed"; fi
    assert_equals "identical" "$SAME" "req-006 rerun (D-1): the helper leaves the manifest byte-identical"
    if [[ "$OUT" == *"rewrote the entries"* ]]; then REWROTE="printed"; else REWROTE="absent"; fi
    assert_equals "absent" "$REWROTE" "req-006 rerun (D-1): the helper prints no 'rewrote the entries' line"
    ;;
esac

print_summary
