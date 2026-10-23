---
title: "Requirement: req-010 - Windows Git Bash leg"
summary: "Run the bash suite on windows-latest under Git Bash, and fix or skip each failing suite with a recorded reason."
status: "draft"
version: "0.1.0"
---
# Requirement: req-010 - Windows Git Bash leg

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Source:** US-010 (backlog 0000093)
**Priority:** should-have

## User Story

> One requirement doc = one user story.

As a framework maintainer, I see the suite run on Windows under Git Bash, so that Git Bash defects fail in CI.

## Functional Requirements

- The `test-suite` job in `.github/workflows/planifest.yml` adds `windows-latest` to its `matrix.os` list. The leg runs `bash planifest-framework/tests/run-tests.sh` with `shell: bash` set on the step.
- The job keeps `fail-fast: false`, `permissions: contents: read`, no secrets, and `timeout-minutes: 10` (0000031 ADR 003). The trigger stays `pull_request` only. The job stays in this repository's workflow (0000031 ADR 002), and `planifest-framework/hooks/planifest.yml` does not change.
- The existing `setup-powershell` job stays as it is. Its PowerShell 7 version check keeps `0000031` tests green.
- Each suite that fails on the Windows leg gets exactly one outcome: a fix or a skip. A fix makes the suite portable and keeps every assertion. A skip returns exit 0 early on Windows only, prints `SKIP (windows): {reason}`, and adds a row to the skip table in `planifest-framework/tests/README.md`. The row holds the suite name, the reason, and the date.
- Skip rule for P3:
  - Fix the suite when the cause is a tool or path difference that one portable change resolves, and no assertion weakens. Examples are `mktemp` paths, `grep -r` without `-H`, and CRLF.
  - Skip the suite when the cause is a Windows limit that no portable change removes. Examples are POSIX file modes, symlinks without privilege, and `/tmp` paths. Skip the check and keep the rest of the suite when only one check fails.
  - The codegen agent decides each case. In `autonomous`, it logs `Decision (P3): git bash suite {name}: fix|skip / reason: {one line}` under the decision rule in `planifest-framework/standards/autonomous-run-standards.md`. Otherwise the human on the loop decides, and the agent presents all failing suites in one batch with a proposed outcome for each.
  - If more than 10 suites fail on the first run, P3 fixes the suites in parallel streams by file ownership. It skips any suite whose fix needs more than one portable change, and it files one backlog entry per skipped suite family. The leg must end green before P4.
- A skip never hides a failure on the Ubuntu or macOS legs. The guard tests the platform (`uname -s` reports `MINGW*`, `MSYS*`, or `CYGWIN*`).
- A new test, `planifest-framework/tests/test-0000037-req-010-windows-git-bash-leg.sh`, checks the workflow text with the same `job_block` approach as `test-0000031-req-001-003-ci-jobs.sh`. The existing 0000031 test keeps passing, because the `os:` line still names `ubuntu-latest` and `macos-latest`.
- `docs/architecture-overview.md` lists the new leg in the CI table and drops the statement that Git Bash has no coverage. `src/setup-hook-integration/docs/quirks.md` Q-005 records the outcome for `mktemp` paths on the Windows leg.

## Acceptance Criteria

- [ ] The `test-suite` matrix holds `windows-latest` with `shell: bash`, keeps `permissions: contents: read`, `timeout-minutes: 10`, `fail-fast: false`, and the `pull_request` trigger, and the consumer workflow has no diff. (Verified by: static workflow-text test, `test-0000037-req-010-windows-git-bash-leg.sh`)
- [ ] The `Test suite (windows-latest)` check passes on the feature PR. (Verified by: CI run on the PR, read through `gh pr checks`)
- [ ] Every suite that skips on Windows prints `SKIP (windows): {reason}` and has a row in the skip table in `planifest-framework/tests/README.md`. No guard exists without a row, and no row exists without a guard. (Verified by: static test comparing the guards with the table rows)

## Dependencies

- req-009 (stream-03) edits many of the same suite files for working-directory independence and the portability lint. P3 sequences the edits to one file by one owner, and the join step reconciles them.
- 0000031 ADR 001 (platform matrix), ADR 002 (repository-only jobs), and ADR 003 (job security posture).
- Q-005 in `src/setup-hook-integration/docs/quirks.md` (Windows `mktemp` paths).

Split step: keep. The requirement holds one concern, a green Windows Git Bash leg. The fix-or-skip rule and the skip record are the means to reach it, and nobody could ship them apart from the leg.
