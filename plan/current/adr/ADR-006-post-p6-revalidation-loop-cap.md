---
title: "ADR 006: Post-P6 revalidation runs after the commit and loops at cap 3 in autonomous"
summary: "Revalidation runs after the P6 commit, logs one Revalidation (P6) line, and loops with a cap of 3 and approach rules in autonomous. Other modes keep 5 cycles. This extends 0000033 ADR 012."
status: "accepted"
version: "0.1.0"
---
# ADR-006 - Post-P6 revalidation runs after the commit and loops at cap 3 in autonomous

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Component:** planifest-framework
**Date:** 2026-10-24

## Context

0000033 ADR 012 added a `## Post-P6 revalidation` section to the docs-agent skill. It reads `planifest-overrides/doc-checks.yml` and falls back to P4 steps 0 to 5. It caps the failure loop at 5 cycles.

req-005 finds four gaps in that section:

- Nothing says the rerun happens after the P6 commit rather than after the last edit.
- No build-log line records the result.
- The 5-cycle cap in `autonomous` differs from the other P1 to P6 loops, which use 3 (Gates as loops in `autonomous-run-standards.md`).
- The orchestrator's P6 gate condition and the autonomous standard's P6 row don't name revalidation.

A docs edit can break a green check. The human on the loop needs to see that before ship.

## Decision

- **Timing:** The docs agent runs revalidation after the P6 commit and before it reports P6 complete. A rerun that happens before the commit doesn't satisfy this.
- **Command:** The docs agent runs the `command` from `planifest-overrides/doc-checks.yml` when it is valid. Otherwise it reruns P4 steps 0 to 5. Step 6 doesn't rerun.
- **Log line:** The docs agent writes one line in the P6 block: `Revalidation (P6): {command | P4 steps 0-5}, {pass | fail | skipped, no P6 edits}`. A failure adds the failing check and its cycle count.
- **Cap in `autonomous`:** The revalidation runs as a loop under `planifest-loop-runner` with a cap of 3 cycles. When the cap runs out, the agent starts a new approach under `## Changing approach`. After 3 approaches, the failure becomes `Exception waiting (P6, revalidation): ...`.
- **Cap elsewhere:** `interactive` and `continuous` keep the 5-cycle cap and the `VALIDATION BLOCKED` escalation.
- **Routing surfaces:** The orchestrator's P6 gate condition and the P6 row of the Gates as loops table both name a passing revalidation.
- **Scope:** This ADR changes no other behaviour of the 0000033 section. The framework still never creates `doc-checks.yml`.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep 5 cycles in every mode | No text change to the cap | Breaks the rule that loops other than P4 keep 3 in `autonomous` | The autonomous standard sets the cap |
| Cap 3 in every mode | One cap to remember | Cuts the cycles that a human on the loop already accepts in other modes | Changes behaviour that req-005 says to keep |
| Rerun before the P6 commit | The fix lands in the same commit | The check then runs on files that differ from the committed ones | The commit is what ship reads |
| Run revalidation as a hook | Deterministic | The design lists no new hook | Skill text enforces the step |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Changes the docs-agent skill, the orchestrator skill, and the autonomous standard |

## Consequences

**Positive:**
- A docs edit can't leave a failing check unseen before ship.
- The `Revalidation (P6)` line gives the human on the loop one place to read the result.
- The `autonomous` cap matches the other P1 to P6 loops.

**Negative:**
- Each P6 run with edits pays for a rerun of the check set.
- The two caps (3 and 5) add a mode-dependent rule to the docs-agent skill.

**Risks:**
- A rerun on a docs-only commit adds time and surfaces late failures (R-019). The `skipped, no P6 edits` result limits this.

## Governs

- req-005 (post-p6-revalidation)

## Related ADRs

- 0000033 ADR 012 - extends

## Supersedes

- None. This ADR extends 0000033 ADR 012 and leaves it in force.

## Superseded By

- None.
