---
title: "Backlog Entry: 0000277 - migration leaves old-named installed files"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000277 - migration leaves old-named installed files

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P9
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

On 2026-10-25 the agent ran the PR #71 manual test plan item. It built a 0.36.0 consumer with Claude Code and Cursor installed. Then it ran `migrate-0.37.0-ravintio-rename.sh` and setup at 0.37.0. Both exited 0, and the core checks passed. Three installed files keep their 0.36.0 form, because neither the helper nor setup changes them:

1. **Old boot files stay in place.** The Cursor boot file moved from `.cursor/rules/planifest.mdc` to `.cursor/rules/ravintio.mdc`. Setup writes the new file and leaves the old one. The old file has `alwaysApply: true`, so Cursor loads both rule sets. The old set names `planifest-framework/` paths and `planifest-*` skills, which no longer exist. Cline has the same change, from `.clinerules/00-planifest-boot.md` to `.clinerules/00-ravintio-boot.md`, and Cline loads every file in `.clinerules/`. The agent tested Cursor only. It found the Cline case by comparing `TOOL_BOOT_FILE` in `setup/*.sh` between `v0.36.0` and 0.37.0.
2. **`.gitattributes` keeps the old hook paths.** The consumer file still sets `text eol=lf` on `planifest-framework/hooks/*`. Setup skips an existing `.gitattributes`. So no LF rule covers `ravintio-framework/hooks/*`. On a Windows checkout with `core.autocrlf`, the hooks can get CRLF endings and stop running.
3. **The workflow body keeps the old brand.** Step 4 rewrites the `name:` line, paths, and variable names in `.github/workflows/ravintio.yml`. The `echo` lines still say `Planifest Fast Path Violation`, `Planifest Strict Violation`, and `Planifest pipeline passed`. This is cosmetic.

Item 2 matters most, because it can stop the hooks from running on Windows. Item 1 gives the agent two conflicting rule sets.

## Suggested Action

- Add a helper step that renames each old boot file the pack owns: `.cursor/rules/planifest.mdc` and `.clinerules/00-planifest-boot.md`. Setup then overwrites the renamed file. Check the other tools for a boot-file change too.
- Add a helper step that rewrites `planifest-framework/` to `ravintio-framework/` in `.gitattributes`, through a temporary file like Step 4.
- Consider rewriting the `Planifest` brand text in the workflow `echo` lines, or record it as a known leftover in the migration guide.
- Add each case to `test-0000039-req-006-consumer-migration.sh`.

## Why Deferred

Found after P9 while running the manual test plan item on PR #71. The fix changes the migration helpers in both shells and their tests, so it needs its own run. A 0.37.1 patch release fits, ideally before consumers upgrade.
