---
title: "Backlog Entry: 0000211 - Windows NTFS permission, shim and name checks skipped"
summary: "Checks that need POSIX modes, an extensionless git shim, or a newline in a folder name skip under Git Bash."
status: "open"
---
# Backlog Entry: 0000211 - Windows NTFS permission, shim and name checks skipped

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

Three fixtures cannot be built on `windows-latest` under Git Bash. Each check skips with `SKIP (windows)`:

- `test-0000030-req-004-install-clean-up-and-retired-flags.sh`: `chmod 555` does not block deletes on NTFS, and `chmod 600` does not stick (stat reports 666). The undeletable-folder warning and the 0600 mode checks skip.
- `test-0000033-req-012-archive-script-without-glob-delete.sh`: the forced-stop resume case puts an extensionless `git` shim on `PATH`. Node finds only `git.exe` on Windows, so the third `git mv` never fails.
- `test-0000036-req-002-skill-drift-check.sh`: NTFS rejects a newline in a folder name, so the escaped-name check skips.

The scripts under test were not shown to misbehave.

## Suggested Action

For the git shim, add a `git.cmd` that calls the bash shim. For the other two, no portable fixture exists, so keep the skips and rely on the Linux and macOS legs.

## Why Deferred

Only the shim has a possible fix, and it needs a Windows-only fixture that this batch cannot test locally.
