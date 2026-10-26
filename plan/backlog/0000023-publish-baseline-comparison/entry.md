---
title: "Backlog Entry: 0000023 - Publish a baseline comparison"
summary: "No comparative evidence exists, which is the binding constraint on external adoption; publish a measured comparison of a fixed task set built with no framework, fast-path, and full pipeline."
status: "open"
---
# Backlog Entry: 0000023 - Publish a baseline comparison

**Source feature:** N/A — independent framework review, corrected second edition (filed ad-hoc via chat, not part of the phased pipeline)
**Source phase:** N/A (filed ad-hoc via chat)
**Date filed:** 2026-07-31
**Reference:** `_reference/` — REQ-008 in the corrected recommendations; finding 6 in the corrected review

---

## Problem

No comparative evidence exists. The README acknowledges this under Limitations, and it is now the binding constraint on external adoption.

The two questions any adopter asks are whether defect escape rate falls, and what the token and wall-clock multiple is against a baseline agent. Neither has a published answer. Design rationale alone will not carry a framework that asks for this much upfront ceremony.

## Suggested Action

Publish a measured comparison of a fixed task set built three ways: baseline agent with no framework, RAVINTIO Framework fast-path, RAVINTIO full pipeline. Minimum five tasks of varied size, with the task definitions published. Measure defects reaching pull request, rework cycles, total tokens and wall-clock duration. Publish the method and the raw results, including results unfavourable to the framework. Link it from the README Limitations section, replacing the "no comparative benchmarks yet" note.

Small and honest beats large and delayed — five tasks published is worth more than fifty planned.

## Positioning note (2026-10-26)

The 0000279 differentiation review moves this entry to RAVINTIO Unbound. The RAVINTIO strategy has Unbound run matched comparisons of governed and ungoverned workflows, with RAVINTIO Insight as the independent assessor. Compare Zero and Framework in the same study, since they are the two governed options. File the entry in the Unbound repository, then close it here with a pointer.

## Why Deferred

Filed from an external review rather than an in-flight pipeline feature. Depends on 0000022, which supplies two of the four metrics automatically; without it, tokens and duration have to be collected by hand.

Best run after 0000021, so the comparison measures the intended artifact set rather than the current unconditional one.
