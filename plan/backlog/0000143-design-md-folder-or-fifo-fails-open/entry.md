---
title: "Backlog Entry: 0000143 - design.md folder or FIFO fails open"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000143 - design.md folder or FIFO fails open

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

`gate-write` reads `plan/current/design.md` in `planifest-framework/hooks/enforcement/path-rules.mjs`, at about lines 701 to 707. If a folder sits at that path, the read throws `EISDIR` and the gate allows the write. If a FIFO sits there, the read waits until the hook times out. Either case lets an agent avoid the design check. The behaviour predates 0000035 and comes from the fail-open rule in 0000003 ADR 005.

## Suggested Action

Check the file type with `lstat` before the read. Treat anything other than a regular file as a missing design, so the gate blocks.

## Why Deferred

The defect predates 0000035 and sits outside its requirements. Changing it means revisiting the fail-open rule in 0000003 ADR 005.
