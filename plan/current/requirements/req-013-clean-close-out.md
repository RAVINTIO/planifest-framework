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

This section applies decision D-010. The P8 build report reaches git in the P9 marker-step commit, which is the run's closing archive commit.

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
- **Reading the run mode:** Read the `Run mode` row in the Header table of `{archive-dir}/build-log.md`. req-006 owns that row. Never read `plan/.run-mode` here, because the P9 marker step deletes it. req-001 defines the `autonomous` value.
- **Leftovers in `autonomous` mode:** Stage each leftover by its explicit path. Commit with the subject `plan(p8): commit close-out leftovers` or `plan(p9): commit close-out leftovers` to match the phase. Put the feature ID in the commit body. The commit names its paths after `--`. If req-005 pushed the branch, push this commit too.
- **Leftovers in other modes:** Carry the P8 and P9 leftovers into the P9 gate summary in Step 11. List each path with the step or sub-agent that wrote it, where known. Ask there whether to commit and push them. The P9 gate already stops in `interactive` and `continuous`, so this adds no new stop. The human on the loop may decline. Never leave a leftover unreported.
- **No leftovers:** Log `Clean-tree check: clean` in the phase's build-log block and continue.
- **Step 11 (Confirm to human):** Add one line that reports the P9 clean-tree result: `clean`, `committed {n} files`, or `{n} files listed below`. Outside `autonomous`, the leftover list and the commit question follow that line.

The check doesn't run `git add -A`, `git add .`, or any glob stage. Untracked changes outside `plan/`, `docs/`, and `src/**/docs/` stay out of scope, as backlog 0000073 states.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`## Phase 9 - Ship`, "What P9 produces":** Add the P9 clean-tree check after the PR step.

### Tests

- A new Bash suite, `planifest-framework/tests/test-0000033-req-013-clean-close-out.sh`, covers this requirement through text assertions on the ship skill. It also runs the scoped `git status --porcelain` command in a temporary git repository and checks which paths it reports. `run-tests.sh` picks it up.
- This requirement edits no existing suite's assertions.
- `planifest-framework/tests/test-0000032-req-001-marker-clear-before-tag.sh` asserts the marker step. req-007 edits it as a listed exception. It must pass in its req-007 form.
- These suites assert nearby text and must pass unchanged:
  - `planifest-framework/tests/test-0000032-req-002-resume-from-archive-evidence.sh`
  - `planifest-framework/tests/test-0000006-build-assessment.sh`
  - `planifest-framework/tests/test-0000032-req-004-handover-note-routing.sh`

### Verified by

- The ship skill has a `Clean-tree check` heading under `## P8: Build Assessment` and another between `### Step 10` and `### Step 11`, checked by line number.
- Both checks name `git status --porcelain -- plan/ docs/ ':(glob)src/**/docs/**'`.
- The P8 check leaves out `{archive-dir}`. The P9 check leaves out nothing.
- Both checks read the `Run mode` row of `{archive-dir}/build-log.md` and don't name `plan/.run-mode` as a source.
- Both checks name `autonomous` and a commit with paths after `--`, with the subject `plan(p8): commit close-out leftovers` or `plan(p9): commit close-out leftovers`.
- Outside `autonomous`, Step 11 lists the leftovers and asks whether to commit and push them. No other new stop appears.
- Neither check contains `git add -A`, `git add .`, or `rm`.
- The P9 marker step checks for `build-report.md` before its `git commit` line, checked by line number.
- In a fixture repo, the scoped command reports `docs/a.md` and `src/x/docs/b.md`, and doesn't report `src/x/app.js`.
- Step 11 reports the clean-tree result.

### Security additions (P5)

- G5: The P8 and P9 clean-tree checks use `git status --porcelain --untracked-files=all` over the same scoped paths. In `autonomous`, before it commits leftovers, the ship agent refuses any `.env*`, `*.pem`, `*.key`, `id_rsa*`, or `*.p12` file. It also refuses any file whose content matches a credential pattern. Refused files stay uncommitted and become an exception item. The scope guard of `plan/`, `docs/`, and `src/**/docs/` stays. The change is in `planifest-ship-agent/SKILL.md`.

## Acceptance Criteria

- [ ] (feature AC 5) The P9 marker-step commit always carries `build-report.md`, and the P7 to P9 order stays as 0000032 set it.
- [ ] (feature AC 5) P8 and P9 each end with the scoped `git status --porcelain` check. In `autonomous` mode it commits leftovers by explicit path. In other modes the P9 gate summary lists them for the human on the loop.
- [ ] (feature AC 7) The new suite, the unchanged 0000032 req-002, 0000006, and handover-routing suites, and the req-007 form of the 0000032 req-001 suite pass under `run-tests.sh`.

## Dependencies

- req-001 defines the `autonomous` value. req-006 owns the build-log `Run mode` header row this requirement reads.
- Decision D-010 places the P8 build report in the P9 marker-step commit.
- req-005 decides whether P9 pushes in `autonomous` mode. The P9 leftover commit follows that decision.
- req-012 prints the `{archive-dir}` this requirement leaves out of the P8 check.
- 0000032 req-001 owns the P9 marker step and its staging of `{archive-dir}`.
- req-007 edits `test-0000032-req-001-marker-clear-before-tag.sh`.
