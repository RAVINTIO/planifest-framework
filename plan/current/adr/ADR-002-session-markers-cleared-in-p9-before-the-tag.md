---
title: "ADR 002: Session markers cleared in P9 before the tag"
summary: "The session markers stay committed and owned by planifest-framework. The ship skill deletes and commits them with the archive after P8 and before the Step 9 tag. Resume Detection step 2a resumes an interrupted close-out from archive evidence."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - Session markers cleared in P9 before the tag

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Component:** planifest-framework
**Date:** 2026-10-17

## Context

Three session markers track a run:

- `plan/.orchestrator-active`
- `plan/.orchestrator-ack`
- `plan/.run-mode`

0000023 req-002 made them committed files. A run can therefore resume from another clone, and the P9 check catches a marker left on a branch.

Today the ship skill deletes all three in P7 Step 6, before P8 and P9 run. From that point nothing marks the run as active. In backlog 0000077, a downstream run lost governance at P7 and took new work after P9 with no triage. The auto-trigger hook also told the agent the orchestrator wasn't loaded, which was false.

0000015 ADR-001 reads "sentinel present and `plan/current/` empty" as an interrupted P9. It then deletes the markers and starts fresh. Once the markers survive P7, that same signal means P8 or P9 hasn't finished. Starting fresh would skip the build report, the tag, and the push decision.

0000015 ADR-004 gives P9 ownership of `.run-mode` deletion, but places the deletion in ship Step 6.

At P0 the human on the loop chose to keep the markers committed and delete them before the tag. The build log records this under "P0 exchange (sentinel timing)".

## Decision

- **Ownership:** `planifest-framework` owns all three markers. The orchestrator skill writes them at P0 and commits them. The ship skill deletes them. Hooks read them only. No other component writes to them.
- **Committed:** The markers stay tracked in git, as 0000023 req-002 requires.
- **Deletion point:** P7 Step 6 no longer touches a marker. A new P9 step, "Clear session markers", runs after P8 and before `Step 9: Create git tag`. It does these things in order:
  1. Deletes the three markers.
  2. Stages the deletions together with the archive directory, so the P8 `build-report.md` and the P8 and P9 build-log blocks land in the same commit.
  3. Commits with the subject `plan(p9): clear session markers for {feature-id}`.
  4. Runs `git ls-files` on the three paths. If any path is still tracked, it stops and names the path to the human on the loop. It doesn't tag.
- **Tag and push:** The Step 9 tag runs only after that commit, so the tag never carries a marker. Push and PR stay optional, per project settings and the human's choice. Step 9b goes, because its check moves into the marker step.
- **Resume Detection step 2a:** The trigger stays "sentinel present and `plan/current/` empty". The step then does these things:
  1. Reads the feature ID from `plan/.orchestrator-active`.
  2. Picks the last `plan/_archive/{feature-id}-*` directory in lexical order.
  3. If that directory has no `build-report.md`, it resumes at P8.
  4. If it has one, it resumes at the P9 marker step.
  5. If no directory matches, or the sentinel holds `pending`, it stops and asks the human on the loop. It deletes no marker.
- Step 2a never deletes markers on its own and never starts fresh.
- **Refinements after the P5 security review:**
  - K-1: Step 2a checks the sentinel ID against `^[0-9]{7}-[a-z0-9-]+$` before use. A `pending` or other non-matching ID stops and asks the human on the loop. Step 2a confirms the chosen directory sits inside `plan/_archive/` and quotes the ID in every shell command.
  - K-2: The marker step runs `git status --porcelain plan/_archive/` first. It reports changes outside this feature's archive directory to the human on the loop and stages only `plan/_archive/{feature-id}-{YYYY-MM-DD}/`.
  - K-3: The marker step stages the archive first. It then deletes the markers, stages the deletions, and commits as one uninterrupted sequence. A new Resume Detection step 2b catches a sentinel that is absent on disk but still committed. It finishes the marker commit and continues to the Step 9 tag.
  - K-4: If nothing is staged and no marker is tracked, the marker step skips the commit and continues to the tag.
- **Refinements after the P5 re-review:**
  - K-2: The marker step works on `{archive-dir}`, the directory P7 Step 6 created or step 2a resolved, so a `-2` suffix carries through. The commit names `{archive-dir}` and the markers that `HEAD` tracks after `--`. Changes staged earlier stay out of it. The K-4 guard checks only those paths, so the step skips the commit when nothing is staged under them.
  - N-8: Step 2b applies step 2a's archive rule. A sentinel that a human on the loop deleted by hand before P8 therefore resumes at P8, not at the tag. With no matching archive, step 2b stops and asks the human on the loop.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Gitignore the markers and delete them after Step 11 | The sentinel covers the whole of P9, including the Step 11 confirmation | Reverses 0000023 req-002, so a run can't resume from another clone | The human on the loop rejected it at P0 |
| Keep committed markers and delete them after Step 11, with a second push | The sentinel covers the Step 11 confirmation | The tag carries the markers, and a second push is needed on every run. Projects that don't push can't clear the branch. | Ties marker cleanup to an optional push |
| Keep deletion in P7 Step 6 and change only the hook message | Smallest change | P8 and P9 still run with no active-run marker | Doesn't fix backlog 0000077 |
| Keep 0000015 ADR-001's clean-up-and-start-fresh response | No change to step 2a | An interrupted P8 or P9 would lose its build report, tag, or push decision | Wrong once markers survive P7 |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | The ship skill moves marker deletion from P7 Step 6 into a P9 step before the tag and drops Step 9b. The orchestrator skill rewrites Resume Detection step 2a. Two existing suites change, and a new suite covers both skills. |

## Consequences

**Positive:**
- Hooks treat P8 and P9 as part of the run, so the auto-trigger hook no longer fires during close-out.
- The tag, and any later push, never carry a marker.
- An interrupted close-out resumes where it stopped, from evidence in the archive.
- A run can still resume from another clone.

**Negative:**
- The sentinel is gone during Step 11 and Step 12. Those steps rely on ADR-003's blocking context clear, not on a hook.
- Step 2a now depends on the archive naming pattern. A renamed archive directory sends it to the stop-and-ask branch.

**Risks:**
- A downstream run already past P7 under the old skill has no markers to read. If one is mid-close-out when it upgrades, step 2a finds no match and stops to ask.
- If the marker commit fails after the deletions, the working tree holds deleted markers that aren't committed. The `git ls-files` check stops the tag in that case. Resume Detection step 2b finishes that commit in the next session.

## Related ADRs

- 0000023 req-002 (markers stay committed) - depends-on
- 0000015 ADR-003 (stale run-mode warn-and-clear) - related-to. It stays the P0 recovery path.
- ADR-001 - related-to
- ADR-003 - related-to. It relies on the sentinel's absence after P9.

## Supersedes

- 0000015 ADR-001 (interrupted P9 detection signal). The signal stays, but it now means "resume P8 or P9 from archive evidence", not "clean up and start fresh".
- Amends 0000015 ADR-004 (run-mode deletion owned by P9). P9 still owns the deletion, but it moves from ship Step 6 into the P9 marker step.

## Superseded By

- None
