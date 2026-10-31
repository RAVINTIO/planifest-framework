---
title: "Backlog Entry: 0000305 - one active feature per repository"
summary: "P0 refuses to start when another feature is active, and the hooks check that design.md belongs to the feature that holds the lock."
status: "open"
---
# Backlog Entry: 0000305 - one active feature per repository

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline
**Related:** 0000295, 0000244, 0000245, 0000267

---

## Context

A review of the sibling repo RAVINTIO Zero on 2026-10-31 found sessions clashing in one working tree. Framework targets regulated industries, such as those that follow GAMP 5. It runs one feature at a time, with controls fit for that feature, and Jira drives the work (0000295).

## Problem

- P0 writes `plan/.orchestrator-active` without checking for one already there (`skills/ravintio-orchestrator/references/phase-0-assess-and-coach.md` line 112).
- Nothing detects another active feature in these places:
  - another open feature branch that carries a sentinel
  - a git worktree
  - another session in the same working tree

Zero's retrospective `zero/plan/retrospectives/0000195-backlog-clearance-initiative-2026-10-27.md` (lines 47 and 48) records two sessions clashing in one working tree. One session's uncommitted id reservation collided with the other's commit.

## Suggested Action

- At P0, refuse to start when any of these exists:
  - another committed sentinel
  - an open `feat/` PR that carries a sentinel
  - a session lock
- Store the active feature key in the lock.
- If Jira is configured, run a JQL claim check for other active issues assigned to the agent account (see 0000295).
- Make `check-design.mjs` and `gate-write.mjs` check that the feature key in `design.md` matches the lock.

## Wanted outcome

A repository has at most one active feature. A second session can't start a feature, or write to `plan/current/`, while another holds the lock.

## Open questions

- How does a human release a stale lock left by a stopped session?
- Should the lock name the session as well as the feature key?

## Why Deferred

The human asked for it on 2026-10-31. It needs its own design and touches two enforcement hooks.
