#!/usr/bin/env bash
# Tests for feature 0000030, req-001 and req-002: the Context Mode and
# Telemetry files are gone, nothing imports them, product.yml lists two
# components, CI has no telemetry job, and NFR-001 finds no residual
# reference outside the allowlist in plan/current/execution-plan.md.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT="$(cd "$FRAMEWORK/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
cd "$ROOT" || exit 1

echo "=== req-001 / req-002: removed paths do not exist ==="
for rel in planifest-framework/hooks/context-mode src/context-mode-hooks docs/context-mode.md \
  planifest-framework/hooks/telemetry \
  planifest-framework/hooks/enforcement/check-telemetry-failures.mjs \
  planifest-framework/hooks/enforcement/check-telemetry-receipts.mjs \
  planifest-framework/hooks/enforcement/phase-enum.mjs \
  planifest-framework/scripts/verify-telemetry-hooks.mjs \
  planifest-framework/tests/helpers/controllable-backend.mjs; do
  if [ -e "$rel" ]; then state=present; else state=absent; fi
  assert_equals "absent" "$state" "req-001/002: $rel is removed"
done

echo "=== req-002: no code imports a removed module ==="
importers=$(git grep -lE "from ['\"][^'\"]*(hooks/telemetry/|hooks/context-mode/|phase-enum\.mjs|check-telemetry-(failures|receipts)\.mjs|controllable-backend\.mjs)" \
  -- '*.mjs' '*.js' '*.ts' | wc -l | tr -d ' ')
assert_equals "0" "$importers" "req-002: no .mjs, .js, or .ts file imports a removed module"

echo "=== req-001: product.yml lists two components ==="
count=$(grep -cE '^  - id: ' product.yml)
assert_equals "2" "$count" "req-001: product.yml components[] has two items"
assert_equals "0" "$(grep -c 'context-mode-hooks' product.yml)" "req-001: product.yml never names context-mode-hooks"
version=$(node planifest-framework/scripts/product-version.mjs 2>/dev/null)
# Compare with the framework component's own version rather than a fixed
# value, so a later version bump doesn't break this check (0000031 P4).
framework_version=$(sed -n 's/^version: "\(.*\)"$/\1/p' planifest-framework/component.yml)
assert_equals "$framework_version" "$version" "req-001: product-version.mjs derives the framework component version"

echo "=== req-002: CI has no telemetry job ==="
assert_equals "0" "$(grep -ci 'telemetry' .github/workflows/planifest.yml)" "req-002: .github/workflows/planifest.yml has no telemetry job or step"

echo "=== NFR-001: no residual reference outside the allowlist ==="
PATTERN='context-mode|context_mode|context mode|structured-telemetry|telemetry|emit_event|backend-url'
residue=""
while IFS= read -r f; do
  case "$f" in
    docs/decisions-index.md|planifest-framework/standards/reference/backend-stack-evaluation.md) continue ;;
    planifest-framework/migrations/migrate-remove-context-mode-and-telemetry.md) continue ;;
    planifest-framework/tests/test-0000030-*) continue ;;
  esac
  hits=$(awk '/BEGIN retired-integrations/{f=1} /END retired-integrations/{f=0;next} !f' "$f" \
    | grep -inE "$PATTERN" \
    | grep -vE '[0-9]{7}-[a-z0-9-]*(context-mode|telemetry)' || true)
  case "$f" in
    planifest-framework/tests/*)
      # Comments and absence assertions in older tests are allowlisted.
      hits=$(printf '%s\n' "$hits" | grep -vE '^[0-9]+:[[:space:]]*#|assert_equals "0"|grep_count|context-mode free|occurrences in|^$' || true) ;;
  esac
  [ -n "$hits" ] && residue="$residue $f"
done < <(git grep -ilE "$PATTERN" -- . ':!plan' ':!planifest-framework/external-skills')
assert_equals "" "$(echo $residue)" "NFR-001: no residual reference outside the allowlist"

print_summary
