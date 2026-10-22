---
title: "Backlog Entry: 0000159 - Permitted basename before enforcement list"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000159 - Permitted basename before enforcement list

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P6 (cross-model review, finding M4)
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

In `planifest-framework/hooks/enforcement/path-rules.mjs` (about line 788), the always-permitted file-name check runs before the Fast Path enforcement list. A file such as `planifest-framework/hooks/enforcement/CLAUDE.md` is therefore admitted, though it sits inside an enforcement folder. The reviewer found no way to use this, because the permitted names are documentation files that no hook loads.

## Suggested Action

Check the enforcement list before the always-permitted names, or limit the always-permitted names to paths outside enforcement folders. Add a suite case for a permitted name inside `hooks/enforcement/`.

## Why Deferred

The order predates 0000035, and the cross-model reviewer rated it non-blocking and not exploitable.
