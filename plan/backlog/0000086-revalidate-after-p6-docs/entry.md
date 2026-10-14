---
title: "Backlog Entry: 0000086 - Revalidate after P6 docs edits"
summary: "P4 runs before P6, so a check over living docs never sees P6's edits until CI."
status: "open"
---
# Backlog Entry: 0000086 - Revalidate after P6 docs edits

**Source feature:** the `ovelunor` product's `0000046-monitor-staleness-alert` run (a downstream consumer of this framework)
**Source phase:** P6
**Deferral source:** postmortem action PA-2
**Date filed:** 2026-10-12

---

## Problem

The pipeline validates at P4 and writes living docs at P6. Some products test their docs, for example a derived ADR count or a recorded test count. P6's edits then break a check that P4 already passed, and nothing reruns it before P9.

In `ovelunor` 0000046, P6 added ADR-167 to the decisions index and five tests to a component. Three count checks failed in a full suite that ran after P6. A rerun before P7 caught them only because the suite happened to run late.

## Proposed change

- Add a "post-P6 revalidation" step to the docs agent. It reruns the suite's doc checks, or the full P4 check set when no subset is declared.
- Let a product declare its doc-check command in `planifest-overrides/`.
