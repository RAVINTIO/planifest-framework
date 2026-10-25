---
title: "Backlog Entry: 0000240 - Use chore branches for work outside a feature"
summary: "The framework names only feat/ branches, so agents put backlog-only and other housekeeping changes on feat/ branches. Planifest Zero already uses chore/ branches and chore: PR titles for that work."
status: "open"
---
# Backlog Entry: 0000240 - Use chore branches for work outside a feature

**Source feature:** none. The agent found this during a housekeeping session after 0000038 shipped.
**Source phase:** none (no run active)
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

The framework names one branch prefix, `feat/`. Two instruction overrides depend on it:

- `planifest-overrides/instructions/custom-001-local-git-only.md` says to work on a `feat/` branch.
- `planifest-overrides/instructions/custom-004-file-backlog-entries-immediately.md` says to push a backlog entry to the current feature branch. It says nothing about where the entry goes when no feature branch is open.

On 2026-10-25 the agent filed and renumbered a backlog entry outside any run. It cut `feat/refile-backlog-0000047` and `feat/renumber-backlog-0000239`. The human on the loop expected `chore/` branches. Renaming the second branch on GitHub closed PR #67, so PR #68 had to replace it.

Planifest Zero already uses `chore/` for this work. Its PRs #15, #16, #22, #24, #26, and #28 came from branches such as `chore/backlog-0000150-faster-powershell-ci` and `chore/remove-stale-backlog-0000150`. Each PR title starts `chore:`. Zero's park command also cuts `chore/park-{feature-id}`.

No CI check reads branch names, so either prefix passes today.

## Suggested Action

Add a `chore/` rule for changes outside a feature run, matching Zero. It covers filing, removing, or renumbering backlog entries, and override or config edits. Use names like `chore/backlog-{id}-{slug}` and PR titles that start `chore:`. Update `custom-001` and `custom-004` so an agent with no open feature branch cuts a `chore/` branch from `main`.

Keep `feat/` for pipeline runs. The autonomous branch check in `planifest-framework/standards/autonomous-run-standards.md` and `planifest-framework/skills/planifest-ship-agent/SKILL.md` should still require `feat/`.

## Why Deferred

No feature run is active. The rule changes generated boot files, so it needs a run that can re-run setup and update the regression tests.
