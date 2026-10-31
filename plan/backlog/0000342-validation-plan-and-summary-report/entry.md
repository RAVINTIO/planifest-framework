---
title: "Backlog Entry: 0000342 - validation plan and summary report"
summary: "A system validation plan written at the first GxP run, and a P7 validation summary report that the quality unit approves."
status: "open"
---
# Backlog Entry: 0000342 - validation plan and summary report

**Source feature:** none (GAMP 5 gap analysis)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline
**Related:** 0000340, 0000341, 0000333, 0000287, 0000286, 0000337

---

## Problem

A GxP system needs a validation plan before work starts and a summary report before release. Framework writes neither.

The P7 archive holds a run's artefacts, and the ship phase raises a PR. Nothing pulls the evidence into one report that a quality unit can read and approve. Nothing states up front which evidence a system will need, who approves it, or what counts as done.

Without these two documents, a regulated team must write them by hand from the archive. That repeats work and risks gaps between what Framework recorded and what the report claims.

## Suggested Action

- Add a system validation plan template. P0 writes it at the first run under the GxP profile in 0000337. Later runs update it when scope changes.
- The plan states scope, GAMP category, risk approach, deliverables, roles, and acceptance criteria for release.
- Add a validation summary report template that P7 fills. It holds:
  - the traceability matrix from 0000340
  - test results from 0000341
  - deviations from 0000333
  - waivers from 0000287
  - open risks
  - a release recommendation
- Route the report to the quality unit for approval through 0000286.

Framework writes a recommendation and never a release decision. The regulated company's quality unit approves or rejects.

## Wanted outcome

- Under the profile, a system without a validation plan can't pass P0.
- Each GxP release has a summary report that cites every source record by path.
- The ship phase won't raise the PR as release-ready until the approval record from 0000286 exists.

## Open questions

- Does the plan live per system beside the living spec in 0000338?
- Should a small change produce a report addendum instead of a full report? See 0000346.

## Why Deferred

The human asked for the GAMP 5 gap analysis findings to reach the backlog. It depends on 0000340, 0000341, and 0000286.
