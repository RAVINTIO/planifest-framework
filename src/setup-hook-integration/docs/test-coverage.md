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
- Boot-file deletion allowlist (REQ-004, 0000020), 13 live-invocation assertions, `test-0000020-req-004-boot-file-deletion-script.sh`

## What is not tested

- `skill-sync.sh` operations (add, remove, preserve, sync) — no automated tests
- `commit-msg` hook warning output — no automated tests
- `gate-write.mjs` and `check-design.mjs` enforcement — no automated tests
- Setup.ps1 correctness — partially covered by `test_setup.ps1`
- `Write-SetupFlagsMarker` (setup.ps1, 0000020), checked statically only, no `pwsh` runtime in this dev environment (Q-006)

## Recommendation

Add a `test-skill-sync.sh` covering: add (mock curl), install, remove, sync, preserve/unpreserve, and validate_skill_name rejection.
