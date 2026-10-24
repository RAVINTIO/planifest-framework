---
title: "Requirement: req-010 - Windows Git Bash leg"
summary: "Run the bash suite on windows-latest under Git Bash, and fix or skip each failing suite with a recorded reason."
status: "draft"
version: "0.1.0"
---
# Requirement: req-010 - Windows Git Bash leg

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Source:** US-010 (backlog 0000093)
**Priority:** should-have

## User Story

As a framework maintainer, I see the suite run on Windows under Git Bash, so that Git Bash defects fail in CI.

## Functional Requirements

- The `test-suite` job in `.github/workflows/planifest.yml` adds `windows-latest` to its `matrix.os` list. The leg runs `bash planifest-framework/tests/run-tests.sh` with `shell: bash` set on the step.
- The job keeps `fail-fast: false`, `permissions: contents: read`, no secrets, and `timeout-minutes: 10` (0000031 ADR 003). The trigger stays `pull_request` only. The job stays in this repository's workflow (0000031 ADR 002), and `planifest-framework/hooks/planifest.yml` does not change.
- Run time risk: Git Bash forks slowly, so the Windows leg may pass 10 minutes. Run 40012567385 shows `Test suite (macos-latest)` at 7 minutes 36 seconds and ubuntu at 3 minutes 28 seconds. The new suites from req-007 to req-011 also add time to the macOS leg, which has about 2.5 minutes of headroom.
- Measurement and fallback for P3:
  - P3 measures the Git Bash leg's run time on its first CI run, and also reads the macOS leg's time.
  - If the Git Bash leg passes 10 minutes, P2 or P3 raises that one leg's `timeout-minutes` to 20. An ADR in block ADR-012 to ADR-014 records the change and amends 0000031 ADR 003 for that leg only. The ubuntu and macOS legs keep 10.
  - If 20 minutes is not enough, or the macOS leg nears its cap, P3 shards the suite across jobs. Sharding is the second fallback.
  - A timeout reads as `cancel`, which req-001 maps to unknown, so the PR would never read as done. This is why the measurement comes first.
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
  - Amended (P1): `timeout-minutes: 10` holds for every leg unless the P3 measurement shows the Git Bash leg passes 10 minutes. In that case an ADR amends 0000031 ADR 003 and the test expects 20 for the `windows-latest` leg only.
  - Verified by: integration - shell suite over the workflow text, `test-0000037-req-010-windows-git-bash-leg.sh`
- [ ] The `Test suite (windows-latest)` check passes on the feature PR. (Verified by: CI run on the PR, read through `gh pr checks`)
  - Verified by: e2e - CI run on the feature PR, read through `gh pr checks`
- [ ] Every suite that skips on Windows prints `SKIP (windows): {reason}` and has a row in the skip table in `planifest-framework/tests/README.md`. No guard exists without a row, and no row exists without a guard. (Verified by: static test comparing the guards with the table rows)
  - Verified by: integration - shell suite comparing the guards with the table rows

## Dependencies

- req-009 (stream-03) edits many of the same suite files for working-directory independence and the portability lint. P3 sequences the edits to one file by one owner, and the join step reconciles them.
- 0000031 ADR 001 (platform matrix), ADR 002 (repository-only jobs), and ADR 003 (job security posture). ADR 003 may be amended for the Windows leg only, through an ADR in block ADR-012 to ADR-014.
- Q-005 in `src/setup-hook-integration/docs/quirks.md` (Windows `mktemp` paths).

Split step: keep. The requirement holds one concern, a green Windows Git Bash leg. The fix-or-skip rule and the skip record are the means to reach it, and nobody could ship them apart from the leg.
