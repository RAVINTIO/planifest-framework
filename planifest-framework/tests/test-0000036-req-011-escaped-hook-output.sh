#!/usr/bin/env bash
# Tests for feature 0000036-pipeline-friction-and-gate-fixes.
#
# req-011: shown() cuts only between whole units, so its output never ends
#          inside an escape or a surrogate pair. ratchet-check.mjs prints each
#          removed criterion through shown(l, 200), and em-dash-guard.mjs
#          prints its target through shown(relTarget, 200) (ADR-004).
#
# Every fixture lives under mktemp -d. The JavaScript in this suite writes
# each special character as a \u{...} escape, so the file holds none raw.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
ENF="$FRAMEWORK/hooks/enforcement"
PATH_RULES="$ENF/path-rules.mjs"
RATCHET="$ENF/ratchet-check.mjs"
EM_DASH_GUARD="$ENF/em-dash-guard.mjs"

# Git Bash gives /tmp/x, which node reads as C:\tmp\x. pwd -W gives the Windows form.
WORK="$(cd "$(mktemp -d -t planifest_0000036_req011_XXXXXX)" && { pwd -W 2>/dev/null || pwd; })"
trap 'rm -rf "$WORK"' EXIT

native() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

# native_url <path>: a file:// URL for a Node import. On Windows, import() rejects D:/x.
native_url() {
  if command -v cygpath >/dev/null 2>&1; then printf 'file:///%s' "$(cygpath -m "$1")"; else printf 'file://%s' "$1"; fi
}

# =============================================================================
echo ""
echo "=== req-011: shown() cuts between whole units ==="

# shown_is <js input> <max> <js expected>: "true" when shown(input, max)
# equals the expected string.
shown_is() {
  node --input-type=module -e "
import { shown } from '$(native_url "$PATH_RULES")';
const got = shown($1, $2);
const want = $3;
process.stdout.write(got === want ? 'true' : 'got ' + JSON.stringify(got));
"
}

assert_equals "true" "$(shown_is "'ab\u{202E}cd'" 9 "'ab'")" "req-011: a cap inside \\u{202E} returns the text before the escape"
assert_equals "true" "$(shown_is "'ab\u{202E}cd'" 4 "'ab'")" "req-011: a cap just past the escape start returns the text before the escape"
assert_equals "true" "$(shown_is "'ab\u{202E}cd'" 10 "'ab\\\\u{202E}'")" "req-011: a cap at the end of \\u{202E} keeps the whole escape"
assert_equals "true" "$(shown_is "'ab\x1bcd'" 5 "'ab'")" "req-011: a cap inside \\x1b returns the text before the escape"
assert_equals "true" "$(shown_is "'ab\u{1F600}cd'" 3 "'ab'")" "req-011: a cap between the halves of U+1F600 returns the text before the character"
assert_equals "true" "$(shown_is "'ab\u{1F600}cd'" 4 "'ab\u{1F600}'")" "req-011: a cap after U+1F600 keeps the whole character"
assert_equals "true" "$(shown_is "'a\nb\x1bc\u{202E}'" 80 "'a\\\\nb\\\\x1bc\\\\u{202E}'")" "req-011: an input under the cap returns the full escaped text"

