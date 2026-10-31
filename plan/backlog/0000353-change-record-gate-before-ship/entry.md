---
title: "Backlog Entry: 0000353 - change record gate before ship"
summary: "Before P9, check for an approved change record in Jira Service Management or ServiceNow, and stop if the adapter can't confirm one."
status: "open"
---
# Backlog Entry: 0000353 - change record gate before ship

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Feature Pipeline
**Related:** 0000282, 0000280, 0000295

---

## Context

This entry splits item 3 out of 0000282. The rest of 0000282 moves into 0000295.

## Problem

Changes to controlled systems need an approved change record before release. A team may keep that record in Jira Service Management or ServiceNow. P9 Ship tags and raises the PR without checking for one. These controls expect the check:

- SOX IT general controls (ITGC) for change management
- GAMP 5 change control

## Suggested Action

- Before P9, ask the change-record adapter whether an approved record exists for the run.
- Use the adapter outcomes from 0000280:

| Outcome | P9 result |
|---------|-----------|
| `found` | P9 continues and records the change record key. |
| `not found` | P9 stops and names the missing record. |
| `unreachable` | P9 stops. Unknown never passes. |
| `not configured` | P9 continues only when policy needs no change record. |

- Framework never approves a change record.
- Make the change in `ravintio-framework/skills/ravintio-ship-agent/SKILL.md`. Confirm the path at pickup.

## Wanted outcome

P9 ships only when policy needs no change record, or the adapter finds an approved one. Tests check these conditions:

- P9 stops on `not found` and on `unreachable`.
- P9 records the change record key on `found`.

## Why Deferred

Filed from the Zero comparison review on 2026-10-31. It depends on the adapter contract in 0000280.
