---
title: "Backlog Entry: 0000273 - a merge from main un-anchors the run mode"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000273 - a merge from main un-anchors the run mode

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P7
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

`ravintio-framework/scripts/run-mode.mjs` rule 5 prints `interactive` when any merge commit changed `plan/current/build-log.md`. In 0000039, P4 merged `origin/main` into the feature branch (1fffd812) to clear a conflict with PR #70. GitHub runs no `pull_request` workflow on a conflicting PR, so the merge was needed.

The merge differs from its `main` parent in the build log, because `main` holds no `plan/current/build-log.md`. From then on, the script printed `interactive` with the reason "a merge commit changed plan/current/build-log.md, so the anchor is ambiguous". The human on the loop had chosen `autonomous` at P0, and the orchestrator and ship agent ran on that choice.

A routine merge from `main` therefore silently changes how every later reader treats the run. The ship agent had to choose between the script and the P0 record.

## Suggested Action

Let rule 5 accept a merge whose first parent holds the build log and whose result keeps the first parent's build log unchanged. Add a test for a feature branch that merges `main` after P0. Also name the case in the orchestrator's resume rules and the ship agent's run-mode section.

## Why Deferred

It changes the run-mode integrity check (0000033), which is outside the rename scope of 0000039 and needs its own design decision.
