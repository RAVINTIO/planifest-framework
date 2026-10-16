# Test Coverage — setup-hook-integration

## Coverage Summary

| Type | Coverage | Notes |
|---|---|---|
| Unit | 0% | No unit tests for individual bash functions |
| Integration | Partial | Setup tests under `planifest-framework/tests/` cover flag handling and hook wiring |
| E2E | Partial | `test_setup.sh` / `test_setup.ps1` validate basic setup paths for tool targets |

## What is tested

- Basic tool target setup (claude-code, cursor, etc.) — covered by `test_setup.sh`
- `.planifest-setup-flags` marker write, content, per-tool directory, no-write-on-failure (REQ-008, 0000020), 21 live-invocation assertions, `test-0000020-req-008-install-time-marker-write.sh`
- Install clean-up and retired flags (0000030 REQ-004, NFR-002), 220 live-invocation assertions, `test-0000030-req-004-install-clean-up-and-retired-flags.sh`. It covers the retired-flag notice and exit 0, the marker without retired flags, every clean-up step and its output, the malformed-file byte-identical skip, the Node-missing skip, the parent-path containment check (F3), failed delete and rename (F4), the exclusive temporary file and mode (F5), the opencode `opencode.json` skip (F1), and static checks of the PowerShell source (F2)
- Removed files and residue (0000030 REQ-001, REQ-002, NFR-001), `test-0000030-req-001-002-removed-files-and-residue.sh`
<!-- BEGIN retired-integrations (0000030) -->
- Telemetry pipeline text removal (0000030 REQ-003), `test-0000030-req-003-telemetry-pipeline-text-removal.sh`
<!-- END retired-integrations (0000030) -->
- Refresh-setup migration and self-hosting (0000030 REQ-005), `test-0000030-req-005-refresh-setup-migration-and-self-hosting.sh`
- Boot-file deletion allowlist (REQ-004, 0000020), 13 live-invocation assertions, `test-0000020-req-004-boot-file-deletion-script.sh`

<!-- BEGIN retired-integrations (0000030) -->
## Tests deleted by 0000030

The feature deleted every test of the removed telemetry and context-mode integrations. That covers the `test-0000017`, `test-0000018`, `test-0000024-req-001`, `test-0000026`, `test-0000027` telemetry suites, the telemetry cases in the 0000028 suites, `test-setup-telemetry.sh`, `test-skill-telemetry.sh`, `test-context-pressure.sh`, `regression/test-skill-telemetry.sh`, and `src/context-mode-hooks/tests/`. Surviving suites lost only their telemetry and context-mode assertions.
<!-- END retired-integrations (0000030) -->

## What is not tested

- `skill-sync.sh` operations (add, remove, preserve, sync) — no automated tests
- `commit-msg` hook warning output — no automated tests
- `gate-write.mjs` and `check-design.mjs` enforcement — no automated tests
- Setup.ps1 correctness — partially covered by `test_setup.ps1`
- `Write-SetupFlagsMarker` (setup.ps1, 0000020), run live by the Windows CI job since 0000031. `test_setup.ps1` checks every marker field (Q-006, resolved).
- The `setup.ps1` clean-up and `Write-SettingsFile` (0000030) run live in the Windows CI job on a fresh install, with nothing stale to remove. The clean-up of stale entries and the retired-flag branch are still checked statically only (Q-013).

## Recommendation

Add a `test-skill-sync.sh` covering: add (mock curl), install, remove, sync, preserve/unpreserve, and validate_skill_name rejection.
