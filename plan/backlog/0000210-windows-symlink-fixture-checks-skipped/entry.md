---
title: "Backlog Entry: 0000210 - Windows symlink fixture checks skipped"
summary: "Symlink checks in four feature suites skip under Git Bash because ln -s copies instead of linking."
status: "open"
---
# Backlog Entry: 0000210 - Windows symlink fixture checks skipped

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

Git Bash on `windows-latest` makes a copy when a suite runs `ln -s`, so no symlink exists. The symlink checks then see ordinary files and fail. These checks skip with `SKIP (windows)`:

- `test-0000033-req-001-run-mode-script.sh`: the three symlinked-record cases.
- `test-0000033-req-012-archive-script-without-glob-delete.sh`: the symlinked archive target, `plan/_archive`, `plan/current`, dangling `.archive-target`, and symlinked `.archive-target` cases.
- `test-0000033-req-017-join-owner-and-reconciliation.sh` and its `regression/` copy: the symlinked changed-file case.
- `test-0000030-req-004-install-clean-up-and-retired-flags.sh`: the linked-parent refusal check.

The scripts under test (`run-mode.mjs`, `archive-current.mjs`, `stream-reconcile.mjs`, `setup.sh`) were not shown to misbehave. The fixtures cannot be built.

## Suggested Action

Set `MSYS=winsymlinks:nativestrict` and enable Developer Mode on the runner so `ln -s` makes real links. Then remove the guards and the skip table rows. Alternatively, create the links with `node -e "fs.symlinkSync(...)"`, which works on `windows-latest` with the right privilege.

## Why Deferred

The fix depends on a runner privilege decision and touches the CI workflow. The Linux and macOS legs still run every symlink check.
