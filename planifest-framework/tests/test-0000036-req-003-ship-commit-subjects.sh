#!/usr/bin/env bash
# Tests for feature 0000036-pipeline-friction-and-gate-fixes.
#
# req-003: no commit subject template in a framework skill or workflow holds a
#          placeholder (ADR-012). Subjects name the phase and the action only,
#          and the feature ID moves to the commit body through a second -m.
#          Each subject the scan finds passes hooks/commit-msg with exit 0.
#
# The scan reads the first -m value of each `git commit` command, and each
# backtick span in prose that has the type(scope): description form.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$FW/hooks/commit-msg"
SHIP="$FW/skills/planifest-ship-agent/SKILL.md"
ORCH="$FW/skills/planifest-orchestrator/SKILL.md"

WORK="$(mktemp -d -t planifest_0000036_req003_XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

# subjects <file>...: prints one "file:line<TAB>subject" row per subject found.
TAB=$'\t'
subjects() {
  local f
  for f in "$@"; do
    grep -nE 'git commit[^"`]*-m "[^"]*"' "$f" 2>/dev/null \
      | sed -E "s/^([0-9]+):.*git commit[^\"\`]*-m \"([^\"]*)\".*/\\1${TAB}\\2/" \
      | sed "s|^|$f:|"
    grep -noE '`[a-z]+\([^)`]+\)!?: [^`]+`' "$f" 2>/dev/null \
      | sed -E "s/^([0-9]+):\`(.*)\`\$/\\1${TAB}\\2/" \
      | sed "s|^|$f:|"
  done
}

# violations <file>...: prints one row per subject that breaks a rule.
violations() {
  local where subj
  while IFS=$'\t' read -r where subj; do
    [ -z "$where" ] && continue
    if [[ "$subj" == *[\{\}\<\>]* ]]; then
      printf 'placeholder: %s: %s\n' "$where" "$subj"
    fi
    if [ "${#subj}" -gt 72 ]; then
      printf 'too long (%s): %s: %s\n' "${#subj}" "$where" "$subj"
    fi
  done < <(subjects "$@")
}

FILES=()
for f in "$FW"/skills/*/SKILL.md "$FW"/workflows/*; do
  [ -f "$f" ] && FILES+=("$f")
done

echo "=== req-003: the scan finds the ship subjects ==="

ALL=$(subjects "${FILES[@]}")
COUNT=$(grep -c . <<< "$ALL")
assert_equals "yes" "$([ "$COUNT" -ge 5 ] && echo yes || echo no)" \
  "req-003: the scan finds at least five commit subjects (found $COUNT)"
for s in "plan(p7): archive plan/current" "plan(p9): clear session markers" "plan(p9): add final report"; do
  assert_contains "$s" "$ALL" "req-003: the scan finds the subject '$s'"
done

echo ""
echo "=== req-003: no subject holds a placeholder or runs past 72 characters ==="

V=$(violations "${FILES[@]}")
assert_equals "" "$V" "req-003: every skill and workflow commit subject is placeholder-free and at most 72 characters"

echo ""
echo "=== req-003: each subject passes hooks/commit-msg ==="

N=0
while IFS=$'\t' read -r where subj; do
  [ -z "$where" ] && continue
  N=$((N + 1))
  printf '%s\n' "$subj" > "$WORK/msg-$N"
  bash "$HOOK" "$WORK/msg-$N" >/dev/null 2>&1
  assert_equals "0" "$?" "req-003: commit-msg accepts '$subj' (${where##*/skills/})"
done <<< "$ALL"

echo ""
echo "=== req-003: the feature ID moves to the commit body ==="

SHIPT=$(cat "$SHIP")
assert_contains 'git commit -m "plan(p7): archive plan/current" -m "{feature-id}"' "$SHIPT" \
  "req-003: P7 Step 7 carries the feature ID in the body"
assert_contains 'git commit -m "plan(p9): clear session markers" -m "{feature-id}" -- "{archive-dir}"' "$SHIPT" \
  "req-003: P9 marker step carries the feature ID before the path list"
assert_contains 'git commit -m "plan(p9): add final report" -m "{feature-id}" -- "{archive-dir}/final-report.md"' "$SHIPT" \
  "req-003: P9 Step 11 carries the feature ID before the path list"
assert_contains 'git tag v{version} -m "{feature-id}"' "$SHIPT" "req-003: the tag message stays"
assert_contains '`plan(p9): clear session markers`' "$(grep '^\*\*What P9 produces' "$ORCH")" \
  "req-003: orchestrator quotes the new P9 marker subject"
assert_equals "0" "$(grep -c 'git commit .*for {feature-id}"' "$SHIP")" "req-003: no ship subject ends with for {feature-id}"

echo ""
echo "=== req-003: the scan flags a bad fixture subject ==="

FIX="$WORK/fixture.md"
{
  printf '%s\n' 'git commit -m "plan(p7): archive {feature-id}"'
  printf '%s\n' 'Commit with `plan(p9): add <thing>` in prose.'
  printf '%s\n' "git commit -q -m \"docs(p6): $(printf 'x%.0s' $(seq 1 70))\""
  printf '%s\n' 'git commit -m "plan(p8): commit close-out leftovers" -m "{feature-id}"'
} > "$FIX"
FV=$(violations "$FIX")
assert_contains "placeholder: $FIX:1" "$FV" "req-003: the scan flags a {feature-id} subject"
assert_contains "placeholder: $FIX:2" "$FV" "req-003: the scan flags a <placeholder> prose subject"
assert_contains "too long" "$FV" "req-003: the scan flags a subject past 72 characters"
assert_equals "0" "$(grep -c "$FIX:4" <<< "$FV")" "req-003: the scan ignores a placeholder in the body -m"

print_summary
