---
title: "Backlog Entry: 0000303 - guard git bypasses and agent merges"
summary: "Stop advising --no-verify, add a fail-closed Bash guard for git bypasses and merges, and make ship stage explicit paths."
status: "open"
---
# Backlog Entry: 0000303 - guard git bypasses and agent merges

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline (the new hook is an enforcement path)
**Related:** 0000238, 0000225, 0000276, 0000286

---

## Context

A review of the sibling repo RAVINTIO Zero on 2026-10-31 compared how each pack stops an agent from bypassing git controls. Framework targets regulated industries, such as those that follow GAMP 5. There, merging to `main` is a human approval, and a commit must pass its hooks.

## Problem

- **The pack advises a bypass.** These places tell the agent to use `git commit --no-verify`:
  - `ravintio-framework/hooks/commit-msg` lines 6 and 69
  - `templates/standard-boot.md` line 32
  - `standards/commit-standards.md` line 58

  The flag also skips the pre-commit and pre-push hooks, not only the message check.
- **Merging is prose only.** `standards/autonomous-run-standards.md` line 78 says merging a PR stays human-only. No hook enforces it.
- **No git guard.** No hook blocks force pushes, pushes to `main`, forced adds, or broad adds in agent sessions.
- **Ship stages whole folders.** `skills/ravintio-ship-agent/SKILL.md` line 155 runs `git add plan/current/ plan/_archive/ plan/changelog/ docs/about.md`. A folder add can sweep in files the step never meant to commit.

Zero's postmortem `zero/plan/postmortems/2026-10-31-step-6-forced-add-committed-driver-files.md` shows a forced add committing ignored files.

## Suggested Action

- Remove the `--no-verify` advice from all three places. Tell the agent to fix the message and stop if it can't.
- Add a PreToolUse Bash guard that blocks these commands:
  - `git commit --no-verify` and `git push --no-verify`
  - `git add -f` and `git add --force`
  - `git add -A` and `git add .` in agent sessions
  - `git push --force` and any push to `main`
  - `gh pr merge` and `gh api .../merge`
- Base the guard on Zero's `ravintio-zero/hooks/enforcement/merge-guard.mjs` (Zero 0000043 req-006 and Zero 0000197). It fails closed, never runs command text, and blocks input over 4096 characters. Drop its `initiative/*` exception, since Framework has no initiative branches.
- Make ship stage explicit paths. Ship fails when `git ls-files -ci --exclude-standard` lists a file.
- Under a regulated profile, run the guard in fail-closed mode.

## Wanted outcome

No pack text advises a hook bypass. An agent can't merge a PR, push to `main`, force a push, or stage ignored files.

## Open questions

- Can the guard tell an agent session from a human shell reliably on every supported tool?

## Why Deferred

The human asked for it on 2026-10-31. It adds an enforcement hook and changes the ship skill, so it needs the Change Pipeline.
