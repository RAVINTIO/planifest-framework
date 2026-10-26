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

### Supervision and driver fixes

Zero's roadmap 0000168 run showed gaps in its own driver design. Zero backlog entry 0000182 holds the full detail. Build these into the port rather than copying the gaps:

- **Supervisor mode.** The session that starts the driver runs as the orchestrator in a supervisor mode. Resume detection skips `plan/current/` while the driver holds its lock, so the supervisor never resumes the child's step. The supervisor doesn't edit the working tree.
- **Separate acks.** Strict mode accepts a supervisor ack beside the child's ack, for example `plan/.orchestrator-supervisor`. Neither session overwrites the other, and the strict-mode banner stays quiet in both.
- **Start from R-B Activate.** The orchestrator starts the driver in supervisor mode, rather than offering it as a separate step.
- **Progress report on request and at each phase end.** It has two parts:
  - **Roadmap:** steps merged out of the total, and backlog entries done out of the total, with a table of each step's feature, entries, version, and status.
  - **Current step:** the phase, progress within it (units done out of planned, and criteria verified out of total once validation starts), and what comes next. Add highlights: what the step changes for the user, and any risk, such as criteria verified only by text search.
- **Heartbeat.** Report at least once every 5 minutes while the driver runs. Each heartbeat names:
  - the step and its phase
  - the last build log line and the time it was written
  - the commits since the last heartbeat
  - whether the driver process is still running
  - any stop

  If nothing changed, say so and give the time since the last change.
- **Immediate events.** Report at once when the build log gains a phase `Complete:`, a `Blocked:`, or a `Resolved:` line.
- **Monitor.** In Claude Code, a read-only background monitor does this. It checks every 30 seconds and prints one line per event and one heartbeat every 5 minutes. A monitor expires after 30 minutes, so the supervisor starts a new one each time until the driver exits.
- **Stale build log.** If the child keeps committing but its build log hasn't changed for 15 minutes, flag it in the report.
- **Final report.** When the driver exits, report each step's version and tag, any `Blocked:` stop with its build log line, and the roadmap PR URL.
- **Prefixes.** Supervisor messages use `R-C Run:` while steps run and `R-E Delivery:` for the final report.
- **Backlog filing during a step.** Entries the supervisor files wait outside the working tree, then land on the roadmap branch after the step merges. Allocate each id against every branch, so two sessions can't take the same id.
- **Driver fixes.** Zero's driver had three bugs. Avoid them in the port:
  1. Read the newest archived build log as well as `plan/current/build-log.md`, and stop on an unresolved `Blocked:` line in either. Zero's driver missed a stop that ship wrote after archiving.
  2. Mark a step `merged` and move `position` only after the merge commit exists.
  3. Set `CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0` in each child's environment, unless the human has set it. Without it, a `claude -p` child stops its background subagents after 10 minutes.

A test runs the driver with a stub child and checks that the supervisor report names each step. Further tests cover each driver fix.

Decide one fork at P0. The framework's `CLAUDE.md` and ship rules make every merge human-only. The roadmap needs the agent to squash-merge step PRs into `roadmap/*`. Zero amended its merge rule for this in 0000043 ADR-003, and merging to `main` stayed human-only.

Decide one more fork at P0. Should one orchestrator skill run both the roadmap workflow and the feature pipeline, or should they split into two skills?

- **One skill.** The orchestrator keeps the R-A to R-E stages and adds supervisor mode. It keeps one entry point, and the auto-trigger hook needs no change. The cost is a larger skill with two resume paths. Resume detection must also tell a supervisor from a step session.
- **Two skills.** A roadmap skill owns charting, the driver, supervision, progress reports, and governance across steps. The orchestrator keeps one feature run, P0 onwards. Each session then loads one skill with one resume path and its own ack. The cost is a second entry point. The auto-trigger hook must also pick the right skill, and the shared hard limits must stay in step across both.

The recommendation is two skills. The supervisor and the step session differ in resume detection, ack, prefixes, and reporting duty. A split keeps the orchestrator to one run, and gives roadmap reporting and governance one owner.

Sources in `RAVINTIO/ravintio-zero` on `main`:

- `ravintio-zero/standards/roadmap-standards.md`, sections "R-B Activate" to "R-E Delivery"
- `ravintio-zero/scripts/roadmap-run.mjs` and `ravintio-zero/scripts/roadmap-labels.mjs`
- `ravintio-zero/hooks/enforcement/merge-guard.mjs`
- `plan/_archive/0000043-autonomous-roadmaps-2026-10-24/`, ADR-003 to ADR-005 and ADR-007, plus `verification-report.md` for the four faults the live run found

## Positioning note (2026-10-26)

The 0000279 differentiation review flags this port. An unattended run to one PR suits Zero. Framework must also keep separation of duties and a change record per release. The agent squash-merging step PRs needs an approval record a team can audit (0000286). Each step's release may also need an approved change record (0000282). Settle both before the merge-rule fork at P0.

## Why Deferred

Filed on request of the human on the loop during triage for 0000039. It changes the merge rule and adds an enforcement hook, so it needs its own design and ADRs.
