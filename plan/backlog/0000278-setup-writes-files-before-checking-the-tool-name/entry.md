---
title: "Backlog Entry: 0000278 - setup writes files before checking the tool name"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000278 - setup writes files before checking the tool name

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P9
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

`ravintio-framework/setup.sh claude` names a tool that doesn't exist. The valid name is `claude-code`. Setup still writes these files before it stops with `Error: no config file at setup/claude.sh`:

- `.gitattributes`, `.gitignore`, and the tool ignore files
- `.github/workflows/ravintio.yml`
- `plan/` and `src/README.md`
- `git config core.hooksPath`

The agent saw this on 2026-10-25 in an empty test repo at 0.37.0, and the same happens at `v0.36.0`. The `VALID_TOOLS` list exists, but setup checks it only after the shared steps run.

## Suggested Action

Check the tool name against `VALID_TOOLS` before the first write, in both `setup.sh` and `setup.ps1`. Exit non-zero with the list of valid names. Add a test that runs setup with an unknown tool name and checks that the project gains no file.

## Why Deferred

Out of scope for 0000039, which doesn't change setup's argument handling. The fix touches `setup.sh` and `setup.ps1`, so it needs the Change Pipeline.
