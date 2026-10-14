#!/usr/bin/env bash
# Tests for feature 0000028, req-002: extract duplicated hook logic into a
# shared readStdin module under hooks/enforcement/ (ADR-002). Telemetry
# parts of the original test were removed by feature 0000030.
#
# Covers:
#   1. readStdin has exactly one definition left in hooks/.
#   2. The shared module exists, every caller imports it by relative path, and
#      every relative import in hooks/ resolves on disk.
#   3. The shared readStdin settles on a stdin stream error rather than
#      hanging, and every caller still exits 0 on that path (NFR-001).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK_SRC="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS="$FRAMEWORK_SRC/hooks"
ENF="$HOOKS/enforcement"

# readStdin callers: every hook in hooks/enforcement/ that reads a payload on
# stdin.
READSTDIN_CALLERS=(
  "$ENF/auto-trigger-orchestrator.mjs" "$ENF/check-design.mjs"
  "$ENF/check-orchestrator-presence.mjs" "$ENF/em-dash-guard.mjs"
  "$ENF/gate-write.mjs" "$ENF/ratchet-check.mjs"
)

count_defs() {
  # count_defs <pattern> <dir>... — files matching a pattern across hooks subtrees.
  # The pattern comes first so multiple directories can be passed as separate
  # arguments; collapsing them into one word makes grep -rl take an invalid
  # path, return no matches, and the assertion pass vacuously.
  local pattern="$1"; shift
  grep -rl "$pattern" "$@" 2>/dev/null | wc -l | tr -d ' '
}

# =============================================================================
# 1. Each extracted helper has exactly one definition remaining
# =============================================================================

echo ""
echo "=== req-002: each extracted helper has exactly one definition ==="

assert_equals "1" "$(count_defs '^export function readStdin' "$ENF")" \
  "req-002: readStdin is defined exactly once across the hook tree"
assert_equals "0" "$(count_defs '^function readStdin' "$ENF")" \
  "req-002: no enforcement hook declares a local readStdin"

# =============================================================================
# 2. Shared modules exist and every caller imports them
# =============================================================================

echo ""
echo "=== req-002: shared modules exist and callers import them ==="

for m in "$ENF/read-stdin.mjs"; do
  if [ -f "$m" ]; then
    assert_equals "0" "0" "req-002: shared module exists: ${m#$FRAMEWORK_SRC/}"
  else
    assert_equals "exists" "missing" "req-002: shared module exists: ${m#$FRAMEWORK_SRC/}"
  fi
done

for caller in "${READSTDIN_CALLERS[@]}"; do
  CONTENT="$(cat "$caller")"
  assert_contains "read-stdin.mjs" "$CONTENT" \
    "req-002: $(basename "$caller") imports the shared readStdin"
done

# Every import in every hook must resolve on disk. A missing shared module is
# an ESM module-load failure, which happens before the hook's own try/catch and
# so cannot degrade gracefully (ADR-002/ADR-004).
echo ""
echo "=== req-002: every relative import in hooks/ resolves on disk ==="
UNRESOLVED=$(node -e '
  const fs = require("fs"), path = require("path");
  const roots = process.argv.slice(1);
  const missing = [];
  for (const root of roots) {
    for (const f of fs.readdirSync(root).filter((n) => n.endsWith(".mjs"))) {
      const src = fs.readFileSync(path.join(root, f), "utf8");
      for (const m of src.matchAll(/from\s+"(\.[^"]+)"/g)) {
        const target = path.resolve(root, m[1]);
        if (!fs.existsSync(target)) missing.push(`${f} -> ${m[1]}`);
      }
    }
  }
  console.log(missing.join(","));
' "$ENF")
assert_equals "" "$UNRESOLVED" "req-002: no hook imports a module that is absent from the source tree"

# =============================================================================
# 3. Shared readStdin settles on a stdin error (NFR-001)
# =============================================================================

echo ""
echo "=== req-002: shared readStdin settles on a stdin stream error ==="

