---
title: "Backlog Entry: 0000152 - Stale scope record hidden from git status"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000152 - Stale scope record hidden from git status

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-22

---

## Problem

`.gitignore` lists `plan/.fast-path-scope` (lines 21 to 24). An interrupted Fast Path can leave the record on disk. `git status` then shows nothing, so the human on the loop can't see it. The record keeps admitting writes to its paths until the branch or `HEAD` changes.

The agent that writes the record also reads the git state it binds to. The binding therefore limits staleness only. P5 finding G-S08 records this as Medium, accepted under R-002 and R-005.

## Suggested Action

Report a leftover record where the human on the loop sees it. Options include orchestrator resume detection, a session-start hook notice, or a P9 clean-tree check that names the file.

## Why Deferred

See G-S08 in `plan/current/security-report.md` (archived with 0000035) and risks R-002 and R-005 in its `risk-register.md`. The human on the loop chose self-authorisation at P0 (ADR-002). See also the Deferred Items table in the 0000035 `recommendations.md`.
