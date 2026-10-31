---
title: "Backlog Entry: 0000313 - run resume detection as a script"
summary: "Move the orchestrator's prose resume checks into a read-only script that the session-start hook runs."
status: "open"
---
# Backlog Entry: 0000313 - run resume detection as a script

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline. The change touches a hook.
**Related:** 0000020, 0000236

---

## Context

A review of RAVINTIO Zero on 2026-10-31 compared how each pack resumes an interrupted run. A resume that misreads state can repeat or skip a phase. A script gives the same result every time and leaves a record.

## Problem

- **Prose checks.** Resume detection lives in prose in `skills/ravintio-orchestrator/SKILL.md` (`## Resume Detection`, from line 61). It has eight numbered steps, and several hold sub-checks. The agent runs each one by reading files.
- **Hook defers to prose.** `hooks/enforcement/auto-trigger-orchestrator.mjs` (line 49) only says "Begin with resume detection as described in the skill".
- **No failure signal.** If the agent skips a check, nothing shows it. A skipped check reads the same as a clean one.

## Zero's fix

Zero commit 64d2348 (feature 0000243) added `scripts/resume-detect.mjs`:

- It prints one fixed line per signal, in check order.
- It never prints repo text, so file content can't steer the agent.
- The session-start hook runs it with a 2-second timeout.
- A missing script, a non-zero exit, or a timeout prints "resume detection did not run". A failed run never reads as clean.

## Suggested Action

- Add a read-only `resume-detect.mjs` that covers every check in `## Resume Detection`.
- Have `auto-trigger-orchestrator.mjs` run it with a timeout and pass its output to the agent.
- Print a fixed failure line when the script doesn't complete.
- Fit the script with `scripts/run-mode.mjs` rather than repeating its logic.
- Cover the archive evidence rule from 0000032 req-002, which resumes an interrupted close-out at P8 or the P9 marker step.
- Cut the skill's prose to a description of each output line.

## Wanted outcome

Every session start shows the same resume findings for the same repo state. Tests check these conditions:

- Each resume signal prints its fixed line, in check order.
- The script prints no text read from repo files.
- A script that fails or times out gives "resume detection did not run".

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It changes a hook and the orchestrator skill, so it needs its own design.
