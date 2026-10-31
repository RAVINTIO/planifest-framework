---
title: "Backlog Entry: 0000339 - GxP quality risk assessment and risk-based test depth"
summary: "Extend the risk register with ICH Q9 fields and a risk class per requirement that sets minimum test types and independent review."
status: "open"
---
# Backlog Entry: 0000339 - GxP quality risk assessment and risk-based test depth

**Source feature:** none (GAMP 5 gap analysis)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline
**Related:** 0000284, 0000350, 0000337

---

## Problem

`ravintio-framework/templates/risk-register.template.md` records category, likelihood, impact, and mitigation. It measures delivery risk. It has no fields for the harms a GxP risk assessment must weigh:

- patient safety
- product quality
- data integrity

It also lacks the severity, probability, and detectability scales that ICH Q9 risk methods often use. No field gives a resulting risk class.

Test depth doesn't follow risk today. A requirement that could corrupt a batch record gets the same test types as a label change. Nothing says when a human or an independent tester must run or review the tests.

## Suggested Action

- When the GxP profile in 0000337 is on, add these columns to the risk register:
  - patient safety, product quality, and data integrity impact
  - severity, probability, and detectability
  - resulting risk class
- Give each requirement a risk class.
- Map each risk class to minimum test types, such as unit, integration, and execution.
- Map each risk class to the review it needs: agent only, human review, or independent tester.
- Keep the mapping in policy, so the regulated company sets it.
- Sync the register with the organisation's risk tool through 0000284.

Framework produces evidence and never claims compliance. The regulated company's quality unit owns the risk acceptance.

## Wanted outcome

- With the profile off, the register stays as it is.
- With the profile on, `ravintio-framework/scripts/consistency-check.mjs` fails a requirement that lacks a risk class.
- A requirement's tests meet the minimum types for its class, and a check reports any gap.

## Open questions

- Should risk class roll up from the risk register, or sit on the requirement file?
- How does this relate to the risk scoring in 0000350?

## Why Deferred

The human asked for the GAMP 5 gap analysis findings to reach the backlog. It depends on 0000337 and needs a design for the class mapping.
