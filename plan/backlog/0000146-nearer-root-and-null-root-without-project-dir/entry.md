---
title: "Backlog Entry: 0000146 - nearer root and null root without project dir"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000146 - nearer root and null root without project dir

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

Two root-finding gaps appear when `CLAUDE_PROJECT_DIR` is unset:

- An agent can make a `planifest-framework/` folder inside a component. That folder then becomes a nearer root. Writes from that cwd to `../other/x.js` or `../../.claude/settings.json` pass the gate.
- If a folder on the cwd path can't be read, `resolveRoot` returns `null`. A `src/` write then passes.

Both depend on assumption A-001 in the 0000035 risk register, which backlog 0000118 tracks. Most of the behaviour predates 0000035.

## Suggested Action

Once 0000118 confirms whether hooks receive `CLAUDE_PROJECT_DIR`, decide how to find the root without it. One option is to distrust a `planifest-framework/` marker below a declared component path. Another is to block a `src/` write when the root is `null`.

## Why Deferred

The fix depends on the 0000118 answer, and most of the behaviour predates 0000035. It needs its own design decision about the fail-open rule.
