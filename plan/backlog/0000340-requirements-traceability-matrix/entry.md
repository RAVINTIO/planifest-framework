---
title: "Backlog Entry: 0000340 - requirements traceability matrix"
summary: "Generate a bidirectional URS-to-evidence matrix at P4, confirm it at P7, keep it per system, and fail on orphans."
status: "open"
---
# Backlog Entry: 0000340 - requirements traceability matrix

**Source feature:** none (GAMP 5 gap analysis)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline
**Related:** 0000268, 0000283, 0000285, 0000290, 0000338

---

## Problem

A regulated auditor asks first for the traceability matrix. Framework doesn't produce one.

`ravintio-framework/scripts/consistency-check.mjs` checks that each requirement file names a source user story. It also checks acceptance criteria counts and orphaned ADR references. It doesn't follow the chain past the requirement:

- It doesn't link a requirement to the tests that verify it.
- It doesn't link a test to its result or its evidence.
- It doesn't flag a test that traces to no requirement.

Any matrix would also be per run, because specs sit in `plan/_archive/{feature}/` after P7. An auditor needs the matrix for the whole system.

## Suggested Action

- Generate a bidirectional matrix at P4: URS to FS to DS to test to result to evidence. Use the spec levels from 0000338.
- Confirm the matrix at P7, before archive, against the final test results.
- Extend `consistency-check.mjs` to fail on these gaps:
  - a test that traces to no requirement
  - a requirement with no test
  - a requirement whose tests have no recorded evidence
- Keep one matrix per system, updated by each run, as well as the run's slice.
- Export the matrix so these entries can use it:
  - 0000283 (test case management links)
  - 0000285 (control mapping)
  - 0000290 (shared evidence schema)

Framework produces evidence and never claims compliance. The regulated company's quality unit judges whether the matrix is enough.

## Wanted outcome

- A reader can trace any requirement forward to evidence and any test back to a requirement.
- A run with an orphan test or an unevidenced requirement fails P4.
- The system matrix shows every requirement in the living spec, not only the current run's.

## Open questions

- Should the matrix be a generated Markdown table, a CSV, or both?
- Gherkin scenario IDs from 0000268 may make better test keys than file paths.

## Why Deferred

The human asked for the GAMP 5 gap analysis findings to reach the backlog. It depends on 0000338 for spec levels.
