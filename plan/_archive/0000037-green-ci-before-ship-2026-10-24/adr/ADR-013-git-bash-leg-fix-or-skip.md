---
title: "ADR 013: Git Bash leg with a fix-or-skip rule"
summary: "windows-latest joins the test-suite matrix under shell bash. Each suite that fails there gets one outcome, a fix or a guarded skip. A skip prints SKIP (windows) with a reason and has a row in the tests README skip table. This amends 0000031 ADR 001."
status: "accepted"
version: "0.1.0"
---
# ADR-013 - Git Bash leg with a fix-or-skip rule

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Component:** repository CI, planifest-framework
**Date:** 2026-10-24

## Context

0000031 ADR 001 deferred running the bash suite on Windows under Git Bash. It said many suites assume POSIX tools, so the first run would need wide fixes. Backlog 0000093 asks for the leg now.

`setup.sh` and the hooks run under Git Bash on Windows, so a defect there reaches real users. Known differences include `mktemp` paths (Q-005), `grep -r` without `-H`, CRLF, POSIX file modes, symlinks without privilege, and `/tmp` paths. The leg must end green before P4, or the PR never reads as done.

A fix-all rule can stall the feature on one suite. A skip-all rule hides defects. The leg needs a rule that decides each suite and leaves a record.

## Decision

1. `windows-latest` joins the `test-suite` job. The leg runs `bash planifest-framework/tests/run-tests.sh` with `shell: bash` set on the step. ADR-014's applied branch delivers it as seven sharded `include` entries, not one `matrix.os` value.
2. The job keeps `fail-fast: false`, `permissions: contents: read`, no secrets, and the `pull_request` trigger. It stays in this repository's workflow, and `planifest-framework/hooks/planifest.yml` does not change. The cap is `timeout-minutes: 10` unless ADR-014 applies.
3. Each suite that fails on the Windows leg gets exactly one outcome, a fix or a skip.
   - Fix the suite when one portable change resolves a tool or path difference and no assertion weakens. Examples are `mktemp` paths, `grep -r` without `-H`, and CRLF.
   - Skip the suite when a Windows limit has no portable change. Examples are POSIX file modes, symlinks without privilege, and `/tmp` paths. When only one check fails, skip that check and keep the rest of the suite.
4. A skip returns exit 0 early on Windows only and prints `SKIP (windows): {reason}`. The guard tests the platform, where `uname -s` reports `MINGW*`, `MSYS*`, or `CYGWIN*`. A skip never hides a failure on the Ubuntu or macOS legs.
5. Each guard has one row in the skip table in `planifest-framework/tests/README.md`. The row holds the suite name, the reason, and the date. No guard exists without a row, and no row exists without a guard. A static test compares the two.
6. The codegen agent decides each case. In `autonomous`, it logs `Decision (P3): git bash suite {name}: fix|skip / reason: {one line}`. Otherwise the agent presents all failing suites to the human on the loop in one batch, with a proposed outcome for each.
7. If more than 10 suites fail on the first run, P3 fixes them in parallel streams by file ownership. It skips any suite whose fix needs more than one portable change. It files one backlog entry per skipped suite family. The leg must end green before P4.
8. `docs/architecture-overview.md` lists the leg in its CI table and drops the statement that Git Bash has no coverage. Q-005 in `src/setup-hook-integration/docs/quirks.md` records the `mktemp` outcome.

This ADR amends 0000031 ADR 001 on the Git Bash point. ADR-012 amends the PowerShell 5.1 point.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Fix every failing suite, no skips | Full coverage on Windows | One Windows limit, such as POSIX modes, can block the feature. A fix may weaken an assertion. | Some limits have no portable fix. |
| Skip every failing suite, no fixes | Fastest to green | Hides defects that one portable change would fix. The leg guards little. | Weak coverage. |
| Run the leg with `continue-on-error` | Never blocks | A red result reads as a pass. The leg guards nothing. | A leg that cannot fail proves nothing. |
| A hand-kept allowlist file of skipped suites | One place to read | A second source of truth beside the suite. Drifts from the guards. | The guard in the suite and the README row stay together and a test compares them. |
| Skip the leg and rely on the PowerShell leg | No fix work | Leaves `setup.sh` and the hooks without Windows coverage. | Backlog 0000093 asks for the leg. |

## Affected Components

| Component | Impact |
|-----------|--------|
| repository CI | `test-suite` gains a `windows-latest` leg. |
| planifest-framework | Suites become portable or gain a guard. `tests/README.md` gains the skip table. |
| setup-hook-integration | Q-005 records the `mktemp` outcome. |

## Consequences

**Positive:**
- A Git Bash defect in `setup.sh` or a hook fails a check before merge.
- Every skip carries a reason and a date, so a reader can review the gaps.
- The suites become more portable, which helps the lint in req-009.

**Negative:**
- Each skip is a coverage gap on Windows.
- The skip table needs upkeep, and the static test enforces it.
- P3 time grows with the number of failing suites.

**Risks:**
- A skip can become permanent without review. The table dates it, and the backlog entries for skipped families track it.
- Two streams may edit one suite file. P3 gives each file one owner, and the join step reconciles.
- The leg may pass 10 minutes (R-023). ADR-014 covers that.

## Requirements governed

- req-010

## Related ADRs

- 0000031 ADR 001 - amends
- 0000031 ADR 002 - depends-on
- 0000031 ADR 003 - depends-on
- ADR-012 - related-to
- ADR-014 - related-to

## Supersedes

- None

## Superseded By

- None
