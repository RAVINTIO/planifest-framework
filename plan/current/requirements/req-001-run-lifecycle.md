---
title: "Requirement: req-001 - run-lifecycle"
summary: "The orchestrator sentinel and session markers stay in place until P8 ends, and an interrupted close-out resumes from archive evidence."
status: "active"
version: "0.1.0"
---
# Requirement: req-001 - run-lifecycle

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Source:** US-001
**Priority:** must-have

## User Story

As the human on the loop, I want the orchestrator sentinel to stay in place until P9 ends, so that hooks treat P8 and P9 as part of the run.

## Functional Requirements

### Ship skill (`planifest-framework/skills/planifest-ship-agent/SKILL.md`)

- **P7 Step 6 (Archive plan/current/):** Remove items 5, 6, and 7, which delete `plan/.orchestrator-active`, `plan/.orchestrator-ack`, and `plan/.run-mode`. Step 6 no longer touches any session marker.
- **P7 Step 7 (Commit archive):** Drop the three marker paths from the `git add` line. The line becomes `git add plan/current/ plan/_archive/ plan/changelog/ docs/about.md`.
- **P9, new marker step:** Add a step under `## P9: Ship`, after the P9 build-log line and before `### Step 9: Create git tag`. Its heading contains the words `Clear session markers`. The step does these things in order:
  1. Delete `plan/.orchestrator-active`.
  2. Delete `plan/.orchestrator-ack` if it exists.
  3. Delete `plan/.run-mode` if it exists.
  4. Stage the deletions and the archive directory, so the commit also carries the P8 `build-report.md` and the P8 and P9 build-log blocks.
  5. Commit with the subject `plan(p9): clear session markers for {feature-id}`.
  6. Run `git ls-files plan/.orchestrator-active plan/.orchestrator-ack plan/.run-mode`. If the output isn't empty, stop and name the tracked paths to the human on the loop. Do not tag.
- **P9 Step 9 (Create git tag):** Runs only after the marker step commits. The tag therefore never carries a marker.
- **P9 Step 9b (Marker tracking pre-flight check):** Remove it. Its check moves into the new marker step, which runs before the tag. No heading named `Step 9b` remains in the skill, and no remaining step after Step 9 names a marker path.
- **P9 Step 10 (Push/PR decision):** Push and PR stay optional, as now. They follow the project's overrides and the human's choice. The step's text stays unchanged apart from any step-number references.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **Resume Detection step 2a:** Replace the "Interrupted P9 detection" cleanup sequence. The trigger stays the same: the sentinel is present and `plan/current/` is empty. The new step does these things:
  1. Read the feature ID from `plan/.orchestrator-active`.
  2. List `plan/_archive/{feature-id}-*` directories and pick the last one in lexical sort order. This picks a `-2` or `-3` suffix over the bare date.
  3. If that directory has no `build-report.md`, load the ship skill and resume at P8.
  4. If that directory has a `build-report.md`, load the ship skill and resume at the P9 marker step.
  5. If no directory matches, or the sentinel holds `pending`, stop and ask the human on the loop how to proceed. Do not delete any marker.
- **Resume Detection step 2a message:** Drop `Interrupted P9 detected: archive completed but sentinels not cleared. Cleanup complete. Starting fresh.` Step 2a never deletes markers on its own and never starts fresh.
- **`## Phase 9 - Ship`:** "What P9 produces" names the marker-deletion commit before the local git tag.
- **`## Phase 7 - Archive`:** "What P7 produces" doesn't list marker deletion.

### Tests

- A new Bash suite under `planifest-framework/tests/` covers this requirement through text assertions on both skill files. `run-tests.sh` picks it up.
- These existing suites assert the old Step 7 `git add` line and the Step 9b check. Update them to match the new behaviour:
  - `planifest-framework/tests/test-0000023-req-002-marker-commit-lifecycle.sh`
  - `planifest-framework/tests/test-0000025-req-002-ship-agent-p7-git-add.sh`

## Acceptance Criteria

- [ ] (AC-1) In the ship skill, the P7 Step 6 section names none of `.orchestrator-active`, `.orchestrator-ack`, or `.run-mode`.
- [ ] (AC-1) In the ship skill, the P7 Step 7 `git add` line names none of the three marker paths, and still names `plan/_archive/`.
- [ ] (AC-1) The ship skill has a heading containing `Clear session markers`. It sits after `## P9: Ship` and before `### Step 9: Create git tag`, checked by line number.
- [ ] (AC-1) The marker step's section names all three marker paths, a `git commit` with subject `plan(p9): clear session markers`, and a `git ls-files` check.
- [ ] (AC-1) Within the marker step, the delete instructions come before the `git commit` line, checked by line number.
- [ ] (AC-1) The ship skill has no `Step 9b` heading. No section from `### Step 9` to the end of the file names a marker path.
- [ ] (AC-1) The P9 Step 10 section still offers both options: agent pushes and the human pushes.
- [ ] (AC-2) Orchestrator step 2a names `plan/.orchestrator-active` as the feature-ID source and the `plan/_archive/{feature-id}-*` pattern.
- [ ] (AC-2) Orchestrator step 2a names `build-report.md`, with "resume at P8" for its absence and the P9 marker step for its presence.
- [ ] (AC-2) Orchestrator step 2a tells the agent to stop and ask the human on the loop when no archive matches.
- [ ] (AC-2) The orchestrator skill no longer contains `Cleanup complete. Starting fresh.`
- [ ] The updated 0000023 and 0000025 suites and the new suite pass under `run-tests.sh` on the 0000031 CI jobs.

## Dependencies

- req-002 depends on this requirement's marker timing. Its auto-trigger message reads "no run active" from the sentinel's absence. That reading is only true once the sentinel survives until the P9 marker step.
- 0000023 req-002 (markers stay committed). This requirement keeps that rule and moves only the deletion commit.
- P2 must write an ADR that supersedes 0000015 ADR-001 (`plan/_archive/0000015-pipeline-session-cleanup-2026-05-19/adr/ADR-001-interrupted-p9-detection-signal.md`). The trigger signal stays, but its meaning changes from "clean up and start fresh" to "resume P8 or P9 from archive evidence".
- 0000015 ADR-004 (run-mode deletion owned by P9) names ship Step 6 as the deletion point. Its decision still holds, but P2 should record that the deletion has moved into P9.
- `docs/decisions-index.md` links the 0000015 ADRs. P6 updates it to show the superseded status.
