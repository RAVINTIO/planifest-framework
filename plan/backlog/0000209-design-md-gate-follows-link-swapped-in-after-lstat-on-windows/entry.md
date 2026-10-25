---
title: "Backlog Entry: 0000209 - design.md gate follows a link swapped in after lstat on Windows"
summary: "On Windows the design.md open has no O_NOFOLLOW, so a link swapped in after lstatSync is read and the gate admits the write."
status: "open"
---
# Backlog Entry: 0000209 - design.md gate follows a link swapped in after lstat on Windows

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

On the `windows-latest` Git Bash leg, `test-0000036-req-008-non-regular-design-md.sh` (swap mode `link`) swapped `plan/current/design.md` for a symbolic link after `lstatSync`. `gate-write` then exited 0 and admitted `src/a.js`. The suite expects exit 2 with the no-design reason. CI run 40049089808 shows it.

The cause is in `ravintio-framework/hooks/enforcement/path-rules.mjs`. The open uses `O_NOFOLLOW ?? 0`, and Windows defines no `O_NOFOLLOW`. The open follows the link. The later `fstatSync` sees a regular file, so the check passes.

A link already in place is caught by `lstatSync`. The hole is the race between `lstatSync` and the open. Reaching it needs a process that writes into `plan/current/` at the right moment. This is an enforcement gap on Windows, so the suite skip is not a fix.

## Suggested Action

After the open, compare the descriptor with a second `lstatSync` of the path (same `dev` and `ino`), or compare `realpathSync` of the path with the path. Close the descriptor and treat the file as non-regular if they differ. Then remove the Windows guard in the suite.

## Why Deferred

The fix changes a hook, and P3 stream 04 may not edit hooks. It needs its own design decision on the Windows check.
