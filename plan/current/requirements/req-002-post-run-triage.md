---
title: "Requirement: req-002 - post-run-triage"
summary: "Every request after P9 goes through triage, the auto-trigger hook says no run is active, and P9 ends with a blocking context clear."
status: "active"
version: "0.1.0"
---
# Requirement: req-002 - post-run-triage

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Source:** US-002
**Priority:** must-have

## User Story

As the human on the loop, I want every request after P9 triaged into a track before any work starts, so that no code change escapes the pipeline.

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

### Ship skill (`planifest-framework/skills/planifest-ship-agent/SKILL.md`)

- **Handover-note rule:** Add a rule under `## Hard Limits`. Any P9 handover note, next-steps list, or runbook pointer routes each next step through a track: Fast Path, Change Pipeline, or Feature Pipeline. The note never says a code change needs no P0, and never points to a runbook that pushes to `main`.
- **Step 11 (Confirm to human):** If the confirmation lists next steps, each one names its track.
- **Step 12:** Rename it to a blocking context-clear step. Replace the advisory text and the `⚡` line. The step does these things:
  1. Ask the human on the loop to run `/clear`, or the host tool's equivalent, or to start a new session.
  2. If a new request arrives in the same session, refuse that work and repeat the request to clear context.
  3. Don't start triage, P0, or any edit for the new request in this session.
- Step 12 no longer contains "do not block".

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`## Context Hygiene`:** The Phase 9 completion clear point matches ship Step 12. After P9, the orchestrator asks for `/clear` or a new session. It refuses any new request in the same session and repeats the request. The "no programmatic context clear" fallback stays for P0 Start Actions step -1. After P9, that fallback also refuses new work until the human on the loop confirms a cleared context or a new session.
- **`## Phase 9 - Ship`, "Completion context reset":** Points to the Context Hygiene rule above and states that the reset blocks new work.
- **`## Routing Directive`:** Keep "Every request must be triaged before any action is taken." Add that this includes every request after P9, whether or not a run is active.

### Tests

- A new Bash suite under `planifest-framework/tests/` covers this requirement. `run-tests.sh` picks it up.
- The suite runs the hook with JSON on stdin, using a temporary directory as `cwd`. It also makes text assertions on both skill files.
- Check whether any regression suite asserts the old hook message, and update it. `planifest-framework/tests/regression/test-0000009-rail-tightening.sh` checks the hook source, so confirm it still passes.

## Acceptance Criteria

- [ ] (AC-3) Given a `cwd` with `planifest-framework/` and no `plan/.orchestrator-active`, the hook exits 0. Its stdout contains `no Planifest run is active`, `Fast Path`, `Change Pipeline`, `Feature Pipeline`, and `planifest-orchestrator`.
- [ ] (AC-3) For the same input, the hook's stdout doesn't contain `has not been loaded`.
- [ ] (AC-3) Given a `cwd` with `planifest-framework/` and `plan/.orchestrator-active`, the hook exits 0 with empty stdout.
- [ ] (AC-3) Given a `cwd` without `planifest-framework/`, the hook exits 0 with empty stdout.
- [ ] (AC-3) Given malformed JSON on stdin, the hook exits 0.
- [ ] (AC-3) Each hook call in the suite completes in under 200 ms on the CI runners.
- [ ] (AC-4) The ship skill's `## Hard Limits` section contains a handover-note rule. It names `Fast Path`, `Change Pipeline`, and `Feature Pipeline`, and states that a code change always needs a track.
- [ ] (AC-4) The ship skill states that a handover note never says a code change needs no P0.
- [ ] (AC-5) The ship skill's Step 12 section contains `/clear` and `new session`, and an instruction to refuse new work in the same session.
- [ ] (AC-5) The ship skill's Step 12 section doesn't contain `do not block` or `⚡`.
- [ ] (AC-5) The orchestrator's `## Context Hygiene` section contains a refusal rule for new requests after P9 in the same session.
- [ ] (AC-5) The orchestrator's `## Phase 9 - Ship` section refers to the Context Hygiene rule and says the reset blocks new work.
- [ ] The new suite and every existing suite pass under `run-tests.sh` on the 0000031 CI jobs.

## Dependencies

- req-001 (run-lifecycle) sets the marker timing. The hook's "no run is active" message is only true once the sentinel survives through P8 and the P9 marker step. Without req-001, the hook would still fire during P8 and P9.
- Build req-001 before this requirement, or in the same wave with req-001's ship-skill edits merged first. Both edit the ship skill.
- P2 must write an ADR that supersedes 0000015 ADR-002 (`plan/_archive/0000015-pipeline-session-cleanup-2026-05-19/adr/ADR-002-new-session-recommendation-not-block.md`). That ADR chose an advisory post-P9 message. This requirement makes Step 12 blocking.
- 0000009 ADR-003 (auto-trigger via UserPromptSubmit) still holds. Only the message text changes.
