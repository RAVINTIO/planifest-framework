---
title: "ADR 011: Split step before a fourth criterion"
summary: "The spec agent, the design critic, and the loop runner's fix rule each carry a split step. It fires before a requirement gains a fourth acceptance criterion and asks whether the requirement holds two concerns. Under an active loop, a split only adds files and lines, and any move of an existing criterion waits."
status: "accepted"
version: "0.1.0"
---
# ADR-011 - Split step before a fourth criterion

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

This ADR serves [req-007](../requirements/req-007-story-split-step.md) (US-007, backlog 0000139).

0000035 ADR 012 raised the criteria limit in `consistency-check.mjs` to 10, with a warning from 4. It left the missing split step to backlog 0000139. Only `templates/feature-brief.template.md` asks for a split, and only at P0. The check's warning arrives after a requirement is already packed.

A split moves criteria between files. `hooks/enforcement/ratchet-check.mjs` guards each criterion line in `plan/current/` while any loop-state file holds `status: active`. It compares one file at a time, so a criterion moved to another file counts as removed. The write exits 2.

Most splits happen inside a loop, because critic findings at P1 and P2 add criteria. 0000035 hit this. A fold back to three criteria needed a `.ratchet-approve` line from the human on the loop.

0000016 ADR 004 made `.ratchet-approve` the only way past the ratchet. 0000017 ADR 001 lets an agent write it only on explicit, in-the-moment instruction from the human on the loop. No agent writes it on its own initiative.

## Decision

- **Trigger:** The step fires before an agent adds a fourth acceptance criterion to a requirement. It also fires when an agent finds a requirement that already holds four or more.
- **Question:** The step asks one question: "Does this requirement hold two concerns?" A concern is one observable outcome that a reader could ship on its own.
- **Yes, split by addition only:** The new concern's criteria go into a new requirement file with the next free ID. The fourth criterion goes there, not into the existing file. A new user story in the feature brief backs it and adds no scope. The agent never moves or removes an existing criterion line during the split.
- **Design record:** A split after P0 is a deviation. The agent logs it, and the orchestrator updates the `design.md` story list as an additive change.
- **Deferred moves:** If an existing criterion belongs to the new concern, it stays in place. Both files carry a cross-reference, and the move becomes a follow-up. The move waits until no loop-state file holds `status: active`, or until the human on the loop supplies the `.ratchet-approve` line under 0000017 ADR 001.
- **`autonomous`:** The agent answers the question itself under the autonomous decision rule. It logs each deferred move as a build-log `Decision` line, and the gate summary lists it. Nobody gives an in-the-moment instruction, so no approve line gets written, and the move waits for the loop to end.
- **No, keep one requirement:** The agent records a one-line reason in two places. One is a build-log `Decision` line. The other is a `Split step: keep` note in the requirement file.
- **Where the step lives:** The spec agent's functional requirements rules, a new design critic rubric row, and a loop runner rule beside the Iteration Cycle for any fix unit. Each starts with the marker `Split step:`.
- **Critic row:** A requirement with more than three criteria fails the row unless a recorded keep answer names one concern. A recorded deferred move passes the row while a loop is active.
- **Check unchanged:** `consistency-check.mjs` keeps its warning from 4 and its fail above 10.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Split by moving criteria straight away | Each file holds only its own criteria at once | Under an active loop every move exits 2. Each split would stall the fix loop until the human on the loop writes an approve line. | It stalls fix loops, which is the friction 0000035 hit |
| Let the agent write `.ratchet-approve` for its own split | No stall and no deferred moves | It reopens the forgery risk that 0000016 ADR 004 closed. 0000017 ADR 001 allows an agent write only on explicit instruction. | An agent can't approve its own weakening |
| Teach `ratchet-check.mjs` to see a move across files as no removal | Moves pass with no human step | The hook would need to match criterion text across files. A reworded criterion could then vanish under cover of a move. | It weakens the ratchet and adds parsing risk to a hook that must stay small |
| Rely on the `consistency-check.mjs` warning alone | No skill text to add | The warning comes after the requirement is packed. It never asks the question, so agents fold criteria into sub-bullets instead. | 0000035 ADR 012 already showed the warning alone doesn't prompt a split |
| Lower the hard limit back to 3 | Forces a split | It revives the fold-to-pass pattern that 0000035 ADR 012 removed | The human on the loop chose 10 with a warning in 0000035 |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `skills/planifest-spec-agent/SKILL.md`, `skills/planifest-design-critic/SKILL.md`, and `skills/planifest-loop-runner/SKILL.md` each gain a `Split step:` paragraph or row. A new suite, `test-0000036-req-007-story-split-step.sh`, checks the three skills and runs `ratchet-check.mjs` on a split write and a move write. |

## Consequences

**Positive:**
- A packed requirement meets the question before it grows, not after the check warns.
- A split never stalls a fix loop, because the ratchet passes additions.
- A keep answer leaves a record that a fresh-context critic can find without the spec agent's context.

**Negative:**
- After a split with a deferred move, a criterion sits in the wrong file until the loop ends. P3 can build against a requirement whose criteria list is out of date, guided only by a cross-reference.
- In `autonomous`, deferred moves can pile up over a run. Nobody clears them until the human on the loop reads the gate summaries or the loop ends.
- Each split adds a requirement and a story mid-run. The design story count drifts from what the human on the loop confirmed at P0, and each change costs a design update.

**Risks:**
- An agent answers "no" to dodge the work of a split. The critic row asks for a recorded keep reason, but a weak reason still passes.
- A deferred move is never done after the loop ends. The cross-reference keeps both files traceable, but the P7 archive could hold both copies of the concern.

## Related ADRs

- 0000035 ADR 012 (criteria limit and warning) - extends. It left the split step to backlog 0000139, which this ADR closes.
- 0000016 ADR 004 (ratchet approval marker) - depends-on. The ratchet is why a split adds and never moves.
- 0000017 ADR 001 (ratchet approve on explicit instruction) - depends-on. It sets who may write the approve line that releases a deferred move.

## Supersedes

- None

## Superseded By

- None
