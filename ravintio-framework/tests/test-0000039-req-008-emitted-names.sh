#!/usr/bin/env bash
# Tests for feature 0000039-ravintio-rebrand
# req-008: hooks, setup output, and the generated boot file emit RAVINTIO names
#
# Verified by: unit         (AC1: path-rules.mjs, run with node on small inputs)
# Verified by: integration  (AC2: setup.sh on a scratch consumer that starts as an old install)
# Verified by: integration  (AC3: generated boot files, sanctioned scripts, workflow name)
#
# Also covers the P3 decision: em-dash-guard.mjs accepts the new sentinel and
# the old one (ADR-002, ADR-004).
#
# Old names appear only where this test plants an old install or checks the
# old sentinel on purpose.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$FRAMEWORK/.." && pwd)"
RULES="$FRAMEWORK/hooks/enforcement/path-rules.mjs"
GUARD="$FRAMEWORK/hooks/enforcement/em-dash-guard.mjs"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

yes_no() {
  if "$@"; then echo yes; else echo no; fi
}

# -----------------------------------------------------------------------
echo ""
echo "=== req-008 AC1: path-rules.mjs emits RAVINTIO names ==="
# -----------------------------------------------------------------------

P1="$TMP/ac1"
mkdir -p "$P1/ravintio-framework" "$P1/plan" "$P1/src/app/sub"

