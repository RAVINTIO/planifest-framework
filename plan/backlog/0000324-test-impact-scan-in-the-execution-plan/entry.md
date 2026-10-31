---
title: "Backlog Entry: 0000324 - test impact scan in the execution plan"
summary: "Add a test impact section to the execution plan and the Change Pipeline, list the tests a change can break, and run them after the first edit."
status: "open"
---
# Backlog Entry: 0000324 - test impact scan in the execution plan

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Change Pipeline
**Related:** 0000083

---

## Problem

Framework plans which components a change affects, but not which tests it can break.

- `ravintio-framework/templates/execution-plan.template.md` has no test impact section.
- `skills/ravintio-change-agent/SKILL.md` (lines 35 to 40) runs a blast radius analysis. It classifies coupling between components. It doesn't list affected tests.

Tests that pin sizes, counts, or exact wording break on edits that look unrelated. In `ravintio-framework/tests/`, about 20 suites use `wc` or numeric limits, and 4 measure bytes with `wc -c`.

RAVINTIO Zero saw this often. Size, count, and wording tests broke late in 12 of 15 steps, even after the team filed the lesson. Zero retros 0000204, 0000205, 0000243, and 0000244 record it. Zero archived feature `0000246-plan-checks-count-and-cap-tests` responded:

- Its plan skill gained a `## Test impact scan` step.
- Its plan gained a `## Test impact` table. Each row names a cause, a test, and a unit, or says `none found`.

GAMP 5 and IEC 62304 expect a documented regression impact analysis for each change.

## Suggested Action

- Add a `## Test impact` table to the execution plan template. Each row names the cause, the test, and the requirement or component, or says `none found`.
- Widen Zero's scope from size and count tests to any test that covers a touched component.
- Add the same scan to the Change Pipeline's Change Summary.
- After the first edit in P3 or the Change Pipeline, run every listed suite before further work.

## Wanted outcome

- Every execution plan and Change Summary holds a test impact table.
- P3 runs the listed suites after the first edit, and the build log records the result.
- A table with no rows and no `none found` fails the P1 gate.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It changes a template and two skills, so it needs its own run.
