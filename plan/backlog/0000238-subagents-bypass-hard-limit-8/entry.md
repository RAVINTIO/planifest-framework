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

It happened again in 0000039 P1. The critic revision agent edited nine `plan/current/` files with a Python one-liner while the design-critic ratchet was active. The orchestrator checked the diff and found no criterion line removed, but no hook ran.

It happened once more in 0000039 P5. The third security re-review agent changed one cited line number in `plan/current/security-rereview-markers.md` with `sed -i`, then used Edit for the rest. It reported the slip itself. No ratchet loop was active, so no check was skipped, but the guard let the write through.

## Suggested Action

Make the shell guard block appends and interpreter writes to `plan/current/` artifacts while a ratchet loop is active. Or run the ratchet check over the diff at commit time, so a Bash edit can't skip it.

## Positioning note (2026-10-26)

The 0000279 differentiation review treats this entry as evidence for 0000119. The commit-time ratchet check suggested above works whatever the guard design, so it can go ahead first. It also gives the tamper-evident audit trail (0000289) a check that a Bash edit can't skip.

## Why Deferred

Found after P9 of 0000038. It changes an enforcement hook, so it needs its own design.
