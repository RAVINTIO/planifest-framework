---
title: "Backlog Entry: 0000104 - subagent acceleration"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000104 - subagent acceleration

**Source feature:** 0000037-self-host-on-planifest-zero
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Moved:** copied from `planifest-zero` backlog entry 0000110 on 2026-10-17, at the human's request
**Date filed:** 2026-10-17

---

## Problem

The pipeline runs most phase work in one context, one artifact at a time. The parallelism rules exist, but each phase decides for itself when to split work. So a run with many small, independent requirements still moves slowly. In 0000037, the human asked mid-run for the build to go as fast as it can with multiple subagents.

The phases also wait on each other more than they need to. For example, P1 writes requirement files one by one, and P3 dispatches subagents only after P2 ends.

## Suggested Action

1. Add a speed setting, for example `fast` in `plan/.run-mode` or a loop toggle, that makes parallel dispatch the default in every phase.
2. In each phase skill, list the work units that can always run in parallel, and dispatch them in one batch.
3. Let independent requirements move through spec, code, and validation as separate subagent streams, joined at the review gates.
4. Record the subagent count and wall-clock time per phase in the build log, so the build assessment can measure the gain.

## Why Deferred

The change needs its own design decision about how far phases may overlap and how the gates stay intact. It touches the orchestrator, the dispatch standards, and each phase skill in `planifest-framework/`. It fits with the pipeline-governance group in 0000095 to 0000098.
