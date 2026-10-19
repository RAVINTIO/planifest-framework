---
title: "Requirement: req-006 - on-the-loop-visibility"
summary: "Each phase writes a one-line progress entry to the build log, the build log records the run mode, and in autonomous mode the P8 report flags any human touchpoint outside the exception list."
status: "draft"
version: "0.1.0"
---
# Requirement: req-006 - on-the-loop-visibility

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-002
**Priority:** must-have

## User Story

As the human on the loop, I get asked only for items on a declared exception list, and only in one final report, so that I know exactly when a run needs me.

## Functional Requirements

### Standards file (`planifest-framework/standards/autonomous-run-standards.md`)

- **`## Visibility`:** The section gives two build-log line formats:
  - Progress, in every run mode: `Progress: P{N} {done | blocked} at {End}: {one-line summary}`
  - Touchpoint, in `autonomous` only: `Human touchpoint (P{N}): {what the run asked or waited for} [{exception: item | outside list}]`
- **`{End}` value:** The progress line reuses the phase block's `End` value from req-018. It never takes a second timestamp.
- **When to write a progress line:** Each phase from P1 to P9 writes one progress line at its gate. P7 to P9 write theirs to the archived build log, as the ship agent's other P7 to P9 entries do.
- **What counts as a touchpoint:** A touchpoint is any point after the P0 confirmation turn where the run asks the human on the loop something or waits for them. Listing an exception item in the final report doesn't count as a touchpoint.
- **No push notifications:** The build log is the only visibility channel.

### Build log template (`planifest-framework/templates/build-log.template.md`)

- **`## Header` table:** Add a `Run mode` row with the value `interactive`, `continuous`, or `autonomous`. P0 writes it when the human on the loop picks the mode (req-001). P0 updates it if the mode changes.
- **Run-mode readers:** Every reader after P0 uses this row, including the ship agent at P7 to P9 and the P8 report. No reader uses `plan/.run-mode` after the P9 marker step deletes it.
- The template shows the progress line format for every mode, and the touchpoint line format marked as `autonomous` only.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`## Phase Conventions`:** Add one line. Each phase writes the progress line at its gate. In `autonomous`, every touchpoint also gets a touchpoint line. The line links to the standards file.

### Ship skill (`planifest-framework/skills/planifest-ship-agent/SKILL.md`)

- P7, P8, and P9 each write their progress line, in every run mode.

### Build assessment skill (`planifest-framework/skills/planifest-build-assessment-agent/SKILL.md`)

- **`## Critical Audit`, new `**Human touchpoint audit**`:** It applies only when the Header's `Run mode` row reads `autonomous`. It checks:
  - the total touchpoint count and the count outside the exception list
  - each touchpoint outside the list, which it flags as a finding
- **`## Critical Audit`, `**Build log integrity**`:** Each phase from P1 to P9 has a progress line, in every mode. A missing line is a finding. The Header has a `Run mode` row.
- **`**Phase gate audit**`:** The existing `continuous_run` check stays.
- In `interactive` and `continuous`, the report has no touchpoint audit.

### Tests

- Add `planifest-framework/tests/test-0000033-req-006-on-the-loop-visibility.sh`. `run-tests.sh` picks it up.
- `planifest-framework/tests/test-0000006-build-assessment.sh` asserts the build assessment skill's text. It must pass unchanged.

### Verified by

- The standards file has a `## Visibility` heading, and the section gives both line formats.
- The progress format names `{End}`, and the section says it reuses the phase block's `End` value.
- The section marks the touchpoint line as `autonomous` only, defines a touchpoint, and says the run sends no push notification.
- The build log template's `## Header` table has a `Run mode` row.
- The build log template shows both line formats.
- The orchestrator's Phase Conventions name the progress line and link to `autonomous-run-standards.md`.
- The ship skill names the progress line for P7, P8, and P9.
- The build assessment skill's `## Critical Audit` has a `Human touchpoint audit` marked as `autonomous` only.
- The build log integrity check names the progress line and the `Run mode` row.
- The phase gate audit still has its `continuous_run` check.

## Acceptance Criteria

- [ ] (AC-2) Each phase from P1 to P9 writes a progress line in every mode, and the build-log Header records the run mode for every later reader.
- [ ] (AC-2) In an `autonomous` run, every touchpoint after P0 writes a touchpoint line, and the P8 report counts them and flags each one outside the exception list.
- [ ] (AC-7) The touchpoint audit is absent from `interactive` and `continuous` reports, and the new suite and the 0000006 suite pass under `run-tests.sh`.

## Dependencies

- req-001 writes the `Run mode` row at P0. req-002 defines the exception list that the touchpoint line refers to.
- req-005 reads the `Run mode` row at P7 to P9.
- req-008 adds the P0 question count and its audit under the same `## Critical Audit` section. This requirement covers P1 to P9 only.
- req-018 adds the `End` row that the progress line reuses, and edits the same build log template and P8 report.
