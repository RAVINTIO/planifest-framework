---
title: "Backlog Entry: 0000192 - credential guard misses mid-run commits and the PR body"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000192 - credential guard misses mid-run commits and the PR body

**Source feature:** none (human request, mirrors Planifest Zero 0000042 security findings F-003 and F-004)
**Source phase:** none (outside a pipeline run)
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-23

---

## Problem

In `autonomous`, a credential can reach the remote before any guard runs. Two paths have no check:

- **Mid-run commits.** The P8 credential guard in `planifest-framework/skills/planifest-ship-agent/SKILL.md` checks only P8 leftovers under `plan/`, `docs/`, and `src/**/docs/`. The P1 to P6 commits get no check, and neither do the commits under `src/`. The orchestrator push cadence (`skills/planifest-orchestrator/SKILL.md`, Hard Limit 7) pushes after each phase-gate commit where a push is authorised. Exception-list item 7 in `standards/autonomous-run-standards.md` says the run "stops using" a sighted credential and finishes other work. It doesn't stop the commit or the push of the file that holds it.
- **The PR body.** Step 10 passes the PR description to `gh pr create` with no scan. The description lists every `Exception waiting` line and a `## Security` section. Neither has a rule that keeps raw output, environment values, or file contents out of it.

Planifest Zero fixed both in 0000042 (REQ-011). It added a credential exception stop that fires before the commit and before any push. It also scans the PR body before `gh pr create`, and limits evidence to results and `file:line` cites.

## Suggested Action

Run the P8 credential patterns and `gitleaks` over every staged file before each `autonomous` commit, and hold back the push when one matches. Scan the PR description with the same patterns before `gh pr create`, and state that PR text cites paths, never raw output.

## Why Deferred

The gap was found while fixing the matching findings in Planifest Zero. It needs its own Framework design pass, because item 7 lets the run carry on rather than stop.
