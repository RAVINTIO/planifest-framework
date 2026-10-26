---
title: "Backlog Entry: 0000274 - move roadmap decisions to chart time"
summary: "A human-requested capability, filed for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000274 - move roadmap decisions to chart time

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-25

---

> Lessons from RAVINTIO Zero roadmap 0000168. Apply them when 0000244 and 0000245 port the roadmap.

## Problem

RAVINTIO Zero roadmap 0000168 needed human decisions mid-run that the chart could have taken up front. Step 3 alone stopped for four:

- profile on Windows after CI missed the speed target
- widen scope to drop skill bundling on every platform
- raise the bump from patch to minor because of the wider scope
- measure the speed target per case, because the step's own new tests counted against a fixed total and runner noise exceeded the margin

Step 1 also failed in CI on a PowerShell bug that P3 passed locally, because the machine had no `pwsh`.

Zero's roadmap already pre-approves schema changes at chart time. No other decision gets the same treatment.

## Suggested Action

Extend chart-time approval to the decisions that stopped roadmap 0000168:

- **Pre-mortem per step.** At chart time, ask what would stop each step. Record each likely fork in a decision table in the roadmap, with its pre-approved answer. A step applies a matching answer, records it in the build log, and stops only for a fork the table doesn't cover.
- **Baseline before a performance target.** A measurable speed or size target needs a profile taken at chart time, showing where the cost goes. The target and the planned fix both come from that profile.
- **Criterion critic.** A critic checks each measurable criterion at chart time. It asks whether the step changes what the criterion measures, such as a total that grows with new tests. It also asks how noisy the measure is across runs, and whether the margin covers that noise.
- **Pre-approved fallbacks.** Each step may list scope it can add if its target is missed, for example "may also change `setup.sh`".
- **Bump rule.** Each step states how its bump changes with scope, for example "rises to minor if the fallback scope is used".
- **Environment check.** Chart checks the local tools each step's tests need. Criteria that only CI can check get marked, and the step counts as validated only after its first CI run.
- **Retrospective input.** Charting reads the latest post-roadmap retrospective, so each past stop becomes a pre-decision next time.

## Wanted outcome

A charted roadmap holds a decision table, a baseline for each performance target, and a bump rule per step. A step that hits a forecast fork applies the pre-approved answer without stopping. Replaying roadmap 0000168's step 3 stops against the new chart would need no human decision.

## Positioning note (2026-10-26)

The 0000279 differentiation review flags this entry with 0000244 and 0000245. A pre-approved answer in a decision table is an approval given in advance. In Framework, record each one as an attributable approval (0000286). If an answer relaxes a gate or control, record it as a waiver (0000287).

## Why Deferred

The human asked for it after RAVINTIO Zero roadmap 0000168 delivered. It pairs with 0000244 (chart), 0000245 (run and supervision), and 0000269 (retrospectives). Zero backlog 0000186 holds the same entry.
