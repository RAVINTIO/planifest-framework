---
title: "Backlog Entry: 0000267 - plan concurrent subagent work by default"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000267 - plan concurrent subagent work by default

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

Plans default to single-threaded work, which is slower. The dispatch standard (`ravintio-framework/standards/agent-dispatch-standards.md`) and each phase skill name units that should run in parallel. But the plan for a run doesn't lay out which work can run concurrently and when. So the orchestrator decides batch by batch and often ends up working in sequence.

In 0000039, the late marker-rename change ran mostly as a chain. Test-writer, implementer, refactor, CI, security re-review, and fix each waited on the one before. The human on the loop had to ask "Can you use subagents to accelerate?" before the orchestrator moved independent work into one batch. That batch held the second security re-review, the P6 doc pass, and CI. Other units that could have overlapped:

- the P4 verify-by-execution run and the P5 security re-review, which read the same code and write different reports
- each TDD fix round and the doc updates for behaviour that was already settled
- reading a failed CI shard's log and writing the next round's tests

## Suggested Action

Make the execution plan, and the orchestrator's re-plan after a reopened phase, include a concurrency plan. It lists the work units, their dependencies, and the batches that can run at once when they share no files. Default to concurrent dispatch when two units have no dependency and no shared write target, and record the reason when work runs in sequence. Record batch count and wall-clock time per phase, so P8 can compare runs.

## Why Deferred

The human on the loop asked for this during 0000039. It changes the execution plan template, the orchestrator, and the dispatch standard, so it needs its own design. RAVINTIO Zero feature 0000172 (subagent acceleration) adds a `fast` run speed with batched dispatch. Check it at pickup and reuse its approach. File the same entry in RAVINTIO Zero.
