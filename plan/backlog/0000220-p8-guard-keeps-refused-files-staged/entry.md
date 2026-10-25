---
title: "Backlog Entry: 0000220 - P8 guard keeps refused files staged"
summary: "The ship skill P8 credential guard leaves a refused staged file in the index, unlike the new held-back rule."
status: "closed"
---
# Backlog Entry: 0000220 - P8 guard keeps refused files staged

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

The P8 credential guard in `ravintio-framework/skills/ravintio-ship-agent/SKILL.md` (about line 198) says a refused file that is staged stays staged. The pre-commit scan rule in `ravintio-framework/standards/autonomous-run-standards.md` now takes a held-back file out of the index with `git restore --staged -- {path}`. The two rules differ. The suite `test-0000033-req-013-clean-close-out.sh` asserts the P8 guard wording "stay uncommitted", and the clean-tree check relies on a staged leftover showing as a leftover.

The new PR temp folder flow also uses a shell variable, `PRTMP`. Shell state does not persist between Bash calls in some hosts, so the ship skill should say that the `mktemp -d`, the scans, and the `gh` call run in one shell call.

## Suggested Action

Decide whether the P8 guard should also unstage refused files, and align the req-013 assertions if it does. Add one sentence to the ship skill that the PR text steps share one shell call.

## Why Deferred

The P8 guard and its req-013 suite are outside the F-04 to F-12 fix scope. Changing them needs its own decision about the clean-tree check.

---

## Resolution

P5 fix 2 closed this entry. The P8 guard now unstages a refused file with `git restore --staged -- {path}` and logs a held-back line. The P7 archive commit unstages held-back paths and scans before it commits. The PR text steps run in one shell call.
