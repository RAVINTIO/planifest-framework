---
title: "Backlog Entry: 0000232 - installed stack evaluation links dangle"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000232 - installed stack evaluation links dangle

**Source feature:** 0000038-token-efficiency-windows-shard
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

The orchestrator's Phase 0 text links to `standards/reference/backend-stack-evaluation.md` and `standards/reference/frontend-stack-evaluation.md`. Setup bundles only the top-level files in `ravintio-framework/standards/`. It doesn't copy the `reference/` subfolder. In an install, both links therefore point at files that don't exist.

The gap predates 0000038. The text used to sit in the orchestrator `SKILL.md`, and the same two links dangled there. Feature 0000038 moved the text to `skills/ravintio-orchestrator/references/phase-0-assess-and-coach.md` and fixed the link prefix. The two target files are still missing from installs.

`ravintio-framework/tests/test-0000038-req-004-installed-reference-links.sh` checks these two links against the source folder, not the install.

## Suggested Action

Either bundle `standards/reference/` with the skills that link to it, or point the two links at a location that every install holds. Then make the install test check them inside the install.

## Why Deferred

The gap is older than 0000038, and fixing it changes which standards setup bundles. That needs its own design decision.
