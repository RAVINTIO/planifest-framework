---
title: "Backlog Entry: 0000101 - Sample the existing records a design depends on at P0"
summary: "A design that reads existing records should sample them in discovery, so a common value that defeats the design shows up before P3."
status: "open"
---
# Backlog Entry: 0000101 - Sample the existing records a design depends on at P0

**Source feature:** ovelunor 0000049-ten-minute-release-path
**Source phase:** P4
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-16

---

## Problem

Ovelunor's 0000049 designed SIT's skip around the deploy log's `commit` column. P0 read the schema but no rows. Five of the last eight SIT rows held `-dirty` commits, which can't be diffed, so the skip would rarely have fired. The first P4 SIT deploy found it, and the run then changed what counts as dirty and deployed again.

## Suggested action

Add a discovery step to the orchestrator: when a design reads existing records, such as a log, a database table, or a config history, discovery samples recent rows and states how often each value the design relies on is usable. The design then names that rate as an assumption.

## Why deferred

It changes the framework's P0, which belongs in the framework repository, not the product run that found it. See the product's postmortem `plan/postmortems/2026-10-16-2203-0000049-ten-minute-release-path-dirty-commits.md`.