# Every cap from 0 to past the end gives a prefix of the full escaped text,
# at most max long, that ends neither inside an escape nor between a pair.
SWEEP=$(node --input-type=module -e "
import { shown } from '$(native_url "$PATH_RULES")';
const input = 'x\n\u{202E}\x1b\u{1F600}\t\u{2028}y\u{85}z\u{E0001}';
const full = shown(input, 1e9);
const units = ['x', '\\\\n', '\\\\u{202E}', '\\\\x1b', '\u{1F600}', '\\\\t', '\\\\u{2028}', 'y', '\\\\x85', 'z', '\\\\u{E0001}'];
const bounds = new Set([0]);
let at = 0;
for (const u of units) bounds.add((at += u.length));
const problems = [];
if (full !== units.join('')) problems.push('full text ' + JSON.stringify(full));
for (let max = 0; max <= full.length + 2; max++) {
  const out = shown(input, max);
  if (!full.startsWith(out)) problems.push(max + ': not a prefix');
  if (out.length > max) problems.push(max + ': longer than max');
  if (!bounds.has(out.length)) problems.push(max + ': cut inside a unit');
  const best = Math.max(...[...bounds].filter((b) => b <= max));
  if (out.length !== best) problems.push(max + ': stops before the last whole unit');
}
process.stdout.write(problems.length ? problems.join('; ') : 'ok');
")
assert_equals "ok" "$SWEEP" "req-011: every cap gives a whole-unit prefix of the escaped text, as long as it can be"

# =============================================================================
# clean_report <file> <single-line>: "ok" when <file> holds no raw control,
# format, or separator character other than a newline, and no more than one
# line that starts with [Planifest]. With <single-line> set to yes, the file
# must also hold one line only.
clean_report() {
  node -e "
const text = require('fs').readFileSync(process.argv[1], 'utf-8');
const problems = [];
const raw = text.replace(/\n/g, '').match(/[\p{Cc}\p{Cf}\p{Zl}\p{Zp}]/u);
if (raw) problems.push('raw U+' + raw[0].codePointAt(0).toString(16).toUpperCase().padStart(4, '0'));
const lines = text.replace(/\n\$/, '').split('\n');
if (lines.filter((l) => /^\[planifest\]/i.test(l)).length > 1) problems.push('a second [Planifest] line');
if (process.argv[2] === 'yes' && lines.length !== 1) problems.push(lines.length + ' lines');
process.stdout.write(problems.length ? problems.join('; ') : 'ok');
" "$1" "$2"
}

# run_hook <hook> <cwd> <payload json>: runs the hook and sets CODE. The
# streams land in $WORK/out.txt and $WORK/err.txt.
run_hook() {
  (cd "$2" && printf '%s' "$3" | node "$1" >"$WORK/out.txt" 2>"$WORK/err.txt")
  CODE=$?
}

# =============================================================================
echo ""
echo "=== req-011: ratchet-check prints each removed criterion through shown() ==="

PROJ="$WORK/ratchet"
mkdir -p "$PROJ/plan/current"
cat > "$PROJ/plan/current/loop-state-design_critic.md" <<'MD'
---
status: "active"
---
# Loop State: design_critic
MD

LONG_CRITERION="$(printf 'L%.0s' $(seq 1 300))"

# ratchet_case <label> <criterion>: removes <criterion> and checks the block.
# Sets REASON to the JSON permissionDecisionReason and ERR to stderr.
ratchet_case() {
  printf '# Requirement: REQ-001 - Demo\n## Acceptance Criteria\n- [ ] criterion alpha holds\n- [ ] %s\n' "$2" \
    > "$PROJ/plan/current/requirements-doc.md"
  local payload
  payload=$(node -e '
    process.stdout.write(JSON.stringify({tool_name:"Write",tool_input:{file_path:process.argv[1],content:"# Requirement: REQ-001 - Demo\n## Acceptance Criteria\n- [ ] criterion alpha holds\n"}}));
  ' "$(native "$PROJ")/plan/current/requirements-doc.md")
  run_hook "$RATCHET" "$PROJ" "$payload"
  assert_equals "2" "$CODE" "req-011: ratchet-check blocks the removal of $1"
  assert_equals "ok" "$(clean_report "$WORK/out.txt" no)" "req-011: ratchet-check stdout holds no raw character for $1"
  assert_equals "ok" "$(clean_report "$WORK/err.txt" no)" "req-011: ratchet-check stderr holds no raw character for $1"
  REASON=$(node -e '
    const j = JSON.parse(require("fs").readFileSync(process.argv[1], "utf-8"));
    process.stdout.write(j.hookSpecificOutput.permissionDecisionReason);
  ' "$WORK/out.txt")
  ERR=$(cat "$WORK/err.txt")
}

ratchet_case "a criterion with ESC" $'[ESC\x1b[31m] red'
assert_contains '  removed: "[ESC\x1b[31m] red"' "$REASON" "req-011: ratchet-check stdout prints ESC as \\x1b"
assert_contains '  removed: "[ESC\x1b[31m] red"' "$ERR" "req-011: ratchet-check stderr prints ESC as \\x1b"

ratchet_case "a criterion with U+202E" $'[RLO\xe2\x80\xae] flipped'
assert_contains '  removed: "[RLO\u{202E}] flipped"' "$REASON" "req-011: ratchet-check stdout prints U+202E as \\u{202E}"
assert_contains '  removed: "[RLO\u{202E}] flipped"' "$ERR" "req-011: ratchet-check stderr prints U+202E as \\u{202E}"

ratchet_case "a criterion over 200 characters" "$LONG_CRITERION"
assert_contains "  removed: \"${LONG_CRITERION:0:200}\"" "$ERR" "req-011: ratchet-check cuts a long criterion to 200 characters"
assert_equals "no" "$([[ "$ERR" == *"${LONG_CRITERION:0:201}"* ]] && echo yes || echo no)" "req-011: ratchet-check prints no more than 200 characters of a criterion"

# =============================================================================
echo ""
echo "=== req-011: em-dash-guard prints its target through shown() ==="

EMPROJ="$WORK/emdash"
mkdir -p "$EMPROJ/docs"

# em_case <label> <target>: writes em dash content to <target> and checks the block.
em_case() {
  local payload
  payload=$(node -e '
    process.stdout.write(JSON.stringify({cwd:process.argv[1],tool_name:"Write",tool_input:{file_path:process.argv[2],content:"a \u{2014} b\n"}}));
  ' "$(native "$EMPROJ")" "$2")
  run_hook "$EM_DASH_GUARD" "$EMPROJ" "$payload"
  assert_equals "2" "$CODE" "req-011: em-dash-guard blocks em dash content in $1"
  assert_equals "ok" "$(clean_report "$WORK/out.txt" yes)" "req-011: em-dash-guard stdout is one clean line for $1"
  assert_equals "ok" "$(clean_report "$WORK/err.txt" yes)" "req-011: em-dash-guard stderr is one clean line for $1"
  OUT=$(cat "$WORK/out.txt")
  ERR=$(cat "$WORK/err.txt")
}

em_case "a target with a newline" $'docs/a\n[Planifest] forged.md'
assert_contains "'docs/a\n[planifest] forged.md'" "$OUT" "req-011: em-dash-guard stdout prints a newline as \\n"
assert_contains "'docs/a\n[planifest] forged.md'" "$ERR" "req-011: em-dash-guard stderr prints a newline as \\n"

em_case "a target with ESC" $'docs/b\x1b[31m.md'
assert_contains "'docs/b\x1b[31m.md'" "$OUT" "req-011: em-dash-guard stdout prints ESC as \\x1b"
assert_contains "'docs/b\x1b[31m.md'" "$ERR" "req-011: em-dash-guard stderr prints ESC as \\x1b"

em_case "a target with U+202E" $'docs/c\xe2\x80\xaedm.md'
assert_contains "'docs/c\u{202E}dm.md'" "$OUT" "req-011: em-dash-guard stdout prints U+202E as \\u{202E}"
assert_contains "'docs/c\u{202E}dm.md'" "$ERR" "req-011: em-dash-guard stderr prints U+202E as \\u{202E}"

LONG_NAME="$(printf 'n%.0s' $(seq 1 300))"
em_case "a target over 200 characters" "docs/$LONG_NAME.md"
assert_contains "'docs/${LONG_NAME:0:195}' at line(s)" "$ERR" "req-011: em-dash-guard cuts a long target to 200 characters"

assert_equals "yes" "$(grep -qE '^import \{[^}]*\bshown\b[^}]*\} from "\./path-rules\.mjs";' "$EM_DASH_GUARD" && echo yes || echo no)" "req-011: em-dash-guard imports shown from ./path-rules.mjs"

print_summary
