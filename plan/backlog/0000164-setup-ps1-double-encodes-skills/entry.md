---
title: "Backlog Entry: 0000164 - setup-ps1-double-encodes-skills"
summary: "On Windows PowerShell 5.1, setup.ps1 reads each SKILL.md as ANSI and writes it as UTF-8, so every non-ASCII skill without a byte order mark installs double-encoded."
status: "open"
---
# Backlog Entry: 0000164 - setup-ps1-double-encodes-skills

**Source feature:** 0000036-pipeline-friction-and-gate-fixes
**Source phase:** P2
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

`Copy-RavintioSkills` in `ravintio-framework/setup.ps1` copies each `SKILL.md` and then rewrites four relative paths:

- `setup.ps1:175` reads the copy with `Get-Content -Path $skillMdPath -Raw` and no `-Encoding`.
- `setup.ps1:180` writes it back with `Set-Content ... -Encoding UTF8`.

Windows PowerShell 5.1 reads a file with no byte order mark in the ANSI code page. Each UTF-8 multi-byte character becomes two or three wrong characters, and the UTF-8 write keeps them. PowerShell 7 reads such files as UTF-8, so it isn't affected.

On 2026-10-22, 15 source skills in `ravintio-framework/skills/` hold non-ASCII text. The orchestrator skill starts with a byte order mark, so PowerShell 5.1 reads it correctly. The other 14 install as double-encoded text. They include the design critic, loop runner, migrator, ship agent, and codegen agent.

The 0000036 drift check (`scripts/skill-drift-check.mjs`, ADR-005) reports these copies as stale after every `setup.ps1` run under PowerShell 5.1. That report is correct. `ravintio-refresh-setup` can't clear it, because each re-run double-encodes the copies again.

## Suggested Action

Add `-Encoding UTF8` to the `Get-Content` call at `setup.ps1:175`. Check the other `Get-Content` calls in `setup.ps1` that read framework text for the same gap. Add a suite case that runs the rewrite on a non-ASCII fixture and compares the result with source.

## Why Deferred

`scope.md` for 0000036 puts changes to what setup copies out of scope, and no 0000036 requirement changes `setup.ps1`. The drift check works as designed. It reports real drift here, so the defect doesn't block 0000036.
