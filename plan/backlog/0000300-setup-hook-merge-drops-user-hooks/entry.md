---
title: "Backlog Entry: 0000300 - setup hook merge drops or duplicates user hooks"
summary: "The settings merge in setup.sh and setup.ps1 removes whole hook entries on a substring match, misses combined matchers, fails on non-array values, and truncates deep JSON on PowerShell."
status: "open"
---
# Backlog Entry: 0000300 - setup hook merge drops or duplicates user hooks

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline
**Related:** 0000110, 0000299

---

## Context

A review of the sibling repo RAVINTIO Zero on 2026-10-31 found merge fixes that Zero made and Framework lacks. Framework targets regulated industries, such as those that follow GAMP 5. There, setup must not change a user's own controls without saying so.

## Problem

Setup merges its hooks into the tool's settings file by removing old RAVINTIO entries and adding new ones. The filters live in `ravintio-framework/setup.sh` lines 421 to 424 and 539 to 566. `setup.ps1` repeats them at lines 412 to 430, 610, and 642. They have five faults:

- **Whole entries go.** The filter drops an entry when any of its commands matches. A user command in the same entry goes with it.
- **Substring matches.** The test is `.includes("gate-write")` or `.includes("check-design")`, and `-match` in PowerShell. A user script such as `my-check-design-helper.sh` matches and is removed.
- **Combined matchers survive.** The `setup.sh` filters check only the `Write` and `Edit` matchers. An older `Write|Edit` entry survives, and the hooks then run twice.
- **Non-array values throw.** If an event value or an entry's `hooks` value isn't an array, `.filter` or `.some` throws a TypeError. The wiring step stops, and the hooks stay unwired.
- **Deep values truncate.** `setup.ps1` writes settings with `ConvertTo-Json -Depth 10` at lines 434, 444, and 494. PowerShell flattens anything deeper to a string, with no error, which corrupts deep user values.

0000110 covers edge cases in the Bash group only, which is narrower.

## Suggested Action

- Filter one command at a time. Remove a command only when it equals a RAVINTIO command exactly, and drop an entry only when it has no commands left.
- Match every matcher form, including `Write|Edit`.
- Treat a non-array event or `hooks` value as a named warning that skips that file, rather than a crash.
- Use `-Depth 100` in `setup.ps1`.
- Add tests for each fault, in shell and PowerShell.

Zero fixed these in commit `328adfb` (0000038), commit `2ac5a4e` (0000039), and commit `c5bfcaa` (0000041). Its tests include `ravintio-zero/tests/test-0000037-req-007-sh-filter-any-matcher.sh` and `ravintio-zero/tests/test-0000037-req-008-non-array-hook-events.sh`. Its fixtures live in `ravintio-zero/tests/fixtures/0000038-hook-filter/` and `ravintio-zero/tests/fixtures/0000039-setup-hardening/`.

## Wanted outcome

A setup re-run leaves every user hook in place, wires each RAVINTIO hook once, and never corrupts a settings value.

## Why Deferred

The human asked for it on 2026-10-31. It changes `setup.sh` and `setup.ps1`, which are enforcement paths, so it needs the Change Pipeline.
