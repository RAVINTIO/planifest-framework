#!/usr/bin/env bash
# Tests for feature 0000035-write-gate-scope-and-path-hardening.
#
# req-005: ratchet-check.mjs finds the root and the target with resolveRoot
#          and resolveTarget from path-rules.mjs, so it guards plan/current/
#          from any subfolder (ADR-007).
#
# Every fixture lives under mktemp -d. Each fixture runs git init so the root
# walk stops at the fixture and never reaches the host repository.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
ENF="$FRAMEWORK/hooks/enforcement"
RATCHET="$ENF/ratchet-check.mjs"

WORK="$(mktemp -d -t planifest_0000035_req005_XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

native() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

now_ms() { node -e 'process.stdout.write(String(Date.now()))'; }

# make_fixture <name>: a git repository with an active loop and a plan/current/
# artifact with two acceptance criteria.
make_fixture() {
  local dir="$WORK/$1"
  mkdir -p "$dir/plan/current" "$dir/src"
  git init "$dir" >/dev/null 2>&1
  printf -- '---\nstatus: "active"\n---\n# Loop State: x\n' > "$dir/plan/current/loop-state-x.md"
  printf '# Requirement\n## Acceptance Criteria\n- [ ] criterion alpha holds\n- [ ] criterion beta holds\n' \
    > "$dir/plan/current/req.md"
  printf '%s' "$dir"
}

