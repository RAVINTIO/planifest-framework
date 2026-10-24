#!/usr/bin/env bash
# Tests for feature 0000038-token-efficiency-windows-shard.
#
# req-001: each timed hook check makes one untimed warm-up call and then one
#          timed call that must finish under 200 ms. No check retries.
#
# Verified by: unit
# Verified by: integration
#
# The helpers under test are lifted out of each suite and run against a hook
# stub that sleeps past 200 ms and counts its calls.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

STUB="$WORK/slow-hook.mjs"
COUNT="$WORK/count.txt"
cat > "$STUB" <<'EOF'
import { appendFileSync } from "node:fs";
appendFileSync(process.env.STUB_COUNT, "x\n");
Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 250);
EOF

# lift <file> <name>: prints one top-level function definition from a suite.
lift() {
  awk -v n="$2" '$0 ~ "^"n"\\(\\) \\{" {p=1} p {print} p && /^}/ {exit}' "$1"
}

SUITES=(
  "$SCRIPT_DIR/test-0000032-req-003-no-run-triage-message.sh"
  "$SCRIPT_DIR/test-0000032-req-007-stderr-block-reasons.sh"
  "$SCRIPT_DIR/test-0000032-req-009-shell-guard-path-parity.sh"
  "$SCRIPT_DIR/regression/test-0000032-req-003-no-run-triage-message.sh"
  "$SCRIPT_DIR/regression/test-0000032-req-007-stderr-block-reasons.sh"
  "$SCRIPT_DIR/regression/test-0000032-req-009-shell-guard-path-parity.sh"
)

echo "=== req-001: helpers warm up once and time one call ==="

for suite in "${SUITES[@]}"; do
  label="req-001: $(basename "$(dirname "$suite")")/$(basename "$suite")"
  case "$suite" in
    *req-009*)
      body="$(cat "$suite")"
      assert_equals "absent" "$([[ "$body" == *"run < 3"* ]] && echo present || echo absent)" \
        "$label has no best-of-three loop"
      assert_equals "absent" "$([[ "$body" == *"Math.min(best"* ]] && echo present || echo absent)" \
        "$label takes no best result"
      assert_equals "present" "$([[ "$body" == *"warm-up"* ]] && echo present || echo absent)" \
        "$label makes a warm-up call"
      ;;
    *)
      if [[ "$suite" == *req-003* ]]; then fn=run_hook; else fn=run_node; fi
      # now_ms is a one-line definition, so it stays outside the lift.
      helpers="now_ms() { perl -MTime::HiRes=time -e 'printf \"%d\\n\", time * 1000'; }
$(lift "$suite" "$fn")
$(lift "$suite" under_200)"
      : > "$COUNT"
      result="$(
        export STUB_COUNT="$COUNT"
        HOOK="$STUB"
        OUTFILE="$WORK/out.txt"; ERRFILE="$WORK/err.txt"
        eval "$helpers"
        if [ "$fn" = run_hook ]; then run_hook '{}'; else run_node "$WORK" "$STUB" '{}'; fi
        under_200 "stub"
      )"
      assert_equals "2" "$(wc -l < "$COUNT" | tr -d ' ')" "$label runs the hook twice, warm-up plus one timed call"
      assert_contains "FAIL:" "$result" "$label fails a call that takes 200 ms or more"
      ;;
  esac
  assert_equals "present" "$([[ "$(cat "$suite")" == *"-lt 200"* ]] && echo present || echo absent)" \
    "$label keeps the 200 ms limit"
done

print_summary
