---
title: "Backlog Entry: 0000154 - Check installed skills match source"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000154 - Check installed skills match source

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-22

---

## Problem

In this repo, a session loads skills and hooks from the git-ignored copies under `.claude/`. Those copies change only when setup reruns. A feature that changes a source skill leaves the installed copy stale for the rest of its own run.

In 0000035, req-002 added Step 5b to `planifest-framework/skills/planifest-ship-agent/SKILL.md`. The installed `.claude/skills/planifest-ship-agent/SKILL.md` has no Step 5b, so P7 must read the source copy by hand. 0000033 hit the same gap with the docs agent, and its REC-003 asked for a setup rerun.

## Suggested Action

Before a phase loads a skill, compare the installed copy with the source copy. If they differ, name the stale file and load the source copy. After each framework merge, rerun setup with `planifest-refresh-setup`.

## Why Deferred

A P4 decision in the 0000035 `build-log.md` chose not to rerun setup mid-run, because it would rewrite the live hooks of the session. See also REC-003 in the 0000035 `recommendations.md`.
