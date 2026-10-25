---
title: "Backlog Entry: 0000219 - setup.ps1 allowedTools merge can drop user settings"
summary: "Merge-AllowedTools rewrites settings.json through ConvertTo-Json -Depth 10 and a case-insensitive hashtable, so deep or case-variant keys and non-object roots lose data."
status: "open"
---
# Backlog Entry: 0000219 - setup.ps1 allowedTools merge can drop user settings

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

`Merge-AllowedTools` in `ravintio-framework/setup.ps1` (around lines 436 to 466) reads `.claude/settings.json` into a hashtable and writes it back with `ConvertTo-Json -Depth 10`. Three inputs lose data.

- A value nested deeper than 10 levels is written as its .NET type name.
- A PowerShell hashtable is case-insensitive, so keys that differ only by case (`Agent` and `agent`) collapse to one.
- A valid JSON root that is not an object (`[]`, `null`, `5`) passes `Test-SettingsFileReadable` and is replaced with `{ "allowedTools": ["Agent"] }`.

Feature 0000037 added `ConvertTo-RavintioHashtable` (line 411) on this path but did not change these behaviours. Claude Code settings rarely nest past 6 levels, so the exposure is low.

## Suggested Action

Raise the depth to 100, or stop and warn when the parsed tree is deeper than 10. Refuse and leave the file unchanged when the root is not an object. Warn on duplicate keys that differ only by case.

## Why Deferred

The behaviour pre-dates feature 0000037 and has low likelihood. It needs its own test cases under both PowerShell 5.1 and 7.
