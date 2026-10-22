---
title: "Requirement: req-007 - story-split-step"
summary: "The spec agent, the design critic rubric, and the loop runner's fix step each carry a split step. Before a requirement reaches a fourth acceptance criterion, the step asks whether it holds two concerns, and a yes splits it into a new requirement and story."
status: "draft"
version: "0.1.0"
---
# Requirement: req-007 - story-split-step

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Source:** US-007 (backlog 0000139)
**Priority:** should-have

## User Story

> One requirement doc = one user story.

As the human on the loop, I see an agent ask whether a requirement holds two concerns before it grows past three criteria, so that a requirement is split rather than packed.

## Functional Requirements

### The problem

- Only `planifest-framework/templates/feature-brief.template.md:27` asks for a split above three criteria. It acts at P0, when the brief is written.
- `planifest-framework/scripts/consistency-check.mjs:65-72` warns at 4 to 10 criteria and fails above 10. The warning arrives after the requirement is already packed.
- The spec agent, the design critic, and the loop runner carry no split step. A requirement can grow to ten criteria with no prompt to split it.

### The split step

- The step fires before an agent adds a fourth acceptance criterion to a requirement. It also fires when an agent finds a requirement that already holds four or more.
- The step asks one question: "Does this requirement hold two concerns?" A concern is one observable outcome that a reader could ship on its own.
- If the answer is yes, the agent splits the requirement:
  - The second concern moves to a new requirement file with the next free requirement ID.
  - A new user story in the feature brief backs the new requirement. It splits the existing story and adds no new scope.
  - Each criterion moves with its concern, so neither file passes three criteria.
- If the answer is no, the agent keeps one requirement and records a one-line reason.
- The agent reports each answer, split or keep, with its reason. The orchestrator carries the answers into the gate summary, so the human on the loop sees each one.
- In `autonomous`, the agent answers the question itself under the decision rule in `standards/autonomous-run-standards.md`.

### Where the step lives

- `planifest-framework/skills/planifest-spec-agent/SKILL.md`: a split step under the functional requirements rules.
- `planifest-framework/skills/planifest-design-critic/SKILL.md`: a new rubric row in Step 2. A requirement with more than three criteria fails the row unless the spec agent's recorded answer names one concern.
- `planifest-framework/skills/planifest-loop-runner/SKILL.md`: the loop runner has no separate fix-dispatch section. The step goes beside the Iteration Cycle, as a rule for any ACT unit that is a fix. Before a fix adds a fourth criterion to a requirement, the fix runs the split step.
- Each of the three skills uses the same marker, `Split step:`, at the start of the step's paragraph or table cell. The suite finds the step by that marker.
- `consistency-check.mjs` keeps its 4 to 10 warning and its fail above 10. This requirement doesn't change the script.

### Suite

- A new suite, `planifest-framework/tests/test-0000036-req-007-story-split-step.sh`, reads the three skill files.
- For each file, it asserts one `Split step:` marker, the fourth-criterion trigger, and the two-concerns question.

## Acceptance Criteria

- [ ] The spec agent, the design critic rubric, and the loop runner's fix step each carry a split step. Before a requirement reaches a fourth criterion, the step asks whether it holds two concerns, and a yes splits it into a new requirement and story.
- [ ] The new suite fails when any of the three skills lacks the `Split step:` marker, the fourth-criterion trigger, or the two-concerns question.

## Dependencies

- `planifest-framework/templates/feature-brief.template.md:27` keeps its P0 rule. This requirement adds the same check at P1, P2, and in fix loops.
- [req-005](req-005-hard-limits-cited-by-name.md) edits the spec agent's Commit Cadence heading. [req-006](req-006-design-critic-default.md) edits the loop runner skill. The orchestrator orders those edits.
- No dependency on req-001 to req-004 or req-008 to req-011.
