---
title: "ADR 014: Git Bash leg conditional 20-minute cap"
summary: "If the first draft-PR CI run that holds the windows-latest leg passes 10 minutes, P3 raises that leg's timeout-minutes to 20. This amends 0000031 ADR 003 for that leg only, and only when the condition fires. Otherwise every job keeps 10."
status: "accepted"
version: "0.1.0"
---
# ADR-014 - Git Bash leg conditional 20-minute cap

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Component:** repository CI
**Date:** 2026-10-24

## Context

0000031 ADR 003 sets `timeout-minutes: 10` on each job. Git Bash forks slowly, so the `windows-latest` leg of `test-suite` may pass 10 minutes. Run 40012567385 shows `Test suite (macos-latest)` at 7 minutes 36 seconds and ubuntu at 3 minutes 28 seconds. The suites from req-007 to req-011 add time to the macOS leg, which has about 2.5 minutes of headroom.

The workflow runs only on `pull_request`, so no CI run exists before the draft PR. P3 cannot know the Git Bash run time at P2. A timeout reads as `cancel`, which req-001 maps to unknown. The PR would then never read as done (R-023).

P2 writes this decision now so P3 needs no return to P2. This is a conditional decision.

## Decision

1. P3 measures the Git Bash leg's run time on the first draft-PR CI run that holds the `windows-latest` leg. P3 also reads the macOS leg's time.
2. If the Git Bash leg passes 10 minutes, P3 raises that leg's `timeout-minutes` to 20. This amends 0000031 ADR 003 for that leg only. `test-suite` sets one `timeout-minutes` for the whole job, so the 20 branch uses the expression `timeout-minutes: ${{ matrix.os == 'windows-latest' && 20 || 10 }}`. In the same P3 change, the line 45 assertion in `test-0000031-req-001-003-ci-jobs.sh` (`timeout-minutes:\s*10$`) accepts that exact expression for `test-suite` as well as the plain `10`.
2a. In the 20 branch, the P3, P4, and P9 poll window grows to 30 minutes, the longest job cap plus 10. In the 10 branch it stays at 20 minutes. So a leg that runs to its cap still reads before the poll ends.
3. The ubuntu leg, the macOS leg, `setup-powershell`, and `setup-powershell-51` keep `timeout-minutes: 10`. Every other part of 0000031 ADR 003 holds, including `permissions: contents: read`, no secrets, and the `pull_request` trigger.
4. If the leg does not pass 10 minutes, this ADR does not apply. Every job keeps 10, and 0000031 ADR 003 stands unamended.
5. P3 records which branch applied. It writes one build-log line, `Decision (P3): git bash leg cap: 10|20 / reason: {measured minutes}`. When the cap is 20, the static test `test-0000037-req-010-windows-git-bash-leg.sh` expects the expression `${{ matrix.os == 'windows-latest' && 20 || 10 }}` from decision 2.
6. Sharding is the second fallback. If 20 minutes is not enough, or the macOS leg nears its cap, P3 shards the suite across jobs. This ADR rejects sharding for now because it changes the job layout and the check names.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Raise every job to 20 minutes up front | No measurement needed | Raises the cost cap on all legs. Weakens the runaway-job stop from 0000031 ADR 003. | The measurement is cheap, and only one leg may need it. |
| Raise only the Windows leg to 20 minutes now, unconditionally | One decision, no branch | Spends cap that may not be needed. Hides a slow suite. | The need is unproven until the first CI run. |
| Keep 10 and shard the suite now | Short legs, no cap change | Changes job layout and check names. More work before any evidence. | Rejected for now. It stays the second fallback. |
| Defer the decision to a P3 return to P2 | Decided with data | Adds a phase return and a delay. | P3 can apply a pre-written decision with no return. |
| Cut the slowest suites on Windows by skipping them | Short leg | Mixes a time problem with the fix-or-skip rule of ADR-013, which skips for Windows limits. | A skip needs a platform reason, not a time reason. |

## Affected Components

| Component | Impact |
|-----------|--------|
| repository CI | The `windows-latest` leg of `test-suite` may carry a 20-minute cap. |
| planifest-framework | The test `test-0000037-req-010-windows-git-bash-leg.sh` accepts the branch P3 records. |

## Consequences

**Positive:**
- A slow Git Bash leg finishes, so the check reads as a pass or a fail and not as unknown.
- The cap rises only for the leg that needs it, and only with a measurement.
- P3 needs no return to P2.

**Negative:**
- If the condition fires, the cost per PR for the two new Windows legs rises from 20 to 30 minutes per PR in the worst case (R-013).
- A reader must check the build log to know which branch applied.
- A 20-minute cap weakens the runaway-job stop for that leg.
- The 20 branch also edits the line 45 assertion in `test-0000031-req-001-003-ci-jobs.sh`, so an earlier feature's suite changes with it.
- The 20 branch lengthens the P3, P4, and P9 poll window from 20 to 30 minutes (decision 2a).

**Risks:**
- A leg that runs under 10 minutes on the first run can pass 10 later as suites grow. The cap check then repeats on a later red run.
- The macOS leg may near its cap because of the new suites. Sharding covers that.

## Requirements governed

- req-010

## Related ADRs

- 0000031 ADR 003 - amends, for the Git Bash leg only and only when the condition fires
- ADR-013 - depends-on

## Supersedes

- None

## Superseded By

- None
