---
title: "Requirement: req-001 - autonomous-run-mode"
summary: "P0 offers autonomous as a third run mode, records it in plan/.run-mode only when the human on the loop picks it, and resume restores it."
status: "draft"
version: "0.1.0"
---
# Requirement: req-001 - autonomous-run-mode

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-001
**Priority:** must-have

## User Story

As the human on the loop, I choose `autonomous` at P0, so that the run goes from confirmed design to a raised PR with no gate waiting for me.

## Functional Requirements

### New standards file (`planifest-framework/standards/autonomous-run-standards.md`)

- This requirement creates the file. req-002 to req-006 add their own sections to it.
- **`## Run modes`:** A table lists the three `plan/.run-mode` values: `interactive`, `continuous`, and `autonomous`. Each row states which stops the mode skips:
  - `interactive` skips none.
  - `continuous` skips the P1 to P6 phase confirmations, as today.
  - `autonomous` skips every stop that isn't on the exception list (req-002).
- **Session flags:** `autonomous` sets both `continuous_run: true` and `autonomous_run: true`. Every existing rule that names `continuous_run` therefore also applies in `autonomous`. Behaviour that only `autonomous` has checks `autonomous_run`.
- **Unknown values:** Any value other than the three reads as `interactive`. An absent or unreadable file also reads as `interactive`. This amends 0000012-ADR-005, which recognised only `continuous`.
- **Overrides win:** If a file in `planifest-overrides/instructions/` conflicts with the `autonomous` text, the override wins.
- **Choosing the mode:** Only the human on the loop's answer to the P0 run-mode prompt sets `autonomous`. An override that describes hands-off running never counts as that choice, and never writes `autonomous` to `plan/.run-mode`.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`### What you produce at the end of Phase 0`, run-mode prompt:** The prompt offers three options. Each option names who acts, per req-007. The options are:
  1. `[1] Interactive: the human confirms after each phase`
  2. `[2] Continuous: the agent runs P1 to P6 without phase confirmations`
  3. `[3] Autonomous: the agent runs from the confirmed design to a raised PR. Only exception-list items wait for the human.`
- **Recording the answer:** If the human picks [3], set `continuous_run: true` and `autonomous_run: true`, and write `autonomous` to `plan/.run-mode`. The handling of [1] and [2] stays as it is.
- **Resume sentence after the prompt:** The sentence names all three values. It says any other value defaults to `interactive`.
- **`## Resume Detection` step 6:** Restore `continuous`, `interactive`, or `autonomous` without asking again. Restoring `autonomous` sets both session flags. Any other value, an absent file, or an unreadable file defaults to `interactive`.
- **`## Phase Conventions`:** Add one line that links to `standards/autonomous-run-standards.md` for the run-mode table. Keep the line short. The orchestrator skill already holds 9,276 words.

### Guides

- **`planifest-framework/getting-started.md`:** The sentence about the run-mode question names three choices: per-phase confirmation, a continuous run, and an autonomous run.
- **`planifest-framework/pipeline-reference.md`:** The P0 row and the copy of the run-mode prompt show the three options from the orchestrator skill.

### Docs agent (`planifest-framework/skills/planifest-docs-agent/SKILL.md`)

- No text change. Gate B checks `continuous_run`, which `autonomous` sets, so Gate B auto-accepts in `autonomous`.

### Tests

- Add `planifest-framework/tests/test-0000033-req-001-autonomous-run-mode.sh`. `run-tests.sh` picks it up.
- These existing suites must pass unchanged:
  - `planifest-framework/tests/test-0000023-req-001-continuous-run-p1-p3.sh`
  - `planifest-framework/tests/test-0000025-req-006-docs-agent-continuous-run.sh`
  - `planifest-framework/tests/test-0000032-req-001-marker-clear-before-tag.sh`

### Verified by

- `planifest-framework/standards/autonomous-run-standards.md` exists and has a `## Run modes` heading.
- The `## Run modes` section names `interactive`, `continuous`, and `autonomous`.
- The section says `autonomous` sets `continuous_run: true` and `autonomous_run: true`.
- The section says an unknown value reads as `interactive` and names 0000012-ADR-005.
- The section says an override never counts as choosing `autonomous`.
- The orchestrator's run-mode prompt contains `[3] Autonomous`, and none of its three options contains the word `I`.
- The orchestrator's recording text writes `autonomous` to `plan/.run-mode` only for option [3].
- Resume Detection step 6 names all three values and still defaults any other value to `interactive`.
- The P1, P2, and P3 rows of the Phase Invocation Table keep the exact `continuous_run` exception text that the 0000023 suite asserts.
- `getting-started.md` and `pipeline-reference.md` both name the autonomous option.
- The new suite and the three existing suites pass under `run-tests.sh`.

## Acceptance Criteria

- [ ] (AC-1) The P0 run-mode prompt offers `autonomous`, and only the human on the loop's choice of it writes `autonomous` to `plan/.run-mode`.
- [ ] (AC-1, AC-7) Resume restores all three values. Any other value reads as `interactive`, and `interactive` and `continuous` keep their current text.
- [ ] (AC-7) The new suite and the 0000023 req-001, 0000025 req-006, and 0000032 req-001 suites pass under `run-tests.sh`.

## Dependencies

- A P2 ADR amends 0000012-ADR-005 (`plan/_archive/0000012-docs-restructure-commit-directives-2026-05-18/adr/ADR-005-run-mode-sentinel-file.md`) to recognise `autonomous`.
- req-002 to req-006 read `autonomous_run` and add sections to the standards file this requirement creates.
- req-007 sets the actor-naming rule for the prompt options.
- req-008 moves the run-mode question into the single P0 confirmation turn with the design and the Scope Lock batch. This requirement changes only the options and their recording.
