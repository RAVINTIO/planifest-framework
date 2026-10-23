---
title: "Backlog Entry: 0000161 - FIFO reads in check-design and ratchet"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000161 - FIFO reads in check-design and ratchet

**Source feature:** 0000036-pipeline-friction-and-gate-fixes
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

Req-008 of 0000036 stops the write gate from opening a non-regular `plan/current/design.md`. Two other hooks still open plan files with a plain `readFileSync` and no file-type check:

- `planifest-framework/hooks/enforcement/check-design.mjs:58-62` reads `plan/current/design.md` on every prompt. A FIFO there makes the `UserPromptSubmit` hook wait until its timeout ends it.
- `planifest-framework/hooks/enforcement/ratchet-check.mjs` reads loop-state files at `:78`, the approval marker at `:136`, and the write target at `:240`. A FIFO at any of those paths makes the hook wait in the same way.

Neither case admits a write the gate would block. Each one delays the session.

## Suggested Action

Move the req-008 file-type check into a shared helper in `path-rules.mjs`. Call it before each of these reads, and treat a non-regular file as absent.

## Why Deferred

US-008 covers the write gate only. These hooks wait rather than admit a write, so the fix needs its own scope decision.
