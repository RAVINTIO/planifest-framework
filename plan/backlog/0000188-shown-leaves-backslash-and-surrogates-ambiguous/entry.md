---
title: "Backlog Entry: 0000188 - shown() leaves backslash and lone surrogates ambiguous"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000188 - shown() leaves backslash and lone surrogates ambiguous

**Source feature:** 0000036-pipeline-friction-and-gate-fixes
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-10-23

---

## Problem

Req-011 made `shown()` escape control and format characters in `ratchet-check.mjs` and `em-dash-guard.mjs` output. A literal backslash prints as itself, so a path that holds the text `\n` reads the same as a path that holds a newline. A lone surrogate also prints in a form that matches an escaped pair. This is finding 5 in `plan/_archive/0000036-*/security-review-hooks.md`. No line can be forged, because every newline is still escaped.

## Suggested Action

Escape a literal backslash as `\\` and print a lone surrogate as `\uXXXX`. Update `test-0000036-req-011-escaped-hook-output.sh` to cover both.

## Why Deferred

P5 rated the finding Low and accepted it. The output is still safe to read, and a change to the escape format touches the suites that assert the current text.
