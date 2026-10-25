---
title: "Backlog Entry: 0000120 - A join can claim another stream's changed file"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000120 - A join can claim another stream's changed file

**Source feature:** 0000033-human-on-the-loop-run-mode
**Source phase:** P5 (security re-review, residual on finding S6)
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-19

---

## Problem

`ravintio-framework/scripts/stream-reconcile.mjs` counts a join record's listed file as a use only if `git log {start-commit}..HEAD` shows it changed. The range holds every stream's commits, not only the join's own. A join record can therefore list a file that another stream changed, and the consumer check passes with no real use of the artifact. The P5 re-review reproduced it. The orchestrator writes join records, so the risk is Low.

## Suggested Action

Require each file a join lists to appear in a commit that carries a `Join: {join-id}` trailer, as stream commits already carry `Stream: {id}`. The script then filters by that trailer.

## Why Deferred

The fix adds a commit trailer convention for batches outside streams, which needs its own design. The current check already catches the 0000006 case that backlog 0000082 named.
