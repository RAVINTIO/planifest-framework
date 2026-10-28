---
title: "Backlog Entry: 0000283 - link acceptance criteria to test case management tools"
summary: "Map each acceptance criterion to a test case in tools such as Xray, Zephyr, or TestRail, and post execution results with provenance."
status: "open"
---
# Backlog Entry: 0000283 - link acceptance criteria to test case management tools

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-26

---

## Problem

Regulated teams keep test cases and execution records in a test case management tool, such as Xray, Zephyr Scale, TestRail, Azure Test Plans, or qTest. Auditors read coverage and results there. Framework writes tests as code and records results in `plan/`. Nothing links an acceptance criterion to a managed test case, so the team must keep the two in step by hand.

## Suggested Action

Through the 0000280 adapter contract:

1. Give each acceptance criterion a stable ID. 0000268 makes criteria Gherkin lines, which most of these tools can import.
2. At P1, map each criterion to an existing test case, or propose a new one. Create the case only when the allowlist permits it.
3. At P3, name the managed test case ID in each test, in the form the tool's importer reads.
4. At P4, post the CI test results (0000281) as a test execution against the right version or release. Keep manual and exploratory tests the team records in the tool as evidence too.
5. Report coverage per criterion: covered and passed, covered and failed, or not covered.

## Wanted outcome

Every acceptance criterion links to a managed test case and its latest result. A test proves that a criterion with no linked case reads as not covered.

## Why Deferred

Filed from the 0000279 differentiation review. It depends on 0000280 and gains from 0000268.
