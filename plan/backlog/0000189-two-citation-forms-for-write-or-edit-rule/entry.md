---
title: "Backlog Entry: 0000189 - Two citation forms for the Write-or-Edit rule"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000189 - Two citation forms for the Write-or-Edit rule

**Source feature:** 0000036-pipeline-friction-and-gate-fixes
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-10-23

---

## Problem

ADR-010 sets the citation form `the {name} rule ({source} Hard Limit N)`. The dispatch-template sentence that req-005 fixes word for word reads "(the Write-or-Edit rule, boot Hard Limit 8)" instead. The suite `ravintio-framework/tests/test-0000036-req-005-hard-limits-cited-by-name.sh` accepts both forms, so a reader meets two shapes for the same rule in `ravintio-framework/standards/agent-dispatch-standards.md`.

## Suggested Action

Rewrite the sentence in the dispatch standards to the ADR-010 form, then tighten the suite to accept one form.

## Why Deferred

The sentence is fixed word for word by req-005, so changing it would reopen a confirmed requirement. The P3 build log records the deviation.
