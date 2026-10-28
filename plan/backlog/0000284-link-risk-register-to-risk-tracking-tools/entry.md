---
title: "Backlog Entry: 0000284 - link the risk register to the organisation's risk tracking tool"
summary: "Raise, link, and update risks in the organisation's risk system, such as a Jira risk project or ServiceNow IRM, so risk acceptance stays with the named risk owner."
status: "open"
---
# Backlog Entry: 0000284 - link the risk register to the organisation's risk tracking tool

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-26

---

## Problem

P1 writes a risk register to `plan/current/` and P7 archives it. In a regulated organisation the risk register of record lives elsewhere, such as a Jira risk project, ServiceNow IRM, Archer, or a GRC tool. A risk named only in Framework's register never reaches the person who owns that risk. Framework can't accept a risk on anyone's behalf, and the strategy says it must not become a competing governance authority.

## Suggested Action

Through the 0000280 adapter contract:

1. At P1, read open risks linked to the affected system or component, and show them to the spec-agent and the design critic.
2. For each new risk the run finds, propose an entry for the risk tool with likelihood, impact, and proposed mitigation. Raise it only when the allowlist permits it.
3. Link each risk to the requirements, ADRs, and controls that mitigate it (0000285).
4. Before P9, check the status of each high or critical risk in the tool. If a risk needs acceptance and the tool records none, stop. A waiver goes through 0000287.
5. Keep the local risk register as the run's working copy, with each row naming its external risk ID.

## Wanted outcome

Each risk the run finds reaches the organisation's risk tool, or the run records why it didn't. A test proves that P9 stops when a high risk has no recorded acceptance.

## Why Deferred

Filed from the 0000279 differentiation review. It depends on 0000280 and links to 0000285 and 0000287.
