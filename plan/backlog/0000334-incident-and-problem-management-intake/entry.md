---
title: "Backlog Entry: 0000334 - incident and problem management intake"
summary: "Add incident and problem records for issues found after release, route each correction into a pipeline, and list residual anomalies in release records."
status: "open"
---
# Backlog Entry: 0000334 - incident and problem management intake

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline
**Related:** 0000280, 0000282, 0000284, 0000330

---

## Problem

Framework stops at P9 Ship. It has no record for an issue found after release. GAMP 5 expects incident and problem management in the operation phase. IEC 62304 clause 9 expects a software problem resolution process. The words "incident" and "problem record" appear nowhere in Framework's own skills or templates. Only vendored external skills mention them.

Release records also don't list known residual anomalies. IEC 62304 clause 5.8 expects each release to list them with an evaluation.

## Suggested Action

Add an incident record for issues found after release. Source it from Jira (0000295) through the adapter contract (0000280). Each incident holds these fields:

- severity
- a regulatory impact triage covering data integrity, patient safety, and financial reporting
- the affected release and components
- links to the Jira issue and any risk entry (0000284)

Raise a problem record when either of these is true:

- one incident is serious
- incidents recur against the same component or cause

A problem record runs the postmortem from 0000330. The corrective change enters the Feature Pipeline or the Change Pipeline with the problem ID as its source. The run links back to the incident and problem through 0000282.

Extend the release record at P9 with a residual anomalies section. List each known open anomaly with its evaluation, its risk link, and why the release can still ship.

Framework records evidence and links to the organisation's QMS. The organisation's incident system stays the system of record.

## Wanted outcome

- An incident record exists for each post-release issue that Framework ingests.
- A serious or recurring incident raises a problem record that links a postmortem.
- A corrective run names its problem ID as its source.
- Every P9 release record has a residual anomalies section, even when it is empty.
- Tests check each link and the release section.

## Open questions

- What counts as "recurring": a count, a window, or both? 0000335 may own that threshold.
- Should incidents live in the repository, or only as links to Jira?

## Why Deferred

The human asked for it during the Zero comparison review. It needs the adapter contract (0000280) and the postmortem (0000330) first.
