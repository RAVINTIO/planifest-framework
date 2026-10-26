---
title: "Backlog Entry: 0000187 - Linked plan folder serves a design from elsewhere"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000187 - Linked plan folder serves a design from elsewhere

**Source feature:** 0000036-pipeline-friction-and-gate-fixes
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-10-23

---

## Problem

The hooks check `design.md` with `lstat`, but they do not check whether `plan/` or `plan/current/` is itself a symbolic link. A linked folder serves a `design.md` from outside the repository, and the gate reads it as the confirmed design. This is finding 3 in `plan/_archive/0000036-*/security-review-hooks.md`. It predates feature 0000036. The affected code is `readDesign` in `ravintio-framework/hooks/enforcement/path-rules.mjs`.

## Suggested Action

Resolve `plan/current/design.md` with `realpathSync` and require the result to sit inside the repository root. Treat a result outside the root as no design.

## Positioning note (2026-10-26)

The 0000279 differentiation review raises the priority of this entry. The confirmed design is an approved artefact. A design served from outside the repository has no approval record and no audit trail. Fix it with 0000286, which binds each approval to an artefact hash.

## Why Deferred

P5 rated the finding Low and accepted it. Fixing it changes how the gate treats every installed project that links `plan/` on purpose, so it needs its own design decision.
