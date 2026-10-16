# Changelog (0000031-ci-test-and-powershell-coverage, 16 Oct 2026)

**Feature:** CI test and PowerShell coverage
**Pipeline run:** P0 to P9 in continuous mode. No phases skipped.
**PR:** https://github.com/planifest/planifest-framework/pull/58 (shared with 0000032 on the same branch)

## What Was Built

- **The suite runs in CI.** A `test-suite` job runs `run-tests.sh` on `ubuntu-latest` and `macos-latest`, with `fail-fast: false`.
- **Failures are named.** `run-tests.sh` lists each failed suite by file name before its summary.
- **`setup.ps1` runs in CI.** A `setup-powershell` job runs `test_setup.ps1` under PowerShell 7 on `windows-latest`.
- **The setup-flags marker is checked live.** `test_setup.ps1` parses `.planifest-setup-flags` after a plain run and a flagged run, and rejects three broken markers. This closes backlog 0000050.
- **A random test failure is fixed.** Eight suites piped output into `grep -q` under pipefail, which failed at random on macOS. They now use here-strings, and a guard suite blocks the pattern.
- **A brittle version check is fixed.** A 0000030 test compared the product version with a fixed `0.29.0`. It now reads `planifest-framework/component.yml`.

## Artifacts Produced

- `feature-brief.md`, `design.md`, `discovery.md`, and `build-log.md`
- `execution-plan.md`, `scope.md`, `risk-register.md`, and `domain-glossary.md`
- `requirements/` (REQ-001 to REQ-004) and `adr/` (ADR-001 to ADR-003)
- `security-report.md`, `recommendations.md`, and `iteration-log.md`

## Decisions

- ADR-001: The suite runs on Linux and macOS, and `test_setup.ps1` runs under PowerShell 7 on Windows. 5.1 is not tested.
- ADR-002: The new jobs stay out of the consumer workflow copy.
- ADR-003: New jobs use `pull_request`, `contents: read`, no secrets, and a 10-minute timeout.

## Skipped Phases

None
