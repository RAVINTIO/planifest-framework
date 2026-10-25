---
title: "Backlog Entry: 0000096 - Multi-release initiative run"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000096 - Multi-release initiative run

**Source feature:** 0000032-governance-continuity-and-write-gate-scope (raised by the human on the loop)
**Source phase:** P0
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-16

---

## Problem

A RAVINTIO Framework run delivers one feature in one release. The framework has no unit of work for an initiative that delivers a series of related features across several releases. Waves split a large feature, but each wave needs a human to start a new run. The orchestrator also stops at the context clear after P9, so nothing carries an initiative across cleared sessions.

## Suggested Action

Add an initiative run that tracks a series of related features from start to end. It should persist its state on disk, so that it continues autonomously across cleared sessions. Each feature still passes through P0 to P9 and its human gates. Related: backlog 0000095 (roadmap area) and 0000078 (human on the loop for continuous run).

## Why Deferred

Out of scope for 0000032. It changes the run model and needs its own design and ADRs. It also depends on 0000032's run-lifecycle fixes, which define when a run ends.
