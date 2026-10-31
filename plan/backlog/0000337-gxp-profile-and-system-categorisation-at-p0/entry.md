---
title: "Backlog Entry: 0000337 - GxP profile and system categorisation at P0"
summary: "A policy-driven GxP profile that records GxP impact, GAMP software category, and system boundary at P0, and scales later phases by category and risk."
status: "open"
---
# Backlog Entry: 0000337 - GxP profile and system categorisation at P0

**Source feature:** none (GAMP 5 gap analysis)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline
**Related:** 0000348, 0000279, 0000288

---

## Problem

Framework has no idea of GxP work. Nothing in `ravintio-framework/` mentions GAMP, GxP, or a validated state. P0 treats a lab data system and an internal dashboard the same way.

`ravintio-framework/standards/release-sizing.md` sizes releases in points against a budget. It has no software category and no risk class. A regulated team can't tell Framework that a Category 5 bespoke system needs more evidence than a Category 1 tool.

Every other GAMP entry needs this category and risk class to decide what it asks for. Without it, each entry would either apply to all work or invent its own trigger.

## Suggested Action

- Add a GxP profile that policy in `ravintio-overrides/` turns on. Build it on the compliance profile mechanism in 0000348, and protect the policy file through 0000288.
- When the profile is on, P0 records three facts in the feature brief or design:
  - GxP impact: yes or no, with a reason.
  - GAMP software category: 1, 3, 4, or 5.
  - System boundary: what is in scope and which interfaces cross it.
- Map category and risk class to the artefacts, reviews, and test depth that later phases require. Low-risk work gets less ceremony, in line with the critical thinking theme of GAMP 5 Second Edition.
- Keep the mapping in policy, so the regulated company sets it and the agent can't loosen it.

Framework produces evidence and never claims compliance. The regulated company's quality unit owns the validation decision.

## Wanted outcome

- With the profile off, P0 behaves as it does today.
- With the profile on, P0 refuses to confirm a design that lacks GxP impact, category, and boundary.
- A test shows that each category and risk class selects the artefact set the policy names.

## Open questions

- Should category live per component in `component.yml` as well as per feature?
- Check the GAMP 5 Second Edition category definitions against the source text at pickup.

## Why Deferred

The human asked for the GAMP 5 gap analysis findings to reach the backlog. This entry needs 0000348 first and its own design at P0.
