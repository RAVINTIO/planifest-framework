---
title: "Requirement: req-003 - gates-as-loops"
summary: "In autonomous mode every P1 to P6 phase gate runs as a loop under planifest-loop-runner, with a checker in place of the human on the loop."
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

- **`## Gates as loops`:** A table maps each P1 to P6 gate to its pass condition and its checker in `autonomous`. The checkers match execution-plan D-001:

  | Gate | Pass condition | Checker |
  |------|----------------|---------|
  | P1 | The orchestrator's P1 gate condition | `planifest-design-critic` over the P1 artifacts |
  | P2 | The orchestrator's P2 gate condition | `planifest-design-critic` over the P1 and P2 artifacts |
  | P3 | Every requirement reaches GREEN | The P4 CI run that follows P3 |
  | P4 | CI passes and acceptance criteria verify | The validate loop, then `planifest-verify-by-execution` |
  | P5 | The orchestrator's P5 gate condition | A fresh-context re-review of each fixed finding |
  | P6 | Zero drift and every expected artifact | The cross-model review gate |

- **Why P3 uses P4:** The P4 CI run is deterministic. It checks the P3 output more strongly than a fresh-context read would.
- **Fresh context:** A fresh-context checker never shares context with the agent that made the artifact (0000016 ADR-006).
- **Existing caps stay:** Each loop keeps its cap. P4 validate keeps 5, and the other loops keep 3.
- **No stop:** In `autonomous`, a gate that passes moves straight to the next phase. A gate that fails follows req-004.
- **Gate record:** The orchestrator writes the gate summary to the build log in place of presenting it.

### Loop runner (`planifest-framework/skills/planifest-loop-runner/SKILL.md`)

- **`## Toggle Protocol (ADR-003)`:** Add one rule. When the run mode is `autonomous`, an absent key reads as `on` for these five keys:
  - `design_critic`
  - `verify_by_execution`
  - `cross_model_review`
  - `reversal_protocol`
  - `parallel_streams`
- An explicit value in `planifest-overrides/loop-toggles.yml` always wins.
- Outside `autonomous`, an absent key still reads as `off`, so behaviour doesn't change.
- The line "The framework never creates `planifest-overrides/loop-toggles.yml`" stays.

### Loop toggles template (`planifest-framework/templates/loop-toggles.template.yml`)

- The header comment states the same rule as the Toggle Protocol.
- The `design_critic`, `verify_by_execution`, `cross_model_review`, and `reversal_protocol` lines ship commented out. Each comment describes the default: `off`, or `on` in `autonomous`. Copying the template therefore never sets an explicit `off` by accident.
- The `p0_completeness` line stays as it is.
- req-015 adds the commented-out `parallel_streams` line under this rule.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`## Phase Invocation Table (P1-P6)`:** Add one sentence below the table. In `autonomous`, each gate runs as a loop per `standards/autonomous-run-standards.md` and never stops. The six rows keep their current text, so the P4, P5, and P6 stop rules still apply in `interactive` and `continuous`.
- **Design-critic paragraph and `### Cross-Model Review Gate`:** Each links to the Toggle Protocol's `autonomous` rule in one sentence.

### Validate skill (`planifest-framework/skills/planifest-validate-agent/SKILL.md`)

- In `autonomous`, verify-by-execution runs after CI passes, as the P4 checker.

### Security skill (`planifest-framework/skills/planifest-security-agent/SKILL.md`)

- In `autonomous`, each fixed finding gets a fresh-context re-review before the P5 gate passes.

### Tests

- Add `planifest-framework/tests/test-0000033-req-003-gates-as-loops.sh`. `run-tests.sh` picks it up.
- `planifest-framework/tests/test-0000016-pipeline-governance.sh` asserts the loop-toggles template text. It counts uncommented `key: on` lines and checks for `report-only`. It also asserts loop-runner toggle text. It must pass unchanged, and commented-out keys keep its `on` count at 0.
- `planifest-framework/tests/test-0000023-req-001-continuous-run-p1-p3.sh` asserts the invocation table rows. It must pass unchanged.

### Verified by

- The standards file has a `## Gates as loops` heading, and its table has a row for each of P1 to P6.
- The table names `planifest-design-critic`, `planifest-verify-by-execution`, and the cross-model review gate.
- The P3 row names the P4 CI run, and the P5 row names a fresh-context re-review.
- The section says each loop keeps its cap, with 5 for P4.
- The orchestrator has an `autonomous` sentence below the Phase Invocation Table that links to `autonomous-run-standards.md`.
- The loop runner's Toggle Protocol names `autonomous` and all five keys. It says an explicit value wins and an absent key is `off` outside `autonomous`.
- The loop-toggles template has no uncommented line for the four checker keys, and each commented line names `autonomous`.
- Every row of the Phase Invocation Table matches its text before this feature.

### Security additions (P5)

- G1: In `autonomous`, an explicit `off` or `report-only` for any of the four checker keys blocks the `autonomous` choice at P0. P0 names the key and recommends removing it or setting `on`. `parallel_streams` stays free to set. The changes are in `planifest-loop-runner/SKILL.md`, `autonomous-run-standards.md`, and `planifest-orchestrator/SKILL.md`.
- G8: At P1 start, the build log records every resolved toggle and its source. The source is a file value, the `autonomous` default, or an absent default. The change is in `planifest-loop-runner/SKILL.md` and `loop-toggles.template.yml`.

## Acceptance Criteria

- [ ] (AC-1) In `autonomous`, every P1 to P6 gate runs as a loop with a named checker, and no gate stops for the human on the loop.
- [ ] (AC-1) In `autonomous`, an absent toggle key reads as `on` for the five named keys, an explicit value wins, and the template ships those keys commented out.
- [ ] (AC-7) The new suite and the 0000016 and 0000023 req-001 suites pass under `run-tests.sh`.

## Dependencies

- req-001 defines `autonomous_run`.
- req-002 relies on `reversal_protocol` reading as `on` in `autonomous`.
- req-004 defines what happens when a gate loop hits its cap or makes no progress.
- req-015 adds the `parallel_streams` line to the template and refers to this rule.
- P2 writes an ADR for autonomous checkers starting at `on` rather than `report-only`.
- 0000016 loop engineering provides `planifest-loop-runner`, the toggles, and the caps.
