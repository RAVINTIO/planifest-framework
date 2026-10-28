---
title: "Backlog Entry: 0000285 - map requirements to the organisation's controls"
summary: "Link requirements, ADRs, tests, and evidence to control IDs the organisation supplies, such as ISO 27001, SOC 2, or IEC 62304, without claiming compliance."
status: "open"
---
# Backlog Entry: 0000285 - map requirements to the organisation's controls

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-26

---

## Problem

Regulated teams must show which controls a change touches and what evidence shows each control still holds. Framework traces requirements to tests, but it has no idea of a control. A team using ISO/IEC 27001, SOC 2, PCI DSS, IEC 62304, ISO 13485, DORA, or an internal control set must build that map outside Framework.

## Suggested Action

- Let the organisation supply a control catalogue as a versioned file in `ravintio-overrides/`, with control ID, title, and the evidence each control expects. Framework ships no catalogue of its own, beyond an example.
- At P0, ask which catalogue applies, or read it from policy. At P1, tag each requirement with the controls it touches. At P2, tag each ADR the same way.
- At P4 to P6, link each control tag to its evidence (0000281, 0000283).
- Report each control as `evidenced`, `evidence missing`, or `not assessed`. Never report a control as compliant.
- Add a control traceability matrix to the archive and to the evidence export (0000290).

## Wanted outcome

For any run, a reader can list the controls it touched and the evidence for each. A test proves that a control with a tag but no evidence reads `evidence missing`.

## Why Deferred

Filed from the 0000279 differentiation review. It needs a P0 decision on catalogue format and on where the matrix lives.
