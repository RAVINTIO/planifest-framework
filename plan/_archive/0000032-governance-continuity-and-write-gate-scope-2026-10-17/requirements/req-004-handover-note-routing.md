---
title: "Requirement: req-004 - handover-note-routing"
summary: "Every P9 handover note and next-steps list routes each next step through a track, and never says a code change needs no P0."
status: "active"
version: "0.1.0"
---
# Requirement: req-004 - handover-note-routing

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Source:** US-002
**Priority:** must-have

## User Story

As the human on the loop, I want each next step in a P9 handover note routed through a track, so that no follow-up code change skips the pipeline.

## Functional Requirements

### Ship skill (`planifest-framework/skills/planifest-ship-agent/SKILL.md`)

- **Handover-note rule:** Add a rule under `## Hard Limits`. Any P9 handover note, next-steps list, or runbook pointer routes each next step through a track: Fast Path, Change Pipeline, or Feature Pipeline. The note never says a code change needs no P0, and never points to a runbook that pushes to `main`.
- **Step 11 (Confirm to human):** If the confirmation lists next steps, each one names its track.

### Tests

- A new Bash suite under `planifest-framework/tests/` covers this requirement through text assertions on the ship skill. `run-tests.sh` picks it up.

### Verified by

- The ship skill's `## Hard Limits` section contains a handover-note rule. It names `Fast Path`, `Change Pipeline`, and `Feature Pipeline`, and states that a code change always needs a track.
- The ship skill states that a handover note never says a code change needs no P0.
- The new suite passes under `run-tests.sh` on the 0000031 CI jobs.

## Acceptance Criteria

- [ ] (AC-4) The ship skill's `## Hard Limits` section requires a handover note to route each next step through Fast Path, Change Pipeline, or Feature Pipeline.
- [ ] (AC-4) The ship skill states that a handover note never says a code change needs no P0.
- [ ] (AC-4) The new suite passes under `run-tests.sh` on the 0000031 CI jobs.

## Dependencies

- req-001 (marker-clear-before-tag) sets the marker timing that ends the run at P9.
- Build req-001 before this requirement, or in the same wave with req-001's ship-skill edits merged first. Both edit the ship skill.
- [ADR-003](../adr/ADR-003-blocking-context-clear-after-p9.md) records the handover-note rule.
