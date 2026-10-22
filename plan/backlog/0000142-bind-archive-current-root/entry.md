---
title: "Backlog Entry: 0000142 - bind archive-current root"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000142 - bind archive-current root

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

`planifest-framework/scripts/archive-current.mjs` takes a free `--root` argument and defaults to the current folder (line 86). It doesn't check the root against the one the write gate uses. As a sanctioned script, it moves files past the gate, so a wrong or crafted root moves content to a place no gate judges. Risk R-023 in the 0000035 risk register records this.

## Suggested Action

Bind `--root` as `set-product-release.mjs` does. The script requires the real path that `resolveRoot` returns and exits 2 on any mismatch.

## Why Deferred

The script is outside the 0000035 requirements. P5 narrowed the other sanctioned scripts that the feature touches.
