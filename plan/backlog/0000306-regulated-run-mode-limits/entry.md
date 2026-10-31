---
title: "Backlog Entry: 0000306 - limit run modes under a regulated profile"
summary: "continuous skips human gates with checkers off, and autonomous turns questions into decisions and caps into new approaches. A regulated profile needs tighter limits."
status: "open"
---
# Backlog Entry: 0000306 - limit run modes under a regulated profile

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline
**Related:** 0000190, 0000078, 0000273, 0000286, 0000288

---

## Context

A review of the sibling repo RAVINTIO Zero on 2026-10-31 compared each pack's run modes. Framework targets regulated industries, such as those that follow GAMP 5. There, a human approves each phase output, and an agent stops when it can't solve a problem.

## Problem

**`continuous`** removes human gates without adding checks:

- It skips the P1 to P6 human gates (`skills/ravintio-orchestrator/SKILL.md` lines 269 and 280 to 282).
- Outside `autonomous`, checker loops default to off, and the design critic only reports (`skills/ravintio-loop-runner/SKILL.md` lines 27 and 41).
- It has no git anchor. `scripts/run-mode.mjs` (lines 18 and 19) prints `continuous` as read from the file, so any write to `plan/.run-mode` sets it.

**`autonomous`** replaces stops with decisions (`standards/autonomous-run-standards.md`):

- A question that isn't on the exception list becomes a recorded decision (line 62).
- A cap starts a new approach rather than a stop (lines 157 to 165). Each loop allows 3 approaches, so P4 allows up to 15 attempts. The boot escalation rule says 5.

In 0000273, agents ignored the script's `interactive` output and carried on in the earlier mode.

## Suggested Action

Under a regulated profile:

- Disable `continuous`, or force every checker loop on when it runs.
- Allow `autonomous` only where the policy permits it. Never let it stand in for a human-only approval.
- Give `continuous` a git anchor, as `autonomous` has.
- Cap approaches at 1, so P4 stops after 5 attempts as the boot rule says.

## Wanted outcome

No run mode removes a human gate or a checker without an explicit policy that permits it. A regulated run stops at the boot escalation limit.

## Open questions

- Where does the regulated profile live, and who may set it? 0000288 may answer this.
- Which phase gates does a regulated policy treat as human-only in every mode?

## Why Deferred

The human asked for it on 2026-10-31. It changes run-mode behaviour across several skills, so it needs its own design.
