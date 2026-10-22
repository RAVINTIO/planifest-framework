---
title: "Backlog Entry: 0000147 - Promote temp file not link-checked"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000147 - Promote temp file not link-checked

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

`planifest-framework/scripts/promote-to-regression.sh` rewrites the promoted suite through a temp file named `$DEST.tmp` in its sed step. P5 bound the source and the destination and refuses links at both. It doesn't check the temp path. If a link already sits at `$DEST.tmp`, the sed output follows it and writes outside `tests/regression/`.

## Suggested Action

Create the temp file with `mktemp` inside `tests/regression/`, or refuse to run when `$DEST.tmp` already exists or is a link. Add a suite case with a planted link at the temp path.

## Why Deferred

The P5 findings didn't name it. The P5 fix agent found it while binding the source and destination, and left it to keep the fix narrow.
