---
title: "Backlog Entry: 0000122 - Turn the design critic on by default"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000122 - Turn the design critic on by default

**Source feature:** 0000033-human-on-the-loop-run-mode
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-19

---

## Problem

`design_critic` defaults to `off` outside `autonomous`. In 0000033, an ad hoc fresh-context review at P1 found one blocker and six major findings across 18 requirements that four drafting agents had missed. At P5, fresh-context reviews rated the first fixes High twice. The toggle would have caught the P1 class of finding at the gate in every run.

## Suggested Action

Make `design_critic` default to `report-only` in every mode, then `on` once a few runs show its false-positive rate. Update `planifest-framework/templates/loop-toggles.template.yml` and the loop-runner Toggle Protocol.

## Why Deferred

See REC-004 in `plan/_archive/0000033-human-on-the-loop-run-mode-2026-10-19/recommendations.md`. Changing a default for every product needs its own decision.
