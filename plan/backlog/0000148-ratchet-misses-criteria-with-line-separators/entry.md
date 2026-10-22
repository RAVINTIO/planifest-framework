---
title: "Backlog Entry: 0000148 - Ratchet misses criteria with line separators"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000148 - Ratchet misses criteria with line separators

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

`guardedLines` in `planifest-framework/hooks/enforcement/ratchet-check.mjs` matches guarded lines with a pattern that ends in `(.+)$`. In JavaScript, `.` doesn't match a lone CR, U+2028, or U+2029. An acceptance-criterion or In Scope line that already holds one of them isn't guarded. The P5 final re-review confirmed this for a lone CR as well. Removing that line while a loop is active doesn't trigger the block.

Adding the character to an existing line already counts as removing the old line, so an agent can't use this on a clean criterion. It applies only to a line that already holds the character.

## Suggested Action

Use the `s` flag or `[^\n]+` in place of `.+`, and treat U+2028 and U+2029 as ordinary characters inside a line. Add a ratchet suite case that removes a criterion holding U+2028 and expects exit 2.

## Why Deferred

The P5 gates fix agent found it while it tested escaping in the ratchet output. It sits outside the P5 findings.
