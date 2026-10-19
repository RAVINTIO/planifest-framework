---
title: "Requirement: req-004 - escalation-changes-approach"
summary: "In autonomous mode a loop that hits its cap or makes no progress tries a different approach, up to 3 per gate. A fourth approach becomes an exception-list item."
status: "draft"
version: "0.1.0"
---
# Requirement: req-004 - escalation-changes-approach

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-003
**Priority:** must-have

## User Story

As the human on the loop, I see a failed gate retried by a fresh-context checker with a changed approach, so that a cap or a no-progress halt doesn't stop an autonomous run.

## Functional Requirements

### Standards file (`planifest-framework/standards/autonomous-run-standards.md`)

- **`## Changing approach`:** The section states the rule for `autonomous`:
  1. When a loop hits its iteration cap or the no-progress rule, the agent records the attempts and starts a new approach.
  2. A new approach states how it differs from each earlier approach, such as a new root-cause hypothesis or a new method. Restating an earlier approach doesn't count as a new one.
  3. The iteration counter restarts at 1 for each approach. The approach counter never restarts.
  4. Each gate allows up to 3 approaches. If the gate needs a fourth, the loop escalates as an exhausted budget, which is an exception-list item (req-002).
  5. The reversal budget stays at 2 per feature. Its exhaustion is an exception-list item in `autonomous`.

### Loop runner (`planifest-framework/skills/planifest-loop-runner/SKILL.md`)

- **`## Stop Rules`:** Add one sentence below the table. In `autonomous`, the iteration cap and no-progress rules decide `change-approach` while the approach count is below 3. At the third approach's cap, they decide `escalate`. The table rows stay as they are for `interactive` and `continuous`.
- **`## The Iteration Cycle`:** The DECIDE step lists `change-approach` as a fourth outcome.
- **`## Escalation Format`:** In `autonomous`, the agent writes the escalation as an `Exception waiting` build-log line and carries on with independent work. The `Px: Blocked` line stays for other modes.
- **Hard Limit 3:** The approach counter is a budget counter. No agent resets it.

### Loop state template (`planifest-framework/templates/loop-state.template.md`)

- The field table gains an `Approach` row: `{{n}} of 3 (autonomous only)`.
- Each run-log record gains an `Approach` field.
- The `Last decision` field and the run-log `Decision` field list `change-approach`.
- Escalation Context lists each approach that was tried.

### Validate skill (`planifest-framework/skills/planifest-validate-agent/SKILL.md`)

- **Self-correct section:** The sentence "your halt/escalate behaviour is unchanged" applies to `interactive` and `continuous`. In `autonomous`, the fifth failed cycle starts a new approach. After 3 approaches, the `VALIDATION BLOCKED` text becomes an exception-list item.
- The `VALIDATION BLOCKED` format stays for `interactive` and `continuous`.

### Codegen skill (`planifest-framework/skills/planifest-codegen-agent/SKILL.md`)

- **`**TDD Inner Loop Protocol:**`:** In `autonomous`, the third failed attempt on one requirement starts a new approach. After 3 approaches, the requirement becomes an exception-list item. Codegen moves on to requirements that don't depend on it.
- The `TDD LOOP BLOCKED` format and the "wait for human direction" line stay for `interactive` and `continuous`.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`### Cross-Model Review Gate`, step 5:** In `autonomous`, a cap or halt starts a new approach. After 3 approaches, the outstanding findings become an exception-list item. The current text stays for other modes.

### Tests

- Add `planifest-framework/tests/test-0000033-req-004-escalation-changes-approach.sh`. `run-tests.sh` picks it up.
- `planifest-framework/tests/test-0000016-pipeline-governance.sh` asserts the loop runner's `no-progress` and `loop-state` text. It must pass unchanged.

### Verified by

- The standards file has a `## Changing approach` heading. The section names 3 approaches per gate and says the reversal budget stays at 2.
- The section says the approach counter never restarts.
- The loop runner names `change-approach` in both the Iteration Cycle and the Stop Rules sections.
- The Stop Rules table still has its four rows, with cap 3, P4's 5, and the reversal budget of 2.
- The loop-state template has an `Approach` row and lists `change-approach`.
- The validate skill still contains `VALIDATION BLOCKED` and names `autonomous` in its self-correct section.
- The codegen skill still contains `TDD LOOP BLOCKED` and names `autonomous` in its TDD protocol.
- Cross-model review step 5 names `autonomous` and still blocks P7 in other modes.

## Acceptance Criteria

- [ ] (AC-1) In `autonomous`, the loop runner, validate, codegen, and the cross-model gate change approach at a cap or a no-progress halt, up to 3 approaches per gate.
- [ ] (AC-2) A fourth approach, or an exhausted reversal budget of 2, becomes an exception-list item, and the run carries on with independent work.
- [ ] (AC-7) The escalation text for `interactive` and `continuous` stays, and the new suite and the 0000016 suite pass under `run-tests.sh`.

## Dependencies

- req-002 defines the exception list and the `Exception waiting` line.
- req-003 makes each gate a loop.
- 0000016-ADR-007 keeps budget counters in the git-tracked loop-state file, so a restart doesn't reset the approach counter.