# run_ratchet <process cwd> <stdin cwd> <file_path> <old> <new>: runs an Edit
# through ratchet-check and sets CODE, ERR, and MS.
run_ratchet() {
  local payload errfile="$WORK/stderr.txt" t0
  payload=$(node -e '
    const [cwd, fp, oldS, newS] = process.argv.slice(1);
    process.stdout.write(JSON.stringify({cwd, tool_name: "Edit", tool_input: {file_path: fp, old_string: oldS, new_string: newS}}));
  ' "$(native "$2")" "$3" "$4" "$5")
  t0=$(now_ms)
  (cd "$1" && node "$RATCHET" >/dev/null 2>"$errfile" <<< "$payload")
  CODE=$?
  MS=$(( $(now_ms) - t0 ))
  ERR=$(cat "$errfile")
}

BETA=$'- [ ] criterion beta holds\n'
GAMMA=$'- [ ] criterion beta holds\n- [ ] criterion gamma holds\n'

# =============================================================================
echo ""
echo "=== req-005: a weakening Edit from a subfolder ==="

FX="$(make_fixture sub)"
run_ratchet "$FX/src" "$FX/src" "../plan/current/req.md" "$BETA" ""
assert_equals "2" "$CODE" "req-005: removing a criterion from src/ with a relative file_path exits 2"
assert_contains "Ratchet: this write weakens plan/current/req.md" "$ERR" "req-005: the ratchet reason names the root-relative path"

run_ratchet "$FX" "$FX" "plan/current/req.md" "$BETA" ""
assert_equals "2" "$CODE" "req-005: the same Edit from the root also exits 2"

run_ratchet "$FX/src" "$FX/src" "$(native "$FX")/plan/current/req.md" "$BETA" ""
assert_equals "2" "$CODE" "req-005: an absolute file_path from src/ exits 2"

run_ratchet "$FX/src" "$FX/src" "../plan/current/req.md" "$BETA" "$GAMMA"
assert_equals "0" "$CODE" "req-005: adding a criterion from src/ exits 0"

# The stdin cwd decides, not the process working folder.
run_ratchet "$WORK" "$FX/src" "../plan/current/req.md" "$BETA" ""
assert_equals "2" "$CODE" "req-005: a relative file_path resolves against the stdin cwd"

# The exemptions still apply from a subfolder.
run_ratchet "$FX/src" "$FX/src" "../plan/current/loop-state-x.md" 'status: "active"' 'status: "done"'
assert_equals "0" "$CODE" "req-005: a loop-state file stays exempt from a subfolder"

# =============================================================================
echo ""
echo "=== req-005: an approval line still lets the write pass from a subfolder ==="

FX="$(make_fixture approve)"
printf 'plan/current/req.md | human approved | 2026-10-22T00:00:00Z\n' > "$FX/plan/current/.ratchet-approve"
git -C "$FX" add plan/current/.ratchet-approve >/dev/null 2>&1
git -C "$FX" -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -q -m approve --no-verify >/dev/null 2>&1
run_ratchet "$FX/src" "$FX/src" "../plan/current/req.md" "$BETA" ""
assert_equals "0" "$CODE" "req-005: a committed approval line lets the weakening pass from src/"
assert_equals "no" "$([ -f "$FX/plan/current/.ratchet-approve" ] && echo yes || echo no)" "req-005: the approval line is consumed at the root"
assert_contains "human approved" "$(cat "$FX/plan/ratchet-audit-log.md" 2>/dev/null)" "req-005: the audit log lands under the root"

# =============================================================================
echo ""
echo "=== req-005: link targets and unresolvable targets ==="

FX="$(make_fixture links)"
if ln -s req.md "$FX/plan/current/l10" 2>/dev/null; then
  for i in $(seq 9 -1 1); do ln -s "l$((i + 1))" "$FX/plan/current/l$i"; done
  run_ratchet "$FX/src" "$FX/src" "../plan/current/l1" "$BETA" ""
  echo "  10-link ratchet call: ${MS} ms"
  assert_equals "2" "$CODE" "req-005: a weakening Edit through a 10-link chain exits 2"
  assert_equals "yes" "$([ "$MS" -lt 500 ] && echo yes || echo no)" "req-005: a 10-link ratchet call takes under 500 ms"

  ln -s loop-b.md "$FX/plan/current/loop-a.md"
  ln -s loop-a.md "$FX/plan/current/loop-b.md"
  run_ratchet "$FX/src" "$FX/src" "../plan/current/loop-a.md" "$BETA" ""
  assert_equals "0" "$CODE" "req-005: an unresolvable target passes the ratchet, since gate-write blocks it"
else
  echo "  SKIP: req-005: this platform can't create symbolic links"
fi

# The Write tool collapses .. as text, so docs/L/../../plan/current/req.md
# lands in plan/current/req.md even with docs/L -> ../plan/x/y (G-S01).
FXT="$(make_fixture textual)"
mkdir -p "$FXT/plan/x/y" "$FXT/docs"
if ln -s ../plan/x/y "$FXT/docs/L" 2>/dev/null; then
  run_ratchet "$FXT" "$FXT" "docs/L/../../plan/current/req.md" "$BETA" ""
  assert_equals "2" "$CODE" "req-005: removing a criterion through docs/L/../../plan/current/req.md exits 2"
  assert_contains "Ratchet: this write weakens plan/current/req.md" "$ERR" "req-005: the ratchet judges the text-collapsed path"
  run_ratchet "$FXT" "$FXT" "docs/L/../../plan/current/req.md" "$BETA" "$GAMMA"
  assert_equals "0" "$CODE" "req-005: adding a criterion through the same path exits 0"
fi

# A target outside the root passes.
mkdir -p "$WORK/outside/plan/current"
cp "$FX/plan/current/req.md" "$WORK/outside/plan/current/req.md"
run_ratchet "$FX/src" "$FX/src" "$(native "$WORK/outside/plan/current/req.md")" "$BETA" ""
assert_equals "0" "$CODE" "req-005: a target outside the root passes"

# =============================================================================
echo ""
echo "=== req-005: input validation ==="

FX="$(make_fixture limits)"
# Control: a nested artifact under plan/current/ is guarded.
mkdir -p "$FX/plan/current/n"
cp "$FX/plan/current/req.md" "$FX/plan/current/n/req.md"
run_ratchet "$FX/src" "$FX/src" "../plan/current/n/req.md" "$BETA" ""
assert_equals "2" "$CODE" "req-005: control, a nested plan/current/ artifact is guarded"
# The same artifact past MAX_PATH_SEGMENTS passes, as in gate-write.mjs.
DEEP="plan/current/$(printf 'd/%.0s' $(seq 1 260))"
mkdir -p "$FX/$DEEP"
cp "$FX/plan/current/req.md" "$FX/${DEEP}req.md"
run_ratchet "$FX/src" "$FX/src" "../${DEEP}req.md" "$BETA" ""
assert_equals "0" "$CODE" "req-005: a file_path past MAX_PATH_SEGMENTS passes with exit 0"

# A non-string file_path passes.
(cd "$FX/src" && node "$RATCHET" >/dev/null 2>&1 <<< "{\"cwd\":\"$(native "$FX/src")\",\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":42,\"old_string\":\"x\",\"new_string\":\"\"}}")
assert_equals "0" "$?" "req-005: a non-string file_path passes with exit 0"

# =============================================================================
echo ""
echo "=== req-005: ratchet-check.mjs uses the shared rules ==="

SRC="$(cat "$RATCHET")"
assert_contains "resolveRoot" "$SRC" "req-005: ratchet-check.mjs uses resolveRoot"
assert_contains "resolveTarget" "$SRC" "req-005: ratchet-check.mjs uses resolveTarget"
assert_contains 'from "./path-rules.mjs"' "$SRC" "req-005: ratchet-check.mjs imports path-rules.mjs"
assert_equals "no" "$([[ "$SRC" == *"process.cwd()"* ]] && echo yes || echo no)" \
  "req-005: ratchet-check.mjs calls process.cwd() only through the shared cwd fallback"
assert_equals "no" "$([[ "$SRC" == *"realpathSync"* ]] && echo yes || echo no)" \
  "req-005: ratchet-check.mjs keeps no root or path logic of its own"

print_summary
