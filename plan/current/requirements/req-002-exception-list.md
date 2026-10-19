---
title: "Requirement: req-002 - exception-list"
summary: "In autonomous mode only exception-list items wait for the human on the loop. Every other question becomes a recorded decision, and a product can add items in an override."
status: "draft"
version: "0.1.0"
---
# Requirement: req-002 - exception-list

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-002
**Priority:** must-have

## User Story

As the human on the loop, I get asked only for items on a declared exception list, and only in one final report, so that I know exactly when a run needs me.

## Functional Requirements

### Standards file (`planifest-framework/standards/autonomous-run-standards.md`)

- **`## Exception list`:** The section lists the six items that wait for the human on the loop in `autonomous`:
  1. A schema change or a destructive operation (orchestrator Hard Limits 2 and 3).
  2. A gross deviation.
  3. Human review of the running result.
  4. Promotion beyond the candidate environment.
  5. A human-only input, such as a captcha.
  6. An exhausted budget, such as the reversal budget or the approach budget (req-004).
- **What the agent does for an item:** The agent writes what the item needs, such as a migration proposal or a defect report. It finishes every piece of work that doesn't depend on the item. It records the item in the build log and lists it in the final report (req-005). It never asks about the item mid-run.
- **Human review item:** The agent lists every page or endpoint for review as a full link.
- **Human-only input item:** The agent runs the check up to the point that needs the input.
- **Gross deviation:** A gross deviation is a change the reversal protocol would class as *altering*. It changes the confirmed problem, the users, or the in-scope list. Every other deviation keeps the design's intent, and the agent records it as *additive*.
- **Who classifies:** The fresh-context `planifest-reversal-assessor` classifies a deviation as *altering*. The agent that deviates never classifies its own deviation. If that agent suspects a gross deviation, it files a defect report and the assessor decides.
- **Reversal protocol on:** In `autonomous`, an absent `reversal_protocol` toggle key reads as `on` (req-003). The assessor is therefore available in every `autonomous` run.
- **Decisions are recorded, not asked:** In `autonomous`, a question that isn't an exception-list item becomes a decision. The agent takes the option it would have recommended. It records the decision in the build log and in the requirement, ADR, or design the decision touches.
- **Build-log line formats:**
  - `Decision (P{N}): {what was decided} / reason: {one line}`
  - `Deviation (P{N}, {additive | altering}): {what changed from the confirmed artifact}`
  - `Exception waiting (P{N}, {item}): {what the human on the loop must do}`
- **Standing rules in every mode:** Merging a PR stays human-only. Hard Limits 2 and 3 stay human-gated. No override can remove an item from the list.
- **Product extension:** A product adds items in `planifest-overrides/exception-list.yml`. The file can only add items. An absent file means the six items alone.

### New template (`planifest-framework/templates/exception-list.template.yml`)

- The template shows the `additional:` key with a list of free-text items. A comment says to copy the file to `planifest-overrides/exception-list.yml`, and that the framework never writes there.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`## Phase Conventions`:** Add one line. In `autonomous`, the one-question rule and recommend-then-confirm give way to the standards file's exception list and decision rule.
- **`## Governed Phase-Reversal Protocol`, step 4 (Human gates):** The "always stop" list keeps its four cases for `interactive` and `continuous`. In `autonomous`:
  - Cases (a) altering, (b) a re-exit from P0, and (c) budget exhaustion become exception-list items.
  - Case (d), a cascade larger than 3 artifacts, isn't on the list. The reversal proceeds with a build-log entry.

### Reversal assessor (`planifest-framework/skills/planifest-reversal-assessor/SKILL.md`)

- **Rubric row 5:** Add one sentence. In `autonomous`, an *altering* classification is a gross deviation and becomes an exception-list item.

### Phase skills

- Each of these skills' one-question rule gains one sentence that defers to the standards file in `autonomous`:
  - `planifest-spec-agent`
  - `planifest-adr-agent`
  - `planifest-codegen-agent`
  - `planifest-validate-agent`
  - `planifest-security-agent`
  - `planifest-docs-agent`
  - `planifest-ship-agent`
- **Codegen `**Deviation & Escalation Protocol:**`:** In `autonomous`, option 2 (Stop-and-Ask) becomes a defect report to the reversal assessor. If the assessor classes it *altering*, it becomes an exception-list item. Otherwise codegen takes option 1 and records an *additive* deviation.

### Tests

- Add `planifest-framework/tests/test-0000033-req-002-exception-list.sh`. `run-tests.sh` picks it up.
- No existing suite asserts the reversal step 4 text or the one-question lines. Every existing suite must pass unchanged.

### Verified by

- The standards file has a `## Exception list` heading, and the section names all six items.
- The section defines a gross deviation as the reversal protocol's *altering* class. It names `planifest-reversal-assessor` as the classifier and says the deviating agent never classifies its own deviation.
- The section gives the `Decision`, `Deviation`, and `Exception waiting` line formats.
- The section says merging stays human-only in every mode, and names `planifest-overrides/exception-list.yml`.
- `planifest-framework/templates/exception-list.template.yml` exists and has an `additional:` key.
- Reversal step 4 still contains "Always stop regardless of run mode" text for `interactive` and `continuous`, and has an `autonomous` sentence naming exception-list items.
- The reversal assessor's row 5 names `autonomous` and the exception list.
- Each of the seven phase skills names `autonomous-run-standards.md`.

### Security additions (P5)

- G2: The standing rules rank above every override, including `planifest-overrides/instructions/`. "Overrides win" applies to all other behaviour. The change is in `autonomous-run-standards.md`.
- G4: Before P7 in `autonomous`, the fresh-context reversal assessor reviews every `Deviation` line in the build log. It also reviews each recorded decision that touches data, a schema, or a destructive operation. Anything it classes as altering, schema, or destructive becomes an exception item. The changes are in `autonomous-run-standards.md` and `planifest-codegen-agent/SKILL.md`.
- G10: Rubric item 3 of the reversal assessor now matches the autonomous rule. An additive cascade over 3 proceeds and is recorded. An altering reversal waits. The change is in `planifest-reversal-assessor/SKILL.md`.
- G11: Hard Limits 4 (data owned by one component) and 6 (no credentials in context) join the standing rules. A credential sighting is a seventh exception item. The run stops using the credential, finishes other work, and raises it in the final report. The change is in `autonomous-run-standards.md` and `exception-list.template.yml`.

## Acceptance Criteria

- [ ] (AC-2) The standards file lists the six exception items, the gross-deviation rule, and the decision line formats, and a product can add items through `planifest-overrides/exception-list.yml`.
- [ ] (AC-2) In `autonomous`, the reversal protocol, the reversal assessor, codegen, and each phase skill route non-exception questions to recorded decisions, and exception items to the final report.
- [ ] (AC-7) The `interactive` and `continuous` stop text stays as it is, and the new suite and every existing suite pass under `run-tests.sh`.

## Dependencies

- req-001 creates the standards file and the `autonomous_run` flag.
- req-003 owns the toggle rule that reads an absent `reversal_protocol` key as `on` in `autonomous`.
- req-004 defines the approach budget that item 6 names.
- req-005 lists each waiting item in the final report.
- req-006 counts a touchpoint for each item that reaches the human on the loop.
