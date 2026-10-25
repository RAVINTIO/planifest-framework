---
title: "Backlog Entry: 0000268 - map user stories and write Gherkin acceptance criteria"
summary: "A human-requested capability, filed for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000268 - map user stories and write Gherkin acceptance criteria

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-25

---

## Problem

Nothing checks the user stories for gaps, so a story the brief missed never becomes a requirement. Acceptance criteria are free text, so a test can't map to them line by line.

RAVINTIO Zero shipped both changes in 0.15.0, feature 0000170-story-mapping-and-gherkin.

## Suggested Action

Port Zero feature 0000170:

- The plan phase runs a story mapping pass first and writes `plan/current/story-map.md` from a new story map template. A gap the brief states or implies becomes a story. Any other gap goes out of scope.
- The requirement template writes each criterion as one checkbox line with `Given`, `When`, and `Then` steps under it.
- The consistency check reports a criterion with a missing step or steps out of order. It also reports a plan with requirements but no story map, and a story missing from the map.
- `ratchet-check` guards each Gherkin step line, so a loop edit can't remove or reword one.

Zero's archive at `plan/_archive/0000170-story-mapping-and-gherkin-*` holds the requirements and tests.

## Wanted outcome

Every plan phase writes a story map, and every acceptance criterion has `Given`, `When`, and `Then` steps. The consistency check fails a plan that breaks either rule.

## Why Deferred

The human asked for parity with RAVINTIO Zero.
