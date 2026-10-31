---
title: "Backlog Entry: 0000335 - trend analysis across quality records"
summary: "A read-only script counts recurring gaps across postmortems and CAPAs, raises a problem record past a threshold, and shows the trend at P0."
status: "open"
---
# Backlog Entry: 0000335 - trend analysis across quality records

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline
**Related:** 0000269, 0000290, 0000097

---

## Problem

RAVINTIO Zero reads each postmortem and retrospective on its own. No step looks across them, so a recurring cause goes unnoticed:

- Entry 0000264 appears in nine Zero retrospectives. One says it "failed four steps in a row". No aggregate flagged it.
- One lesson recurred six times before anyone acted on it.

A regulated QMS expects trend analysis of quality data. Without it, each record looks like a one-off. 0000330 adds fixed fishbone categories, and 0000331 adds CAPA records. Nothing counts them yet.

## Suggested Action

Add a read-only script, for example `ravintio-framework/scripts/quality-trend.mjs`. It reads every postmortem, CAPA, and retrospective record and counts these:

- the gap category each 5 whys chain ends at
- fishbone categories
- affected components
- backlog entries that more than one record links

When a count crosses a threshold, the script raises a problem record under 0000334. One default is the same gap three times in 90 days, which matches the Zero 0000264 pattern. A product can set its own thresholds.

P0 shows the trend summary for each component the new feature touches. The run retrospective from 0000269 reads the same summary. The script writes its output in the shared schemas from 0000290, so RAVINTIO Insight can read it.

## Wanted outcome

- The script writes no file except the trend output and any problem record it raises.
- Seeded records with three matching gaps in 90 days raise exactly one problem record.
- Seeded records below the threshold raise none.
- P0 prints the trend summary for affected components.
- Running the script twice raises no duplicate problem record.

## Open questions

- 0000097 covers workflow quality gates, and 0000279 proposes moving it to RAVINTIO Insight. Does trend analysis stay in Framework, with Insight as a reader?
- Should retrospectives count toward thresholds, or only postmortems and CAPAs?

## Why Deferred

The human asked for it during the Zero comparison review. It needs the record formats from 0000330 and 0000331 first.
