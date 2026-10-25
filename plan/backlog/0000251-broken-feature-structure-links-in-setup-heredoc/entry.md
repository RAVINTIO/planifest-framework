---
title: "Backlog Entry: 0000251 - Broken feature-structure links in the setup heredoc"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000251 - Broken feature-structure links in the setup heredoc

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

The heredoc that `setup.sh` writes links to `../planifest/spec/feature-structure.md` at lines 788 and 957. `setup.ps1` has the same link at lines 894 and 1065. No `planifest/spec/` folder exists, so the links are already broken. The heredoc lines also hold mojibake bytes, so 0000039 changes only the brand word in them.

## Suggested Action

Point the links at the real feature-structure document, or remove them. Fix the mojibake in the same change, with a byte-level test.

## Why Deferred

Out of scope. 0000039 keeps the mojibake lines byte-identical apart from the brand word (req-004), so a link fix there needs its own change.
