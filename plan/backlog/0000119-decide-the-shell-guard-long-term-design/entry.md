---
title: "Backlog Entry: 0000119 - decide the shell guard's long-term design"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000119 - decide the shell guard's long-term design

**Source feature:** 0000032-governance-continuity-and-write-gate-scope
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-10-17

---

## Problem

`ravintio-framework/hooks/enforcement/shell-write-guard.mjs` is a heuristic shell reader of about 830 lines (ADR-006). The 0000032 P5 loop took three fix rounds. Each fix to the reader opened new edge cases:

- The F2 fix (judge against both `cd` bases) led to N-1, which blocked `cd X && relative-write`.
- The F5 fix (read arithmetic as one unit) led to N-2, an unclosed `((` read as arithmetic.
- The N-1 fix led to G-1 (folder tracking follows text order, not run order) and G-2 (bare `cd`, `cd ~`, and bare `pushd`).

Five more bypass families sit in the backlog (0000105, 0000108, 0000115, 0000116, 0000117). Each fix adds code to the reader, and each addition gives the next review more to attack.

## Suggested Action

Make a design decision before fixing any more edge cases. Two options stand out:

1. A smaller, conservative guard. It stops tracking `cd`, and blocks any command that names a gated path next to a writer token. The cost is more false positives, which the boot-file rule and **Write** or **Edit** already cover.
2. A real shell parser. Hooks must stay dependency-free (0000003-ADR-005), so this means a vendored parser or an ADR that allows one dependency. It must still meet the 200 ms target.

Record the choice as an ADR that supersedes or amends 0000032 ADR-006.

## Positioning note (2026-10-26)

The 0000279 differentiation review puts this decision ahead of every other shell-guard fix. Entries 0000225 and 0000238 show subagents getting past Hard Limit 8 in practice. An auditor won't accept a heuristic as a preventive control. Add a third option to the two above:

3. Enforce writes through tool permissions or a sandbox, so the control is preventive. Then reclassify the shell guard as a detective control, and record each detected bypass in the audit trail (0000289).

The answer decides the fate of 0000105, 0000108, 0000115, 0000116, 0000144, and 0000225.

## Why Deferred

The choice needs its own design decision and ADR. 0000032 closed P5 with every Medium finding fixed and verified. See the Tech Debt table in the 0000032 `recommendations.md` and the re-review rounds in its `security-report.md`.
