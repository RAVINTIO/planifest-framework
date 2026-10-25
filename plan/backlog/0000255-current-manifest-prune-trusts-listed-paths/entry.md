---
title: "Backlog Entry: 0000255 - Current manifest prune trusts listed paths"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000255 - Current manifest prune trusts listed paths

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

Setup prunes skill folders that the installed-skills manifest lists, at `ravintio-framework/setup.sh` around lines 1105 to 1115 and `setup.ps1` around lines 1335 to 1345. It doesn't check that each listed path sits inside the tool's skills folder. A manifest entry that is absolute, holds `..`, or passes through a linked parent can make setup delete a folder outside the repo. The P5 review of 0000039 found the same gap in that feature's new old-manifest prune and fixed it there. This older prune predates 0000039.

## Suggested Action

Resolve each entry's parent with `pwd -P` in Bash and `Get-Item ... FullName` in PowerShell. Delete only when that parent equals the real skills folder, and act on the joined path. Add survival tests for an absolute path, a `..` path, and a linked parent.

## Why Deferred

Out of scope. 0000039 fixes only the prune it added, and this one needs its own tests across the per-tool setup scripts.
