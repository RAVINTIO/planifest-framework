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

## Positioning note (2026-10-26)

The 0000279 differentiation review moves this entry out of Framework. Scoring how a run followed governance is the "AI workflow" dimension of RAVINTIO Insight. Scoring a skill against its criteria belongs to RAVINTIO Qualify. Framework's part is to record what those tools need, such as attributable approvals (0000286) and labelled audit records (0000289). File the entry in the Insight and Qualify repositories, then close it here with a pointer.

## Why Deferred

Out of scope for 0000032. It needs its own design for the metrics, where they come from, and how thresholds apply.
