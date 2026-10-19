---
title: "Requirement: req-003 - gates-as-loops"
summary: "In autonomous mode every P1 to P6 phase gate runs as a loop under planifest-loop-runner, with a fresh-context checker in place of the human on the loop."
status: "draft"
version: "0.1.0"
---
# Requirement: req-003 - gates-as-loops

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-003
**Priority:** must-have

## User Story

As the human on the loop, I see a failed gate retried by a fresh-context checker with a changed approach, so that a cap or a no-progress halt doesn't stop an autonomous run.

## Functional Requirements

### Standards file (`planifest-framework/standards/autonomous-run-standards.md`)

- **`## Gates as loops`:** A table maps each P1 to P6 gate to its pass condition and its checker in `autonomous`:

  | Gate | Pass condition | Checker |
  |------|----------------|---------|
  | P1 | The orchestrator's P1 gate condition | `planifest-design-critic` over the P1 artifacts |
  | P2 | The orchestrator's P2 gate condition | `planifest-design-critic` over the P1 and P2 artifacts |
  | P3 | Every requirement reaches GREEN | The TDD loop's test run |
  | P4 | CI passes and acceptance criteria verify | The validate loop, then `planifest-verify-by-execution` |
  | P5 | The orchestrator's P5 gate condition | The security report |
  | P6 | Zero drift and every expected artifact | The cross-model review gate |

- **Fresh context:** The checker never shares context with the agent that made the artifact (0000016 ADR-006).
- **Existing caps stay:** Each loop keeps its cap. P4 validate keeps 5, and the other loops keep 3.
- **No stop:** In `autonomous`, a gate that passes moves straight to the next phase. A gate that fails follows req-004.
- **Gate record:** The orchestrator writes the gate summary to the build log in place of presenting it.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`## Phase Invocation Table (P1-P6)`:** Add one sentence below the table. In `autonomous`, each gate runs as a loop per `standards/autonomous-run-standards.md` and never stops. The six rows keep their current text, so the P4, P5, and P6 stop rules still apply in `interactive` and `continuous`.
- **Design-critic paragraph:** In `autonomous`, an absent `design_critic` key reads as `on`.
- **`### Cross-Model Review Gate`:** In `autonomous`, an absent `cross_model_review` key reads as `on`.

### Loop runner (`planifest-framework/skills/planifest-loop-runner/SKILL.md`)

- **`## Toggle Protocol (ADR-003)`:** Add one rule. In `autonomous`, an absent key reads as `on` for `design_critic`, `verify_by_execution`, and `cross_model_review`. An explicit value in `planifest-overrides/loop-toggles.yml` wins. In other modes, the absent-key rule stays `off`.
- The line "The framework never creates `planifest-overrides/loop-toggles.yml`" stays.

### Loop toggles template (`planifest-framework/templates/loop-toggles.template.yml`)

- The header comment adds the `autonomous` default for the three checker keys. The listed default values stay `off`.

### Validate skill (`planifest-framework/skills/planifest-validate-agent/SKILL.md`)

- In `autonomous`, verify-by-execution runs after CI passes, as the P4 checker.

### Tests

- Add `planifest-framework/tests/test-0000033-req-003-gates-as-loops.sh`. `run-tests.sh` picks it up.
- `planifest-framework/tests/test-0000016-pipeline-governance.sh` asserts loop-runner toggle text. It must pass unchanged.
- `planifest-framework/tests/test-0000023-req-001-continuous-run-p1-p3.sh` asserts the invocation table rows. It must pass unchanged.

### Verified by

- The standards file has a `## Gates as loops` heading, and its table has a row for each of P1 to P6.
- The table names `planifest-design-critic`, `planifest-verify-by-execution`, and the cross-model review gate.
- The section says each loop keeps its cap, with 5 for P4.
- The orchestrator has an `autonomous` sentence below the Phase Invocation Table that links to `autonomous-run-standards.md`.
- The loop runner's Toggle Protocol names `autonomous` and the three checker keys, and still says an absent key is `off` in other modes.
- The loop-toggles template's listed values stay `off` for all five existing keys.
- Every row of the Phase Invocation Table matches its text before this feature.

## Acceptance Criteria

- [ ] (AC-1) In `autonomous`, every P1 to P6 gate runs as a loop with a named fresh-context checker, and no gate stops for the human on the loop.
- [ ] (AC-1) In `autonomous`, an absent toggle key reads as `on` for the three checker loops, and an explicit value wins.
- [ ] (AC-7) The new suite and the 0000016 and 0000023 req-001 suites pass under `run-tests.sh`.

## Dependencies

- req-001 defines `autonomous_run`.
- req-004 defines what happens when a gate loop hits its cap or makes no progress.
- req-015 adds the `parallel_streams` key to the same loop-toggles template, with the same `autonomous` default pattern.
- 0000016 loop engineering provides `planifest-loop-runner`, the toggles, and the caps.
