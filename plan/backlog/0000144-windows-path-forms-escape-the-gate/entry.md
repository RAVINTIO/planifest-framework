---
title: "Backlog Entry: 0000144 - Windows path forms escape the gate"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000144 - Windows path forms escape the gate

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

Some Windows path forms escape the root comparison or the enforcement list in `planifest-framework/hooks/enforcement/path-rules.mjs`:

- `\\?\C:\…` device paths
- `\\.\C:\…` device paths
- UNC paths
- trailing dots
- `::$DATA` alternate streams
- 8.3 short names such as `SETTIN~1.JSO`

P5 proved these only as string logic with `path.win32`. Nobody has tested them on a Windows host.

## Suggested Action

Run the cases on a Windows host. For each form that escapes, normalise it before the root comparison and the enforcement check, or refuse it.

## Why Deferred

The cases need a Windows host to confirm, and this repo's CI has none. The fixes need their own design across both hooks.
