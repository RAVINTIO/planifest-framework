---
title: "Backlog Entry: 0000208 - Windows hook suite checks skipped for cwd, link, mode, and name limits"
summary: "Four hook suites skip checks on the Git Bash leg because Windows cannot build the fixture. Find a Windows-native way to cover each."
status: "open"
---
# Backlog Entry: 0000208 - Windows hook suite checks skipped for cwd, link, mode, and name limits

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

Four suites in `planifest-framework/tests/` print `SKIP (windows)` for the checks below. Each fixture needs something Git Bash on `windows-latest` cannot build. The README skip table has one row per suite.

- `test-0000035-req-004-root-when-cwd-deleted.sh`: Windows cannot delete a directory that is a process's cwd, so the no-cwd and `process.cwd()` throws checks skip. `chmod 000` sets no NTFS block, so the EACCES block skips.
- `test-0000035-req-005-ratchet-check-shared-root.sh`: `ln -s` copies the target under Git Bash, so the 10-link chain and link loop skip. A Windows file name cannot hold a newline or a colon, so the forged-name and forged-approval checks skip.
- `test-0000035-req-008-sanctioned-scripts.sh` and its regression copy: the `--root`, `--component`, `product.yml`, manifest, source, destination, `tests/`, and `regression/` link checks skip for the same `ln -s` reason. The kept-mode check and the unwritable-root and unreadable-file checks skip because NTFS has no POSIX mode bits.
- `test-0000036-req-008-non-regular-design-md.sh`: the FIFO case skips because Git Bash `mkfifo` made no file that Node reported as non-regular. The swap-to-link case skips because of backlog 0000209.

## Suggested Action

Set `MSYS=winsymlinks:nativestrict` on the leg and rebuild the link fixtures with Node `fs.symlinkSync`. Use `icacls` for the deny cases. Create the name cases with a Node `\\?\` path or drop them for a unit test of the escaping function. Related entries: 0000210 and 0000211 cover the same limits in other suites.

## Why Deferred

Each fix needs a Windows machine to prove. The Git Bash leg must end green before P4, and the checks stay covered on Ubuntu and macOS.
