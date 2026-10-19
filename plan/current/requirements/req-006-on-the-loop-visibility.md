---
title: "Requirement: req-006 - on-the-loop-visibility"
summary: "In autonomous mode each phase writes a one-line progress entry to the build log, every human touchpoint is logged, and the P8 report flags any touchpoint outside the exception list."
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

- **`## Visibility`:** The section gives two build-log line formats for `autonomous`:
  - Progress: `Progress: P{N} {done | blocked} ({ISO-8601 UTC}): {one-line summary}`
  - Touchpoint: `Human touchpoint (P{N}): {what the run asked or waited for} [{exception: item | outside list}]`
- **When to write a progress line:** Each phase from P1 to P9 writes one progress line at its gate. P7 to P9 write theirs to the archived build log, as the ship agent's other P7 to P9 entries do.
- **What counts as a touchpoint:** A touchpoint is any point after the P0 confirmation turn where the run asks the human on the loop something or waits for them. Listing an exception item in the final report doesn't count as a touchpoint.
- **No push notifications:** The build log is the only visibility channel.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`## Phase Conventions`:** Add one line. In `autonomous`, each phase writes the progress line at its gate, and every touchpoint gets a touchpoint line. The line links to the standards file.

### Ship skill (`planifest-framework/skills/planifest-ship-agent/SKILL.md`)

- P7, P8, and P9 each write their progress line in `autonomous`.

### Build assessment skill (`planifest-framework/skills/planifest-build-assessment-agent/SKILL.md`)

- **`## Report Structure`:** If the build log records `autonomous`, the report gains a `## Human Touchpoints` section. The section gives the total count and the count outside the exception list. It lists each touchpoint outside the list as a finding.
- **`**Phase gate audit**`:** Add two checks for `autonomous`:
  - The P0 audit trail records that the human on the loop chose `autonomous`.
  - Each phase from P1 to P9 has a progress line. A missing line is a finding.
- The existing `continuous_run` check stays.
- In `interactive` and `continuous`, the report has no `## Human Touchpoints` section.

### Build log template (`planifest-framework/templates/build-log.template.md`)

- The template shows the progress and touchpoint line formats, marked as `autonomous` only.

### Tests

- Add `planifest-framework/tests/test-0000033-req-006-on-the-loop-visibility.sh`. `run-tests.sh` picks it up.
- `planifest-framework/tests/test-0000006-build-assessment.sh` asserts the build assessment skill's text. It must pass unchanged.

### Verified by

- The standards file has a `## Visibility` heading, and the section gives both line formats.
- The section defines a touchpoint and says the run sends no push notification.
- The orchestrator's Phase Conventions name the progress line and link to `autonomous-run-standards.md`.
- The ship skill names the progress line for P7, P8, and P9.
- The build assessment skill has a `## Human Touchpoints` section, marked as `autonomous` only.
- The phase gate audit names the `autonomous` choice check and the progress line check.
- The phase gate audit still has its `continuous_run` check.
- The build log template shows both line formats.

## Acceptance Criteria

- [ ] (AC-2) In `autonomous`, each phase from P1 to P9 writes a progress line, and every touchpoint after P0 writes a touchpoint line.
- [ ] (AC-2) The P8 report counts touchpoints and flags each one outside the exception list in an `autonomous` run.
- [ ] (AC-7) Build logs and P8 reports for `interactive` and `continuous` don't change, and the new suite and the 0000006 suite pass under `run-tests.sh`.

## Dependencies

- req-001 defines `autonomous`. req-002 defines the exception list that the touchpoint line refers to.
- req-008 adds the P0 question count to the P0 build-log block. This requirement covers P1 to P9 only.
- req-018 adds subagent count and wall-clock time per phase to the same P8 report.
