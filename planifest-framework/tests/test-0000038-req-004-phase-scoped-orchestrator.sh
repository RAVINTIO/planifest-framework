#!/usr/bin/env bash
# Verified by: unit
# test-0000038-req-004-phase-scoped-orchestrator.sh
# req-004: Phase 0 and Adoption Modes move byte for byte into two reference files
# (ADR-002). The orchestrator reads both at P0 and on a resume at P0. SKILL.md
# ends under 41,500 bytes and no longer holds the moved text.
# Run from any directory: bash planifest-framework/tests/test-0000038-req-004-phase-scoped-orchestrator.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_DIR="$SCRIPT_DIR"
if [ "$(basename "$SCRIPT_DIR")" = "regression" ]; then
  TESTS_DIR="$(dirname "$SCRIPT_DIR")"
fi
source "$TESTS_DIR/helpers/assert.sh"

FW="$TESTS_DIR/.."
ORCH_DIR="$FW/skills/planifest-orchestrator"
ORCH="$ORCH_DIR/SKILL.md"
P0_REF="$ORCH_DIR/references/phase-0-assess-and-coach.md"
AM_REF="$ORCH_DIR/references/adoption-modes.md"
BASE_BLOB="5966840:planifest-framework/skills/planifest-orchestrator/SKILL.md"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

echo "=== req-004: reference files exist ==="
assert_equals "yes" "$([ -f "$P0_REF" ] && echo yes || echo no)" "req-004: phase-0-assess-and-coach.md exists"
assert_equals "yes" "$([ -f "$AM_REF" ] && echo yes || echo no)" "req-004: adoption-modes.md exists"

echo ""
echo "=== req-004: moved blocks match the 5966840 blob byte for byte ==="
git -C "$FW" show "$BASE_BLOB" 2>/dev/null | sed -n '239,588p' > "$TMP/p0.base"
git -C "$FW" show "$BASE_BLOB" 2>/dev/null | sed -n '768,818p' > "$TMP/am.base"
assert_equals "yes" "$([ -s "$TMP/p0.base" ] && [ -s "$TMP/am.base" ] && echo yes || echo no)" \
  "req-004: baseline blob 5966840 is readable"
[ -f "$P0_REF" ] && sed -n '/^## Phase 0 - Assess and Coach$/,$p' "$P0_REF" > "$TMP/p0.new" || : > "$TMP/p0.new"
[ -f "$AM_REF" ] && sed -n '/^## Adoption Modes$/,$p' "$AM_REF" > "$TMP/am.new" || : > "$TMP/am.new"
assert_equals "same" "$(cmp -s "$TMP/p0.base" "$TMP/p0.new" && echo same || echo different)" \
  "req-004: Phase 0 block is byte-identical to lines 239-588 of the baseline"
assert_equals "same" "$(cmp -s "$TMP/am.base" "$TMP/am.new" && echo same || echo different)" \
  "req-004: Adoption Modes block is byte-identical to lines 768-818 of the baseline"
assert_contains "planifest-orchestrator/SKILL.md" "$(head -12 "$P0_REF" 2>/dev/null)" \
  "req-004: Phase 0 file names SKILL.md as its owner"
assert_contains "planifest-orchestrator/SKILL.md" "$(head -12 "$AM_REF" 2>/dev/null)" \
  "req-004: Adoption Modes file names SKILL.md as its owner"

echo ""
echo "=== req-004: SKILL.md lacks the moved text, the reference files hold it ==="
SKILL_TEXT=$(cat "$ORCH")
P0_TEXT=$(cat "$P0_REF" 2>/dev/null)
AM_TEXT=$(cat "$AM_REF" 2>/dev/null)
for s in '## Phase 0 - Assess and Coach' '### Phase 0 Start Actions' '### Phase 0 → Phase 1 Gate Checklist'; do
  lacks "$s" "$SKILL_TEXT" "req-004: SKILL.md lacks '$s'"
  assert_contains "$s" "$P0_TEXT" "req-004: Phase 0 file holds '$s'"
done
for s in '## Adoption Modes' 'The coaching conversation in Phase 0 and the pipeline phases are the same regardless of mode'; do
  lacks "$s" "$SKILL_TEXT" "req-004: SKILL.md lacks '$s'"
  assert_contains "$s" "$AM_TEXT" "req-004: Adoption Modes file holds '$s'"
done

echo ""
echo "=== req-004: Framework Index, P0 load, and gate check ==="
INDEX=$(awk '/^## Framework Index/{f=1; next} f && /^## /{exit} f' "$ORCH")
assert_contains "references/phase-0-assess-and-coach.md" "$INDEX" "req-004: Framework Index lists the Phase 0 file"
assert_contains "references/adoption-modes.md" "$INDEX" "req-004: Framework Index lists the Adoption Modes file"

POINTER=$(awk '/^## Phase 0 and Adoption Modes \(reference files\)/{f=1; print; next} f && /^## /{exit} f' "$ORCH")
assert_contains "## Phase 0 and Adoption Modes (reference files)" "$POINTER" "req-004: pointer section exists"
assert_contains "./references/phase-0-assess-and-coach.md" "$POINTER" "req-004: pointer links the Phase 0 file"
assert_contains "./references/adoption-modes.md" "$POINTER" "req-004: pointer links the Adoption Modes file"
assert_contains "start of P0" "$POINTER" "req-004: pointer loads both files at the start of P0"
assert_contains "P0 references loaded: {paths}" "$POINTER" "req-004: pointer writes the build-log line"
assert_contains "P0 to P1 gate" "$POINTER" "req-004: pointer checks the log line before the P0 to P1 gate"

echo ""
echo "=== req-004: Resume Detection reloads at P0 ==="
RESUME=$(awk '/^## Resume Detection/{f=1; next} f && /^## /{exit} f' "$ORCH")
assert_contains "still at P0" "$RESUME" "req-004: Resume Detection covers a run still at P0"
assert_contains "phase-0-assess-and-coach.md" "$RESUME" "req-004: Resume Detection reloads the Phase 0 file"
assert_contains "adoption-modes.md" "$RESUME" "req-004: Resume Detection reloads the Adoption Modes file"

echo ""
echo "=== req-004: size (NFR-002) ==="
SIZE=$(wc -c < "$ORCH" | tr -d ' ')
assert_equals "under" "$([ "$SIZE" -lt 41500 ] && echo under || echo over)" \
  "req-004: SKILL.md is under 41,500 bytes (now $SIZE)"

print_summary
