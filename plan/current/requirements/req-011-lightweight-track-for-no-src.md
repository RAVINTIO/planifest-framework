---
title: "Requirement: req-011 - lightweight-track-for-no-src"
summary: "Fast Path's prerequisite relaxes to admit a change with no src/ target, its four criteria stay, and the orchestrator's track table says so."
status: "draft"
version: "0.1.0"
---
# Requirement: req-011 - lightweight-track-for-no-src

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-010
**Priority:** should-have

## User Story

As the human on the loop, I route a change with no `src/` component through a lightweight track, so that governance and documentation changes stop running the full Feature Pipeline.

## Functional Requirements

### Fast Path workflow (`planifest-framework/workflows/fast-path.md`)

- **`## Prerequisites`:** Replace "An existing feature with code at `src/{component-id}/`" with two alternatives. Either one meets the prerequisite:
  - an existing feature with code at `src/{component-id}/`
  - a change with no `src/` target, such as a change to documentation, governance, tooling, or framework text
- **`## Prerequisites`:** Keep "The request meets **ALL** Fast Path criteria". A no-`src/` change must still meet all four.
- **`## Fast Path Criteria`:** The four numbered criteria stay word for word. So does the line that routes a failed criterion to `/change-pipeline`.
- **`## Steps`, step 4 (Update `component.yml`):** Update the `component.yml` that covers the changed paths, such as `planifest-framework/component.yml`. If no manifest covers them, skip step 4.
- **`## Steps`, step 5 (Log the change):** For a no-`src/` change, the `Component:` line names the covering manifest's component, or the changed paths if none covers them.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`### Three-Track Decision Tree`:** Add a row. Its signal reads: a change with no `src/` target, such as documentation, governance, or tooling. Its track reads: **Fast Path** - if ALL Fast Path criteria are met.
- **`### Fast Path Criteria and Execution`:** Add one sentence. Fast Path admits a change with no `src/` target, and its four criteria still apply.
- If a no-`src/` change fails any criterion, routing doesn't change. It goes to the Change Pipeline or the Feature Pipeline by the existing rows.

### Unchanged files

- `planifest-framework/hooks/pre-push` and `.github/workflows/planifest.yml` don't change. Their Fast Path check applies only when `src/` changed, so a no-`src/` Fast Path push already passes.

### Tests

- Add `planifest-framework/tests/test-0000033-req-011-lightweight-track-for-no-src.sh`. It makes text assertions on the two files above. `run-tests.sh` picks it up.
- These existing suites assert `Fast Path` in routing text. They must pass unchanged:
  - `planifest-framework/tests/test-0000032-req-003-no-run-triage-message.sh`
  - `planifest-framework/tests/test-0000032-req-004-handover-note-routing.sh`

### Verified by

- `workflows/fast-path.md` `## Prerequisites` names both `src/{component-id}/` and `no \`src/\` target`.
- `workflows/fast-path.md` still holds the four criteria word for word: "new external dependencies", "database schemas or data models", "security parameters, authentication, or routing logic", and "UI styling, copy changes, or isolated pure-function logic bugs".
- Step 4 of `workflows/fast-path.md` says to skip the step when no manifest covers the changed paths.
- The orchestrator's `### Three-Track Decision Tree` table has a row naming `no \`src/\` target` with **Fast Path** as its track.
- The orchestrator's `### Fast Path Criteria and Execution` section names `no \`src/\` target` and still links to `planifest-framework/workflows/fast-path.md`.

### Security additions (P5)

- G12: Fast Path still admits a change with no `src/` target. It never admits a change to `planifest-framework/hooks/`, `planifest-framework/scripts/`, `setup.sh`, `setup.ps1`, or any enforcement hook. Those take the Change or Feature Pipeline. The changes are in `workflows/fast-path.md` and the Three-Track Decision Tree row of `planifest-orchestrator/SKILL.md`.
- Fast Path also excludes `planifest-framework/standards/autonomous-run-standards.md`.

## Acceptance Criteria

- [ ] Fast Path's prerequisite admits a change with no `src/` target. A change with code under `src/` still meets it as before.
- [ ] The four Fast Path criteria stay word for word, and a no-`src/` change must meet all four.
- [ ] The orchestrator's track table routes a no-`src/` change to Fast Path when all criteria pass. The new suite and the two 0000032 suites pass under `run-tests.sh`.

## Dependencies

- req-010 (release-budget) and req-008 (p0-real-forks-only) don't depend on this requirement. Fast Path skips P0, so neither applies to a Fast Path change.
- Backlog 0000060 and 0000061 came from the same downstream analysis. They stay out of scope.
