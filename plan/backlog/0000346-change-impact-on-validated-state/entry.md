---
title: "Backlog Entry: 0000346 - change impact on validated state"
summary: "Add GxP impact, affected specs, matrix rows to re-run, and revalidation scope to the change summary, and block shipping without a summary report addendum."
status: "open"
---
# Backlog Entry: 0000346 - change impact on validated state

**Source feature:** none (GAMP 5 gap analysis)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline
**Related:** 0000282, 0000295, 0000353, 0000342

---

## Problem

Once a GxP system is in a validated state, every change must show its effect on that state. The Change Pipeline doesn't ask.

`ravintio-framework/templates/change-summary.template.md` records the request, classification, blast radius, changes made, and validation. Blast radius names affected code and components. It doesn't name these:

- whether the change has GxP impact
- which specification entries change
- which traceability matrix rows must run again
- the revalidation scope

A bug fix to a validated component can ship today with no record of what it did to the validated state. An auditor would see a gap between the last summary report and the running system.

## Suggested Action

- When the GxP profile is on, add these sections to the change summary:
  - GxP impact, yes or no, with a reason
  - affected URS, FS, and DS entries
  - traceability matrix rows to re-run
  - revalidation scope and the risk class that sets it
- Block the ship phase for a change to a validated component until a summary report addendum exists. 0000342 defines the report.
- Link the change to the organisation's change record through 0000282 and 0000295.
- Align with 0000353 on how changes are classified.

Framework records the impact. The regulated company's quality unit decides whether the system stays in a validated state.

## Wanted outcome

- A change summary under the profile can't pass without all four new sections.
- A change to a validated component produces an addendum that cites the re-run matrix rows and their results.
- With the profile off, the change summary stays as it is.

## Open questions

- Which components count as validated? The living spec in 0000338 could record that.
- Can a no-impact change skip the addendum if the quality unit agrees in policy?

## Why Deferred

The human asked for the GAMP 5 gap analysis findings to reach the backlog. It depends on 0000342 and the traceability matrix in 0000340.
