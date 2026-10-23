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
- If the answer is yes, the agent splits the requirement by addition only:
  - The agent writes the new concern's criteria into a new requirement file with the next free requirement ID. The fourth criterion goes there, not into the existing file.
  - A new user story in the feature brief backs the new requirement. It splits the existing story and adds no new scope. The agent adds the new story's criteria to the brief and leaves the existing story's criteria lines as they are.
  - A split after P0 changes the confirmed design's story list. The agent records it as `Deviation (P{N}, unclassified): split req-NNN into req-MMM`. The orchestrator then updates the `design.md` story list and criteria count, under the mid-pipeline requirement change protocol as an additive change.
  - The agent never moves or removes an existing acceptance-criteria line during the split.
- If an existing criterion belongs to the new concern, the agent leaves it in place for now:
  - It adds a cross-reference in both files. The existing file names the new requirement beside that criterion's concern. The new file names the criterion it will receive.
  - It records the move as a follow-up. The move happens later, under the rules in "Splitting while a loop is active".
- If the answer is no, the agent keeps one requirement and records a one-line reason in two places:
  - a build-log line in the active phase block, in this format: `Decision (P{N}): split step for req-NNN: keep / reason: {one line}`
  - a `Split step: keep` note in the requirement file, under Functional Requirements, with the same reason
- A fresh-context design critic reads both places. It finds the keep answer without the spec agent's context.
- The agent reports each answer, split or keep, with its reason. The orchestrator carries the answers into the gate summary, so the human on the loop sees each one.
- In `autonomous`, the agent answers the question itself under the decision rule in `standards/autonomous-run-standards.md`.

### Splitting while a loop is active

- `planifest-framework/hooks/enforcement/ratchet-check.mjs` guards each `- [ ]` line under `## Acceptance Criteria` in a `plan/current/` Markdown file. It does so while any `plan/current/loop-state-*.md` file holds `status: active`.
- The hook compares one file at a time (`ratchet-check.mjs:238-248`). A criterion moved to another file therefore counts as removed, and the write exits 2.
- Only a `plan/current/.ratchet-approve` line lets such a removal through. An agent never writes the marker on its own initiative. It writes the line only when the human on the loop gives an explicit instruction in the moment, as 0000017 ADR 001 and ADR-011 allow. In `autonomous`, no one gives that instruction, so every deferred move waits for the loop to end.
- The boot file forbids any agent write of the marker. Backlog 0000167 tracks that conflict with 0000017 ADR 001. The skills P3 writes state the rule above, and 0000167 settles the wider question.
- The step avoids the block because it fires before the agent writes the fourth criterion. A yes answer only adds files and lines, and the ratchet passes additions.
- A follow-up move of an existing criterion waits until one of these holds:
  - no loop-state file holds `status: active`
  - the human on the loop writes the `.ratchet-approve` line for that file
- In `autonomous`, the agent records each pending move as a build-log line in the active phase block: `Decision (P{N}): split step for req-NNN: move {criterion} to req-MMM deferred / reason: ratchet active`. The orchestrator lists pending moves in the gate summary.
- In `interactive` and `continuous`, the agent names the pending move to the human on the loop at the gate. The human on the loop either writes the approve line or leaves the move for after the loop.
- A split never stalls a fix loop. The new requirement stands on its own, and the cross-reference keeps both files traceable until the move happens.

### Where the step lives

- `planifest-framework/skills/planifest-spec-agent/SKILL.md`: a split step under the functional requirements rules.
- `planifest-framework/skills/planifest-design-critic/SKILL.md`: a new rubric row in Step 2. A requirement with more than three criteria fails the row unless a recorded keep answer names one concern. The critic looks for the `Split step: keep` note in the requirement file and the matching `Decision` line in the build log. A requirement with a recorded pending move passes the row while a loop is active.
- `planifest-framework/skills/planifest-loop-runner/SKILL.md`: the loop runner has no separate fix-dispatch section. The step goes beside the Iteration Cycle, as a rule for any ACT unit that is a fix. Before a fix adds a fourth criterion to a requirement, the fix runs the split step. The rule states that a split inside a loop only adds files and lines, and defers any move as "Splitting while a loop is active" says.
- Each of the three skills uses the same marker, `Split step:`, at the start of the step's paragraph or table cell. The suite finds the step by that marker.
- `consistency-check.mjs` keeps its 4 to 10 warning and its fail above 10. This requirement doesn't change the script.

### Suite

- A new suite, `planifest-framework/tests/test-0000036-req-007-story-split-step.sh`, reads the three skill files.
- For each file, it asserts one `Split step:` marker, the fourth-criterion trigger, and the two-concerns question.
- It asserts that the spec agent and loop runner text holds these items:
  - the rule that a split never moves or removes an existing criterion while a loop is active
  - the `.ratchet-approve` condition for a deferred move
  - the keep-answer build-log format, `split step for req-NNN: keep`
- It asserts that the design critic row names the `Split step: keep` note and the build log as the places to look.
- A ratchet case builds a fixture with an active loop-state file and a requirement that holds three criteria. It runs `ratchet-check.mjs` on two writes:
  - a write that adds a new requirement file with one criterion: exit 0
  - a write that removes a criterion from the existing file: exit 2
- That case shows the split route passes the hook and a move doesn't.

## Acceptance Criteria

- [ ] The spec agent, the design critic rubric, and the loop runner's fix step each carry a split step. Before a requirement reaches a fourth criterion, the step asks whether it holds two concerns, and a yes splits it into a new requirement and story.
- [ ] The new suite fails when any of the three skills lacks the `Split step:` marker, the fourth-criterion trigger, or the two-concerns question.

## Dependencies

- `planifest-framework/templates/feature-brief.template.md:27` keeps its P0 rule. This requirement adds the same check at P1, P2, and in fix loops.
- [req-005](req-005-hard-limits-cited-by-name.md) edits the spec agent's Commit Cadence heading. [req-006](req-006-design-critic-default.md) edits the loop runner skill. The orchestrator orders those edits.
- No dependency on req-001 to req-004 or req-008 to req-011.
