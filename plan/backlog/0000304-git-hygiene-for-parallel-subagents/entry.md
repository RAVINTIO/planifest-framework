---
title: "Backlog Entry: 0000304 - git hygiene for parallel subagents"
summary: "Set rules so parallel subagents never change git state, the dispatcher alone commits, and a progress marker lets a resume find unfinished units."
status: "open"
---
# Backlog Entry: 0000304 - git hygiene for parallel subagents

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline
**Related:** 0000238, 0000225, 0000267

---

## Context

A review of the sibling repo RAVINTIO Zero on 2026-10-31 compared each pack's rules for subagents that share one working tree. Framework targets regulated industries, such as those that follow GAMP 5. There, every change must trace to the unit that made it, and no agent may lose another's work.

## Problem

`ravintio-framework/standards/agent-dispatch-standards.md` line 94 says stream subagents don't commit, and the orchestrator commits for them. That rule covers streams only. The standard has no rule on these actions for any parallel subagent:

- `git stash`, `git checkout`, and `git reset`
- `git add -A`
- a held `index.lock`
- a progress marker before each unit

Parallel TDD subagents at P3 fall under the commit cadence in `skills/ravintio-codegen-agent/SKILL.md` line 212. That section names no single committer.

Zero hit these gaps. A Zero P2 Implement subagent ran `git stash` and took its siblings' edits for a time. The sources are:

- `zero/plan/retrospectives/0000195-backlog-clearance-initiative-2026-10-27.md`
- Zero archive `0000200-reply-conventions-2026-10-27`
- Zero archive `0000247-git-state-hygiene-2026-10-28` and its test `test-0000247-req-003-no-stash-in-batch.sh`

## Suggested Action

Add these rules to `agent-dispatch-standards.md`, and point the codegen commit cadence at them:

- A parallel subagent never changes git state. That rules out stash, checkout, reset, commit, and add.
- The dispatcher is the only committer.
- The dispatcher stages by path, never with `git add -A` or `git add .`.
- If `index.lock` exists, the dispatcher waits and retries rather than deleting it.
- Before each unit, the dispatcher commits a line `- In progress: {unit} ({timestamp})`, so a resume finds the unfinished unit.

Zero made these changes in commit `2259559` (0000172) and commit `3260b73` (0000247).

## Wanted outcome

Parallel subagents never disturb each other's work. Every commit comes from the dispatcher. A resumed run knows which unit was in progress.

## Why Deferred

The human asked for it on 2026-10-31. It changes a standard and the codegen skill, so it needs the Change Pipeline.
