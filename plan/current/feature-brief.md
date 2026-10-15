---
title: "Feature Brief - CI test and PowerShell coverage"
summary: "Make CI run the framework test suite on Linux and macOS, and run setup.ps1 under PowerShell 7 on Windows."
status: "draft"
version: "0.30.0"
---
# Feature Brief - CI test and PowerShell coverage

**Feature ID:** 0000031-ci-test-and-powershell-coverage

> Drafted by the orchestrator from backlog entries 0000091 and 0000050 and the P0 answers in `build-log.md`. The human on the loop confirms it at the P0 gate.

## Business Goal

Today a pull request can break the framework test suite and still pass CI. `.github/workflows/planifest.yml` runs only the code/doc parity check and `self-description-check.mjs`. Nothing runs `setup.ps1`, so PowerShell defects surface only when a reviewer reads the code. This feature makes CI fail any pull request that breaks the suite on Linux or macOS, or breaks `setup.ps1` under PowerShell 7 on Windows.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| Suite in CI | As the human on the loop, I see CI fail a pull request when `run-tests.sh` fails on Linux or macOS, so that a broken suite can't merge. | must-have | 1 |
| PowerShell setup in CI | As the human on the loop, I see CI fail a pull request when `setup.ps1` fails under PowerShell 7 on Windows, so that PowerShell-only defects show up before review. | must-have | 1 |
| Live setup-flags marker check | As the human on the loop, I see CI fail when `Write-SetupFlagsMarker` writes a `.planifest-setup-flags` file that isn't valid JSON or lacks its fields, so that a `ConvertTo-Json` bug can't ship (backlog 0000050). | must-have | 1 |

## Waves

One wave. All three stories ship together.

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| planifest-framework | component-pack | existing | Owns `tests/test_setup.ps1` and the setup scripts under test. |
| Repository CI (`.github/workflows/planifest.yml`) | CI workflow | existing | Runs the checks on every pull request to `main`. |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| None | n/a | n/a |

### Integration Points

| From | To | Method | Contract |
|------|-----|--------|----------|
| GitHub Actions | `planifest-framework/tests/run-tests.sh` | shell | Exit 0 means pass, non-zero means fail. |
| GitHub Actions | `planifest-framework/tests/test_setup.ps1` | `pwsh` | A thrown error means fail. |

## Stack

| Concern | Decision |
|---------|----------|
| Language | Bash, PowerShell 7, Node.js (built-ins only) |
| Runtime | `ubuntu-latest`, `macos-latest`, and `windows-latest` GitHub runners |
| Framework | none |
| Frontend | none |
| Database | none |
| ORM | none |
| Testing | `run-tests.sh` and `test_setup.ps1` |
| IaC | none |
| Cloud | none |
| Compute | GitHub-hosted runners |
| CI | GitHub Actions |
| Build target | ci-only |

## Scope Boundaries

### In Scope
- A job in `.github/workflows/planifest.yml` that runs `bash planifest-framework/tests/run-tests.sh` on `ubuntu-latest` and `macos-latest`.
- A job that runs `planifest-framework/tests/test_setup.ps1` under `pwsh` on `windows-latest`.
- A new assertion in `test_setup.ps1` that parses `.planifest-setup-flags` and checks its fields, with and without flags.
- `run-tests.sh` prints the names of failed suites before its summary.
- The suite matrix sets `fail-fast: false`, so one platform's failure never cancels the other.
- Any fix the new jobs show to be needed in the tests or setup scripts.

### Out of Scope
- Windows PowerShell 5.1. The documented runtime is PowerShell 7+.
- The consumer workflow copy at `planifest-framework/hooks/planifest.yml`. Consumer repos don't run the framework's own suite.
- Branch protection settings on GitHub. Only the human on the loop can change those.
- Backlog 0000089. CI starts the suite from the repository root, so that defect doesn't affect these jobs.

### Deferred
- Windows PowerShell 5.1 coverage, filed as a new backlog entry.
- Running `run-tests.sh` on Windows under Git Bash.

## Non-Functional Requirements

| NFR | Target | Measurement |
|-----|--------|-------------|
| CI duration | Each new job finishes in under 10 minutes | GitHub Actions job timing on the feature PR |
| Reliability | No flaky failures across 2 consecutive runs on the same commit | Re-run the workflow once on the final commit |
| Security | Jobs use read-only `contents` permission and no secrets | Workflow `permissions` block |

## Constraints and Assumptions

### Constraints
- The human on the loop can test only on macOS locally. The Linux and Windows jobs get checked only in GitHub Actions.
- 0000019's ADR keeps repository-only jobs out of the consumer workflow copy.

### Assumptions
- The suite passes on Linux as it does on macOS. The P0 scan found no BSD-only `sed -i`, `stat -f`, or `date -j` calls.
- `windows-latest` runners ship with PowerShell 7 as `pwsh`.

## Scenario Paths

**Happy path:**

> A pull request to `main` triggers the workflow. All jobs pass, and the PR shows green checks.

**First-run path:**

> The first run happens on this feature's own PR. Any job that fails then shows a real gap, which this feature fixes before P4 completes.

**Error / sad path:**

> A suite or setup failure fails its job, and the log names the failing suite or assertion.

**Cross-session continuity:**

> CI keeps no state between runs. Each job checks out the commit fresh and writes only to runner temp folders.

## Acceptance Criteria

- [ ] On a pull request to `main`, CI runs `run-tests.sh` on `ubuntu-latest` and `macos-latest`, and either job fails if the suite exits non-zero.
- [ ] On a pull request to `main`, CI runs `test_setup.ps1` under `pwsh` on `windows-latest`, and the job fails if the script throws.
- [ ] `test_setup.ps1` parses `.planifest-setup-flags` after a plain run and after a run with `--include-full-skill-library`. It fails unless `tool`, `flags`, `writtenAt`, and `attemptStatus` are present, `flags` is an array, and `flags` matches the flags passed.
- [ ] When a suite fails, `run-tests.sh` lists each failed suite by file name before its summary, and the Linux and macOS jobs both run to completion.
- [ ] All new jobs pass on this feature's PR, and each finishes in under 10 minutes.
- [ ] `docs/` describes the new CI jobs, and a backlog entry records the 5.1 deferral.
