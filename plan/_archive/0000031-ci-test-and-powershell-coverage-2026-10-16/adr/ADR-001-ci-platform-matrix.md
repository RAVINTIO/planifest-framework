---
title: "ADR 001: CI platform matrix"
summary: "The suite runs on ubuntu-latest and macos-latest, and test_setup.ps1 runs under PowerShell 7 on windows-latest. Windows PowerShell 5.1 is not tested."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - CI platform matrix

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000031-ci-test-and-powershell-coverage
**Component:** repository CI
**Date:** 2026-10-16

## Context

The design declares the stack as Bash, PowerShell 7, and Node.js built-ins, run on GitHub-hosted runners. The suite is bash and passes on macOS. `setup.ps1` has had no live run since 0000020, and `docs/architecture-overview.md` lists PowerShell 7+ as its runtime. The human on the loop can check only macOS locally.

## Decision

- The suite job runs `run-tests.sh` as a matrix over `ubuntu-latest` and `macos-latest`, with `fail-fast: false`.
- The Windows job runs `test_setup.ps1` with `shell: pwsh` on `windows-latest`, and fails if the major version is below 7.
- No job runs Windows PowerShell 5.1 or runs `run-tests.sh` under Git Bash on Windows.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| macOS runners only, with `pwsh` on macOS | Every CI result matches a local Mac run | Never exercises Windows paths, drive letters, or junctions | The human on the loop chose all three platforms at P0 |
| Add Windows PowerShell 5.1 | Covers older Windows installs | Turns an undocumented runtime into a blocking check | 5.1 isn't a documented runtime. Deferred to the backlog. |
| Run the bash suite on Windows under Git Bash | Covers the bash setup path on Windows | Many suites assume POSIX tools, so the first run would need wide fixes | Out of this feature's size. Deferred. |

## Affected Components

| Component | Impact |
|-----------|--------|
| repository CI | Gains three job legs. |
| planifest-framework | `run-tests.sh` and `test_setup.ps1` must pass on the new platforms. |

## Consequences

**Positive:**
- A PR that breaks the suite on Linux or macOS, or breaks `setup.ps1` under PowerShell 7, shows a red check.
- `Write-SetupFlagsMarker` gets its first live run (backlog 0000050).

**Negative:**
- Linux and Windows fixes can only be checked by pushing and waiting for CI.
- Each PR uses more runner minutes. macOS minutes cost the most.

**Risks:**
- A `-latest` image update can turn a job red with no code change.

## Related ADRs

- ADR-002 - related-to
- ADR-003 - related-to

## Supersedes

- None

## Superseded By

- None
