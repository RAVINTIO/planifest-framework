---
title: "ADR 007: P0 real forks and one confirmation turn"
summary: "P0 asks only real forks. Derivable items go into the design draft, and the design, the Scope Lock batch, and the run mode confirm in one turn. That turn is a second named exception to 0000014-ADR-008. P0 records its question count and samples existing records the design depends on."
status: "accepted"
version: "0.1.0"
---
# ADR-007 - P0 real forks and one confirmation turn

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Component:** planifest-framework
**Date:** 2026-10-19

## Context

0000014-ADR-008 makes one question at a time, with recommend-then-confirm, a framework-wide rule. P0 applies it to every item, including items the agent can derive alone. Adoption mode, version, stack, NFR targets, risks, the component split, and the feature ID each get their own exchange today.

Backlog 0000076 reports that P0 asks too many questions. Downstream, `ovelunor` wrote a `p0-ask-only-real-forks.md` override to work around it.

0000025-ADR-003 already made one narrow exception to 0000014-ADR-008. It batches the four Scope Lock drafts into one turn, with a separate accept, edit, or reject per item. The run-mode question and the design confirmation still come as separate turns.

Backlog 0000101 adds a related gap. A design can depend on existing records, such as a log, a table, or a config history. Today nobody checks how often the value it relies on is usable until P3 or P4.

P1 left two gaps. D-005 asked how the combined turn relates to 0000014-ADR-008. D-008 asked when the P8 report flags a high question count.

## Decision

- **Real forks only:** P0 asks only real forks. A real fork is a question whose answer needs the human's judgement or changes what gets built. Scope, data rules, and trade-off choices are real forks. P0 asks them one at a time, with recommend-then-confirm, under 0000014-ADR-008.
- **Derivable items:** These seven items go into the design draft as recommendations:
  - adoption mode
  - version
  - stack, when unchanged
  - NFR targets
  - risks
  - the component split
  - the feature ID
- **Exceptions that still ask first:**
  - A conflict warning asks with its own prompt.
  - The version hard block (0000014-ADR-005) still refuses a lower version, including one the human types into the design draft.
  - External Anchor, or `versionPolicy: external`, still asks for the version.
  - The declared product ID hard stop still asks for the ID.
- **Combined confirmation turn (D-005):** One message presents the design draft, the four Scope Lock drafts, and the run-mode choice. The human answers all three in one reply.
  - Each Scope Lock item keeps its separate, explicit accept, edit, or reject. No blanket confirmation covers them.
  - If the human edits a derived item, the orchestrator updates the draft and confirms only that change.
  - Each run-mode option names who acts (req-007).
  - This turn is the second named exception to 0000014-ADR-008, next to 0000025-ADR-003. 0000014-ADR-008 governs every other question.
- **Question count (D-008):** Each message that waits for an answer counts as one question. The combined turn counts as one. At design confirmation, P0 writes three build-log lines:
  - `P0 questions asked: {n}`
  - `Brief complete: yes|no`
  - `Stack unchanged: yes|no`
- The P8 report flags a count above 3 only when both of the last two lines read `yes`.
- **Record sampling:** If the design depends on existing records, discovery samples recent rows of each source. It writes a `## Record Samples` table with the usable rate of each value. The sample is read-only. Each row becomes a design assumption with its impact if wrong. A design that reads no records writes `None`.
- **Where the detail lives:** `standards/p0-question-policy.md` holds the policy, and the orchestrator links to it (ADR-001).

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep one question per item (status quo) | No change to 0000014-ADR-008 | P0 keeps asking about items the agent can derive, and products keep writing overrides | Backlog 0000076 names this as the defect |
| Batch every P0 question into one turn | Fewest turns | Coaching questions depend on earlier answers, so a batch asks the wrong follow-ups | Real forks still need one at a time |
| Keep the design, Scope Lock, and run-mode confirmations as three turns | Each confirmation stays separate | Two extra turns that hold no new judgement | The three answers don't depend on each other |
| Confirm the whole combined turn with one "yes" | One word from the human | Breaks 0000025-ADR-003's per-item Scope Lock rule | Per-item accept, edit, or reject must stay |
| Flag any count above 3 at P8 | One fixed threshold | Flags runs where an incomplete brief or a stack change makes the extra questions real forks | D-008 ties the flag to the NFR-002 case |
| Leave record sampling to P3 or P4 | No P0 work | A low usable rate surfaces after the design is confirmed | The rate is a derivable fact, so P0 finds it |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | A new `standards/p0-question-policy.md`. The orchestrator rewrites `### How you coach`, steps 3a and 3d, and the version text. It also rewrites the end-of-P0 turn, the Scope Lock scope note, the P0 audit trail, and the gate checklist. The build-log, discovery, and design templates and the build assessment skill gain new lines. New suites cover req-008 and req-009. |

## Consequences

**Positive:**
- A complete brief with an unchanged stack reaches design confirmation in about three questions (NFR-002).
- The human on the loop sees every derived item once, in context, with the design.
- The P8 report shows whether P0 kept to its question budget.
- A design that relies on existing records states the usable rate before anyone builds on it.

**Negative:**
- The combined turn is long. The human on the loop must read the design, four drafts, and a run-mode choice at once.
- A wrong derived item is easier to miss inside a full design draft than in its own question.
- 0000014-ADR-008 now has two named exceptions, so readers must check both before applying it.

**Risks:**
- A reader could treat the combined turn as one blanket approval. The req-008 suite asserts that "separate, explicit accept / edit / reject" and "No blanket or implied confirmation" stay in the Scope Lock text.
- The agent could class a real fork as derivable and skip a question the human needed. The design draft still shows the choice, and the human can edit it.
- A sample of recent rows can miss older rows with a different shape. The design names the window as part of the assumption.

## Related ADRs

- ADR-001 - depends-on. New detail goes into standards files.
- ADR-002 - depends-on. It defines the run-mode options the combined turn presents.
- ADR-008 - related-to. The release-budget fill stays a real fork and counts as one question.
- 0000025-ADR-003 (Scope Lock batch) - related-to. It is the first named exception to 0000014-ADR-008.
- 0000014-ADR-005 (version regression hard block) - related-to. It still applies.
- 0000014-ADR-009 (incremental P0 audit trail) - related-to. The new lines join that trail.
- 0000017-ADR-004 (structured discovery pass) - extends. `## Record Samples` adds one section to `discovery.md`.

## Supersedes

- Amends 0000014-ADR-008 (one question at a time). The combined confirmation turn becomes its second named exception. Derivable items no longer get their own question. The rule still governs every real fork.

## Superseded By

- None
