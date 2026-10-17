---
title: "Requirement: req-005 - blocking-context-clear"
summary: "P9 ends with a blocking context clear, and the orchestrator refuses new work in the same session until the context is cleared."
status: "active"
version: "0.1.0"
---
# Requirement: req-005 - blocking-context-clear

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Source:** US-002
**Priority:** must-have

## User Story

As the human on the loop, I want P9 to end with a blocking context clear, so that every new request starts in a fresh session and goes through triage.

## Functional Requirements

### Ship skill (`planifest-framework/skills/planifest-ship-agent/SKILL.md`)

- **Step 12:** Rename it to a blocking context-clear step. Replace the advisory text and the `⚡` line. The step does these things:
  1. Ask the human on the loop to run `/clear`, or the host tool's equivalent, or to start a new session.
  2. If a new request arrives in the same session, refuse that work and repeat the request to clear context.
  3. Don't start triage, P0, or any edit for the new request in this session.
- Step 12 no longer contains "do not block".

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`## Context Hygiene`:** The Phase 9 completion clear point matches ship Step 12. After P9, the orchestrator asks for `/clear` or a new session. It refuses any new request in the same session and repeats the request. The "no programmatic context clear" fallback stays for P0 Start Actions step -1. After P9, that fallback also refuses new work until the human on the loop confirms a cleared context or a new session.
- **`## Phase 9 - Ship`, "Completion context reset":** Points to the Context Hygiene rule above and states that the reset blocks new work.

### Tests

- A new Bash suite under `planifest-framework/tests/` covers this requirement through text assertions on both skill files. `run-tests.sh` picks it up.

### Verified by

- The ship skill's Step 12 section contains `/clear` and `new session`, and an instruction to refuse new work in the same session.
- The ship skill's Step 12 section doesn't contain `do not block` or `⚡`.
- The orchestrator's `## Context Hygiene` section contains a refusal rule for new requests after P9 in the same session.
- The orchestrator's `## Phase 9 - Ship` section refers to the Context Hygiene rule and says the reset blocks new work.
- The new suite and every existing suite pass under `run-tests.sh` on the 0000031 CI jobs.

## Acceptance Criteria

- [ ] (AC-5) Ship Step 12 asks the human on the loop to run `/clear` or start a new session, and refuses new work in the same session. It no longer contains `do not block` or `⚡`.
- [ ] (AC-5) The orchestrator's Context Hygiene section refuses new requests after P9 in the same session. Its `## Phase 9 - Ship` section points to that rule.
- [ ] (AC-5) The new suite and every existing suite pass under `run-tests.sh` on the 0000031 CI jobs.

## Dependencies

- req-001 (marker-clear-before-tag) sets the marker timing that ends the run at P9.
- Build req-001 before this requirement, or in the same wave with req-001's ship-skill edits merged first. Both edit the ship skill.
- [ADR-003](../adr/ADR-003-blocking-context-clear-after-p9.md) supersedes 0000015's advisory post-P9 ADR (`plan/_archive/0000015-pipeline-session-cleanup-2026-05-19/adr/ADR-002-new-session-recommendation-not-block.md`). That ADR chose an advisory post-P9 message. This requirement makes Step 12 blocking.