# Run a small node program against the real module, from the scratch folder.
rules_eval() {
  (cd "$P1" && node --input-type=module -e "
    import * as p from '$RULES';
    const root = p.resolveRoot(process.cwd());
    $1
  " 2>&1)
}

OUT="$(rules_eval "console.log(root === null ? 'null' : 'root-ok');")"
assert_equals "root-ok" "$OUT" "req-008 AC1: ravintio-framework/ marks the repository root"

# A folder that holds only the old marker is not a root, so the walk finds the real one.
mkdir -p "$P1/src/app/sub/planifest-framework"
OUT="$(cd "$P1/src/app/sub" && node --input-type=module -e "
  import * as p from '$RULES';
  import { realpathSync } from 'node:fs';
  console.log(p.resolveRoot(process.cwd()) === realpathSync('$P1') ? 'top' : 'nested');
" 2>&1)"
assert_equals "top" "$OUT" "req-008 AC1: the old marker folder does not mark a root"

OUT="$(rules_eval "console.log(JSON.stringify(p.evaluateWrite(root, '.ravintio-session')));")"
assert_equals '{"allowed":true}' "$OUT" "req-008 AC1: .ravintio-session is always permitted"

OUT="$(rules_eval "console.log(p.isEnforcementPath('.opencode/plugins/@ravintio/opencode-hooks/index.ts'));")"
assert_equals "true" "$OUT" "req-008 AC1: the @ravintio OpenCode plugin path is an enforcement path"

OUT="$(rules_eval "console.log(p.isEnforcementPath('.github/workflows/ravintio.yml'));")"
assert_equals "true" "$OUT" "req-008 AC1: ravintio.yml is an enforcement path"

OUT="$(rules_eval "console.log(p.isEnforcementPath('ravintio-framework/hooks/enforcement/gate-write.mjs'));")"
assert_equals "true" "$OUT" "req-008 AC1: ravintio-framework/hooks/ is an enforcement path"

# The gate-write reasons: no design, and no orchestrator sentinel.
GATE_REASON="$(rules_eval "console.log(p.evaluateWrite(root, 'src/app/x.js').reason);")"
PRESENCE_REASON="$(rules_eval "console.log(p.evaluateWrite(root, 'plan/current/x.md').reason);")"

assert_equals "yes" "$(yes_no grep -q '^\[RAVINTIO\]' <<< "$GATE_REASON")" "req-008 AC1: the gate-write reason starts with [RAVINTIO]"
assert_equals "yes" "$(yes_no grep -q '^\[RAVINTIO\]' <<< "$PRESENCE_REASON")" "req-008 AC1: the sentinel reason starts with [RAVINTIO]"
assert_equals "yes" "$(yes_no grep -q 'ravintio-orchestrator' <<< "$PRESENCE_REASON")" "req-008 AC1: the sentinel reason names ravintio-orchestrator"

# The gate-write hook itself, fed a Write payload.
GATE_OUT="$(cd "$P1" && printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"plan/current/x.md","content":"x"},"cwd":"'"$P1"'"}' | node "$FRAMEWORK/hooks/enforcement/gate-write.mjs" 2>&1)"
assert_equals "yes" "$(yes_no grep -q 'ravintio-orchestrator' <<< "$GATE_OUT")" "req-008 AC1: gate-write.mjs output names ravintio-orchestrator"
assert_equals "no" "$(yes_no grep -qi 'planifest' <<< "$GATE_OUT")" "req-008 AC1: gate-write.mjs output holds no old brand name"

# The presence hook, in strict mode with no ack.
mkdir -p "$P1/plan"
echo "0000039-test" > "$P1/plan/.orchestrator-active"
: > "$P1/plan/.orchestrator-strict"
PRES_OUT="$(cd "$P1" && printf '%s' '{"cwd":"'"$P1"'","session_id":"s1"}' | node "$FRAMEWORK/hooks/enforcement/check-orchestrator-presence.mjs" 2>&1)"
assert_equals "yes" "$(yes_no grep -q 'ravintio-orchestrator' <<< "$PRES_OUT")" "req-008 AC1: the presence hook names ravintio-orchestrator"
assert_equals "no" "$(yes_no grep -qi 'planifest' <<< "$PRES_OUT")" "req-008 AC1: the presence hook output holds no old brand name"

# -----------------------------------------------------------------------
echo ""
echo "=== req-008 AC2: setup.sh moves an old 0.36.0 install to RAVINTIO names ==="
# -----------------------------------------------------------------------

C="$TMP/consumer"
mkdir -p "$C"
cp -R "$FRAMEWORK" "$C/ravintio-framework"
(
  cd "$C" || exit 1
  git init -q . 2>/dev/null
  # Plant the old 0.36.0 state.
  git config core.hooksPath planifest-framework/hooks
  mkdir -p "$C/planifest-framework/hooks" ".opencode/plugins/@planifest/opencode-hooks"
  echo "old" > ".opencode/plugins/@planifest/opencode-hooks/index.ts"
)

# The migration helper is absent from the pack, so removing the old folder stands in for it.
HELPER="$(ls "$FRAMEWORK"/migrations/*ravintio*rename* 2>/dev/null | head -1)"
rm -rf "$C/planifest-framework"

SETUP_OUT="$(cd "$C" && ./ravintio-framework/setup.sh claude-code 2>&1)"
SETUP_RC=$?
SETUP_OUT2="$(cd "$C" && ./ravintio-framework/setup.sh opencode 2>&1)"
SETUP_ALL="$SETUP_OUT"$'\n'"$SETUP_OUT2"

assert_equals "0" "$SETUP_RC" "req-008 AC2: setup.sh claude-code exits zero on the old install"
assert_equals "ravintio-framework/hooks" "$(cd "$C" && git config core.hooksPath)" "req-008 AC2: core.hooksPath is ravintio-framework/hooks"
assert_equals "yes" "$(yes_no test -d "$C/.opencode/plugins/@ravintio/opencode-hooks")" "req-008 AC2: the OpenCode plugin sits under @ravintio"
assert_equals "no" "$(yes_no grep -qiF '[Planifest]' <<< "$SETUP_ALL")" "req-008 AC2: setup output holds no [Planifest]"
assert_equals "yes" "$(yes_no grep -qF '[RAVINTIO]' <<< "$SETUP_ALL")" "req-008 AC2: setup output carries the [RAVINTIO] prefix"
if [ -n "$HELPER" ]; then
  assert_equals "yes" "$(yes_no test -f "$HELPER")" "req-008 AC2: the migration helper exists"
fi

# -----------------------------------------------------------------------
echo ""
echo "=== req-008 AC3: generated boot files hold no old path ==="
# -----------------------------------------------------------------------

B="$TMP/boot"
mkdir -p "$B"
cp -R "$FRAMEWORK" "$B/ravintio-framework"
(cd "$B" && git init -q . 2>/dev/null)
BOOT_OUT="$(cd "$B" && ./ravintio-framework/setup.sh all 2>&1)"
BOOT_RC=$?
assert_equals "0" "$BOOT_RC" "req-008 AC3: setup.sh all exits zero"

# Boot files: every generated file outside the pack, the skills folders, and .git.
BOOT_FILES="$(cd "$B" && find . -type f \
  -not -path './ravintio-framework/*' -not -path './.git/*' \
  -not -path '*/skills/*' -not -path '*/hooks/*' -not -path '*/plugins/*' \
  -not -name 'node_modules' 2>/dev/null | sort)"
assert_equals "yes" "$(yes_no test -f "$B/CLAUDE.md")" "req-008 AC3: CLAUDE.md is generated"

BAD=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if grep -qF 'planifest-framework/' "$B/$f" 2>/dev/null; then BAD="$BAD $f"; fi
done <<< "$BOOT_FILES"
assert_equals "" "$BAD" "req-008 AC3: no generated boot file holds a planifest-framework/ path"

# Sanctioned scripts from Hard Limit 8 exist under ravintio-framework/.
CLAUDE_MD="$(cat "$B/CLAUDE.md" 2>/dev/null)"
for s in scripts/archive-current.mjs scripts/set-product-release.mjs scripts/promote-to-regression.sh \
         scripts/refresh-delete-boot-files.sh scripts/refresh-delete-boot-files.ps1 setup.sh setup.ps1; do
  assert_equals "yes" "$(yes_no test -f "$REPO/ravintio-framework/$s")" "req-008 AC3: ravintio-framework/$s exists"
  assert_equals "yes" "$(yes_no grep -qF "ravintio-framework/$s" <<< "$CLAUDE_MD")" "req-008 AC3: generated CLAUDE.md lists ravintio-framework/$s"
done

WF="$REPO/.github/workflows/ravintio.yml"
assert_equals "yes" "$(yes_no grep -qx 'name: RAVINTIO Strict Pipeline' "$WF")" "req-008 AC3: the workflow name reads RAVINTIO Strict Pipeline"

# -----------------------------------------------------------------------
echo ""
echo "=== req-008 P3 decision: em-dash guard accepts both sentinels ==="
# -----------------------------------------------------------------------

G="$TMP/guard"
mkdir -p "$G/ravintio-framework" "$G/plan/current"
EM_DASH=$'\xe2\x80\x94'

guard_rc() {
  local content="$1" payload
  payload="$(node -e '
    process.stdout.write(JSON.stringify({tool_name:"Write",tool_input:{file_path:"plan/current/notes.md",content:process.argv[1]}}));
  ' "$content")"
  (cd "$G" && printf '%s' "$payload" | node "$GUARD" >/dev/null 2>&1; echo $?)
}

assert_equals "2" "$(guard_rc "text $EM_DASH here")" "req-008: an em dash with no sentinel is blocked"
assert_equals "0" "$(guard_rc "<!-- ravintio-em-dash-allow -->"$'\n'"text $EM_DASH here")" "req-008: the ravintio-em-dash-allow sentinel allows the write"
assert_equals "0" "$(guard_rc "<!-- planifest-em-dash-allow -->"$'\n'"text $EM_DASH here")" "req-008: the old planifest-em-dash-allow sentinel still allows the write"

print_summary
