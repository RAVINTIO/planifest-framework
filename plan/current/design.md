# Design - 0000031-ci-test-and-powershell-coverage

## Feature
- Problem: A pull request can break the framework test suite or `setup.ps1` and still pass CI, because CI runs neither.
- Adoption mode: standard-iterative
- Feature ID: 0000031-ci-test-and-powershell-coverage
- Version: 0.30.0
- Discovery: see `plan/current/discovery.md` (raw P0 findings; do not embed them here; this document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As the human on the loop, I see CI fail a pull request when `run-tests.sh` fails on Linux or macOS, so that a broken suite can't merge.
  - US-002: As the human on the loop, I see CI fail a pull request when `setup.ps1` fails under PowerShell 7 on Windows, so that PowerShell-only defects show up before review.
  - US-003: As the human on the loop, I see CI fail when `Write-SetupFlagsMarker` writes a `.planifest-setup-flags` file that isn't valid JSON or lacks its fields, so that a `ConvertTo-Json` bug can't ship (backlog 0000050).
- Acceptance criteria confirmed: 6 (see `plan/current/feature-brief.md`)
- Constraints:
  - The human on the loop can check only macOS locally. The Linux and Windows jobs get checked only in GitHub Actions.
  - The 0000019 ADR keeps repository-only jobs out of the consumer workflow copy at `planifest-framework/hooks/planifest.yml`.
- Integrations: GitHub Actions (`ubuntu-latest`, `macos-latest`, `windows-latest` runners)

## Architecture Layer
- Latency target: each new CI job finishes in under 10 minutes
- Availability target: not applicable (no running service)
- Scalability target: not applicable
- Reliability target: no flaky failures across 2 consecutive runs on the same commit
- Security: no auth. Jobs declare `permissions: contents: read` and use no secrets. Data classification: public source code only.
- Data privacy: no regulated data
- Observability: job logs. `run-tests.sh` lists failed suites by file name, and `test_setup.ps1` throws `FAIL:` messages.
- Cost boundary: GitHub-hosted runner minutes on a public repository

## Engineering Layer
- Stack: Bash / PowerShell 7 / Node.js built-ins / no database / no ORM / no IaC / no cloud / GitHub-hosted runners / GitHub Actions / Build target: ci-only
- Components:
  - `planifest-framework`: owns `tests/run-tests.sh`, `tests/test_setup.ps1`, and the setup scripts under test.
  - Repository CI (`.github/workflows/planifest.yml`): runs the checks on every pull request to `main`.
- Data ownership: none. Tests write only to temp folders.
- Deployment: none. The workflow change takes effect on the next pull request.
- API versioning: not applicable

## Scope
- In:
  - A suite job running `bash planifest-framework/tests/run-tests.sh` on `ubuntu-latest` and `macos-latest`, with `fail-fast: false`.
  - A Windows job running `planifest-framework/tests/test_setup.ps1` under `pwsh`.
  - `run-tests.sh` lists failed suites by file name before its summary.
  - `test_setup.ps1` parses `.planifest-setup-flags` and checks its fields, with and without flags.
  - Fixes that the new jobs show to be needed in the tests or setup scripts.
- Out:
  - Windows PowerShell 5.1.
  - The consumer workflow copy at `planifest-framework/hooks/planifest.yml`.
  - Branch protection settings. Only the human on the loop can change them.
  - Backlog 0000089. CI starts the suite from the repository root.
- Deferred:
  - Windows PowerShell 5.1 coverage. A new backlog entry records it. Nothing in this run depends on it.
  - Running `run-tests.sh` on Windows under Git Bash. Nothing in this run depends on it.

## Assumptions
- The suite passes on Linux as it does on macOS. Impact if wrong: the Linux job starts red, and this run fixes the portability defects it finds.
- `windows-latest` runners ship PowerShell 7 as `pwsh`. Impact if wrong: the Windows job needs a PowerShell install step.
- `test_setup.ps1` runs unchanged on Windows, since it uses `$env:TEMP` and backslash paths. Impact if wrong: the script needs fixes that only CI can check.

## Risks
- R-001: Linux-only test failures surface on first run (likelihood medium, impact medium). Each fix needs a push and a CI run, because the human on the loop can't check Linux locally.
- R-002: The Windows job exposes `setup.ps1` defects that need large changes (likelihood medium, impact medium). If a fix grows past this feature's scope, it goes to the backlog and the job tests the rest.
- R-003: Runner image changes make jobs flaky (likelihood low, impact low). Jobs pin to `-latest` labels, and the reliability NFR checks two consecutive runs.

## Dependencies
- Upstream: GitHub Actions hosted runners, `actions/checkout@v4`
- Downstream: feature 0000032 on the same branch (backlog 0000077 and 0000084) gains CI coverage for its hook changes

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| REQ-001 - suite-ci-job | planifest-codegen-agent | Workflow YAML change, checked by a static test and the PR run. |
| REQ-002 - failed-suite-list | planifest-codegen-agent | Small `run-tests.sh` change with a red-green test. |
| REQ-003 - windows-pwsh-ci-job | planifest-codegen-agent | Workflow YAML change, checked by the PR run through `planifest-verify-by-execution`. |
| REQ-004 - setup-flags-marker-check | planifest-codegen-agent | New `test_setup.ps1` assertions. Only the Windows CI job runs them live. |

## Repo Instructions
- `custom-001`: The agent may fetch, pull, push, and create pull requests without asking. Work on a `feat/` branch, never in a worktree. Committing to `main` and merging pull requests are human-only.
- `custom-002`: Prefer subagent decomposition for long or multi-unit tasks, and state the reason when a task can't be split.
- `custom-003`: `GUTD` means check out `main`, pull, and report untracked files.

## Confirmation
Human confirmed this design before proceeding: yes // Date and Time confirmed: 16 Oct 2026 @ 06:52 p.m. BST
