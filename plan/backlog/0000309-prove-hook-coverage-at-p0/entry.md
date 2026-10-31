---
title: "Backlog Entry: 0000309 - prove hook coverage at P0 with a canary write"
summary: "At P0, attempt a write the hooks must block, stop if it succeeds, and record the result as installation evidence."
status: "open"
---
# Backlog Entry: 0000309 - prove hook coverage at P0 with a canary write

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline
**Related:** 0000118, 0000317

---

## Context

A review of RAVINTIO Zero on 2026-10-31 found runs that assumed hooks were active without proof. Framework's controls depend on its hooks. If a hook doesn't run, the run carries on with no gate and no record of the gap.

## Problem

- **Codex hook trust.** Codex skips project hooks until a person trusts them with `/hooks`. Zero found this in step 14 of its initiative 0000195 (`zero/plan/retrospectives/0000195-backlog-clearance-initiative-2026-10-27.md` line 67).
- **Claims from docs.** In step 12, the agent said a guard was active in Codex. It based that on the docs alone (line 66 of that retrospective).
- **Partial tool support.** `shell-write-guard` runs only in Claude Code. Other tools have no `PreToolUse` hook for Bash, so shell writes there pass unchecked.
- **No proof at start.** The orchestrator skill has no step that tests whether a hook fires in the current session.

## Suggested Action

- At P0, attempt a canary write that a hook must block, for example a **Write** to a file under `hooks/enforcement/`.
- If the write succeeds, revert it, stop the run, and name the hook that didn't fire.
- Where the tool supports `PreToolUse` for Bash, also attempt a canary shell write.
- Record each canary result in the build log as installation evidence.
- Design the canary so it does no harm if the hook doesn't fire. For example, target a path that gate-write blocks but that holds no real file.

## Wanted outcome

No run starts work with an unproven hook. Tests check these conditions:

- P0 stops when the canary write succeeds.
- The build log holds one canary line per tested hook, with its result.
- A canary that the hook blocks leaves the working tree unchanged.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It changes P0 and needs a design for each supported tool.
