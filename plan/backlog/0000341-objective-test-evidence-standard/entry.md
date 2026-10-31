---
title: "Backlog Entry: 0000341 - objective test evidence standard"
summary: "Make test and verification reports record expected and actual results, executor, clock time, environment, commit, and a named human reviewer."
status: "open"
---
# Backlog Entry: 0000341 - objective test evidence standard

**Source feature:** none (GAMP 5 gap analysis)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline
**Related:** 0000281, 0000283, 0000351, 0000333

---

## Problem

Regulated test evidence must show who ran what, when, where, and with what result. Framework's reports don't record that.

- `ravintio-framework/templates/test-report.template.md` summarises the test run.
- `ravintio-verify-by-execution` writes `plan/current/verification-report.md` from its skill text, with no template.

Neither report records all of these:

- expected and actual result per test
- the executor, whether an agent with its model ID or a named human
- the date and time from the system clock, not an agent estimate
- the environment and the commit under test
- a named human reviewer and the review date

A failed test also loops quietly through the validate loop until it passes. A formal test failure in a regulated setting needs a recorded deviation.

## Suggested Action

- When the GxP profile is on, add the fields above to the test report and to a new verification report template.
- Take the timestamp from the system clock in a script, never from the agent.
- Take CI and test tool results as evidence through 0000281, and link test cases through 0000283.
- When a formal test fails, open a deviation through 0000333 rather than looping. Keep the loop for development tests.
- Pin the executor's model ID through 0000351.

Framework produces evidence and never claims compliance. The regulated company's quality unit judges whether the evidence is sufficient.

## Wanted outcome

- Each formal test result names its expected result, actual result, executor, clock time, environment, and commit.
- A report without a named human reviewer and review date fails the P7 check under the profile.
- A failed formal test leaves a deviation record behind, even after a later pass.

## Open questions

- Which tests count as formal? The risk class from 0000339 could decide.
- Should the human reviewer sign through the approval record in 0000286?

## Why Deferred

The human asked for the GAMP 5 gap analysis findings to reach the backlog. It needs its own design for the formal and development test split.
