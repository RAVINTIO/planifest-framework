---
title: "Backlog Entry: 0000252 - Consistency check reads cross-feature ADR references as local"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000252 - Consistency check reads cross-feature ADR references as local

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

`ravintio-framework/scripts/consistency-check.mjs` matches every `ADR-\d{3}` in `plan/current/` and expects a local file in `adr/`. A reference such as `0000035 ADR-010` or `RAVINTIO Zero 0000160 ADR-003` names another feature's ADR, but the check reports it as missing. In 0000039 P1 it raised seven false findings. Authors work around it by writing `ADR 010` without the hyphen. RAVINTIO Zero 0000160 hit the same fault.

## Suggested Action

Skip a match that a seven-digit feature id precedes, or state the hyphen-free convention in the requirement and ADR templates. A test should cover both forms.

## Why Deferred

Out of scope. 0000039 renames the pack and doesn't change check rules.
