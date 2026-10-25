---
title: "Backlog Entry: 0000257 - Rename helper misses other secret reference forms"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000257 - Rename helper misses other secret reference forms

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

The 0000039 P5 fix (M-001) stops `migrate-0.37.0-ravintio-rename.sh` and `.ps1` from renaming a pack variable name after `secrets.` or `vars.`. The re-review found that both helpers still rename these consumer-owned forms:

- `secrets['X']`, `Secrets.X`, and `secrets . X`
- the key under a reusable-workflow `secrets:` block
- `inputs.` and `needs.*.outputs.` references

Each rename makes the consumer's reference read as empty, with no error. The re-review rated the residue Low, because such names rarely start with a pack variable name.

## Suggested Action

Rewrite only the bare pack variable names the migration body lists, at word boundaries, and skip every expression context. Add cases for each form to the req-006 suite.

## Why Deferred

Non-blocking residue of a Medium finding that P5 closed. It needs a parser-level rule, which is outside a rename.
