---
title: "Backlog Entry: 0000117 - a path through a symbolic link and .. is judged as text"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000117 - a path through a symbolic link and .. is judged as text

**Source feature:** 0000032-governance-continuity-and-write-gate-scope
**Source phase:** P5
**Deferral source:** deliberate scope decision
**Source finding:** G-3 in the 0000032 P5 re-review 2 (build log)
**Severity:** Low
**Priority:** Low
**Date filed:** 2026-10-17

---

## Problem

`toRootRelative` collapses `..` as text before it resolves symbolic links. An agent can create a link under `plan/`, which is always permitted, that points deeper into the repository. A path such as `plan/l/../../../src/x.js` then reads as a `plan/` path to the gate. The shell resolves the link first, so the write lands in `src/`. Both `gate-write` and the shell guard pass it. The gap predates 0000032 and belongs to the same family as 0000106.

## Suggested Action

Resolve the target through the file system one segment at a time, following each link with a hop limit, before collapsing `..`. Fix it together with 0000106.

## Why Deferred

At the third P5 gate, the human on the loop chose to fix G-1 and G-2 in 0000032 and file this Low finding. The decision is in the 0000032 build log.
