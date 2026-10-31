---
title: "Backlog Entry: 0000312 - check build log integrity with a script"
summary: "Add a read-only script that fails an incomplete or inconsistent build log before archive."
status: "open"
---
# Backlog Entry: 0000312 - check build log integrity with a script

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline. A read-only check needs no sanction. If the script writes files, Hard Limit 8 must sanction it first.
**Related:** 0000097, 0000227, 0000289

---

## Context

A review of RAVINTIO Zero on 2026-10-31 compared how each pack checks its build log. The build log is Framework's record of what each phase did and when. ALCOA+ expects that record to be complete and contemporaneous.

## Problem

- **No script checks the log.** No script under `scripts/` checks `plan/current/build-log.md` for completeness. `run-mode.mjs` reads only the `Run mode` row.
- **Prose rules only.** The ship skill tells the agent to fill `End`, `Wall-clock`, and `Agents spawned` for P7, P8, and P9 (`skills/ravintio-ship-agent/SKILL.md` lines 49, 177, and 231). Nothing checks that it did.
- **Audit by reading.** The P8 assessor checks the per-phase fields by reading them (`skills/ravintio-build-assessment-agent/SKILL.md` line 130). An agent's reading can miss a gap or accept an estimate.

## Zero's fix

Zero's `ravintio-zero/scripts/build-log-check.mjs` (commit 9ac2aad, archive 0000248) runs before archive. It fails a log that has any of these faults:

- A blank Start, End, or Wall clock in a phase block.
- A Wall clock more than one minute away from End minus Start.
- A missing phase block with no `Skipped: P{n}` line.
- A blank or "not recorded" total wall clock.

## Suggested Action

- Add a read-only `build-log-check.mjs` that covers Zero's four checks for Framework's P0 to P9.
- Also reject these faults:
  - A time later than the commit that recorded it, or later than now.
  - A phase that opens and never closes.
  - Summary counts that disagree with the phase rows.
- Run the same checks on each `plan/current/loop-state-*.md` file.
- Run the script in the ship skill before P7 archives, and stop on any finding.
- Have the P8 assessor report the script's output instead of auditing fields by reading.

## Wanted outcome

No run archives an incomplete or inconsistent build log. Tests check these conditions:

- A log with a blank End in any phase fails.
- A log whose Wall clock disagrees with End minus Start by more than one minute fails.
- A log with a time later than its commit time fails.
- A loop-state file with an unclosed loop fails.
- A complete log passes.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It adds a new script and a gate in the ship skill.
