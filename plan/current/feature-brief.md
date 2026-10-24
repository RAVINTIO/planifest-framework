---
title: "Feature Brief - green CI before ship"
summary: "The business case, scope, and product requirements for the feature."
status: "draft"
version: "0.1.0"
---
# Feature Brief - green CI before ship

**Feature ID:** 0000037-green-ci-before-ship

> Drafted by the orchestrator from backlog entries 0000191, 0000192, 0000086, 0000186, 0000100, 0000071, 0000089, 0000093, 0000092, and 0000094, and the P0 answers in `build-log.md`. The human on the loop confirms it at the P0 gate.

## Business Goal

PR #62 merged with a failing `Test suite (ubuntu-latest)` check, and no agent reported it. The pipeline must not report a run as done while CI is red, and the suites must catch defects on every platform the framework supports. The goal is that the head P9 reads on every PR the ship agent raises has green checks, or a reported failure, before the final report.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| CI status at ship and sync (0000191) | As the human on the loop, I see the PR's CI result in the P9 report, so that a red PR never looks done. As the human on the loop, I see the CI result of the last merged PR when I send GUTD, so that a red `main` never looks healthy. | must-have | 1 |
| Credential guard for mid-run commits and the PR body (0000192) | As the human on the loop, I know that an `autonomous` run scans staged files before each commit and push, so that a credential never reaches the remote. As the human on the loop, I know that the PR body cites paths and never raw output, so that the PR text leaks nothing. | must-have | 1 |
| Revalidate after P6 (0000086) | As the human on the loop, I see the P4 checks rerun after the P6 docs edits, so that a docs change can't break a green check before ship. | should-have | 1 |
| Trace requirements to tests before P4 (0000100) | As the human on the loop, I see each acceptance criterion name its test type at P1, and P3 run the requirement-ID scan before it closes, so that untested requirements surface before P4. | should-have | 1 |
| Test the real artifacts (0000071, 0000186) | As a framework maintainer, I run a test that executes the hook command string `setup.sh` writes, so that a broken wiring fails the suite. As a framework maintainer, I run a test that compares a re-run-setup migration's file list with the release diff, so that a wrong list fails the suite. | should-have | 1 |
| Portable suites (0000089, 0000191) | As a framework maintainer, I run any suite from any working directory, and a lint flags unportable tool use such as `grep -r` without `-H`, so that a GNU and BSD difference fails locally before CI. | should-have | 1 |
| Windows CI coverage (0000093, 0000092, 0000094) | As a framework maintainer, I see the suite run on Windows under Git Bash, `setup.ps1` run under Windows PowerShell 5.1, and the stale clean-up and retired-flag paths run live under PowerShell, so that Windows defects fail in CI. | should-have | 1 |

## Waves

One wave. The human on the loop confirmed all 10 entries as one run, above the three-story rule.

| Wave | Features Included | Ships When |
|------|-------------------|------------|
| 1 | All seven features above | The PR's CI checks pass on every matrix leg |

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| `planifest-framework` | component-pack | existing | Ship, orchestrator, docs, spec, and codegen skills. Standards, templates, scripts, and test suites. |
| `setup-hook-integration` | component-pack | existing | `setup.sh` and `setup.ps1`, the code under test for the wired-command and PowerShell tests. |

The CI workflow `.github/workflows/planifest.yml` sits outside both components, as in 0000031.

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| `plan/current/build-log.md` | `planifest-framework` (orchestrator) | none |
| PR and CI check state on GitHub | GitHub, read only through `gh` | `planifest-framework` (read only) |

### Integration Points

| From | To | Method | Contract |
|------|-----|--------|----------|
| ship agent (P9) | GitHub | `gh pr checks` | Reads check names and conclusions for the PR it raised |
| GUTD instruction | GitHub | `gh pr list` and `gh pr checks` | Reads the checks of the last merged PR |
| autonomous commits | `gitleaks` and the P8 credential patterns | local command | Scans staged files before a commit and a push |

## Stack

Unchanged from 0000036.

| Concern | Decision |
|---------|----------|
| Language | Bash, PowerShell, JavaScript (Node ES modules) |
| Runtime | Node, Bash, PowerShell 7 and Windows PowerShell 5.1 |
| Framework | none |
| Frontend | none |
| Database | none |
| ORM | none |
| Testing | Bash suites through `run-tests.sh`, and `test_setup.ps1` |
| IaC | none |
| Cloud | none |
| Compute | none |
| CI | GitHub Actions |
| Build target | local |

## Scope Boundaries

### In Scope
- The P9 CI check after `gh pr create`, and the GUTD CI check.
- The pre-commit credential scan in `autonomous` and the PR body scan.
- A post-P6 revalidation step.
- A "Verified by" field on acceptance criteria and a P3 requirement-ID scan.
- The wired-command test and the migration branch-diff test.
- Working-directory independence for every suite, and a portability lint.
- Windows Git Bash and Windows PowerShell 5.1 CI legs, and the live PowerShell clean-up test.

### Out of Scope
- A `push` trigger on `main`. 0000031-ADR-003 keeps CI on `pull_request` only.
- Auto-merge or any merge by the agent.
- Changes to the consumer workflow copy at `planifest-framework/hooks/planifest.yml`.

### Deferred
- Two items are deferred. Backlog 0000193 covers the unread CI run that the Step 11 `final-report.md` push starts. Backlog 0000199 covers the CI checkout that fetches no tags.

## Non-Functional Requirements

| NFR | Target | Measurement |
|-----|--------|-------------|
| CI wait | P9 waits at most 20 minutes for checks, or 30 if the Git Bash leg's cap rises to 20 (ADR-014) | `gh pr checks --json` polled every 30 seconds |
| CI job time | Each new job keeps `timeout-minutes: 10` | Workflow file |
| Security | No secrets in CI and `permissions: contents: read` | Workflow file, per 0000031-ADR-003 |

## Constraints and Assumptions

### Constraints
- CI keeps the `pull_request` trigger (0000031-ADR-003).
- New CI jobs stay in this repository's workflow only (0000031-ADR-002).
- The agent never merges a PR and never pushes to `main`.

### Assumptions
- `gh` is installed and signed in wherever P9 and GUTD run. If not, the check reports that it could not run.
- `gitleaks` may be absent. If so, the regex patterns still run.

## Scenario Paths

Derived by the orchestrator at the Scope Lock Challenge.

## Acceptance Criteria

- [ ] P9 waits for the PR's checks and reports each failure before the final report.
- [ ] GUTD reports the CI result of the last merged PR.
- [ ] An `autonomous` commit with a staged credential stops before the commit and the push.
- [ ] The PR body passes a credential scan before `gh pr create`.
- [ ] The P4 check set reruns after the P6 commit.
- [ ] Each acceptance criterion names its test type, and P3 runs the requirement-ID scan.
- [ ] A test runs the hook command string from a generated `settings.json`.
- [ ] A test compares the migration file list with the release diff.
- [ ] Every suite passes from any working directory, and the portability lint runs in the suite.
- [ ] CI runs the suite on Windows under Git Bash and `setup.ps1` under Windows PowerShell 5.1.
- [ ] `test_setup.ps1` runs the stale clean-up and a retired flag live.
