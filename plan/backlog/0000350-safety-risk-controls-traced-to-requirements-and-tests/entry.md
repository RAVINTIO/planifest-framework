---
title: "Backlog Entry: 0000350 - safety risk controls traced to requirements and tests"
summary: "Add a hazard and harm register separate from delivery risk, and link each risk control to a requirement and a passing test."
status: "open"
---
# Backlog Entry: 0000350 - safety risk controls traced to requirements and tests

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Feature Pipeline
**Related:** 0000284, 0000285, 0000268, 0000339

---

## Problem

Framework's risk register holds delivery risk, such as schedule slip or an unknown API. It holds no risk of harm to a patient, a user, or the public. ISO 14971 expects a separate record of hazards and harms. It also expects each risk control to have verified effect (ISO 14971 7.2).

Framework can't show that a risk control became a requirement, or that a test proves the control works.

## Suggested Action

- Add a hazard and harm register, separate from the delivery risk register. Each row names the hazard, the harm, and the severity and probability of harm.
- Link each risk control to a requirement and to a test. Use stable criterion IDs from 0000268, so the chain survives edits.
- At P4, confirm that each risk control has passing verification. A control with no test, or a failing one, fails the gate.
- Report residual risk back to the organisation's risk file, through 0000284 where configured.
- Never write risk acceptance. The organisation owns that decision, and Framework only supplies evidence for it.
- Feed the chain into the trace rules of a compliance profile (0000348), such as `[hazard, risk-control, requirement, test]`.

## Wanted outcome

For any run, a reader can follow each hazard to its controls, requirements, and passing tests. Tests check these conditions:

- P4 fails when a risk control has no linked test.
- No Framework artefact records risk acceptance.

## Why Deferred

Filed from the Zero comparison review on 2026-10-31. It needs its own design and depends on stable criterion IDs (0000268).
