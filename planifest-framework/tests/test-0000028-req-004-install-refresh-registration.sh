#!/usr/bin/env bash
# test-0000028-req-004-install-refresh-registration.sh
#
# REQ-004 asserts that enforcement hooks are wired so they actually run.
# Feature 0000030 removed the telemetry halves of this test.
#
# The live-firing half cannot be asserted here. A hook firing requires a real
# host tool session. What IS assertable without one is that setup.sh wires each
# enforcement hook through node.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FRAMEWORK_DIR="$REPO_ROOT/planifest-framework"

source "$SCRIPT_DIR/helpers/assert.sh"

SETUP_SH="$FRAMEWORK_DIR/setup.sh"
setup_content=$(cat "$SETUP_SH")

echo "=== req-004 / SEC-001: enforcement hooks are invoked through node ==="

# P5 SEC-001. These were wired as bare .mjs paths relying on a shebang plus an
# executable bit. That bit is a committed file mode, and 9 of 10 hook files are
# mode 100644, so the shell could not exec them: the command exited 126 and the
# hook silently never ran. A PreToolUse hook that fails to start looks exactly
# like one that passed, so gate-write, em-dash-guard and check-design
# were dead on every bash install.
#
# The suite could not catch this before because every test invokes hooks via
# `node` directly, never through the command string setup.sh actually writes.
# These assertions check the wiring itself, which is where the defect lived.
for hook in gate-write ratchet-check em-dash-guard auto-trigger-orchestrator \
            check-orchestrator-presence check-design; do
  assert_contains "node \\\"\$hooks_dir_rel/$hook.mjs\\\"" "$setup_content" \
    "req-004: setup.sh invokes $hook.mjs through node, not as a bare path"
done

# Guard against a regression that reintroduces a bare-path wiring for any
# enforcement hook, including one added later.
bare_path_wiring=$(printf '%s' "$setup_content" \
  | grep -cE '^\s*local [a-z_]+_cmd="\$hooks_dir_rel/[a-z-]+\.mjs"' || true)
assert_equals "0" "$bare_path_wiring" \
  "req-004: no enforcement hook is wired as a bare path without node"

print_summary
