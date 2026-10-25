#!/usr/bin/env bash
# Verified by: execution
# Verified by: unit
# Verified by: integration
# test-0000039-req-003-environment-variables.sh
# Feature 0000039-ravintio-rebrand, req-003 (environment variables), ADR-004.
#   AC1: the inventory command returns only the kept names in the kept files.
#   AC2: the OpenCode adapter falls back to the legacy session variable
#        silently and prefers the RAVINTIO twin when both are set.
#   AC3: run-tests.sh honours the RAVINTIO shard pair and CI sets the same pair.
# The full-suite half of AC1 is covered by the P4 run, not by this suite,
# because a suite cannot run the full suite that contains it.
# Run from any directory: bash ravintio-framework/tests/test-0000039-req-003-environment-variables.sh

set -o pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ADAPTER="$ROOT/ravintio-framework/hooks/adapters/opencode/index.ts"
RUNNER="$SCRIPT_DIR/run-tests.sh"
WORKFLOW="$ROOT/.github/workflows/ravintio.yml"

# ---------------------------------------------------------------------------
# AC1: inventory command
# ---------------------------------------------------------------------------

INVENTORY="$(git -C "$ROOT" grep -ohE 'PLANIFEST_[A-Z_]+' -- . ':!plan/_archive' ':!plan/changelog' ':!plan/_migrations' ':!plan/current' ':!plan/backlog/*/_reference' ':!ravintio-framework/migrations' ':!ravintio-framework/tests/test-0000039-*' | sort -u)"

EXPECTED_NAMES="PLANIFEST_SESSION_ID
PLANIFEST_TELEMETRY
PLANIFEST_TELEMETRY_URL"
assert_equals "$EXPECTED_NAMES" "$INVENTORY" "req-003 AC1: the inventory returns only PLANIFEST_SESSION_ID and PLANIFEST_TELEMETRY*"

# Every file that holds a kept name must be a kept file.
SESSION_FILES="$(git -C "$ROOT" grep -lE 'PLANIFEST_SESSION_ID' -- . ':!plan/_archive' ':!plan/changelog' ':!plan/_migrations' ':!plan/current' ':!plan/backlog/*/_reference' ':!ravintio-framework/migrations' ':!ravintio-framework/tests/test-0000039-req-006*' | sort)"
BAD_SESSION=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in
    ravintio-framework/hooks/adapters/opencode/index.ts) ;;
    ravintio-framework/tests/*) ;;
    *) BAD_SESSION=1; echo "  unexpected PLANIFEST_SESSION_ID file: $f" ;;
  esac
done <<< "$SESSION_FILES"
assert_equals "0" "$BAD_SESSION" "req-003 AC1: PLANIFEST_SESSION_ID appears only in the adapter and test files"

TELEMETRY_FILES="$(git -C "$ROOT" grep -lE 'PLANIFEST_TELEMETRY' -- . ':!plan/_archive' ':!plan/changelog' ':!plan/_migrations' ':!plan/current' ':!plan/backlog/*/_reference' ':!ravintio-framework/migrations' ':!ravintio-framework/tests/test-0000039-req-006*' ':!ravintio-framework/tests/test-0000039-*' | sort)"
PACK="ravintio-framework"
EXPECTED_TELEMETRY_FILES="$PACK/tests/test-0000030-req-003-telemetry-pipeline-text-removal.sh
$PACK/tests/test-0000030-req-004-install-clean-up-and-retired-flags.sh"
assert_equals "$EXPECTED_TELEMETRY_FILES" "$TELEMETRY_FILES" "req-003 AC1: PLANIFEST_TELEMETRY* appears only in the two 0000030 test files"

# ---------------------------------------------------------------------------
# AC2: OpenCode adapter session id fallback
# ---------------------------------------------------------------------------

# Static checks on getSessionId: read order and no warning call.
FN_SRC="$(awk '/^function getSessionId/ {p=1} p {print} p && /^}/ {exit}' "$ADAPTER")"
assert_contains "RAVINTIO_SESSION_ID" "$FN_SRC" "req-003 AC2: getSessionId reads RAVINTIO_SESSION_ID"
assert_contains "PLANIFEST_SESSION_ID" "$FN_SRC" "req-003 AC2: getSessionId falls back to PLANIFEST_SESSION_ID"

R_LINE="$(grep -n 'RAVINTIO_SESSION_ID' <<< "$FN_SRC" | head -1 | cut -d: -f1)"
P_LINE="$(grep -n 'PLANIFEST_SESSION_ID' <<< "$FN_SRC" | head -1 | cut -d: -f1)"
if [ -n "$R_LINE" ] && [ -n "$P_LINE" ] && [ "$R_LINE" -lt "$P_LINE" ]; then
  echo "  PASS: req-003 AC2: RAVINTIO_SESSION_ID is read before PLANIFEST_SESSION_ID"
  PASS=$((PASS + 1))
