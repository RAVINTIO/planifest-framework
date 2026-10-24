---
title: "Backlog Entry: 0000212 - Windows gitleaks stand-in and bare .mjs checks skipped"
summary: "Two checks in feature 0000037 suites skip under Git Bash because the fixtures cannot run there."
status: "open"
---
# Backlog Entry: 0000212 - Windows gitleaks stand-in and bare .mjs checks skipped

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

Two checks skip on `windows-latest` under Git Bash with `SKIP (windows)`.

- `planifest-framework/tests/test-0000037-req-003-credential-scan.sh` fakes gitleaks with a shell script. `credential-scan.mjs` starts gitleaks without a shell, so node finds only `gitleaks.exe`. The fake is never found, and the three gitleaks-mode checks cannot run.
- `planifest-framework/tests/test-0000037-req-007-wired-command.sh` builds a negative fixture with the node prefix removed. Git Bash runs a bare `.mjs` path through its `#!/usr/bin/env node` line, so the fixture exits 0. The check expects non-zero.

The other checks in both suites run on Windows. The first CI run failed because the suite built a `PATH` of linked `node` and `git`. Under Git Bash the links are copies that cannot start, so every scan exited 2 with `git diff failed`.

## Suggested Action

For req-003, build a real `gitleaks.exe` stand-in on Windows, for example a small compiled program, or let the script accept a `PLANIFEST_GITLEAKS` override. For req-007, choose a negative fixture that fails on both platforms, such as a path to a file with no shebang.

## Why Deferred

Neither check blocks the green-CI goal, and each fix needs its own design decision about the stand-in. The cost of the skip is low because the Linux and macOS legs still run both checks.
