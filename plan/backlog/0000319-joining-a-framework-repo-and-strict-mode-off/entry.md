---
title: "Backlog Entry: 0000319 - joining a Framework repo, and turning strict mode off"
summary: "Document setup after a clone, warn at session start when setup wired no hooks, and remove the strict-mode marker when setup runs without the strict flag."
status: "open"
---
# Backlog Entry: 0000319 - joining a Framework repo, and turning strict mode off

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Change Pipeline
**Related:** 0000309

---

## Problem

Two gaps let developers on one repo run under different controls.

**Joining after a clone.** Setup writes hook wiring into tool folders. Git often ignores those folders. This repo's `.gitignore` lists `.claude/` and `CLAUDE.md`, for example. A developer who clones a Framework repo gets the pack but may get no wired hooks. `ravintio-framework/getting-started.md` doesn't describe this case. Nothing warns the developer at session start. The orchestrator can't load through the `auto-trigger-orchestrator` hook if that hook isn't wired.

**Setup can't turn strict mode off.** `setup.sh` (line 1396) creates `plan/.orchestrator-strict` when you pass `--strict-orchestrator`. `setup.ps1` (line 1548) does the same. No code removes the marker when a later run leaves the flag out. `ravintio-refresh-setup` (line 67) also reads the marker as proof of the flag and passes it again. Strict mode then stays on.

RAVINTIO Zero backlog 0000291 covers the same two gaps.

## Suggested Action

1. Add a "Join an existing Framework repo" section to `getting-started.md`. Tell the developer to run setup for their tool after the clone.
2. At session start, have the orchestrator check the tool's hook wiring. If it finds none, warn the developer and name the setup command. Tools without hook support read the orchestrator directly, so the check works there too.
3. In `setup.sh` and `setup.ps1`, remove `plan/.orchestrator-strict` when a run leaves out `--strict-orchestrator`. Print a line that says strict mode is off.

## Wanted outcome

- A fresh clone with no wiring produces a session-start warning.
- A setup run without `--strict-orchestrator` leaves no `plan/.orchestrator-strict`.
- `setup.sh` and `setup.ps1` behave the same.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It touches setup and the orchestrator, so it needs its own run.
