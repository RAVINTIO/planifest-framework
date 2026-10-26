---
title: "Backlog Entry: 0000287 - an exception and waiver register"
summary: "Replace free-text phase skips with waiver records that name a risk owner, an expiry date, and the control or gate each one relaxes."
status: "open"
---
# Backlog Entry: 0000287 - an exception and waiver register

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-26

---

## Problem

When a human skips a phase, the orchestrator writes one free-text line to `plan/current/.skips`. The ship-agent copies it into the changelog and deletes the file. The record names no risk owner, no expiry, and no control. Deferred items in `scope.md` and accepted risks have the same gap. Nobody revisits an exception after the run ends.

Regulated processes treat each exception as a governed record. Someone with authority accepts it, it expires, and someone reviews it.

## Suggested Action

- Add a waiver template with an ID, the gate or control it relaxes, a reason, a risk owner, an approver (0000286), a granted date, an expiry date, and compensating controls.
- Keep waivers in a lasting register outside `plan/current/`, so they outlive the run.
- Make `.skips`, risk acceptances, and a gate passed with known findings each produce a waiver.
- At P0, list waivers that have expired or will expire soon for the affected components.
- Sync waivers with the risk tool when one is set (0000284).

## Wanted outcome

Every exception from a run is a waiver with an owner and an expiry. A test proves that P0 reports an expired waiver for a component the run touches.

## Why Deferred

Filed from the 0000279 differentiation review. It depends on 0000286 for approver identity.
