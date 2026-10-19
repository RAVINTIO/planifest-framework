---
title: "Requirement: req-003 - windows-pwsh-ci-job"
summary: "CI runs test_setup.ps1 under PowerShell 7 on Windows."
status: "active"
version: "0.1.0"
---
# Requirement: req-003 - windows-pwsh-ci-job

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000031-ci-test-and-powershell-coverage
**Source:** US-002
**Priority:** must-have

## User Story

As the human on the loop, I see CI fail a pull request when `setup.ps1` fails under PowerShell 7 on Windows, so that PowerShell-only defects show up before review.

## Functional Requirements
- `.github/workflows/planifest.yml` has a job on `windows-latest` that runs `planifest-framework/tests/test_setup.ps1` with `shell: pwsh`.
- The job fails when the script throws or exits non-zero.
- The job prints `$PSVersionTable.PSVersion` before the test, and fails if the major version is below 7.
- The job sets `permissions: contents: read`, uses no secrets, and sets `timeout-minutes: 10`.
- Defects the job exposes in `setup.ps1` or `test_setup.ps1` get fixed in this feature. A defect that needs changes beyond those two files goes to the backlog instead.

## Acceptance Criteria
- [ ] On a pull request to `main`, the Windows job runs `test_setup.ps1` under PowerShell 7.
- [ ] If `test_setup.ps1` throws, the job fails, and the log shows the `FAIL:` message.
- [ ] The job passes on this feature's pull request in under 10 minutes.

## Dependencies
- None. REQ-004 adds assertions that this job runs.
