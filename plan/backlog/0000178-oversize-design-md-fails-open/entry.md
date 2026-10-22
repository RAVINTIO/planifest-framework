---
title: "Backlog Entry: 0000178 - an oversize design.md fails the write gate open"
summary: "A regular plan/current/design.md over Node's string limit makes the read throw, and the gate admits every write, enforcement paths included."
status: "open"
---
# Backlog Entry: 0000178 - an oversize design.md fails the write gate open

**Source feature:** 0000036-pipeline-friction-and-gate-fixes
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-23

---

## Problem

`readDesign` in `planifest-framework/hooks/enforcement/path-rules.mjs` reads a regular `design.md` with `readFileSync(fd, "utf-8")`. Past about 512 MiB, the read throws `ERR_STRING_TOO_LONG`. Past 2 GiB, it throws `ERR_FS_FILE_TOO_LARGE`. The `catch` returns `unreadable`, and `evaluateWrite` admits the write under 0000003 ADR 005.

A sparse file costs no disk space. The shell guard doesn't block `truncate` on a `plan/` path. On a fixture whose design lists only `src/allowed/`, `truncate -s 600M plan/current/design.md` makes `gate-write.mjs` exit 0 for `planifest-framework/hooks/enforcement/gate-write.mjs`. The 3 GiB case also exits 0 on `main`, so the gap predates 0000036.

Backlog 0000162 covers `EACCES` and `EPERM` only, so its suggested fix wouldn't close this. See finding 2 in `plan/current/security-review-hooks.md` (0000036 P5).

## Suggested Action

Check `fstatSync(fd).size` against a cap, such as 1 MiB, before the read. Treat an oversize file as no design, so `scopeVerdict` judges the write. Decide it with 0000162, because both revise the same fail-open line.

## Why Deferred

The fix narrows 0000003 ADR 005 for one more case. That needs its own design decision, as 0000162 does, and sits outside 0000036's scope.
