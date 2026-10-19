---
title: "Scope - CI test and PowerShell coverage"
summary: "Defines explicit boundaries of what is in scope and out of scope."
status: "active"
version: "0.1.0"
---
# Scope - CI test and PowerShell coverage

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000031-ci-test-and-powershell-coverage
**Version:** 0.30.0

## In Scope

- A suite job in `.github/workflows/planifest.yml` that runs `run-tests.sh` on `ubuntu-latest` and `macos-latest`, with `fail-fast: false` (REQ-001).
- A `Failed suites:` list in `run-tests.sh` output (REQ-002).
- A Windows job that runs `test_setup.ps1` under PowerShell 7 (REQ-003).
- Marker assertions in `test_setup.ps1` for `.planifest-setup-flags` (REQ-004, backlog 0000050).
- Fixes in tests or setup scripts that the new jobs show to be needed, limited to `setup.ps1`, `test_setup.ps1`, `run-tests.sh`, and the `test-*.sh` suites.
- A backlog entry for the Windows PowerShell 5.1 deferral.
- Docs updates for the new CI jobs.

## Out of Scope

- Windows PowerShell 5.1. The documented runtime is PowerShell 7+.
- The consumer workflow copy at `planifest-framework/hooks/planifest.yml` (0000019 ADR).
- Branch protection settings on GitHub. Only the human on the loop can change them.
- Backlog 0000089. CI starts the suite from the repository root.
- Temp-folder hygiene in the 36 suites that don't use `mktemp`. CI runners are discarded after each run.

## Deferred

- Windows PowerShell 5.1 coverage. Nothing in this feature is blocked by it. It blocks any claim that `setup.ps1` supports 5.1.
- Running `run-tests.sh` on Windows under Git Bash. Nothing in this feature is blocked by it. It blocks CI coverage of the bash setup path on Windows.
- `setup.ps1` defects that need changes beyond the in-scope files. Each goes to the backlog when found. The Windows job stays red only if such a defect breaks `test_setup.ps1`, and the run then escalates.
