---
title: "Backlog Entry: 0000080 - The P1 gate does not check its own mandatory artifacts"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000080 - The P1 gate does not check its own mandatory artifacts

**Source feature:** the `ovelunor` product's 0000006-two-new-categories
**Source phase:** P6
**Deferral source:** discovered mid-flight
**Date filed:** 2026-09-21
**Moved:** from the `ovelunor` product's backlog entry 0000106 on 2026-10-10, because the fix belongs in this framework

---

## Problem

The spec-agent skill names five artifacts as always produced, regardless of feature size: the
execution plan, the requirements, the scope, the risk register, and the domain glossary.

Feature 0000006 reached P6 with four of them missing. Only the requirements existed, because the
briefs the orchestrator wrote for its P1 agents asked for requirements and nothing else. Nothing
between P1 and P6 noticed.

The P1 gate passed. The design critic was not run. The consistency check reported 13 findings at
P1, every one the archived-ADR false positive from backlog 0000104, so the noise hid nothing but
also revealed nothing.

## Suggested Action

Make the P1 gate check for the five mandatory artifacts by name before it passes. That is a
deterministic check with no judgement in it, and it belongs in `consistency-check.mjs` alongside
the story-traceability and acceptance-criteria checks it already performs.

Consider also whether the orchestrator's own P1 dispatch should be driven from that list rather
than from a hand-written brief, so the two cannot drift.

## Why Deferred

Found at P6 of feature 0000006 and fixed there by writing the four missing artifacts. The gate
change is framework work rather than feature work, and it sits naturally with backlog entry
0000104, which is the other outstanding fix to the same script.
