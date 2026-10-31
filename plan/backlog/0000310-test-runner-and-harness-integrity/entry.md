---
title: "Backlog Entry: 0000310 - make the test runner and assert helpers able to fail"
summary: "Stop suites passing when a file never runs, an assert helper is misspelt, or a substring match hides a wrong order."
status: "open"
---
# Backlog Entry: 0000310 - make the test runner and assert helpers able to fail

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline
**Related:** 0000221, 0000254, 0000262

---

## Context

A review of RAVINTIO Zero on 2026-10-31 found that Zero had fixed several faults that Framework's test harness still has. In a regulated setting, a passing suite counts as validation evidence. A suite that can't fail gives false evidence.

## Problem

- **A suite that never runs.** `tests/run-tests.sh` runs only files that match `test-*.sh` (line 173). `tests/test_setup.sh` uses an underscore, so the runner skips it. CI runs `run-tests.sh` and `test_setup.ps1` only (`.github/workflows/ravintio.yml` lines 107 and 129). `tests/README.md` tells people to run `test_setup.sh` by hand, but no automated check does.
- **Misspelt asserts pass.** `print_summary` in `tests/helpers/assert.sh` checks only `$FAIL` (lines 121 to 130). A call to an undefined assert helper prints `command not found`, and the suite still passes.
- **Substring matches.** `assert_contains` matches any substring. In Zero, a check that wanted "before" passed on "not before" (`zero/plan/retrospectives/0000246-plan-checks-count-and-cap-tests-2026-10-28.md` line 23).
- **No negative or order helper.** `assert.sh` has no `assert_not_contains` and no helper that checks the order of two pieces of text.
- **Leaky environment.** The runner unsets only `CLAUDE_PROJECT_DIR` and the two shard variables (lines 9 and 25). Any other inherited variable can change a suite's result.

## Zero's fixes

- Zero commit cb84ae7 (feature 0000036) added a pre-flight check with a `KNOWN_NON_SUITES` list. Any file under `tests/` that is neither a suite nor on the list fails the run. The runner also runs `test-*.ps1` suites with `pwsh`, or prints how many it skipped.
- Zero archive `0000239-test-suite-reliability` counts a call to an undefined `assert_*` function as a failure. It also adds `assert_not_contains`.

## Suggested Action

- Rename `test_setup.sh` to match `test-*.sh`, or retire it if `test_setup.ps1` and the feature suites cover it.
- Add a pre-flight check that fails the run on any file under `tests/` that is neither a suite nor on a known list.
- Fail a suite that calls an undefined assert helper.
- Add `assert_not_contains` and an ordered-text helper.
- Run each suite in a clean environment, for example with `env -i` and an explicit allowlist of variables.
- Add a test-writer rule: prove each new guard test fails on a mutated copy of the code it guards.

## Wanted outcome

Every suite under `tests/` runs, and each can fail. Tests check these conditions:

- A stray file under `tests/` fails the run and the runner names it.
- A suite that calls `assert_contians` fails.
- The ordered-text helper fails when the second text comes first.
- A suite sees none of the caller's variables outside the allowlist.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It touches the shared test harness, so it needs its own run.
