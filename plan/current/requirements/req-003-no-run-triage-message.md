---
title: "Requirement: req-003 - no-run-triage-message"
summary: "When no run is active, the auto-trigger hook says so and tells the agent to load the orchestrator and triage the request before acting."
status: "active"
version: "0.1.0"
---
# Requirement: req-003 - no-run-triage-message

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Source:** US-002
**Priority:** must-have

## User Story

As the human on the loop, I want the auto-trigger hook to say no run is active and to require triage, so that the agent routes every new request into a track.

## Functional Requirements

### Auto-trigger hook (`planifest-framework/hooks/enforcement/auto-trigger-orchestrator.mjs`)

- The two existence checks stay as they are. If `planifest-framework/` is missing, or `plan/.orchestrator-active` exists, the hook exits 0 with no output.
- When `planifest-framework/` exists and the sentinel doesn't, the stdout message says these things:
  - No Planifest run is active.
  - The agent must load the `planifest-orchestrator` skill before it responds.
  - The agent must triage the request as Fast Path, Change Pipeline, or Feature Pipeline before acting.
  - The agent begins with resume detection, as the skill describes.
- The message no longer says the orchestrator "has not been loaded yet". The hook can't know that, so it doesn't claim it.
- The file's header comment describes check 2 as "no run is active", not "orchestrator not yet loaded".
- The hook still never exits 2, and still exits 0 on any unexpected error.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`## Routing Directive`:** Keep "Every request must be triaged before any action is taken." Add that this includes every request after P9, whether or not a run is active.

### Tests

- A new Bash suite under `planifest-framework/tests/` covers this requirement. `run-tests.sh` picks it up.
- The suite runs the hook with JSON on stdin, using a temporary directory as `cwd`.
- Check whether any regression suite asserts the old hook message, and update it. `planifest-framework/tests/regression/test-0000009-rail-tightening.sh` checks the hook source, so confirm it still passes.

### Verified by

- Given a `cwd` with `planifest-framework/` and no `plan/.orchestrator-active`, the hook exits 0. Its stdout contains `no Planifest run is active`, `Fast Path`, `Change Pipeline`, `Feature Pipeline`, and `planifest-orchestrator`.
- For the same input, the hook's stdout doesn't contain `has not been loaded`.
- Given a `cwd` with `planifest-framework/` and `plan/.orchestrator-active`, the hook exits 0 with empty stdout.
- Given a `cwd` without `planifest-framework/`, the hook exits 0 with empty stdout.
- Given malformed JSON on stdin, the hook exits 0.
- Each hook call in the suite completes in under 200 ms on the CI runners.
- The new suite and `test-0000009-rail-tightening.sh` pass under `run-tests.sh` on the 0000031 CI jobs.

## Acceptance Criteria

- [ ] (AC-3) With `planifest-framework/` present and no sentinel, the hook exits 0. Its stdout says no Planifest run is active, names the three tracks and `planifest-orchestrator`, and omits `has not been loaded`.
- [ ] (AC-3) With the sentinel present, without `planifest-framework/`, or with malformed JSON, the hook exits 0 within 200 ms. The first two cases give empty stdout.
- [ ] (AC-3) The new suite and `test-0000009-rail-tightening.sh` pass under `run-tests.sh` on the 0000031 CI jobs.

## Dependencies

- req-001 (marker-clear-before-tag) sets the marker timing. The hook's "no run is active" message is only true once the sentinel survives through P8 and the P9 marker step. Without req-001, the hook would still fire during P8 and P9.
- [ADR-003](../adr/ADR-003-blocking-context-clear-after-p9.md) records the new hook message.
- 0000009's auto-trigger ADR (auto-trigger via UserPromptSubmit) still holds. Only the message text changes.
