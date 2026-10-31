---
title: "Backlog Entry: 0000329 - setup target safety for agents"
summary: "Stop dispatched agents and tests from running setup against the real repo by mistake, through a dispatch warning and a copied pack or explicit target."
status: "open"
---
# Backlog Entry: 0000329 - setup target safety for agents

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Change Pipeline
**Related:** 0000293

---

## Problem

`ravintio-framework/setup.sh` (line 15) sets `PROJECT_ROOT` from its own location. It installs into the folder above the pack, whatever the caller meant.

An agent that tests setup can install into the real repo by mistake. That run rewrites boot files and hook wiring outside any plan. In a regulated repo, it changes controls with no record or approval.

RAVINTIO Zero hit this in build 0000164. Zero retro 0000217 (line 24) records it in these words:

> `setup.sh` installed into this repo on the first attempt, because it takes its project root from its own location.

The run removed the stray files by hand.

`ravintio-framework/standards/agent-dispatch-standards.md` gives dispatched agents no warning about this.

## Suggested Action

- Add a warning to `agent-dispatch-standards.md`. A dispatched agent never runs setup against the repo it works in, unless the human asked for that.
- Require tests to run setup only from a copy of the pack in a temporary folder.
- Or add an explicit target, such as `--target {dir}`, and refuse to run when an agent session calls setup without it. Choose between the two at pickup.
- Make the same change in `setup.ps1`.

## Wanted outcome

- No test in `ravintio-framework/tests/` runs setup against the working repo.
- The dispatch standard names the risk and the safe pattern.
- If the explicit target wins, setup without a target in an agent session exits non-zero and changes nothing.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. The choice between a copied pack and an explicit target needs its own decision.
