---
title: "Backlog Entry: 0000279 - differentiate RAVINTIO Framework for regulated environments"
summary: "Umbrella review: the backlog makes Framework a heavier Zero, not a product for regulated, multi-team, or traceability-heavy work. Lists every recommendation and the entries that carry it."
status: "open"
---
# Backlog Entry: 0000279 - differentiate RAVINTIO Framework for regulated environments

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-26

---

## Problem

The RAVINTIO technical strategy (shared by the human on the loop on 2026-10-26) gives Zero and Framework different jobs:

- **Zero:** lightweight autonomous delivery with essential governance. Its question is "How can we build this with minimal ceremony?"
- **Framework:** structured autonomous engineering that fits more complex governance layers. Its question is "How can we work within established governance requirements?"

The strategy says Framework isn't "Zero with more power". Both aim for high autonomy. The difference is the depth and explicitness of governance. Framework owns these concerns:

- traceable requirements
- architectural boundaries, ADRs, and component ownership
- threat modelling
- formal risk handling, approvals, and exception management
- rich engineering evidence

Framework doesn't replace CI/CD, test tools, scanners, work trackers, or the organisation's own governance. It integrates with them and uses their outputs as evidence. It must not become a competing governance authority.

A review of the backlog on 2026-10-26 found 132 open entries that sort roughly like this:

| Theme | About | Fit with the strategy |
|---|---|---|
| Hook and shell-guard hardening | 40 | Mixed. The heuristic keeps opening new edge cases. |
| Setup, install, and Windows CI | 40 | Neutral. Both products need it. |
| Pipeline flow and autonomy | 20 | Fits. Governance must not cause needless interruptions. |
| Ports from Zero | 8 | Some pull Framework towards Zero. |
| Work for another RAVINTIO repo | 5 | Out of Framework's scope. |
| Regulated-environment governance | 0 | The gap. |

## Suggested Action

Work through the recommendations below. Each one names the entries that carry it.

### 1. Review the Zero ports before pickup

- 0000190: keep the phase-name prefixes and the product-naming fix. Don't merge `continuous` into Zero's two modes until 0000286 and 0000288 settle which approval points a regulated team must be able to set.
- 0000244, 0000245, and 0000274: an unattended roadmap chain needs a traceable approval record per step and per artefact (0000286). It also needs evidence each step can export (0000290).
- 0000268: keep it and raise its priority. Gherkin criteria are the base of requirement-to-evidence tracing (0000283, 0000285).
- 0000263 and 0000240: keep them. They are infrastructure and don't affect positioning.

### 2. Move work that belongs to other RAVINTIO products

- 0000085 (blameless post-mortem): RAVINTIO Insight, incident review support.
- 0000097 (workflow quality gates): RAVINTIO Insight, "AI workflow" dimension. Skill scoring belongs to RAVINTIO Qualify.
- 0000048 (loop designer): RAVINTIO Qualify, for evaluating the loops it designs.
- 0000023 (baseline comparison): RAVINTIO Unbound, governed and ungoverned comparisons, with Insight as the independent assessor.

### 3. Stop building scanners

The strategy says Framework doesn't own security scanners. Entries 0000216, 0000217, and 0000253 keep growing `ravintio-framework/scripts/credential-scan.mjs`. Make an external scanner the main path, such as gitleaks or the organisation's own tool, through 0000281. Keep the built-in patterns as a minimal fallback.

### 4. Settle the shell guard before more guard fixes

Decide 0000119 first. Entries 0000225 and 0000238 show that subagents get past Hard Limit 8 in practice. An auditor won't accept a heuristic as a preventive control. Choose one of these:

- Enforce writes through tool permissions or a sandbox, so the control is preventive.
- Reclassify the guard as a detective control, backed by the audit trail in 0000289.

Most hook entries depend on that choice, including 0000105, 0000108, 0000115, 0000116, 0000144, and 0000225.

### 5. Raise entries that protect evidence integrity

These entries matter more under audit than their severity suggests:

- 0000141: any agent can write a migration record.
- 0000179: `.gitattributes` can hide changes to enforcement files from review.
- 0000180: setup installs arriving files before anyone confirms where they came from.
- 0000187: a linked `plan/` folder can serve a `design.md` from outside the repository.
- 0000227: loop-state timestamps that an agent estimated.
- 0000276: AI attribution slipping into commits and PRs.
- 0000025: the adoption position. State Framework's audience next to Zero's.

### 6. Build the missing capabilities

Integration with external tooling:

- 0000280: one adapter contract for every external tool.
- 0000281: take CI/CD, test, and scanner results as gate evidence.
- 0000282: link runs to work-tracking and change-record systems, such as Jira.
- 0000283: link acceptance criteria to test case management tools.
- 0000284: link the risk register to the organisation's risk tracking tool.

Governance inside Framework:

- 0000285: map requirements to the organisation's controls.
- 0000286: attributable approvals and separation of duties.
- 0000287: an exception and waiver register.
- 0000288: protect policy configuration from agent changes.
- 0000289: a tamper-evident audit trail.
- 0000290: export evidence in the shared RAVINTIO schemas.
- 0000291: data classification and privacy triggers.

### 7. Keep the autonomy work

Entries 0000076, 0000078, 0000103, 0000104, 0000266, and 0000267 cut needless prompts and speed up runs. The strategy wants that. Framework's approvals should come from policy, not from habit.

## Wanted outcome

A reader can name what Framework does that Zero doesn't, from the README and the backlog alone. Every entry listed here carries a note that points back to this review.

## Why Deferred

The human asked for the review and for every recommendation to reach the backlog. Each capability needs its own design at P0.
