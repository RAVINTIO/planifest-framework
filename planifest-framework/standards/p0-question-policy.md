---
title: "P0 Question Policy"
version: "1.0.0"
---
# P0 Question Policy

P0 asks the human on the loop only real forks. Every derivable item goes into the design draft, and the human confirms it once with the design. The orchestrator's `### How you coach` section links here (0000033-ADR-007).

---

## Real forks

A **real fork** is a question whose answer needs the human's judgement or changes what gets built. These are real forks:

- scope, including backlog pickup and the release fill
- data rules
- any choice with a trade-off to weigh

`0000014-ADR-008` still governs every real fork. P0 asks them one at a time, with recommend-then-confirm.

## Derivable items

The orchestrator works these out from the brief, the repo, and discovery. Each goes into the design draft as a recommendation, and the human confirms it once with the design:

- adoption mode
- version
- stack, when unchanged
- NFR targets
- risks
- the component split
- the feature ID

A derivable item never gets its own question, unless an exception below applies.

## Exceptions that still ask first

These still ask with their own prompt, before the design draft:

- A conflict warning (Adoption Modes, Conflict Warnings) asks with its own prompt.
- The version hard block still refuses a version that is lower than the last known version. It also applies when the human edits the version in the design draft. Its message stays: `{proposed} is lower than the last known version ({current})`.
- External Anchor, or a `product.yml` with `versionPolicy: external`, still asks the human for the version.
- The step 3b declared product id hard stop still asks for the id.

## Combined confirmation turn

The **combined confirmation turn** is one message that presents three things:

1. the design draft, with every derivable item in it
2. the four Scope Lock drafts
3. the run-mode choice, where each option names who acts

The human answers all three in one reply.

- Each Scope Lock item keeps its separate, explicit accept / edit / reject. No blanket confirmation covers them.
- If the human edits a derived item, the orchestrator updates the draft and confirms only that change.
- If a Scope Lock answer raises a clarifying question, the orchestrator asks it after the combined turn, one at a time.

This turn is the second named exception to `0000014-ADR-008`, next to the Scope Lock batch (0000025-ADR-003).

## Question count

Each message to the human that waits for an answer counts as one question. The combined confirmation turn counts as one. The count covers all of P0, from the pre-flight check to design confirmation.

At design confirmation, the orchestrator appends three lines to the P0 build-log block:

```
P0 questions asked: {n}
Brief complete: yes|no
Stack unchanged: yes|no
```

The P8 build report flags a count above 3 only when `Brief complete` and `Stack unchanged` both read `yes` (NFR-002).
