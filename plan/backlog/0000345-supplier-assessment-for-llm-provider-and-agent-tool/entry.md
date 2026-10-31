---
title: "Backlog Entry: 0000345 - supplier assessment for the LLM provider and agent tool"
summary: "A supplier assessment template for the model provider and agent tool, with generated code treated as Category 5 bespoke output."
status: "open"
---
# Backlog Entry: 0000345 - supplier assessment for the LLM provider and agent tool

**Source feature:** none (GAMP 5 gap analysis)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline
**Related:** 0000344, 0000349

---

## Problem

GAMP 5 expects a regulated company to assess each supplier whose product affects a GxP system. A team that uses Framework depends on two suppliers it doesn't control:

- the LLM provider
- the agent tool that runs the pipeline, such as Claude Code or Cursor

Framework gives the team nothing to assess them with. The team must work out alone what to ask about data handling, model changes, and uptime.

The status of generated code is also unclear. A team might treat it as supplier output and lean on the supplier. GAMP 5 would treat it as bespoke Category 5 code, which the regulated company owns and must verify.

ISO 27001 control A.8.30 may treat the model vendor as outsourced development. That adds its own supplier duties.

## Suggested Action

- Add a supplier assessment template that covers:
  - the provider's quality system and certifications
  - data handling, retention, and training use of prompts
  - notice of model changes and deprecations
  - availability and support terms
- State in the GxP profile that generated code is Category 5 bespoke output. The regulated company owns it and verifies it through the normal test and review path.
- Note the possible A.8.30 duty, and check it against the standard at pickup.
- Feed model change notices into the requalification trigger in 0000344.

Framework supplies a template. The regulated company's quality unit runs the assessment and decides whether to accept the supplier.

## Wanted outcome

- A team can fill one template per supplier and file it with its validation records.
- The GxP profile names generated code as Category 5 in plain words.
- A model change notice opens a requalification check under 0000344.

## Open questions

- Does 0000349 cover the same ISO 27001 ground, and should the two merge?
- Should the template include a filled example for one provider?

## Why Deferred

The human asked for the GAMP 5 gap analysis findings to reach the backlog. It pairs with 0000344 and needs its own design.
