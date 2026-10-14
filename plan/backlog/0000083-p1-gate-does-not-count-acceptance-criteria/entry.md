---
title: "Backlog Entry: 0000083 - The P1 gate does not count acceptance criteria"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000083 - The P1 gate does not count acceptance criteria

**Source feature:** the `ovelunor` product's 0000007-mastheads-in-motion
**Source phase:** P6
**Deferral source:** discovered mid-flight
**Date filed:** 2026-09-23
**Moved:** from the `ovelunor` product's backlog entry 0000115 on 2026-10-10, because the fix belongs in this framework

---

## Problem

The spec-agent standard says a user story implying more than three acceptance
criteria should be split into two stories. Feature 0000007 wrote six
requirements carrying five or six criteria each. Every one broke the rule, and
nothing noticed until P6.

`scripts/consistency-check.mjs` does check the count, and it reports the
violation clearly. Nothing runs it at the P1 gate. The orchestrator's P1 to P2
gate condition asks only that every artifact exists and that an OpenAPI spec
covers every implied endpoint. A count that no gate reads is guidance rather
than a rule.

By P6 the cost of correcting it has changed shape. The acceptance harness
registers its checks by requirement id, printing `0000007.req-001` and the
rest, and `component.yml` records the same ids in its scope entries.
Renumbering then changes shipped identifiers to make a document match a rule,
with no change to what runs.

Feature 0000007 recorded the overrun as a deviation for that reason. That is
the correct call at P6 and the wrong outcome overall, because the rule exists
and was broken six times.

## Suggested Action

Run `consistency-check.mjs` at the P1 gate, before P2 begins, and treat a
criteria-count finding as blocking. Splitting a requirement is cheap while
nothing references its id.

Consider the same for the story-to-requirement traceability check. Feature
0000007's req-005 carried no source user story, because it came from a pulled-in
backlog entry rather than from the design's own stories. That also surfaced at
P6 rather than P1, though it was cheap to fix.

Note that the checker cannot see archived ADRs, which backlog 0000104 records.
Making it blocking at P1 without fixing that first would block every run on
false positives, so 0000104 comes first.

## Why Deferred

It changes a pipeline gate rather than this feature's own code. Feature
0000007's requirements are written, implemented, tested and validated by a
human, so splitting them now would be documentation churn. The fix belongs at
the point where splitting is still cheap.