assert_contains 'process.stdin.on("error"' "$(cat "$ENF/read-stdin.mjs")" \
  "req-002: shared readStdin wires an error handler"

# stdin must stay OPEN for this to mean anything: with /dev/null the stream
# reaches "end" immediately and resolves before any error can be observed.
# Process substitution on a sleeping process gives an fd that produces no data
# and no EOF for the life of the check, which is the shape a stalled stdin has.
SETTLE=$(node --input-type=module -e "
  import { readStdin } from '$ENF/read-stdin.mjs';
  let settled = 'HUNG';
  readStdin().then(() => { settled = 'RESOLVED'; }, () => { settled = 'REJECTED'; });
  setTimeout(() => process.stdin.emit('error', new Error('synthetic stdin failure')), 50);
  setTimeout(() => { console.log(settled); process.exit(0); }, 500);
" < <(sleep 5) 2>&1 | tail -1)
assert_equals "REJECTED" "$SETTLE" \
  "req-002: readStdin rejects on a stdin error instead of hanging forever"

# End-to-end, in the exact shape a hook uses it: await inside a try/catch that
# exits 0. The shared version must reach the catch and exit 0.
node --input-type=module -e "
  import { readStdin } from '$ENF/read-stdin.mjs';
  setTimeout(() => process.stdin.emit('error', new Error('synthetic stdin failure')), 50);
  try { await readStdin(); process.exit(0); } catch { process.exit(0); }
" < <(sleep 5) >/dev/null 2>&1
assert_exit_zero $? "req-002: a hook using the shared readStdin exits 0 on a stdin stream error"

# Control: the pre-extraction shape (no "error" handler) never settles its
# promise, so the stream's error surfaces as an unhandled "error" event that
# bypasses the hook's own top-level try/catch entirely and aborts the process
# non-zero. That is the latent NFR-001 violation consolidating fixed, and the
# reason the discrepancy was resolved toward the error-handling variant rather
# than away from it.
node --input-type=module -e "
  function readStdinOld() {
    return new Promise((resolve) => {
      let data = '';
      process.stdin.setEncoding('utf-8');
      process.stdin.on('data', (chunk) => { data += chunk; });
      process.stdin.on('end', () => resolve(data));
      process.stdin.resume();
    });
  }
  setTimeout(() => process.stdin.emit('error', new Error('synthetic stdin failure')), 50);
  try { await readStdinOld(); process.exit(0); } catch { process.exit(0); }
" < <(sleep 5) >/dev/null 2>&1
PRE_EXIT=$?
if [ "$PRE_EXIT" -ne 0 ]; then
  assert_equals "0" "0" "req-002: the pre-extraction readStdin shape exits non-zero on the same input (the bug this fixed)"
else
  assert_equals "non-zero" "0" "req-002: the pre-extraction readStdin shape exits non-zero on the same input (the bug this fixed)"
fi

# The rejection must land on each caller's existing fail-open path, so no hook
# turns a stdin error into a non-zero exit. Each caller either wraps its await
# in a top-level try/catch or attaches .catch() to its main().
echo ""
echo "=== req-002: every readStdin caller still exits 0 on a rejected stdin ==="
for caller in "${READSTDIN_CALLERS[@]}"; do
  NAME="$(basename "$caller")"
  GUARDED=$(node -e '
    const fs = require("fs");
    const s = fs.readFileSync(process.argv[1], "utf8");
    // Either a top-level try/catch, or main().catch(...)
    const hasTry = /^try\s*\{/m.test(s) && /^\}\s*catch/m.test(s);
    const hasMainCatch = /\)\.catch\(/.test(s) || /main\(\)\.catch/.test(s);
    console.log(hasTry || hasMainCatch ? "guarded" : "unguarded");
  ' "$caller")
  assert_equals "guarded" "$GUARDED" "req-002: $NAME routes a readStdin rejection to a fail-open catch"
done

print_summary
