#!/usr/bin/env bash
# Verified by: integration
# test-0000039-req-002-runtime-names.sh
# Feature 0000039-ravintio-rebrand, req-002-runtime-names (ADR-004, ADR-010).
# Setup writes only .ravintio-* markers and RAVINTIO blocks, reads the old
# .planifest-* state once, and stops while an old pack folder exists.
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

# Run setup.sh in a repo. Sets OUT and RC.
run_setup() {
  local repo="$1"
  OUT="$(cd "$repo" && bash ravintio-framework/setup.sh claude-code 2>&1)"
  RC=$?
}

# Count occurrences of a fixed string in a file (0 when the file is missing).
count_in() {
  local needle="$1" file="$2"
  if [ ! -f "$file" ]; then echo 0; return; fi
  grep -cF -- "$needle" "$file" || true
}

# List files under a repo except the pack copy, the git folder, and the skills folder.
snapshot() {
  (cd "$1" && find . -path ./ravintio-framework -prune -o -path ./.git -prune -o -print | sort)
}

echo "=== req-002 AC1: old markers are carried into .ravintio-* and removed ==="
R1="$(make_repo ac1)"
mkdir -p "$R1/.claude/skills/planifest-orchestrator"
echo "# old skill" > "$R1/.claude/skills/planifest-orchestrator/SKILL.md"
printf '%s\n' "$R1/.claude/skills/planifest-orchestrator" > "$R1/.claude/skills/.planifest-manifest"
cat > "$R1/.claude/.planifest-setup-flags" <<'EOF'
{
  "tool": "claude-code",
  "flags": ["--strict-orchestrator"],
  "writtenAt": "2026-10-01T00:00:00Z",
  "attemptStatus": "completed"
}
EOF
run_setup "$R1"
assert_exit_zero "$RC" "req-002 AC1: setup exits 0 on a repo with old markers"
OLD_LEFT="$(cd "$R1" && find . -path ./ravintio-framework -prune -o -name '.planifest-*' -print)"
assert_equals "" "$OLD_LEFT" "req-002 AC1: no .planifest-* marker is left"
if [ -f "$R1/.claude/.ravintio-setup-flags" ]; then
  FLAGS_BODY="$(cat "$R1/.claude/.ravintio-setup-flags")"
else
  FLAGS_BODY="(missing)"
fi
assert_contains "--strict-orchestrator" "$FLAGS_BODY" "req-002 AC1: new flags marker holds the old flag"
if [ -f "$R1/.claude/skills/.ravintio-manifest" ]; then
  MANIFEST_OK="yes"
else
  MANIFEST_OK="no"
fi
assert_equals "yes" "$MANIFEST_OK" "req-002 AC1: .ravintio-manifest exists"
if [ -d "$R1/.claude/skills/planifest-orchestrator" ]; then
  OLD_SKILL="present"
else
  OLD_SKILL="gone"
fi
assert_equals "gone" "$OLD_SKILL" "req-002 AC1: old installed skill folder is gone"

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
    OUT="$(cd "$R3P" && pwsh -NoProfile -File ravintio-framework/setup.ps1 claude-code 2>&1)"
    RC=$?
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

print_summary
