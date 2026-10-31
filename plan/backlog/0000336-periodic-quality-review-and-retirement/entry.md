---
title: "Backlog Entry: 0000336 - a periodic quality review and a retirement plan"
summary: "A dated, signed periodic review states whether the validated state still holds, and a retirement plan template covers migration, archival, and retention."
status: "open"
---
# Backlog Entry: 0000336 - a periodic quality review and a retirement plan

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline
**Related:** 0000287, 0000286, 0000285, 0000269

---

## Problem

GAMP 5 expects a computerised system to have a periodic review during operation and a planned retirement. Framework has neither. The phrases "periodic review" and "validated state" appear nowhere in `ravintio-framework/`.

Quality records also go stale without a review. RAVINTIO Zero shows the result: all 26 of its postmortems and retrospectives still read `status: "open"` on 2026-10-31. Once 0000331 adds CAPAs and 0000287 adds waivers with expiry dates, something must check them on a schedule.

## Suggested Action

Add a periodic review record, dated and signed through 0000286. It covers these inputs:

- open and overdue CAPAs (0000331)
- effectiveness checks that fall due
- expired or expiring waivers (0000287)
- the trend report (0000335)
- incidents and problems since the last review (0000334)
- supplier changes, including AI model and tool version changes
- control mapping changes (0000285)

The record ends with one of two conclusions:

1. The validated state still holds.
2. The validated state needs revalidation, and the record names the scope.

A configurable interval triggers the review. P0 checks for an overdue review and warns before a new run starts. An organisation can make an overdue review block P0.

Add a retirement plan template under `ravintio-framework/templates/`. It covers data migration, archival, retention periods, and access to records after retirement. Link it from `templates/operational-model.template.md`.

Framework records the review as evidence and links it to the organisation's QMS. It never claims the system is compliant.

## Wanted outcome

- A review record exists for each elapsed interval, signed by a named human.
- Each record states whether the validated state holds, or names the revalidation scope.
- P0 warns when a review is overdue.
- The retirement plan template exists and the operational model template links it.
- Tests cover the overdue check and the required record sections.

## Open questions

- Where does the interval live, and does 0000288 protect it from agent edits?
- Should the run retrospective from 0000269 feed the periodic review, or stay separate?

## Why Deferred

The human asked for it during the Zero comparison review. It reads records that 0000331, 0000334, and 0000335 define.
