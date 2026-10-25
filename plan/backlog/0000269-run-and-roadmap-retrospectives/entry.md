---
title: "Backlog Entry: 0000269 - add retrospectives at the end of a run and a roadmap"
summary: "A human-requested capability, filed for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000269 - add retrospectives at the end of a run and a roadmap

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-25

---

## Problem

The P8 build report lists efficiency metrics, but no step reviews what went well and what to change. A roadmap ends with no review across its steps. Lessons stay in build logs that nobody rereads, so the next run repeats the same friction.

The vendored `external-skills/retro` skill is a weekly commit report for a team. It doesn't run inside the pipeline and doesn't file actions.

## Suggested Action

Add a blameless retrospective at two points:

- **Run:** after the P8 build report. Review what helped, what slowed the run, and what to try next. Read the build log, the self-corrections, the stops, and any postmortems from backlog entry 0000085.
- **Roadmap, after delivery:** a post-roadmap retrospective across every step, once the last step has merged. It runs before the roadmap pull request to `main`, so the record ships with the roadmap. It covers these questions:
  - How did the charted steps, bumps, and versions compare with what shipped?
  - Which friction repeated across steps?
  - What happened at each stop, and how long did each step take?
  - Which roadmap tooling gaps showed up, such as driver bugs?

Each improvement becomes a backlog entry or a repo instruction, with its source retrospective named. Store retrospectives outside `plan/current/`, for example in `plan/retrospectives/`, so a later run can read them at P0.

## Wanted outcome

Every shipped run has a retrospective record. Every delivered roadmap has a post-roadmap retrospective in its pull request to `main`. Each record names at least one thing to keep and one to change, and each change links to a filed action. P0 discovery and roadmap charting read the latest retrospectives.

## Why Deferred

The human asked for it. It pairs with backlog entry 0000085 and matches RAVINTIO Zero backlog entry 0000178.
