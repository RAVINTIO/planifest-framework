---
title: "Requirement: req-008 - p0-real-forks-only"
summary: "P0 asks only real forks, puts every derivable item into the design draft, confirms the design, the Scope Lock batch, and the run mode in one turn, and records its question count."
status: "draft"
version: "0.1.0"
---
# Requirement: req-008 - p0-real-forks-only

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-004
**Priority:** must-have

## User Story

As the human on the loop, I answer P0 questions only where the answer needs my judgement or changes what gets built, so that derivable items reach me once, in the design draft.

## Functional Requirements

### New standard (`planifest-framework/standards/p0-question-policy.md`)

The orchestrator skill is already 9,276 words, so the detail lives here and the skill links to it.

- Defines a **real fork**. A real fork is a question whose answer needs the human's judgement or changes what gets built. Scope, data rules, and any choice with a trade-off to weigh are real forks.
- Lists the **derivable items**. These go into the design draft as recommendations, and the human confirms them once with the design:
  - adoption mode
  - version
  - stack, when unchanged
  - NFR targets
  - risks
  - the component split
  - the feature ID
- States the exceptions that still ask on their own, before the design draft:
  - A conflict warning (Adoption Modes, Conflict Warnings) still asks with its own prompt.
  - The version hard block still refuses a version lower than the last known version. It applies when the human edits the version in the design draft too.
  - External Anchor, or a `product.yml` with `versionPolicy: external`, still asks the human for the version.
  - The 3b declared product id hard stop still asks for the id.
- States that `0000014-ADR-008` still governs every real fork that remains. P0 asks those one at a time, with recommend-then-confirm.
- Defines the **combined confirmation turn**. One message presents the design draft, the four Scope Lock drafts, and the run-mode choice. The human answers all three in one reply.
  - The Scope Lock items keep their separate, explicit accept / edit / reject. No blanket confirmation covers them.
  - If the human edits a derived item, the orchestrator updates the draft and confirms only that change.
  - A clarifying question that a Scope Lock answer raises still goes one at a time, after the combined turn.
- Defines the **question count**. Each message to the human that waits for an answer counts as one question. The combined confirmation turn counts as one. The count covers all of P0, from the pre-flight check to design confirmation.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`### How you coach`, "One question at a time":** Rewrite the paragraph. P0 asks only real forks, one at a time. Every derivable item goes into the design draft. The paragraph links to `standards/p0-question-policy.md`.
- **`### How you coach`, "Recommend, then confirm":** Keep the format block. For a derivable item, the recommendation goes into the design draft, and the design confirmation confirms it. The sentence about other phases (P1 to P9) stays unchanged.
- **`### How you coach`, "When the brief is already complete":** The orchestrator confirms the brief through the design draft, not item by item.
- **`### Phase 0 Start Actions`, step 3a (Detect adoption mode):** Replace "recommend the detected mode with its signal and confirm before proceeding". The detected mode and its signal go into the design draft under `Adoption mode:`. If a conflict warning applies, the orchestrator asks with the conflict warning protocol first. The `Adoption mode: {mode}, confirmed by human on {date}` build-log line is written when the design is confirmed.
- **`### Phase 0 Start Actions`, version bump text after step 3d:** Replace "Present the last known version and the suggested bump to the human". The last known version and the suggested bump go into the design draft. The **Hard block** paragraph and its message stay word for word.
- **`### What you produce at the end of Phase 0`:** Replace the separate "Before asking for design confirmation, ask:" run-mode prompt with the combined confirmation turn. The run-mode options are the ones req-001 defines. The hard gate sentence "Do not proceed to Phase 1 until the human has confirmed the Design" stays.
- **`### Scope Lock Challenge`, "Scope of this default":** Name the combined confirmation turn as the second narrow exception to `0000014-ADR-008`. The phrases "does not alter" and `0000014-ADR-008` stay.
- **`### P0 Audit Trail`:** At design confirmation, append `P0 questions asked: {n}` to the P0 build-log block.
- **`### Phase 0 → Phase 1 Gate Checklist`:** The adoption mode and version items are met when the human confirms the design that contains them.

### Build log template (`planifest-framework/templates/build-log.template.md`)

- Add a `P0 questions asked` row to the `### P0: Assess & Coach` table.

### Build assessment skill (`planifest-framework/skills/planifest-build-assessment-agent/SKILL.md`)

- **`## Critical Audit`:** Add a P0 question audit. It reports the `P0 questions asked` count and flags a count above 3. The NFR target is at most 3 coaching questions when the brief is complete and the stack is unchanged.

### Tests

- Add `planifest-framework/tests/test-0000033-req-008-p0-real-forks-only.sh`. It makes text assertions on the files above. `run-tests.sh` picks it up.
- These existing suites assert text near the edits. They must pass unchanged:
  - `planifest-framework/tests/test-0000025-req-007-scope-lock-default-batch.sh`
  - `planifest-framework/tests/test-0000017-req-005-scope-lock-suggested-answers.sh`
  - `planifest-framework/tests/test-0000017-req-006-structured-discovery-pass.sh`

### Verified by

- `standards/p0-question-policy.md` exists and contains `real fork`, each of the seven derivable items, `combined confirmation turn`, and `0000014-ADR-008`.
- The orchestrator's `### How you coach` section links to `p0-question-policy.md`.
- Step 3a no longer contains "confirm before proceeding". It still names the conflict warning protocol.
- The orchestrator still contains the **Hard block** message `is lower than the last known version`.
- The orchestrator no longer contains "Present the last known version and the suggested bump to the human".
- `### What you produce at the end of Phase 0` names the design, the Scope Lock batch, and the run mode in one turn. It still contains "Do not proceed to Phase 1 until the human has confirmed the Design".
- The Scope Lock section still contains "separate, explicit accept / edit / reject" and "No blanket or implied confirmation".
- The orchestrator and the build-log template both contain `P0 questions asked`.
- The build assessment skill's `## Critical Audit` names `P0 questions asked` and a threshold of 3.

## Acceptance Criteria

- [ ] P0 asks only real forks. Adoption mode, version, stack, NFRs, risks, the component split, and the feature ID reach the human once, in the design draft. The conflict warning protocol and the version hard block still apply.
- [ ] The design, the Scope Lock batch, and the run mode confirm in one turn. Each Scope Lock item keeps its own accept / edit / reject, and `0000014-ADR-008` still governs the remaining real forks.
- [ ] The P0 build-log block records `P0 questions asked: {n}`, and the P8 report flags a count above 3. The new suite and the three existing suites pass under `run-tests.sh`.

## Dependencies

- req-001 (autonomous-run-mode) defines the run-mode options that the combined confirmation turn presents. Both requirements edit `### What you produce at the end of Phase 0`, so the edits must merge.
- req-006 (on-the-loop-visibility) also adds a count to the P8 report. The two audits should sit together in `## Critical Audit`.
- req-010 (release-budget) changes backlog pickup at step 3c. Step 3c stays a real fork in this requirement.
- 0000025-ADR-003 (Scope Lock batching) is the first exception to `0000014-ADR-008`. This requirement adds a second, so P2 needs an ADR for it.
