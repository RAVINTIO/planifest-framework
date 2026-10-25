---
title: "Backlog Entry: 0000190 - clarify autonomous mode, phase prefixes, and the product name"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000190 - clarify autonomous mode, phase prefixes, and the product name

**Source feature:** none (human request, mirrors RAVINTIO Framework Zero feature 0000042-autonomous-mode-and-prefixes)
**Source phase:** none (outside a pipeline run)
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-23

---

## Problem

RAVINTIO Zero release 0.9.0 (feature 0000042) overhauls three things. The human wants the same overhaul in RAVINTIO Framework.

1. **Run modes.** RAVINTIO Framework offers three modes: interactive, continuous, and autonomous. Zero 0.9.0 keeps two, `gated` and `autonomous`. P0 stays interactive. `autonomous` runs every later phase to a raised PR and stops only on exceptions. `gated` stops for confirmation at the end of each phase.
2. **Phase prefixes.** RAVINTIO Framework prefixes messages with a bare number, such as `P3:`. A reader needs a legend to know the phase. Zero 0.9.0 uses the number plus a short name, such as `P2 Implement:`, then a status: `P2 Implement: Complete: {one-liner}`.
3. **Product name.** Zero now never calls itself a framework, so "framework" means RAVINTIO Framework. RAVINTIO Framework docs should name both products clearly wherever the two could be confused.

## Suggested Action

Read the Zero 0000042 design and ADRs in `planifest/planifest-zero` under `plan/_archive/0000042-*`. Then decide whether to collapse continuous into the other two modes and adopt the `P{n} {Name}:` prefix form.

## Why Deferred

The human raised it during a RAVINTIO Zero run. It needs its own design, since RAVINTIO Framework has ten phases and an exception list Zero does not share.
