---
title: "Requirement: req-001 - marker-clear-before-tag"
summary: "The ship skill keeps the session markers in place through P8 and deletes and commits them in P9 before the Step 9 tag."
status: "active"
version: "0.1.0"
---
# Requirement: req-001 - marker-clear-before-tag

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Source:** US-001
**Priority:** must-have

## User Story

As the human on the loop, I want the ship skill to delete the session markers in P9 before the tag, so that hooks treat P8 and P9 as part of the run.

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

- **`## Phase 9 - Ship`:** "What P9 produces" names the marker-deletion commit before the local git tag.
- **`## Phase 7 - Archive`:** "What P7 produces" doesn't list marker deletion.

### Tests

- A new Bash suite under `planifest-framework/tests/` covers this requirement through text assertions on the ship skill. `run-tests.sh` picks it up.
- These existing suites assert the old Step 7 `git add` line and the Step 9b check. Update them to match the new behaviour:
  - `planifest-framework/tests/test-0000023-req-002-marker-commit-lifecycle.sh`
  - `planifest-framework/tests/test-0000025-req-002-ship-agent-p7-git-add.sh`

### Verified by

- In the ship skill, the P7 Step 6 section names none of `.orchestrator-active`, `.orchestrator-ack`, or `.run-mode`.
- In the ship skill, the P7 Step 7 `git add` line names none of the three marker paths, and still names `plan/_archive/`.
- The ship skill has a heading containing `Clear session markers`. It sits after `## P9: Ship` and before `### Step 9: Create git tag`, checked by line number.
- The marker step's section names all three marker paths, a `git commit` with subject `plan(p9): clear session markers`, and a `git ls-files` check.
- Within the marker step, the delete instructions come before the `git commit` line, checked by line number.
- The ship skill has no `Step 9b` heading. No section from `### Step 9` to the end of the file names a marker path.
- The P9 Step 10 section still offers both options: agent pushes and the human pushes.
- The marker step runs `git status --porcelain plan/_archive/` and then stages only `plan/_archive/{feature-id}-{YYYY-MM-DD}/`. It never stages the whole of `plan/_archive/` (security finding K-2).
- The marker step's code block runs the delete, the `git rm --cached` line, and the commit on consecutive lines, and the prose names one uninterrupted sequence (K-3).
- The commit line reads `git diff --cached --quiet || git commit ...`, and the prose skips the commit when nothing is staged and no marker is tracked (K-4).
- The updated 0000023 and 0000025 suites and the new suite pass under `run-tests.sh` on the 0000031 CI jobs.

## Acceptance Criteria

- [ ] (AC-1) The ship skill's P7 steps no longer delete, stage, or name `.orchestrator-active`, `.orchestrator-ack`, or `.run-mode`.
- [ ] (AC-1) A P9 `Clear session markers` step deletes and commits the three markers before the Step 9 tag. No `Step 9b` remains, and Step 10 still leaves push and PR optional.
- [ ] (AC-1) The new suite and the updated 0000023 and 0000025 suites pass under `run-tests.sh` on the 0000031 CI jobs.

## Dependencies

- [ADR-002](../adr/ADR-002-session-markers-cleared-in-p9-before-the-tag.md) records the decision to clear the markers in P9 before the tag.
- req-002, req-003, req-004, and req-005 depend on this requirement's marker timing.
- 0000023 req-002 (markers stay committed). This requirement keeps that rule and moves only the deletion commit.
- 0000015's run-mode deletion ADR (`plan/_archive/0000015-pipeline-session-cleanup-2026-05-19/adr/`) names ship Step 6 as the deletion point. Its decision still holds, and ADR-002 records that the deletion has moved into P9.
