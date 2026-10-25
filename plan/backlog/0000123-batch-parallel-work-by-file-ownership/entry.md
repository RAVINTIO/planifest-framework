---
title: "Backlog Entry: 0000123 - Batch parallel work by file ownership"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000123 - Batch parallel work by file ownership

**Source feature:** 0000033-human-on-the-loop-run-mode
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-19

---

## Problem

In 0000033 P3, five parallel work packages edited `ravintio-orchestrator/SKILL.md`, the build-log template, and the build-assessment skill at the same time. One package rewrote the orchestrator with `sed -i` mid-wave. No edit was lost, but only the suites showed that. Shared files also stopped each package's work from landing in its own commit.

## Suggested Action

Add a file-ownership rule to `ravintio-framework/standards/agent-dispatch-standards.md`. Batch work units so no two concurrent agents own the same file, or name one owner per shared file and route other packages' edits through it. Ban whole-file rewrites of shared files during a wave.

## Why Deferred

See REC-005 in `plan/_archive/0000033-human-on-the-loop-run-mode-2026-10-19/recommendations.md`. The change alters how every phase splits work, which needs its own design.
