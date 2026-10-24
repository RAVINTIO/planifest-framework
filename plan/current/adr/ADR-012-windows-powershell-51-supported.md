---
title: "ADR 012: Windows PowerShell 5.1 is a supported runtime"
summary: "Windows PowerShell 5.1 becomes a supported runtime for setup.ps1. A new setup-powershell-51 job runs test_setup.ps1 under shell powershell on windows-latest. The existing setup-powershell job stays as the PowerShell 7 check. This amends 0000031 ADR 001."
status: "accepted"
version: "0.1.0"
---
# ADR-012 - Windows PowerShell 5.1 is a supported runtime

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Component:** repository CI, setup-hook-integration
**Date:** 2026-10-24

## Context

0000031 ADR 001 limited the Windows job to PowerShell 7 and said Windows PowerShell 5.1 is not tested. It rejected 5.1 because 5.1 was not a documented runtime. Backlog 0000092 asks for the 5.1 coverage.

Windows 10 and Windows 11 ship Windows PowerShell 5.1 and no `pwsh`. A person on a stock Windows machine runs `setup.ps1` under 5.1. The two versions differ in encoding, JSON handling, and `ConvertFrom-Json` date handling (R-002). Other work already shows the cost. 0000036 ADR 005 records that 5.1 reads a file with no byte order mark in the ANSI code page. Q-014 in `src/setup-hook-integration/docs/quirks.md` covers the BOM-less `Write-SettingsFile`.

GitHub-hosted `windows-latest` runners have Windows PowerShell 5.1 preinstalled (A-003). `shell: powershell` selects it, and `shell: pwsh` selects PowerShell 7.

## Decision

1. Windows PowerShell 5.1 becomes a supported runtime for `setup.ps1`. `docs/architecture-overview.md` lists "PowerShell 7+ or Windows PowerShell 5.1" in its runtime table and CI table.
2. A new job `setup-powershell-51` in `.github/workflows/planifest.yml` runs on `windows-latest` with `shell: powershell`. It runs `./planifest-framework/tests/test_setup.ps1`.
3. The job first prints `$PSVersionTable.PSVersion` and fails if the major version is not 5.
4. The job follows 0000031 ADR 002 and ADR 003. It stays in this repository's workflow, runs on `pull_request` only, sets `permissions: contents: read`, reads no secret, and sets `timeout-minutes: 10`. A comment above the job states that it is repository-only.
5. The job is separate from `setup-powershell`. The existing job keeps `shell: pwsh` and its PowerShell 7 version check. It does not become a matrix.
6. `setup.ps1` and `test_setup.ps1` must run under 5.1. P3 fixes each 5.1 difference in the file that holds it, and each fix keeps PowerShell 7 behaviour.
7. The job verifies on the draft PR's CI run, per "CI before P4" in `design.md`. P3 fixes a red 5.1 check before P4.

This ADR amends 0000031 ADR 001 on the Windows PowerShell 5.1 point only. The Git Bash point of that ADR is amended by ADR-013.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Matrix on `setup-powershell` over `pwsh` and `powershell` | One job definition | The PowerShell 7 version check would need a per-leg branch. The existing job and its `0000031` tests would change. Check names would change. | The existing job must stay as it is, so `test-0000031-req-001-003-ci-jobs.sh` stays green. |
| Leave 5.1 untested | No new CI minutes | A stock Windows install runs an untested runtime. R-002 has no control. | Backlog 0000092 asks for the coverage, and 5.1 is the default Windows shell. |
| Test 5.1 as a non-blocking job with `continue-on-error` | A defect does not block the PR | A red result reads as a pass in `gh pr checks`. The leg guards nothing. | A leg that cannot fail proves nothing. |
| Declare 5.1 unsupported and require PowerShell 7 | Smaller test surface | Excludes the default Windows shell. Needs an install step for every Windows user. | The human on the loop chose to support 5.1. |

## Affected Components

| Component | Impact |
|-----------|--------|
| repository CI | Gains the `setup-powershell-51` job. |
| setup-hook-integration | `setup.ps1` and `test_setup.ps1` must run under 5.1. |
| planifest-framework | `docs/architecture-overview.md` names 5.1 as supported. |

## Consequences

**Positive:**
- A 5.1 defect in `setup.ps1` fails a check before merge.
- The BOM-less settings writer (Q-014) gets a live run under the runtime where it matters.
- The support claim in the docs matches a tested leg.

**Negative:**
- Each PR uses up to 10 more Windows runner minutes (R-013).
- Every future change to `setup.ps1` must keep 5.1 syntax and behaviour.

**Risks:**
- A `windows-latest` image update can change the 5.1 build and turn the job red with no code change.
- If the 5.1 leg reveals many differences, P3 time grows. P3 fixes them before P4.

## Requirements governed

- req-011

## Related ADRs

- 0000031 ADR 001 - amends
- 0000031 ADR 002 - depends-on
- 0000031 ADR 003 - depends-on
- ADR-013 - related-to

## Supersedes

- None

## Superseded By

- None
