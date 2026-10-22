---
title: "Backlog Entry: 0000151 - Promote script partial state and read race"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000151 - Promote script partial state and read race

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

Two informational gaps sit in `planifest-framework/scripts/promote-to-regression.sh`:
- The idempotency check treats a manifest that won't parse as "not promoted". The test copy lands, then the manifest update exits 1 and prints a Node stack trace. A re-run after the manifest is repaired recovers.
- The script checks the source with `lstat`, then `sed` reads it by path. A process that swaps the source for a symlink between the two steps could copy an outside file into the pack. Not reproduced.

## Suggested Action

Parse the manifest before copying, and exit 1 with a clean message if it doesn't parse. Read the source through one descriptor, or copy it to the temp file first and check that copy.

## Why Deferred

The P5 final re-review rated both informational. Neither comes from the P5 fixes.
