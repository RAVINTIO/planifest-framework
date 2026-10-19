---
title: "ADR 011: Close-out commit and leftovers"
summary: "The P8 build report reaches git in the 0000032 P9 marker-step commit, which becomes the run's closing archive commit. P8 and P9 each end with a scoped clean-tree check. Leftovers are committed by explicit path in autonomous mode, or listed at the P9 gate otherwise."
status: "accepted"
version: "0.1.0"
---
# ADR-011 - Close-out commit and leftovers

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Component:** planifest-framework
**Date:** 2026-10-19

## Context

Backlog 0000073 reports two close-out gaps:

- The P8 `build-report.md` can sit uncommitted after a run ends.
- Agents in P8 and P9 can leave files changed in `plan/`, `docs/`, or component `docs/` folders, with nobody told.

An `autonomous` run (ADR-002) must finish without the human on the loop. A dirty tree at the end of such a run is a silent failure.

0000032-ADR-002 already defines a P9 marker step. It stages `{archive-dir}`, deletes the three session markers, and commits before the Step 9 tag. Resume Detection step 2a checks whether `build-report.md` exists in the archive to choose between a P8 and a P9 resume. Moving the P7 commit after P8 would break that signal.

The design's clean close-out row left two points open. P1 settled them in continuous mode as D-010 and D-011:

- D-010: the P8 report lands in the 0000032 marker-step commit.
- D-011: outside `autonomous`, the P9 gate summary lists leftovers and asks there whether to commit them.

req-013 holds the detail.

## Decision

- **Closing commit:** The 0000032 P9 marker-step commit is the run's closing archive commit. It carries the P8 `build-report.md` and the P8 and P9 build-log blocks. The P7 to P9 order stays as 0000032-ADR-002 set it.
- **Report guard:** After the marker step stages `{archive-dir}`, it checks that `{archive-dir}/build-report.md` is staged or tracked by `HEAD`. If it is neither, the step stops and resumes at P8. It never commits the marker deletions without the report.
- **Clean-tree check:** A step headed `Clean-tree check` ends P8, after `P8: Complete`. Another sits between Step 10 and Step 11 in P9. Both run this command:

  ```bash
  git status --porcelain -- plan/ docs/ ':(glob)src/**/docs/**'
  ```

  The P8 check leaves out paths under `{archive-dir}`, because the marker step commits them. The P9 check leaves out nothing, so it catches the Step 10 changelog edit and any Step 9 `product.yml` change.
- **Run-mode source:** Both checks read the `Run mode` row in `{archive-dir}/build-log.md` (D-009). They never read `plan/.run-mode`, because the marker step deletes it.
- **Leftovers in `autonomous`:** The agent stages each leftover by explicit path. It commits with the subject `plan(p8): commit close-out leftovers` or `plan(p9): commit close-out leftovers`, with the paths named after `--`. If P9 pushed the branch (ADR-006), the agent pushes this commit too.
- **Leftovers in other modes:** The agent carries P8 and P9 leftovers into the Step 11 gate summary. It lists each path with the step or subagent that wrote it, where known. It asks there whether to commit and push them. The P9 gate already stops in `interactive` and `continuous`, so no new stop appears. The human on the loop may decline.
- **Clean result:** If nothing is left over, the phase logs `Clean-tree check: clean`. Step 11 reports one line: `clean`, `committed {n} files`, or `{n} files listed below`.
- **No glob stage:** Neither check runs `git add -A`, `git add .`, or `rm`. Changes outside `plan/`, `docs/`, and `src/**/docs/` stay out of scope, as backlog 0000073 states.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Move the P7 archive commit after P8 | One commit carries the archive and the report | Resume Detection step 2a loses its P8 or P9 signal, since the report would exist only after the commit | Breaks 0000032-ADR-002's resume rule |
| A separate commit for the P8 report | Clear history line for the report | Adds a commit that the marker step makes anyway, and adds a resume point between them | The marker-step commit already stages `{archive-dir}` (D-010) |
| A new stop after P8 to ask about leftovers outside `autonomous` | The human on the loop sees P8 leftovers sooner | Adds a stop point in `interactive` and `continuous`, against NFR-003 | D-011 uses the P9 gate, which already stops |
| Commit leftovers with `git add -A` | Catches every change | Stages unrelated work and secrets outside the run's scope | Breaks the explicit-path rule that 0000032-ADR-002 set for staging |
| Check the whole tree, not scoped paths | Nothing escapes the check | Reports a product's unrelated `src/` edits as run leftovers | Backlog 0000073 scopes the check to run-written paths |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | The ship skill gains the report guard in the P9 marker step, two `Clean-tree check` steps, and a Step 11 result line. The orchestrator's `## Phase 9 - Ship` section names the P9 check. A new suite covers req-013. |

## Consequences

**Positive:**
- The P8 report always reaches git before the tag.
- An `autonomous` run ends with a clean scoped tree and needs no human step.
- Outside `autonomous`, the human on the loop sees every leftover at a gate that already exists.
- Resume Detection keeps its archive-evidence rule unchanged.

**Negative:**
- The ship skill grows by two steps and one guard.
- In `autonomous`, P8 and P9 may each add a leftover commit, so history gains up to two small commits per run.
- The checks depend on the `Run mode` row. A build log from an older framework has no such row and reads as not `autonomous`.

**Risks:**
- A subagent might write a leftover under `{archive-dir}` after the marker-step commit. The P9 check catches it, because it leaves out nothing.
- An `autonomous` run could commit a leftover a human would have dropped. The scope limit keeps such files to `plan/` and docs paths, and the final report lists the commit.
- If the leftover commit fails, the tag already exists. Step 11 then reports the files as listed, not committed.

## Related ADRs

- 0000032-ADR-002 (session markers cleared in P9 before the tag) - extends. This ADR makes its marker-step commit the closing archive commit and adds the report guard.
- ADR-002 - depends-on. It defines `autonomous` and the build-log `Run mode` row.
- ADR-006 - depends-on. It decides whether P9 pushes in `autonomous`.
- ADR-010 - related-to. It prints the `{archive-dir}` the P8 check leaves out.

## Supersedes

- None. Amends 0000032-ADR-002 by adding a report guard and two clean-tree checks around its marker step. Its order and staging rules stay.

## Superseded By

- None
