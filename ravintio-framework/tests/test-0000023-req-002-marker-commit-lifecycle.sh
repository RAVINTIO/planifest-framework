#!/usr/bin/env bash
# Tests for feature 0000023-framework-pipeline-fixes, req-002:
# marker commit lifecycle (creation-side: backlog 0000030; deletion-side:
# backlog 0000028).
#
# Covers: session markers (plan/.orchestrator-active, plan/.orchestrator-ack,
# plan/.run-mode) must be committed at the point they are written (P0), and
# their deletion is committed in the P9 marker step before the tag, with a
# git ls-files check (moved from P7 by feature 0000032, req-001).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ORCHESTRATOR="$SCRIPT_DIR/../skills/ravintio-orchestrator/SKILL.md"
SHIP_AGENT="$SCRIPT_DIR/../skills/ravintio-ship-agent/SKILL.md"

for f in "$ORCHESTRATOR" "$SHIP_AGENT"; do
  if [ ! -f "$f" ]; then
    echo "  FAIL: $f not found"
    ((FAIL++)) || true
    print_summary
  fi
done

ORCH_CONTENT=$(cat "$ORCHESTRATOR")
SHIP_CONTENT=$(cat "$SHIP_AGENT")

echo ""
echo "=== req-002: creation-side commit instructions (orchestrator P0) ==="

P0_CONTENT=$(cat "$SCRIPT_DIR/../skills/ravintio-orchestrator/references/phase-0-assess-and-coach.md")
assert_contains "Write the sentinel" "$P0_CONTENT" \
  "req-002: Step 1 (write the sentinel) still present"
assert_contains "Include this file in the P0 commit." "$P0_CONTENT" \
  "req-002: .orchestrator-active commit instruction present"

assert_contains "Write strict-mode ack" "$P0_CONTENT" \
  "req-002: Step 5 (write strict-mode ack) still present"
assert_contains "include \`plan/.orchestrator-ack\` in the P0 commit" "$P0_CONTENT" \
  "req-002: .orchestrator-ack commit instruction present"

echo ""
echo "=== req-002: deletion-side commit (ship-agent P9 marker step) ==="

# Updated by feature 0000032, req-001: marker deletion moved from P7 into a
# P9 marker step that commits before the Step 9 tag. P7 Step 7 no longer
# stages any marker.
assert_contains "git add plan/current/ plan/_archive/ plan/changelog/ docs/about.md" \
  "$SHIP_CONTENT" "req-002: P7 Step 7 git add stages plan/current/ explicitly"
# Updated by feature 0000036, req-003: the subject holds no placeholder and
# the feature ID moves to the commit body.
assert_contains 'git commit -m "plan(p9): clear session markers" -m "{feature-id}"' \
  "$SHIP_CONTENT" "req-002: P9 marker step commits the marker deletions"

echo ""
echo "=== req-002: marker tracking check before the tag ==="

assert_contains "git ls-files plan/.orchestrator-active plan/.orchestrator-ack plan/.run-mode" \
  "$SHIP_CONTENT" "req-002: P9 marker step runs git ls-files against all three markers"

assert_contains "Clear session markers" "$SHIP_CONTENT" \
  "req-002: P9 marker step section exists"

print_summary
