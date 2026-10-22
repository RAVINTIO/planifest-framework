---
title: "Backlog Entry: 0000156 - Check gate paths under Write-tool semantics"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000156 - Check gate paths under Write-tool semantics

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-10-22

---

## Problem

Claude Code's **Write** and **Edit** tools collapse `..` as text, then follow the links that remain. The kernel, which a shell uses, resolves `..` physically. The two can land on different files.

In 0000035, ADR-005 and the req-003 criteria specified physical resolution only. The P3 suites, the P4 coverage audit, and the P4 verification run all used the same model. None caught that `docs/L/../../src/a.js` passed `gate-write`. P5 found it as G-S01, a High regression from `main`. Risk R-019 had already said the gate needs **Write** semantics.

No skill step asks for a path case under both semantics. The codegen agent, the test writer, the validate agent, and verify by execution all lack one.

## Suggested Action

Add a step to the P3 test writer or the P4 validate agent. For any hook that judges a path, each path case runs under text collapse and under physical resolution. The step expects one verdict for both. Consider a design critic prompt at P2 as well.

## Why Deferred

See TD-012 and REC-002 in the 0000035 `recommendations.md`. G-S01 itself is fixed in commit `5a5ad24`. This entry covers the pipeline gap that let it reach P5.
