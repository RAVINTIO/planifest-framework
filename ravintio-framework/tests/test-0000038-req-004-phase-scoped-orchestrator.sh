#!/usr/bin/env bash
# Verified by: unit
# test-0000038-req-004-phase-scoped-orchestrator.sh
# req-004: Phase 0 and Adoption Modes move byte for byte into two reference files
# (ADR-002). The orchestrator reads both at P0 and on a resume at P0. SKILL.md
# ends under 41,500 bytes and no longer holds the moved text.
# Run from any directory: bash ravintio-framework/tests/test-0000038-req-004-phase-scoped-orchestrator.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_DIR="$SCRIPT_DIR"
if [ "$(basename "$SCRIPT_DIR")" = "regression" ]; then
  TESTS_DIR="$(dirname "$SCRIPT_DIR")"
fi
source "$TESTS_DIR/helpers/assert.sh"

FW="$TESTS_DIR/.."
ORCH_DIR="$FW/skills/ravintio-orchestrator"
ORCH="$ORCH_DIR/SKILL.md"
P0_REF="$ORCH_DIR/references/phase-0-assess-and-coach.md"
AM_REF="$ORCH_DIR/references/adoption-modes.md"
# SHA-256 of lines 239-588 and 768-818 of SKILL.md at commit 5966840. A shallow
# clone or a squash merge drops that commit, so the test keeps its hashes.
# Feature 0000039 (RAVINTIO rebrand) renamed the brand words inside both blocks.
# The hashes below are of the same blocks after that scripted pass. The only
# change from the 5966840 text is the brand words.
BASE_P0_SHA="b677d17f9cceea112bfc7cc98c7a2d05acb29318fdc2ffda9b51dad73252c063"
BASE_AM_SHA="e6c2e73f419dfc72877d50407fcc1671f63b85d3cc58bfca1c1a64b42de47dc8"

# sha256_of <file>: prints the file's SHA-256 in hex, or nothing if unreadable.
sha256_of() {
  node -e "process.stdout.write(require('crypto').createHash('sha256').update(require('fs').readFileSync(process.argv[1])).digest('hex'))" "$1" 2>/dev/null
}

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
[ -f "$P0_REF" ] && sed -n '/^## Phase 0 - Assess and Coach$/,$p' "$P0_REF" > "$TMP/p0.new" || : > "$TMP/p0.new"
[ -f "$AM_REF" ] && sed -n '/^## Adoption Modes$/,$p' "$AM_REF" > "$TMP/am.new" || : > "$TMP/am.new"
assert_equals "$BASE_P0_SHA" "$(sha256_of "$TMP/p0.new")" \
  "req-004: Phase 0 block is byte-identical to lines 239-588 of the baseline"
assert_equals "$BASE_AM_SHA" "$(sha256_of "$TMP/am.new")" \
  "req-004: Adoption Modes block is byte-identical to lines 768-818 of the baseline"
assert_contains "ravintio-orchestrator/SKILL.md" "$(head -12 "$P0_REF" 2>/dev/null)" \
  "req-004: Phase 0 file names SKILL.md as its owner"
assert_contains "ravintio-orchestrator/SKILL.md" "$(head -12 "$AM_REF" 2>/dev/null)" \
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
echo "=== req-004: rules that apply after P0 stay reachable ==="
lacks "Load neither file after P0" "$POINTER" "req-004: pointer no longer bars every later read"
assert_contains "At every phase transition and before P3" "$POINTER" "req-004: pointer re-reads Capability Skills at each transition and before P3"
assert_contains '`### Capability Skills`' "$POINTER" "req-004: pointer names the Capability Skills section"
assert_contains "skills-inbox check" "$POINTER" "req-004: pointer names the skills-inbox check"
assert_contains '`### How you coach`' "$POINTER" "req-004: pointer names the coaching section"
assert_contains "recommend-then-confirm" "$POINTER" "req-004: pointer says recommend-then-confirm applies in every phase"
assert_contains "applies in every phase" "$POINTER" "req-004: pointer scopes recommend-then-confirm to every phase"
assert_contains "it means that section of this file" "$POINTER" "req-004: pointer explains the cross-file 'above' wording"
assert_contains "Context Hygiene" "$POINTER" "req-004: pointer names Context Hygiene as an 'above' target"
assert_contains "mid-pipeline change protocol" "$POINTER" "req-004: pointer names the change protocol as an 'above' target"
lacks "Read nothing else" "$POINTER" "req-004: pointer doesn't bar the rules that apply after P0"
assert_contains '`## Skill Map`' "$POINTER" "req-004: pointer keeps the Skill Map update at each phase gate"
assert_contains 'Gate accepted: P{N}' "$POINTER" "req-004: pointer keeps the interactive Gate accepted line"
lacks "Capability Skills above" "$SKILL_TEXT" "req-004: no dangling 'Capability Skills above' cite in SKILL.md"
assert_contains "in \`references/phase-0-assess-and-coach.md\`)" "$SKILL_TEXT" "req-004: the pre-P3 cite names the reference file"

echo ""
echo "=== req-004: Resume Detection reloads at P0 ==="
RESUME=$(awk '/^## Resume Detection/{f=1; next} f && /^## /{exit} f' "$ORCH")
assert_contains "still at P0" "$RESUME" "req-004: Resume Detection covers a run still at P0"
assert_contains "phase-0-assess-and-coach.md" "$RESUME" "req-004: Resume Detection reloads the Phase 0 file"
assert_contains "adoption-modes.md" "$RESUME" "req-004: Resume Detection reloads the Adoption Modes file"

echo ""
echo "=== req-004: size (NFR-002) ==="
# Count the committed LF bytes. Git for Windows can check the file out with CRLF.
SIZE=$(tr -d '\r' < "$ORCH" | wc -c | tr -d ' ')
# The limit was 41,500 before feature 0000039. The RAVINTIO rename adds 4 bytes
# to SKILL.md (longer brand words), so the limit is 41,600 now.
assert_equals "under" "$([ "$SIZE" -lt 41600 ] && echo under || echo over)" \
  "req-004: SKILL.md is under 41,600 bytes (now $SIZE)"

print_summary
