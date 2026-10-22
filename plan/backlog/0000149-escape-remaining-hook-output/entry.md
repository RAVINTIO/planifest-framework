---
title: "Backlog Entry: 0000149 - Escape remaining hook output"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000149 - Escape remaining hook output

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

0000035 routes every printed path in `gate-write`, `shell-write-guard`, and `ratchet-check` through `shown()` in `path-rules.mjs`. Three outputs still print raw text:
- `planifest-framework/hooks/enforcement/ratchet-check.mjs:267` prints the removed criterion as `removed: "${l}"`. A criterion that holds U+202E or an ESC sequence prints those raw. A newline can't reach this line, because of backlog 0000148.
- `planifest-framework/hooks/enforcement/em-dash-guard.mjs:120` prints the target raw. A target that holds a newline starts a new stderr line. `norm()` lowercases it, so a forged line doesn't match the exact `[Planifest] Fast Path: admitted` prefix.
- `shown()` at `path-rules.mjs:122` can cut an escape in half at the length cap, for example a bare `\u`. It prints no raw character.

## Suggested Action

Route both outputs through `shown()`. Cut `shown()` output before an escape, never inside one. Add a suite case for each.

## Why Deferred

The P5 final re-review found these in code next to the fixes. None comes from the fixes, and each is Low or informational.
