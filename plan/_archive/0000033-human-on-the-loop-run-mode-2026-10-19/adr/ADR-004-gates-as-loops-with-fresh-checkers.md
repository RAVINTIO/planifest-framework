---
title: "ADR 004: Gates as loops with fresh checkers"
summary: "In autonomous mode every P1 to P6 gate runs as a loop under planifest-loop-runner with a named checker in place of the human on the loop. Five toggle keys read as on when absent in autonomous, so checkers start at on, not report-only. P3 is checked by the P4 CI run and P5 by a fresh re-review of each fix."
status: "accepted"
version: "0.1.0"
---
# ADR-004 - Gates as loops with fresh checkers

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Component:** planifest-framework
**Date:** 2026-10-19

## Context

In `interactive` mode the human on the loop judges each P1 to P6 gate. In `autonomous` (ADR-002) nobody waits at the gate, so something else must judge it. Design assumption A-001 is that a fresh-context checker can stand in for the human.

0000016 built the parts:

- `planifest-loop-runner` with its caps
- `planifest-design-critic`
- `planifest-verify-by-execution`
- the cross-model review gate
- `planifest-reversal-assessor`

0000016-ADR-006 makes every verifier a fresh-context, REJECT-default subagent. Its rubric-gaming mitigation was a report-only trial before any verifier gains blocking power.

0000016-ADR-003 puts the toggles in `planifest-overrides/loop-toggles.yml`. An absent file or key reads as `off`. The template calls `report-only` the mandatory first rollout level.

Under those defaults an `autonomous` run with no toggle file has no checker at any gate. The gates would pass unchecked. Execution-plan D-012 settles the defaults. D-001 settles the checkers for P3 and P5, which have no 0000016 verifier.

## Decision

- **Gates as loops:** In `autonomous`, each P1 to P6 gate runs as a loop under `planifest-loop-runner`. A passing gate moves straight to the next phase. A failing gate follows ADR-005. The orchestrator writes the gate summary to the build log in place of presenting it.
- **Checkers:**

  | Gate | Checker in `autonomous` |
  |------|-------------------------|
  | P1 | `planifest-design-critic` over the P1 artifacts |
  | P2 | `planifest-design-critic` over the P1 and P2 artifacts |
  | P3 | The P4 CI run that follows P3 (D-001) |
  | P4 | The validate loop, then `planifest-verify-by-execution` |
  | P5 | A fresh-context re-review of each fixed finding (D-001) |
  | P6 | The cross-model review gate |

- **Why P3 uses P4:** The P4 CI run is deterministic. It checks the P3 output more strongly than a fresh-context read would.
- **Fresh context:** Every checker follows 0000016-ADR-006. It never shares context with the agent that made the artifact.
- **Caps stay:** P4 validate keeps 5. The other loops keep 3.
- **Toggle defaults (D-012):** When the run mode is `autonomous`, an absent key reads as `on` for five keys:
  - `design_critic`
  - `verify_by_execution`
  - `cross_model_review`
  - `reversal_protocol`
  - `parallel_streams`
- **Explicit values win:** An explicit value in `loop-toggles.yml` always wins, including `off` and `report-only`. Outside `autonomous`, an absent key still reads as `off`. `p0_completeness` keeps its current default in every mode.
- **Template:** The loop-toggles template ships those keys commented out. Each comment states the default as `off`, or `on` in `autonomous`. Copying the template therefore never sets an explicit `off` by accident. The framework still never creates `planifest-overrides/loop-toggles.yml`.
- **Start at `on`:** In `autonomous`, checkers start at `on`, not at `report-only`. Choosing `autonomous` at P0 is the human on the loop's deliberate act that turns them on.
- **Unchanged rows:** The six Phase Invocation Table rows keep their text. The P4, P5, and P6 stop rules still apply in `interactive` and `continuous`. One sentence below the table links to `standards/autonomous-run-standards.md`.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep absent keys at `off` in `autonomous` | No change to 0000016-ADR-003 | A run with no toggle file passes every gate unchecked | Removes the only stand-in for the human |
| Start `autonomous` checkers at `report-only` | Follows 0000016-ADR-006's trial mitigation | A report-only verdict blocks nothing, so the gate passes whatever the checker finds | A non-blocking checker can't stand in for a gate |
| Require the product to write `loop-toggles.yml` before `autonomous` | Keeps enablement in the override file | Every product must copy and edit a file before its first run. A missing file fails silently. | The P0 choice already carries the human on the loop's intent |
| Use `planifest-design-critic` at P3 | One checker type for P1 to P3 | A text read of code is weaker than running the tests | The P4 CI run is deterministic |
| Rerun the whole P5 security review after fixes | Catches new findings anywhere | Costs a full review per fix cycle | A focused re-review of each fixed finding answers the gate question |
| Raise the caps in `autonomous` | Fewer escalations | More cycles on the same failing approach | ADR-005 changes the approach instead |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `autonomous-run-standards.md` gains `## Gates as loops`. The loop runner's Toggle Protocol gains the `autonomous` default rule. The loop-toggles template comments out the checker keys. The orchestrator gains a sentence below the Phase Invocation Table and links from the design-critic paragraph and the cross-model gate. The validate and security skills gain their `autonomous` checker steps. |

## Consequences

**Positive:**
- No `autonomous` gate passes without a checker, even when the product has no toggle file.
- Each checker is the strongest one available for its phase, and P3 uses a deterministic one.
- `interactive` and `continuous` keep their toggle defaults and stop rules.
- A product can still turn any checker down with an explicit value.

**Negative:**
- `autonomous` skips 0000016-ADR-006's report-only trial. No precision data exists for these checkers as blockers before they block.
- Every `autonomous` gate costs at least one checker spawn, so runs use more tokens.
- The toggle read now depends on the run mode, which adds a branch to the Toggle Protocol.

**Risks:**
- A fresh-context checker approves a defect that a human would have caught (A-001, R-006). Each checker is REJECT-default, and the human on the loop reviews the PR before merging.
- A REJECT-default checker rejects good work, and the gate burns its approaches. ADR-005 turns the fourth approach into an exception, and the P8 report shows how often that happens.
- A product copies an older template with uncommented `off` lines and disables the checkers without knowing. The explicit value wins by design, so the P8 report must name each checker that ran.

## Related ADRs

- 0000016-ADR-003 (loop toggles) - amended by this ADR. Absent keys read as `on` for five keys in `autonomous` only.
- 0000016-ADR-006 (fresh-context verifiers) - depends-on. The report-only trial mitigation doesn't apply in `autonomous`.
- 0000016-ADR-007 (deterministic caps) - depends-on. The caps stay.
- 0000016-ADR-008 (cross-model gate at end of P6) - depends-on
- ADR-002 - depends-on. It defines `autonomous`.
- ADR-003 - related-to. It relies on `reversal_protocol` reading as `on`.
- ADR-005 - related-to. It defines what a failing gate does.
- ADR-013 - related-to. It adds `parallel_streams` under the same default rule.

## Supersedes

- Amends 0000016-ADR-003 in `autonomous` only. An absent key reads as `on` for the five named keys, and checkers start at `on`, not `report-only`. The ADR stays in force in other modes.

## Superseded By

- None
