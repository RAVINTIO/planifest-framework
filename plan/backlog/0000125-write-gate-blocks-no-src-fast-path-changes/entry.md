---
title: "Backlog Entry: 0000125 - Write gate blocks Fast Path changes with no src/ target"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000125 - Write gate blocks Fast Path changes with no src/ target

**Source feature:** 0000033-human-on-the-loop-run-mode
**Source phase:** after P9 (adding an instruction override)
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-19

---

## Problem

0000033 ADR-009 lets Fast Path admit changes with no `src/` target, such as governance or tooling text. Fast Path writes no `plan/current/design.md`. The `gate-write` hook blocks every path outside `ALWAYS_PERMITTED_PREFIXES` and `ALWAYS_PERMITTED_FILES` in `planifest-framework/hooks/enforcement/path-rules.mjs` when no design exists. A write to `planifest-overrides/instructions/` or a root `product.yml` therefore fails with "No confirmed design at plan/current/design.md".

After 0000033 merged, a request to add two instruction overrides hit this block. The agent staged the files in its scratchpad, and the human on the loop copied them in. Backlog 0000124 is the same block at P9 Step 9.

## Suggested Action

Give Fast Path a way to declare its target paths that `gate-write` honours, such as a short-lived scope record under `plan/current/`. Or add `planifest-overrides/` to the always-permitted prefixes, with a test that the enforcement paths stay gated. Decide this alongside 0000124.

## Why Deferred

The fix changes enforcement code, which Fast Path never admits. It needs the Change or Feature Pipeline.
