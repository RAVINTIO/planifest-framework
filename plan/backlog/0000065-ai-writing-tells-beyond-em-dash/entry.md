---
title: "Backlog Entry: 0000065 - AI writing tells beyond the em dash"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000065 - AI writing tells beyond the em dash

**Source feature:** 0000028-telemetry-hardening-and-enforcement-fixes
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-08-08

---

## Problem

Backlog `0000026` asked for a style guard covering the broader set of AI writing tells. At `0000028`'s P0 it was scoped hard to a single deterministic character check, U+2014, which shipped as `ravintio-framework/hooks/enforcement/em-dash-guard.mjs`. Everything else on the original list is still unaddressed and still unspecified: which tells, which artifact classes, and whether a hook is even the right instrument.

The em dash was the easy case precisely because it is decidable by scanning for one code point. Most writing tells are not: "delve", "it's not just X, it's Y", tricolon padding, and hedging openers are all context-dependent, and a deterministic scan for them would produce false positives on legitimate prose at a rate the em dash check does not.

## Suggested Action

Decide first which artifact classes are in scope and whether enforcement is a hook or instruction-only, then treat `em-dash-guard.mjs` and `0000028-ADR-003` as the reference implementation for anything that turns out to be deterministically checkable. Expect the answer for several tells to be that a write-time hook is the wrong instrument.

## Why Deferred

See `0000028`'s `scope.md` Deferred section and `design.md` Scope: the em dash check ships standalone and nothing in that feature was blocked by the rest of the list. Recorded again in `0000028`'s `recommendations.md` Deferred Items table. Best picked up once there is evidence of which tells actually recur in this repo's artifacts, rather than working from a general list.
