---
title: "Backlog Entry: 0000177 - em dash guard lowercases the target path"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000177 - em dash guard lowercases the target path

**Source feature:** 0000036-pipeline-friction-and-gate-fixes
**Source phase:** P4
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-23

---

## Problem

`planifest-framework/hooks/enforcement/em-dash-guard.mjs` builds `relTarget` with its local `norm()` (line 59), which calls `toLowerCase()`. The block message at line 123 then prints that lowercased value. A write to `docs/Guide.md` therefore reports `'docs/guide.md'`. The human on the loop sees a path that differs from the real file name. On a case-sensitive file system, that path may name a different file or none. P4 verify-by-execution observed this when a target `[Planifest] forged.md` printed as `[planifest] forged.md`.

## Suggested Action

Keep the lowercased form for the `isScoped()` match, and print the target with its original case through `shown()`.

## Why Deferred

The behaviour existed before 0000036, and no 0000036 criterion depends on the case of the printed path. It is a message-accuracy fix with its own test.
