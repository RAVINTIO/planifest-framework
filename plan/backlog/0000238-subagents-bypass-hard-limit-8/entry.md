---
title: "Backlog Entry: 0000238 - subagents bypass Hard Limit 8"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000238 - subagents bypass Hard Limit 8

**Source feature:** 0000038-token-efficiency-windows-shard
**Source phase:** P9
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

Subagents in feature 0000038 changed project files through Bash three times. No hook blocked any of them.

- Commit `0411efd` (P1): a Python edit changed a req-005 acceptance criterion. It bypassed `ratchet-check`, which would have blocked the change.
- P7: the ship agent appended its build-log block to `plan/current/build-log.md` with `printf >>`.
- P7: the ship agent removed a stray file with `rm`.

The `shell-write-guard` hook blocks a shell write only where `gate-write` would block a **Write**. Writes to `plan/` are always permitted, so the guard passes them. It also can't see writes inside an interpreter. `ratchet-check` runs only on Write and Edit. The written rule alone didn't stop three agents, even though every dispatch prompt repeated it.

## Suggested Action

Make the shell guard block appends and interpreter writes to `plan/current/` artifacts while a ratchet loop is active. Or run the ratchet check over the diff at commit time, so a Bash edit can't skip it.

## Why Deferred

Found after P9 of 0000038. It changes an enforcement hook, so it needs its own design.
