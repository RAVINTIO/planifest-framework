---
title: "Backlog Entry: 0000162 - chmod 000 on design.md fails the write gate open"
summary: "An agent can run chmod 000 plan/current/design.md. The gate's open throws EACCES and fails open, so any src/ write passes."
status: "open"
---
# Backlog Entry: 0000162 - chmod 000 on design.md fails the write gate open

**Source feature:** 0000036-pipeline-friction-and-gate-fixes
**Source phase:** P2
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

An agent can run `chmod 000 plan/current/design.md`. The write gate in `planifest-framework/hooks/enforcement/path-rules.mjs` finds a regular file with `lstatSync`. Its guarded open then throws `EACCES`, and the gate fails open under 0000003 ADR 005. Any `src/` write then passes. The bypass needs no race.

Feature 0000036 ADR-002 keeps this behaviour. It narrows 0000003 ADR 005 only for non-regular files and a throwing `lstatSync`.

## Suggested Action

Decide whether an `EACCES` or `EPERM` on the open of a regular `design.md` should block as no design, and record the decision as an ADR that revises 0000003 ADR 005 for that case. Add a suite case that runs the gate on a mode `000` file.

## Why Deferred

The fix reverses the fail-open rule of 0000003 ADR 005 for one error class. It needs its own design decision and sits outside the scope of 0000036.
