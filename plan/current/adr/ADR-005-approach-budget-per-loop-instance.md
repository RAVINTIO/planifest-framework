---
title: "ADR 005: Approach budget per loop instance"
summary: "In autonomous mode a loop that hits its cap or the no-progress rule starts a new approach. Each loop instance allows 3 approaches, and a fourth becomes an exhausted-budget exception. The approach counter lives in the git-tracked loop-state file and never resets. The reversal budget stays at 2."
status: "accepted"
version: "0.1.0"
---
# ADR-005 - Approach budget per loop instance

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Component:** planifest-framework
**Date:** 2026-10-19

## Context

0000016-ADR-007 sets the loop limits:

- an iteration cap of 3 per loop, with 5 for P4 validate
- a no-progress halt after 2 identical findings
- a reversal budget of 2 per feature

At a cap or halt, the loop escalates to the human on the loop. The validate skill writes `VALIDATION BLOCKED`, and codegen writes `TDD LOOP BLOCKED` and waits for human direction.

In `autonomous` (ADR-002) nobody waits for that escalation. If a cap still ends the run, one stubborn failure stops a hands-off run. If nothing bounds the retries, a run can loop for ever. US-003 asks for a changed approach after a cap. Design assumption A-002 is that three approaches is enough for most failures.

The approach counter needs a scope. A per-feature count would let one hard requirement use up the budget for every other one. Execution-plan D-014 settles the scope.

## Decision

- **Change approach:** In `autonomous`, when a loop hits its iteration cap or the no-progress rule, the agent records the attempts and starts a new approach. The loop runner's DECIDE step gains a fourth outcome, `change-approach`.
- **A new approach must differ:** It states how it differs from each earlier approach, such as a new root-cause hypothesis or a new method. A restated approach doesn't count.
- **Counters:** The iteration counter restarts at 1 for each approach. The approach counter never restarts.
- **Scope (D-014):** The approach counter belongs to one loop instance. At P1, P2, P4, P5, and P6 the instance is the phase gate. At P3 it is each requirement's TDD loop.
- **Budget:** Each loop instance allows 3 approaches. If it needs a fourth, it escalates as an exhausted budget, which is exception-list item 6 (ADR-003). The agent writes an `Exception waiting` line and carries on with work that doesn't depend on the loop. At P3, codegen moves on to requirements that don't depend on the blocked one.
- **Reversal budget:** It stays at 2 per feature. In `autonomous` its exhaustion is also an exception-list item.
- **Design changes:** If a new approach would change the confirmed design, the agent files a defect report. The fresh-context reversal assessor classes it, never the agent that filed it.
- **Enforcement:** The approach counter is a budget counter in the git-tracked loop-state file, as 0000016-ADR-007 requires for run-shaped limits. The loop-state template gains an `Approach` row, `{{n}} of 3 (autonomous only)`. No agent resets it.
- **Other modes:** The Stop Rules table rows, the `Px: Blocked` line, `VALIDATION BLOCKED`, and `TDD LOOP BLOCKED` stay as they are for `interactive` and `continuous`.
- **Rule text:** The rule lives in `standards/autonomous-run-standards.md` under `## Changing approach` (ADR-001).

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep the cap as a hard stop in `autonomous` | No new counter | One stubborn failure stops a hands-off run and waits for a human | Breaks US-003 |
| Raise the iteration caps in `autonomous` | One number to change | More cycles on the same failing idea. The no-progress rule fires anyway. | Repeats the approach that failed |
| No limit on approaches | The run never stops for a loop | A loop can run for ever and spend unbounded tokens | Fails the ignore test of 0000016-ADR-007 |
| One approach counter per feature | Bounds the whole run | One hard requirement spends the budget for every other loop | D-014 scopes it per loop instance |
| One approach counter per phase at P3 | Fewer counters | Ten requirements share 3 approaches, so one failing TDD loop blocks the rest | Each requirement's TDD loop is its own instance |
| Two or five approaches per instance | Faster stop, or more tries | Two gives little room after one wrong hypothesis. Five spends tokens on low odds. | Three matches the default cap, and P8 reports how often it runs out |
| Raise the reversal budget in `autonomous` | Fewer reversal exceptions | More upstream rework without a human sanctioning it | A reversal changes confirmed artifacts, so the budget stays at 2 |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `autonomous-run-standards.md` gains `## Changing approach`. The loop runner's Iteration Cycle, Stop Rules, and Escalation Format change. The loop-state template gains an `Approach` row. The validate skill's self-correct section, codegen's TDD protocol, and cross-model review step 5 gain `autonomous` text. |

## Consequences

**Positive:**
- A cap or halt in `autonomous` leads to a new idea, not a stop.
- The total retry effort per loop instance has a fixed bound of 3 approaches times the cap.
- One blocked requirement at P3 doesn't stop the other requirements.
- The counter survives a session restart because it lives in git.

**Negative:**
- The worst case per loop instance triples its cycles. At P4 that is 15 validate cycles before an exception.
- An agent must judge whether an approach is new. A weak agent can relabel an old approach.
- The loop-state file gains a field that every loop must keep correct.

**Risks:**
- The agent restates an old approach as a new one and spends the budget on repeats. The rule requires each approach to state how it differs, and the run log records each approach for the P8 report.
- Three approaches prove too few, and many runs end with exceptions (A-002, R-012). The P8 report shows how often a gate reaches a fourth approach.
- A new approach drifts from the confirmed design without a defect report. The ADR-003 gross-deviation rule and the final report's deviation list catch it before merge.

## Related ADRs

- 0000016-ADR-007 (deterministic caps, budget, and ratchet) - extends. It adds a budget counter under the same layer, and keeps the caps and the reversal budget.
- 0000016-ADR-005 (cascade threshold) - related-to
- ADR-002 - depends-on. It defines `autonomous`.
- ADR-003 - depends-on. It defines the exhausted-budget item.
- ADR-004 - related-to. It makes each gate a loop.

## Supersedes

- None

## Superseded By

- None
