---
title: "Backlog Entry: 0000105 - shell guard misses writers behind wrappers"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000105 - shell guard misses writers behind wrappers

**Source feature:** 0000032-governance-continuity-and-write-gate-scope
**Source phase:** P5
**Deferral source:** deliberate scope decision
**Source finding:** F3 in the 0000032 P5 security report (`plan/_archive/0000032-governance-continuity-and-write-gate-scope/security-report.md` once archived)
**Severity:** Low
**Priority:** Low
**Date filed:** 2026-10-17

---

## Problem

`shell-write-guard.mjs` judges the first word of each command as the writer. A wrapper in front hides the real writer, so the guard passes the write. The 0000032 P5 review found these wrappers: `command`, `env`, `sudo`, `nohup`, `xargs`, `time -p`, and `bash -c "…"`. For example, `env sed -i s/a/b/ src/x.js` writes into a gated path without a block.

## Suggested Action

Strip known wrapper prefixes before the guard picks the writer, and parse the string passed to `bash -c` as a command. Otherwise list the wrappers as known limits in the guard header and in 0000032 ADR-006.

## Why Deferred

At the P5 gate, the human on the loop chose to fix the Medium findings and the cheap Low ones in 0000032. This Low finding went to the backlog. The decision is in the 0000032 build log.
