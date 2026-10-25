---
title: "Backlog Entry: 0000227 - loop-state timestamps can be estimated"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000227 - loop-state timestamps can be estimated

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-10-24

---

## Problem

`plan/current/loop-state-design_critic-p1.md` records iteration 2 at `00:40:00Z` and iteration 3 at `00:55:00Z`. Both were estimates, not `date -u` readings. The file carries a correction note, and the build log records the same correction. Nothing in the loop-state template or the loop runner stops an agent from writing an estimate, and no check can tell an estimate from a reading.

## Suggested Action

In `ravintio-loop-runner`, make the orchestrator run `date -u +%Y-%m-%dT%H:%M:%SZ` in the same step that appends each iteration, and paste the output. Add a loop-close check that each iteration timestamp falls between the commit times of the previous and next iteration artifacts (`git log --format=%cI`). Flag a round number such as `:00:00Z` for review.

## Why Deferred

The timestamps are audit data only, and no gate reads them. The loop-runner change is a separate design choice. See `plan/current/recommendations.md` row REC-004.
