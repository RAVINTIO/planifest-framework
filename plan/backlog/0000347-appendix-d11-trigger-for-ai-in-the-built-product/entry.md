---
title: "Backlog Entry: 0000347 - Appendix D11 trigger for AI in the built product"
summary: "Flag an ML or LLM component at P0 and require data provenance, evaluation, drift, and oversight artefacts at P1."
status: "open"
---
# Backlog Entry: 0000347 - Appendix D11 trigger for AI in the built product

**Source feature:** none (GAMP 5 gap analysis)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline
**Related:** 0000337, 0000344

---

## Problem

This entry concerns AI inside the product that Framework builds, not the agent that builds it. 0000344 covers the agent.

A GxP system that includes a machine learning model or an LLM needs extra evidence. GAMP 5 Second Edition Appendix D11 and the ISPE GAMP AI Guide describe it. Check both against the source text at pickup, since the gap analysis used general knowledge.

Framework doesn't notice when a design includes an AI component. P1 writes the same artefacts for a rules engine and for a classifier trained on patient data. Nothing asks where training data came from, how the model performs, or who can override it.

## Suggested Action

- When the GxP profile in 0000337 is on, P0 flags any ML or LLM component in the design.
- For a flagged component, P1 requires artefacts that cover:
  - data provenance and data quality
  - training and evaluation method
  - acceptance metrics and thresholds
  - drift monitoring in operation
  - human oversight and override
- Note that the EU AI Act applies only when the product is a high-risk AI system. P0 records that judgement and the reason for it.

Framework produces evidence and never claims compliance. The regulated company's quality unit decides whether the AI component is fit for its intended use.

## Wanted outcome

- A design with an ML or LLM component can't pass P1 under the profile without the five artefacts.
- A design with no AI component sees no change.
- P0 records the EU AI Act judgement for every flagged component.

## Open questions

- Should drift monitoring link to `ravintio-framework/templates/operational-model.template.md`?
- How should P0 detect an AI component: by human answer, or by scanning dependencies?

## Why Deferred

The human asked for the GAMP 5 gap analysis findings to reach the backlog. It depends on 0000337 and needs its own design.
