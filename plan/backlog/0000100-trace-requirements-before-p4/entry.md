---
title: "Backlog Entry: 0000100 - Trace requirements to tests before P4"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000100 - Trace requirements to tests before P4

**Source feature:** monkey-vs-gulls 0000001-typescript-tests-and-sit
**Source phase:** P9 (postmortem PA-1 and DA-1)
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-16

---

## Problem

In monkey-vs-gulls, five of eight requirements covered config and markup. P3 wrote no test naming them, because builds and lint already exercised them. P4's semantic check was the first to notice. See `monkey-poop/plan/postmortems/2026-10-16-2112-0000001-typescript-tests-and-sit-p4-traceability-gap.md`.

## Suggested Action

- Add a "Verified by" field to each acceptance criterion in `templates/requirement.template.md`, so the spec agent names the test type up front.
- Have the codegen agent run the requirement-ID scan before P3 closes, not only at P4.

## Why Deferred

A framework change, raised from a product run. It needs its own feature in the framework repository.
