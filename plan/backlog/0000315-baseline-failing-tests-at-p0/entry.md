---
title: "Backlog Entry: 0000315 - record failing tests on the base commit at P0"
summary: "Record the base commit's failing tests at P0, so P4 Validate stops only on new failures and logs inherited ones."
status: "open"
---
# Backlog Entry: 0000315 - record failing tests on the base commit at P0

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline
**Related:** 0000287, 0000295

---

## Context

A review of RAVINTIO Zero on 2026-10-31 found that runs couldn't tell an inherited test failure from one they caused. In a regulated setting, validation evidence must show which defects a change introduced and which it found.

## Problem

- `skills/ravintio-validate-agent/` has no step that records the base commit's failing tests.
- P4 Validate therefore treats every failure as the run's own. It either spends self-correction attempts on a failure it didn't cause, or stops on it.
- The evidence from P4 doesn't separate inherited defects from new ones.

## Zero's design

Zero backlog 0000295 (`zero/plan/backlog/0000295-baseline-failing-tests-at-p0/entry.md`) proposes this flow:

- At Zero P0 Discovery, run the suite on the base commit and record each failing test.
- At Zero P3 Validate, stop only on failures that the baseline doesn't list.
- Report the inherited failures in the build report.

Zero's entry cites a stop of about 5 hours caused by an inherited failure.

## Suggested Action

- At P0, run the suite on the base commit and record each failing test in `plan/current/`.
- At P4 Validate, stop only on failures missing from that record.
- Raise a Jira defect for each inherited failure (0000295).
- Record each inherited failure in the waiver register (0000287), so carrying it forward is a decision someone owns.

## Wanted outcome

P4 Validate stops on new failures and reports inherited ones. Tests check these conditions:

- A run whose only failures match the baseline passes P4 and lists them.
- A run with a failure missing from the baseline stops at P4.
- Each inherited failure has a Jira defect and a waiver register row.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It depends on the Jira workflow (0000295) and the waiver register (0000287).
