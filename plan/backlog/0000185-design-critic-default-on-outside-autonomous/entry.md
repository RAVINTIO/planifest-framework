---
title: "Backlog Entry: 0000185 - Design critic default on outside autonomous"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000185 - Design critic default on outside autonomous

**Source feature:** 0000036-pipeline-friction-and-gate-fixes
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-23

---

## Problem

Feature 0000036 (req-006) made an absent `design_critic` key, or an absent `loop-toggles.yml`, read as `report-only` outside `autonomous`. In `autonomous` it still reads as `on`. The critic only reports outside `autonomous`, so a false positive never stops a phase, but a true positive does not stop one either. The default files are `planifest-framework/skills/planifest-loop-runner/SKILL.md` and `planifest-framework/templates/loop-toggles.template.yml`.

## Suggested Action

Collect the critic's false-positive rate across several runs from the `design-critic-p1*.md` and `design-critic-p2*.md` verdicts. If the rate is low, move the outside-`autonomous` default to `on` and update the five locations that state it.

## Why Deferred

The decision waits on data. See `plan/_archive/0000036-*/scope.md` (Out of Scope) and the P1 decision on req-006 in the build log. The false-positive rate is unknown until the critic has run under `report-only` in more features.
