---
title: "Backlog Entry: 0000081 - Fast Path cannot write through gate-write"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000081 - Fast Path cannot write through gate-write

**Source feature:** the `ovelunor` product's 0000006-two-new-categories (Fast Path run, 2026-09-22)
**Source phase:** P0
**Deferral source:** discovered mid-flight
**Date filed:** 2026-09-22
**Moved:** from the `ovelunor` product's backlog entry 0000107 on 2026-10-10, because the fix belongs in this framework

---

## Problem

The Fast Path route and the `gate-write` hook contradict each other. `gate-write`
blocks every Write or Edit under `src/` unless `plan/current/design.md` exists.
Fast Path states plainly that `plan/current/design.md` is not touched and no
Feature Brief or design is produced. A Fast Path change to application code
therefore cannot be written through the Write or Edit tools at all.

The route is sanctioned by the framework, so this is not an agent trying to
evade a control. It is two framework rules that cannot both hold. An agent that
reaches for a shell heredoc instead gets the change written, and the
deterministic control it was meant to pass never runs. That is the outcome
regardless of intent, which makes it worth fixing rather than working around.

Hit while making the two masthead animations visible, a UI-styling change that
met all four Fast Path criteria.

## Suggested Action

Give `gate-write` a Fast Path condition. One option is a short-lived marker,
written at the start of a Fast Path run and cleared at its commit, that the hook
accepts in place of `design.md` while still checking the target path against a
declared component. Another is to let the hook treat a changelog entry under
`plan/changelog/` for the current date as the authorisation Fast Path already
requires at step 5.

## Why Deferred

It changes framework enforcement, so it needs its own design decision about what
authorises a Fast Path write. Folding that into a CSS fix would have been the
wrong place to settle it.
