---
title: "Backlog Entry: 0000097 - Quality and governance gates for agent workflow evaluation"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000097 - Quality and governance gates for agent workflow evaluation

**Source feature:** 0000032-governance-continuity-and-write-gate-scope (raised by the human on the loop)
**Source phase:** P0
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-16

---

## Problem

RAVINTIO Framework gates check artifacts at each phase, and P8 reports build efficiency. Nothing measures the quality of the agent workflows themselves. No gate scores whether a run followed its skills, how often it needed human correction, or whether governance held from P0 to P9. The 0000077 lapses were found by the human, not by a gate.

## Suggested Action

Define quality and governance gates that evaluate agent workflows against measurable criteria. Examples are skill adherence, human corrections per phase, and governance gaps per run. Report the scores at P8, and allow a gate to fail a run when a score drops below a threshold.

## Why Deferred

Out of scope for 0000032. It needs its own design for the metrics, where they come from, and how thresholds apply.
