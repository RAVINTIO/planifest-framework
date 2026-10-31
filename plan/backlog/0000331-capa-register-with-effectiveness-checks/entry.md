---
title: "Backlog Entry: 0000331 - a CAPA register with effectiveness checks"
summary: "Turn each postmortem action into a CAPA record with a lifecycle, a measurable effectiveness criterion, and closure only on evidence."
status: "open"
---
# Backlog Entry: 0000331 - a CAPA register with effectiveness checks

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline
**Related:** 0000085, 0000287, 0000290, 0000286

---

## Problem

RAVINTIO Zero files each postmortem action as a backlog entry and stops there. Nothing closes a record or checks that an action worked. On 2026-10-31, all 26 Zero postmortems and retrospectives still read `status: "open"`.

Zero's retrospectives show what this costs:

- One lesson recurred six times.
- Entry 0000264 appears in nine retrospectives, and one of them says it "failed four steps in a row".

A regulated QMS expects each corrective action to prove it worked before it closes. Framework has no CAPA record at all today.

## Suggested Action

Make each postmortem action (0000330) a CAPA record in a lasting register, for example `plan/quality/capa/`. A record lives outside `plan/current/`, so P7 never archives it away.

Each record holds these fields:

- type: corrective, preventive, or detective
- the source postmortem
- an owner and a due date
- a measurable effectiveness criterion, such as "no recurrence in 10 runs" or "the detective test fails on the seeded fault"
- a check trigger: a run count, a date, or a named event
- links to a Jira issue (0000295) or the organisation's QMS CAPA

States run in this order:

1. `open`
2. `implemented`
3. `effectiveness-pending`
4. `effective` or `ineffective`
5. `closed`

An `ineffective` result reopens the record and links a new postmortem. Closure needs evidence that meets the criterion. That evidence ends Zero's open-forever records.

The organisation's QMS CAPA stays the system of record. Framework records evidence and links to it. Framework never closes a QMS CAPA itself. Named-human closure sign-off, bound to the record hash, comes through 0000286. The register exports in the shared schemas from 0000290. A CAPA that needs a temporary waiver links a 0000287 waiver record.

## Wanted outcome

- Every postmortem action has exactly one CAPA record.
- A record can't reach `closed` without effectiveness evidence and a sign-off reference.
- An `ineffective` record links a new postmortem.
- Tests cover each state transition and reject each skipped state.

## Open questions

- Should the register hold one file per CAPA, or one index file plus a folder per CAPA?
- How does a product override the default effectiveness window?

## Why Deferred

The human asked for it during the Zero comparison review. It depends on the record format from 0000330.
