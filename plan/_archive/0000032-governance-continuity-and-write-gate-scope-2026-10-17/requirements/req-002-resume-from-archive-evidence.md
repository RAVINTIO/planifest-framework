---
title: "Requirement: req-002 - resume-from-archive-evidence"
summary: "Resume Detection step 2a resumes an interrupted close-out at P8 or the P9 marker step from archive evidence, and never deletes markers on its own."
status: "active"
version: "0.1.0"
---
# Requirement: req-002 - resume-from-archive-evidence

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Source:** US-001
**Priority:** must-have

## User Story

As the human on the loop, I want an interrupted close-out to resume from archive evidence, so that P8 and P9 finish as part of the same run.

## Functional Requirements

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **Resume Detection step 2a:** Replace the "Interrupted P9 detection" cleanup sequence. The trigger stays the same: the sentinel is present and `plan/current/` is empty. The new step does these things:
  1. Read the feature ID from `plan/.orchestrator-active`.
  2. List `plan/_archive/{feature-id}-*` directories and pick the last one in lexical sort order. This picks a `-2` or `-3` suffix over the bare date.
  3. If that directory has no `build-report.md`, load the ship skill and resume at P8.
  4. If that directory has a `build-report.md`, load the ship skill and resume at the P9 marker step.
  5. If no directory matches, or the sentinel holds `pending`, stop and ask the human on the loop how to proceed. Do not delete any marker.
- **Resume Detection step 2b (interrupted marker commit):** If the sentinel is absent on disk but still in `HEAD`, read the feature ID from `HEAD` and apply step 2a's archive rule. This covers a P9 marker commit that stopped and a sentinel that a human on the loop deleted by hand.
  1. If the archive directory has no `build-report.md`, resume at P8.
  2. If it has one, resume at the P9 marker step, finish its commit, and continue to the Step 9 tag.
  3. If no directory matches, stop and ask the human on the loop. Do not delete any marker.
- **Resume Detection step 2a message:** Drop `Interrupted P9 detected: archive completed but sentinels not cleared. Cleanup complete. Starting fresh.` Step 2a never deletes markers on its own and never starts fresh.

### Tests

- A new Bash suite under `planifest-framework/tests/` covers this requirement through text assertions on the orchestrator skill. `run-tests.sh` picks it up.

### Verified by

- Orchestrator step 2a names `plan/.orchestrator-active` as the feature-ID source and the `plan/_archive/{feature-id}-*` pattern.
- Orchestrator step 2a names `build-report.md`, with "resume at P8" for its absence and the P9 marker step for its presence.
- Orchestrator step 2a tells the agent to stop and ask the human on the loop when no archive matches.
- Orchestrator step 2a checks the ID against `^[0-9]{7}-[a-z0-9-]+$` before it lists the archive. It confirms the directory sits inside `plan/_archive/` and quotes the ID in commands (security finding K-1).
- Orchestrator step 2b handles a sentinel that is absent on disk but still committed. It reads the ID from `HEAD`, tells the human on the loop, and resumes at the P9 marker step before the Step 9 tag (K-3).
- Orchestrator step 2b applies step 2a's archive rule. It resumes at P8 without a `build-report.md` and stops and asks the human on the loop when no archive matches. It names a hand-deleted sentinel as a trigger (re-review finding N-8).
- The orchestrator skill no longer contains `Cleanup complete. Starting fresh.`
- The new suite passes under `run-tests.sh` on the 0000031 CI jobs.

## Acceptance Criteria

- [ ] (AC-2) Resume Detection step 2a reads the feature ID from the sentinel and picks the latest `plan/_archive/{feature-id}-*` directory.
- [ ] (AC-2) Step 2a resumes at P8 without a `build-report.md`, and at the P9 marker step with one. With no matching archive, it stops and asks the human on the loop.
- [ ] (AC-2) The orchestrator skill no longer contains `Cleanup complete. Starting fresh.`, and the new suite passes under `run-tests.sh`.

## Dependencies

- req-001 (marker-clear-before-tag). Step 2a resumes at the P9 marker step that req-001 adds.
- [ADR-002](../adr/ADR-002-session-markers-cleared-in-p9-before-the-tag.md) supersedes 0000015's interrupted-P9 detection ADR (`plan/_archive/0000015-pipeline-session-cleanup-2026-05-19/adr/`). The trigger signal stays, but its meaning changes from "clean up and start fresh" to "resume P8 or P9 from archive evidence".
- `docs/decisions-index.md` links the 0000015 ADRs. P6 updates it to show the superseded status.
