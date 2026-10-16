---
title: "Risk Register - CI test and PowerShell coverage"
summary: "Technical, operational, and security risks with their mitigations."
status: "active"
version: "0.1.0"
---
# Risk Register - CI test and PowerShell coverage

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000031-ci-test-and-powershell-coverage
**Version:** 0.30.0
**Overall Risk Level:** medium

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | Suites that pass on macOS fail on `ubuntu-latest`, for example through GNU and BSD tool differences or a missing `pwsh`. | medium | medium | Fix each in this feature. Each fix needs a push and a CI run, because no local Linux check exists. | open |
| R-002 | technical | The Windows job exposes `setup.ps1` defects too large for this feature. | medium | medium | Fix defects within the in-scope files. File larger ones to the backlog and escalate if they keep `test_setup.ps1` red. | open |
| R-003 | operational | `-latest` runner image updates change tool versions and make jobs fail without a code change. | low | low | `timeout-minutes: 10` stops runaway jobs. The reliability NFR runs the workflow twice on the final commit. | open |
| R-004 | technical | `ConvertFrom-Json` hides a one-item array that `ConvertTo-Json` wrote as a string, so the REQ-004 check passes wrongly. | medium | medium | REQ-004 checks the raw marker text for a JSON array literal as well as the parsed value. | open |
| R-005 | security | A workflow change widens token permissions or runs untrusted pull request code with secrets. | low | high | Jobs set `permissions: contents: read`, use no secrets, and keep the `pull_request` trigger, not `pull_request_target`. | open |
| R-006 | operational | Red checks don't block merges until branch protection marks them as required. | high | medium | The P9 report tells the human on the loop which job names to mark as required. | accepted |

## Assumptions Logged as Risks

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | The suite passes on Linux as it does on macOS. | The Linux leg starts red, and R-001 applies. | open |
| A-002 | `windows-latest` runners ship PowerShell 7 as `pwsh`. | The Windows job needs an install step. | open |
| A-003 | `test_setup.ps1` runs unchanged on Windows, since it uses `$env:TEMP` and backslash paths. | The script needs fixes that only CI can check. | open |
