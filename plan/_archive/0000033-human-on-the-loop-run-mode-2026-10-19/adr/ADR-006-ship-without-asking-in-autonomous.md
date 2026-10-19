---
title: "ADR 006: Ship without asking in autonomous"
summary: "In autonomous mode P7 to P9 ask nothing. P9 always raises the PR, as a draft when an exception waits, and the run ends with one final report. Merging stays human-only, a local-git-only override still wins, and the framework adds no deploy step."
status: "accepted"
version: "0.1.0"
---
# ADR-006 - Ship without asking in autonomous

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Component:** planifest-framework
**Date:** 2026-10-19

## Context

The ship agent owns P7 to P9 (0000012-ADR-003). Today it stops for the human on the loop at several points:

- P7 always ends with a confirmation stop.
- P7 Step 4 asks the human to confirm each regression candidate (0000004-ADR-003).
- P9 Step 10 asks whether the agent pushes and raises the PR (0000012-ADR-004).
- P9 Step 11 sends a confirmation message.

In `autonomous` (ADR-002), the human on the loop chose at P0 to step back until the PR exists. Each of these stops would leave the run waiting at its last mile. req-005 asks for a close-out with no question and one final report.

Two gaps came up at P1. D-003 asked whether P9 raises the PR while an exception waits. D-004 asked about the backlog's deploy to a candidate environment.

## Decision

- **No question in P7 to P9:** In `autonomous`, P7 to P9 ask the human on the loop nothing. The ship agent reads the run mode from the build-log `Run mode` row (D-009), never from `plan/.run-mode`.
- **P7 gate:** The "always a confirmation stop" rule stays for `interactive` and `continuous`. In `autonomous`, P7 doesn't stop.
- **Regression candidates:** In `autonomous`, the agent decides each P7 Step 4 candidate and records the decision. It passes `agent` as the promoted-by argument to `promote-to-regression.sh`. The final report lists each candidate and its decision.
- **Push and PR (Step 10):** The `local-git-only` check runs first, as today, and the override still wins.
  - With no override, the agent skips the prompt and takes Option [1]. It pushes and raises the PR.
  - With the override, it takes Option [2] and puts the PR title and description in the final report.
- **Draft PR (D-003):** P9 always raises the PR. If any `Exception waiting` line exists in the build log, P9 raises it as a draft PR. The PR description lists each waiting exception.
- **After the PR:** The agent pushes each later commit straight away, unless the `local-git-only` override applies.
- **Final report:** In `autonomous`, one report replaces the Step 11 message. `standards/autonomous-run-standards.md` gives its six parts. The report is the only P7 to P9 output that addresses the human on the loop. It ends by saying that the human on the loop reviews and merges the PR. Step 12 still runs after it.
- **Merging:** No step in any mode runs `gh pr merge` or merges the PR another way.
- **No deploy step (D-004):** The framework adds no deploy to a candidate environment. A product adds one through an override, as `ovelunor` does today. Promotion beyond the candidate environment stays on the exception list (ADR-003).

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep the Step 10 push prompt in `autonomous` | No change to 0000012-ADR-004 | The run waits for the human at the last step, which breaks US-001 | `autonomous` exists to reach a raised PR with no gate waiting |
| Hold the PR until every waiting exception clears | The human never sees a PR with open questions | The run stops short of a PR, and the work sits on a branch no one reviews | D-003 chose a visible draft PR over a silent wait |
| Raise a ready PR and list exceptions only in the final report | One PR state to handle | A reviewer could merge a PR that still has an open exception | A draft PR blocks a merge until the human on the loop clears it |
| Add a framework deploy step to a candidate environment | Matches the backlog's suggested action | The framework has no deploy target, and each product deploys differently | D-004 leaves deploy to product overrides |
| Let `autonomous` merge when CI passes | Fully hands-off | Removes the last human check, against the design's merge constraint | Merging stays human-only in every mode |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | The ship skill changes P7 Step 4, Step 10, and Step 11 for `autonomous`. It also adds the after-PR push and draft-PR rules. The orchestrator's Phase 7 and Phase 9 text and `pipeline-reference.md` name `autonomous`. A new `## Final report` section goes into `standards/autonomous-run-standards.md`. A new suite covers req-005. |

## Consequences

**Positive:**
- An `autonomous` run reaches a raised PR with no stop after P0.
- The human on the loop reads one report that holds every decision, deviation, and waiting exception.
- A waiting exception shows on the PR itself, because the PR is a draft.
- A `local-git-only` repo keeps its behaviour, since the override still runs first.

**Negative:**
- The agent decides regression promotion with no human check in `autonomous`. A weak test can enter the regression pack.
- The ship agent now has three Step 10 paths to maintain and test: the prompt, the `autonomous` default, and the override.
- A product that wants a candidate deploy must still write and maintain its own override.

**Risks:**
- The build-log `Run mode` row may be missing or misread. The ship agent could then prompt in an `autonomous` run or skip a prompt in another mode. The req-005 suite asserts where the agent reads the mode.
- If an `Exception waiting` line is written in the wrong format, P9 raises a ready PR instead of a draft. The final report still lists the exception, so the human on the loop can catch it before merging.
- A push after the PR can fail on credentials in an unattended run. The final report must then name the commit that didn't reach the remote.

## Related ADRs

- ADR-002 - depends-on. It defines `autonomous` and the build-log `Run mode` row.
- ADR-003 - depends-on. It defines the exception list and the `Exception waiting` lines.
- ADR-011 - related-to. The clean-tree check feeds the final report.
- 0000012-ADR-003 (ship agent orchestrates P7 to P9) - related-to
- 0000025-ADR-001 (PR footer default-off) - related-to. The footer rule still applies to the raised PR.
- 0000032-ADR-003 (blocking context clear after P9) - related-to. Step 12 still runs after the final report.

## Supersedes

- Amends 0000012-ADR-004 (P9 human push/PR decision protocol). The protocol stays for `interactive` and `continuous`. In `autonomous`, the agent takes Option [1] without asking, unless `local-git-only` applies.
- Amends 0000004-ADR-003 (regression promotion criteria). Human confirmation stays for `interactive` and `continuous`. In `autonomous`, the agent decides and records each candidate.

## Superseded By

- None
