---
title: "Backlog Entry: 0000099 - Verify UI with real input, not dispatched events"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000099 - Verify UI with real input, not dispatched events

**Source feature:** monkey-vs-gulls 0000001-typescript-tests-and-sit
**Source phase:** P9 (postmortem DA-2)
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-16

---

## Problem

In monkey-vs-gulls, P4's first browser play-through dispatched pointer events straight to the canvas with `element.dispatchEvent`. It scored points while a visible overlay covered the canvas and blocked every real click. Only a later check with Playwright's real mouse found the defect. See `monkey-poop/plan/postmortems/2026-10-16-2114-0000001-typescript-tests-and-sit-p4-css-defects.md`.

## Suggested Action

In `ravintio-verify-by-execution`, require UI checks to drive input through the real pointer and keyboard path, such as Playwright `page.mouse` or `locator.click`. Allow dispatched events only for setup, never as evidence that a criterion passed.

## Why Deferred

A framework change, raised from a product run. It needs its own feature in the framework repository.
