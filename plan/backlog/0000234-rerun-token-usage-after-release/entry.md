---
title: "Backlog Entry: 0000234 - re-run the token usage measurement after release"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000234 - re-run the token usage measurement after release

**Source feature:** 0000038-token-efficiency-windows-shard
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-24

---

## Problem

The savings that backlog 0000230 estimated (19.9% to 26.1% from the model tiers alone) are unconfirmed. Feature 0000038 shipped the changes, but no one has measured a week of real sessions on release 0.36.0.

## Suggested Action

One week after the 0.36.0 release, repeat the usage measurement that 0000230 used. Compare the result with the estimate. If the remaining context cost supports it, pick up backlog 0000231 (the ship-agent split).

## Why Deferred

The measurement needs a week of sessions after release, so it can't run inside this pipeline. See the Deferred section of `plan/current/scope.md`.
