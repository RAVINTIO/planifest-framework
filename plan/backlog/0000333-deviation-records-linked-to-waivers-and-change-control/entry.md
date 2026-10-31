---
title: "Backlog Entry: 0000333 - deviation records linked to waivers and change control"
summary: "Record each departure from an approved spec, process, or Hard Limit as a classified deviation, and link it to a waiver, a postmortem, or a change record."
status: "open"
---
# Backlog Entry: 0000333 - deviation records linked to waivers and change control

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline
**Related:** 0000287, 0000282, 0000353

---

## Problem

A regulated QMS expects every departure from an approved process to leave a deviation record. Framework captures departures as free text today:

- Autonomous runs write `Deviation (P{N}, unclassified): {what changed from the confirmed artifact}` lines to the build log. Feature 0000033 req-002 defines that format.
- Hard Limit 7 asks for a documentation update after a deviation, but records no classification or justification.
- A history rewrite or a skipped phase leaves only a build-log line or a commit message.

Nothing classifies these lines or links them to an approval. An auditor can't tell a planned, approved departure from an unplanned one.

## Suggested Action

Add a deviation record, stored outside `plan/current/`, for example in `plan/quality/deviations/`. Each record holds these fields:

- what departed from which approved spec, process, or Hard Limit
- planned or unplanned
- minor or major, against criteria the organisation can override
- the justification
- the phase and evidence, such as a build-log line or a commit

Link each class to its follow-up:

- A planned deviation is a waiver. It needs a 0000287 waiver record before it happens.
- An unplanned major deviation triggers a postmortem under 0000330.
- A deviation that changes validated scope must reference an approved change record before P9 (0000353). That record can live in the organisation's change system through 0000282.

Turn each `Deviation (P{N}, ...)` build-log line into one of these records. Examples to cover at pickup:

- a Hard Limit 7 documentation update
- a history rewrite
- a skipped phase

## Wanted outcome

- Every `Deviation (P{N}, ...)` line in a run maps to one deviation record.
- Every planned deviation links a waiver.
- Every unplanned major deviation links a postmortem.
- P9 stops if a scope-changing deviation lacks an approved change record.
- Tests seed each case and check the links.

## Open questions

- Who classifies a deviation as minor or major: the agent, the human on the loop, or a rule table?
- Should the existing `unclassified` label stay as a holding state until a human classifies the line?

## Why Deferred

The human asked for it during the Zero comparison review. It depends on the waiver register (0000287) and the change record (0000353).
