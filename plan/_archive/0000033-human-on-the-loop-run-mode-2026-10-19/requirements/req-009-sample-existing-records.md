---
title: "Requirement: req-009 - sample-existing-records"
summary: "When a design depends on existing records, P0 discovery samples recent rows and states how often each value is usable, and the design names that rate as an assumption."
status: "draft"
version: "0.1.0"
---
# Requirement: req-009 - sample-existing-records

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-004
**Priority:** must-have

## User Story

As the human on the loop, I answer P0 questions only where the answer needs my judgement or changes what gets built, so that derivable items reach me once, in the design draft.

This requirement covers the record-sampling part of US-004. A usable-rate figure is a derivable fact, so discovery finds it instead of P3 or P4.

## Functional Requirements

### Discovery template (`planifest-framework/templates/discovery.template.md`)

- Add a `## Record Samples` section after `## Mode Findings`. It applies in every adoption mode.
- The section opens with a comment. If the design reads no existing records, write `None` and stop.
- Otherwise the section holds one table row per value the design relies on, with these columns:
  - `Source`: the log, database table, or config history read
  - `Value relied on`: the field or column
  - `Rows sampled`: the count and the window, such as "last 8 rows"
  - `Usable rows`: the count of rows where the value works for the design
  - `Usable rate`: usable rows over rows sampled, as a fraction and a percentage
- An unreadable source keeps the existing rule. Its row states plainly that the rate could not be determined.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`### Structured Discovery Pass (all modes)`:** Add one paragraph. If a design depends on existing records, discovery samples recent rows of each source. It states how often each value the design relies on is usable. Examples of a source are a log, a database table, and a config history.
- **`### Phase 0 Start Actions`, step 3d (Write discovery.md):** Say when the sample runs:
  - If the brief already shows the design reads existing records, step 3d samples them.
  - If coaching reveals the dependency later, the orchestrator samples before it writes the design draft. It appends the rows to `## Record Samples` and commits `discovery.md` again.
- The sample is read-only. Discovery never writes to the records it samples.

### Design template (`planifest-framework/templates/design.template.md`)

- **`## Assumptions`:** Add a guidance line. Each `## Record Samples` row becomes an assumption that names the source, the value, and the usable rate. Its "impact if wrong" says what the design loses if the rate is lower. An example is "the skip rarely fires".

### Tests

- Add `planifest-framework/tests/test-0000033-req-009-sample-existing-records.sh`. It makes text assertions on the three files above. `run-tests.sh` picks it up.
- `planifest-framework/tests/test-0000017-req-006-structured-discovery-pass.sh` asserts the discovery template's five existing sections and the Structured Discovery Pass text. It must pass unchanged.

### Verified by

- The discovery template contains `## Record Samples`, and its line number is after `## Mode Findings`.
- The `## Record Samples` section names the columns `Source`, `Value relied on`, `Rows sampled`, `Usable rows`, and `Usable rate`.
- The `## Record Samples` section contains `None` as the value when the design reads no existing records.
- The orchestrator's `### Structured Discovery Pass (all modes)` section contains `samples recent rows` and `usable`.
- Step 3d names the later-sampling path and says the orchestrator commits `discovery.md` again.
- The orchestrator says the sample is read-only.
- The design template's `## Assumptions` section names `Record Samples` and `usable rate`.

## Acceptance Criteria

- [ ] If a design depends on existing records, `discovery.md` holds a `## Record Samples` table. The table states the usable rate of each value the design relies on.
- [ ] The confirmed design names each usable rate as an assumption, with its impact if wrong.
- [ ] A design that reads no existing records gets `None` in `## Record Samples`. The new suite and the 0000017 req-006 suite pass under `run-tests.sh`.

## Dependencies

- req-008 (p0-real-forks-only). The usable rate goes into the design draft as a derived item and needs no question of its own.
- 0000017 req-006 (structured discovery pass) defines `discovery.md` and its lifecycle. This requirement adds one section and keeps that lifecycle.