else
  echo "  FAIL: req-003 AC2: RAVINTIO_SESSION_ID is read before PLANIFEST_SESSION_ID (lines: '${R_LINE}' '${P_LINE}')"
  FAIL=$((FAIL + 1))
fi

if grep -qE 'console\.|process\.stderr|warn' <<< "$FN_SRC"; then
  echo "  FAIL: req-003 AC2: getSessionId prints no warning"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: req-003 AC2: getSessionId prints no warning"
  PASS=$((PASS + 1))
fi

# Behavioural check: run the extracted function under Node type stripping.
HARNESS="$TMP/harness.ts"
{
  echo 'import { existsSync, readFileSync, writeFileSync, mkdirSync } from "node:fs";'
  echo 'import { join, dirname } from "node:path";'
  echo 'import { randomUUID } from "node:crypto";'
  printf '%s\n' "$FN_SRC"
  echo 'process.stdout.write(getSessionId(process.argv[2]));'
} > "$HARNESS"

mkdir -p "$TMP/cwd"
run_harness() {
  # args: env assignments for env(1)
  env -u RAVINTIO_SESSION_ID -u PLANIFEST_SESSION_ID "$@" node --experimental-strip-types "$HARNESS" "$TMP/cwd" 2>"$TMP/stderr"
}

PROBE="$(env -u RAVINTIO_SESSION_ID RAVINTIO_SESSION_ID=probe node --experimental-strip-types "$HARNESS" "$TMP/cwd" 2>/dev/null)"
if [ "$PROBE" = "probe" ]; then
  ONLY_LEGACY="$(run_harness PLANIFEST_SESSION_ID=legacy-id)"
  assert_equals "legacy-id" "$ONLY_LEGACY" "req-003 AC2: only PLANIFEST_SESSION_ID set, the adapter uses its value"
  assert_equals "" "$(cat "$TMP/stderr")" "req-003 AC2: only PLANIFEST_SESSION_ID set, the adapter prints no warning"
  BOTH="$(run_harness PLANIFEST_SESSION_ID=legacy-id RAVINTIO_SESSION_ID=new-id)"
  assert_equals "new-id" "$BOTH" "req-003 AC2: both set, the adapter uses RAVINTIO_SESSION_ID"
else
  echo "  SKIP: req-003 AC2: node cannot run TypeScript here, the static checks above stand in"
fi

# ---------------------------------------------------------------------------
# AC3: sharding
# ---------------------------------------------------------------------------

# Fixture: a copy of the runner beside five stub suites that print a marker.
FIX="$TMP/fixture/tests"
mkdir -p "$FIX"
cp "$RUNNER" "$FIX/run-tests.sh"
for n in a b c d e; do
  printf '#!/usr/bin/env bash\necho "RAN-%s"\nexit 0\n' "$n" > "$FIX/test-$n.sh"
done

SHARD_OUT="$(env RAVINTIO_SHARD_INDEX=2 RAVINTIO_SHARD_COUNT=3 bash "$FIX/run-tests.sh" 2>&1)"
SHARD_RAN="$(grep -o 'RAN-[a-e]' <<< "$SHARD_OUT" | tr '\n' ' ')"
assert_equals "RAN-b RAN-e " "$SHARD_RAN" "req-003 AC3: RAVINTIO shard 2 of 3 runs the second and fifth suites"

LEGACY_OUT="$(env -u RAVINTIO_SHARD_INDEX -u RAVINTIO_SHARD_COUNT PLANIFEST_SHARD_INDEX=2 PLANIFEST_SHARD_COUNT=3 bash "$FIX/run-tests.sh" 2>&1)"
LEGACY_RAN="$(grep -o 'RAN-[a-e]' <<< "$LEGACY_OUT" | tr '\n' ' ')"
assert_equals "RAN-a RAN-b RAN-c RAN-d RAN-e " "$LEGACY_RAN" "req-003 AC3: the old shard names no longer select a slice"

# The runner source names only the RAVINTIO pair.
assert_contains "RAVINTIO_SHARD_INDEX" "$(cat "$RUNNER")" "req-003 AC3: run-tests.sh reads RAVINTIO_SHARD_INDEX"
assert_contains "RAVINTIO_SHARD_COUNT" "$(cat "$RUNNER")" "req-003 AC3: run-tests.sh reads RAVINTIO_SHARD_COUNT"

# The CI workflow sets the same two names.
assert_contains "RAVINTIO_SHARD_INDEX:" "$(cat "$WORKFLOW")" "req-003 AC3: ravintio.yml sets RAVINTIO_SHARD_INDEX"
assert_contains "RAVINTIO_SHARD_COUNT:" "$(cat "$WORKFLOW")" "req-003 AC3: ravintio.yml sets RAVINTIO_SHARD_COUNT"

print_summary
