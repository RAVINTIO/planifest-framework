---
title: "Backlog Entry: 0000245 - Roadmap run, advance, and delivery"
summary: "Port RAVINTIO Zero's roadmap driver, R-B to R-E stages, and merge-guard hook, so a charted roadmap runs unattended to one PR."
status: "open"
---
# Backlog Entry: 0000245 - Roadmap run, advance, and delivery

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-25

> Replaces 0000096 (multi-release initiative run). The human on the loop asked for the design that RAVINTIO Zero built instead.

---

## Problem

A framework run delivers one feature in one release. A chain of related features needs the human on the loop to start every run. After P9 the orchestrator requires a context clear, so nothing carries the chain across sessions. An `autonomous` run reaches a PR, but a multi-release plan still waits on a human at each release.

RAVINTIO Zero solved this in feature 0000043 (v0.10.0, PR #21 in `RAVINTIO/ravintio-zero`). This entry ports its run half. 0000244 ports the chart half.

## Suggested Action

Port these parts of the Zero design. Each step runs the framework's full P0 to P9 pipeline, not Zero's P0 to P4.

- **R-B Activate.** Cut `roadmap/{id}-{slug}` and write `plan/current-roadmap/roadmap.md`. Refuse if no remote exists, if `gh` access fails, or if a roadmap is already active.
- **R-C Run.** Run one step on its own feature branch through P0 to P9.
- **R-D Advance.** The ship agent owns this stage.
  1. Update the step row, clear the session markers, and push before it raises the PR. The markers then don't reach the roadmap branch.
  2. Raise the step PR against the roadmap branch.
  3. Wait for at least one check, then for green CI.
  4. Squash-merge with `--delete-branch`.
  5. Tag the PR's merge commit, not the branch tip.
- **R-E Delivery.** Archive `plan/current-roadmap/` to `plan/_archive/{id}-{slug}-roadmap-{date}/`. Raise one PR from the roadmap branch to `main`. Its body asks the human on the loop for a merge commit, so each step tag stays reachable from `main`.
- **Driver script.** Add a Node driver like `roadmap-run.mjs`. It runs each step in a fresh `claude -p` session, holds a lock, and stops on a block or a position that doesn't advance. Port the hardened version from Zero `main`. It writes each child session's output to `plan/.roadmap-logs/step-{position}.log` and refuses symlinked log paths.
- **`merge-guard` hook.** Add a Bash `PreToolUse` hook that blocks every `gh pr merge` unless it squash-merges into a `roadmap/*` base. It fails closed when it can't read the base. Wire it in `setup.sh` and `setup.ps1`.
- **Resume.** Each dispatched unit logs `In progress:` before it starts and `Done:` after. A restarted driver resumes the same step and reruns an interrupted unit from its start.
- **Telemetry labels.** Add the roadmap id, slug, and position to `OTEL_RESOURCE_ATTRIBUTES` per step, as Zero's `roadmap-labels.mjs` does.
- **CI trigger.** The framework workflow must trigger on pull requests to `roadmap/**`.

Decide one fork at P0. The framework's `CLAUDE.md` and ship rules make every merge human-only. The roadmap needs the agent to squash-merge step PRs into `roadmap/*`. Zero amended its merge rule for this in 0000043 ADR-003, and merging to `main` stayed human-only.

Sources in `RAVINTIO/ravintio-zero` on `main`:

- `ravintio-zero/standards/roadmap-standards.md`, sections "R-B Activate" to "R-E Delivery"
- `ravintio-zero/scripts/roadmap-run.mjs` and `ravintio-zero/scripts/roadmap-labels.mjs`
- `ravintio-zero/hooks/enforcement/merge-guard.mjs`
- `plan/_archive/0000043-autonomous-roadmaps-2026-10-24/`, ADR-003 to ADR-005 and ADR-007, plus `verification-report.md` for the four faults the live run found

## Why Deferred

Filed on request of the human on the loop during triage for 0000039. It changes the merge rule and adds an enforcement hook, so it needs its own design and ADRs.
