---
title: "Backlog Entry: 0000025 - Declare adoption position and stability policy"
summary: "The repository reads as both an internal standard and a commercial product; state the intended audience and the versioning and breaking-change commitment in the README."
status: "open"
---
# Backlog Entry: 0000025 - Declare adoption position and stability policy

**Source feature:** N/A — independent framework review, corrected second edition (filed ad-hoc via chat, not part of the phased pipeline)
**Source phase:** N/A (filed ad-hoc via chat)
**Date filed:** 2026-07-31
**Reference:** `_reference/` — REQ-012 in the corrected recommendations; finding 9 in the corrected review

---

## Problem

Zero stars, zero forks, one contributor, formats explicitly subject to change, and a product concept document describing a commercial model. The repository currently reads as both an internal standard and a product, and the two imply different roadmaps.

The ambiguity deters the adopters most likely to benefit: anyone who needs format stability cannot tell from the README whether to expect it.

## Suggested Action

State the current position and the stability commitment in the README. The Status section should say who the framework is currently for. Add a versioning and breaking-change policy, including how migrations are delivered — `ravintio-framework/migrations/` and the `ravintio-migrator` skill already exist, so the mechanism can be described rather than invented. Make the roadmap link reflect the same position.

## Why Deferred

Filed from an external review rather than an in-flight pipeline feature. This is a positioning decision, not a defect — it needs the human to decide what RAVINTIO Framework is before anything can be written down.

## Related

0000016 restates the CI parity guarantee honestly. The Limitations section is the framework's strongest credibility asset with exactly the audience this entry is about; it should be expanded rather than softened when the position is declared.
