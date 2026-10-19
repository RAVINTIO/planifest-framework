---
title: "Requirement: req-013 - clean-close-out"
summary: "The P8 build report reaches git in the archive's closing commit, and P8 and P9 end with a scoped git status check that commits leftovers in autonomous mode or lists them for the human on the loop otherwise."
status: "draft"
version: "0.1.0"
---
# Requirement: req-013 - clean-close-out

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-007
**Priority:** must-have

## User Story

As the human on the loop, I get a P7 to P9 close-out that needs no glob delete and ends with a clean working tree, so that an autonomous run can finish without me.

This requirement covers the clean working tree half of US-007. req-012 covers the archive script.

## Functional Requirements

### What changes, given 0000032

0000032 req-001 already stages `{archive-dir}` in the P9 marker step. That commit therefore carries the P8 `build-report.md` and the P8 and P9 build-log blocks. This requirement keeps that order. It doesn't move the P7 commit after P8, because Resume Detection step 2a checks whether `build-report.md` exists to pick between P8 and P9.

The marker-step commit becomes the archive's closing commit. This requirement adds three things:

- a check that the commit carries `build-report.md`
- a scoped clean-tree check at the end of P8
- the same check at the end of P9

### Ship skill (`planifest-framework/skills/planifest-ship-agent/SKILL.md`)

- **P9 marker step, after staging `{archive-dir}`:** Check that `{archive-dir}/build-report.md` is staged or already tracked by `HEAD`. If it is neither, stop and resume at P8. Don't commit the marker deletions without the report.
- **New P8 step, after `P8: Complete`:** Its heading contains `Clean-tree check`. Run:

  ```bash
  git status --porcelain -- plan/ docs/ ':(glob)src/**/docs/**'
  ```

  Leave out paths under `{archive-dir}`, because the P9 marker step commits them. Treat every other line as a leftover.
- **New P9 step, after Step 10 and before Step 11:** Its heading contains `Clean-tree check`. Run the same command with no paths left out. Treat every line as a leftover. This catches the Step 10 changelog PR-URL edit and any Step 9 `product.yml` change.
- **Leftovers in `autonomous` mode:** Read the mode from `plan/.run-mode` as req-001 defines it. Stage each leftover by its explicit path. Commit with the subject `plan(p8): commit close-out leftovers for {feature-id}` or `plan(p9): ...` to match the phase. The commit names its paths after `--`. If req-005 pushed the branch, push this commit too.
- **Leftovers in other modes:** List each leftover path for the human on the loop, with the step or sub-agent that wrote it where known. Ask whether to commit and push it. The human on the loop may decline. Never leave a leftover unreported.
- **No leftovers:** Log `Clean-tree check: clean` in the phase's build-log block and continue.
- **Step 11 (Confirm to human):** Add one line that reports the P9 clean-tree result: `clean`, `committed {n} files`, or `{n} files listed above`.

The check doesn't run `git add -A`, `git add .`, or any glob stage. Untracked changes outside `plan/`, `docs/`, and `src/**/docs/` stay out of scope, as backlog 0000073 states.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`## Phase 9 - Ship`, "What P9 produces":** Add the P9 clean-tree check after the PR step.

### Tests

- A new Bash suite, `planifest-framework/tests/test-0000033-req-013-clean-close-out.sh`, covers this requirement through text assertions on the ship skill. It also runs the scoped `git status --porcelain` command in a temporary git repository and checks which paths it reports. `run-tests.sh` picks it up.
- These suites assert nearby text and must pass unchanged:
  - `planifest-framework/tests/test-0000032-req-001-marker-clear-before-tag.sh`
  - `planifest-framework/tests/test-0000032-req-002-resume-from-archive-evidence.sh`
  - `planifest-framework/tests/test-0000006-build-assessment.sh`
  - `planifest-framework/tests/test-0000032-req-004-handover-note-routing.sh`

### Verified by

- The ship skill has a `Clean-tree check` heading under `## P8: Build Assessment` and another between `### Step 10` and `### Step 11`, checked by line number.
- Both checks name `git status --porcelain -- plan/ docs/ ':(glob)src/**/docs/**'`.
- The P8 check leaves out `{archive-dir}`. The P9 check leaves out nothing.
- Both checks name `autonomous` and a commit with paths after `--`. Both list leftovers for the human on the loop in other modes.
- Neither check contains `git add -A`, `git add .`, or `rm`.
- The P9 marker step checks for `build-report.md` before its `git commit` line, checked by line number.
- In a fixture repo, the scoped command reports `docs/a.md` and `src/x/docs/b.md`, and doesn't report `src/x/app.js`.
- Step 11 reports the clean-tree result.

## Acceptance Criteria

- [ ] (feature AC 5) The P9 marker-step commit always carries `build-report.md`, and the P7 to P9 order stays as 0000032 set it.
- [ ] (feature AC 5) P8 and P9 each end with the scoped `git status --porcelain` check. In `autonomous` mode it commits leftovers by explicit path. In other modes it lists them for the human on the loop.
- [ ] (feature AC 7) The new suite and the unchanged 0000032, 0000006, and handover-routing suites pass under `run-tests.sh`.

## Dependencies

- req-001 defines the `autonomous` value of `plan/.run-mode`.
- req-005 decides whether P9 pushes in `autonomous` mode. The P9 leftover commit follows that decision.
- req-012 prints the `{archive-dir}` this requirement leaves out of the P8 check.
- 0000032 req-001 owns the P9 marker step and its staging of `{archive-dir}`.
