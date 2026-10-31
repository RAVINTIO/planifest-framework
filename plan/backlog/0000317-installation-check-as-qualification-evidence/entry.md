---
title: "Backlog Entry: 0000317 - installation check as qualification evidence"
summary: "Add a setup installation check that verifies the install and writes a dated report into the evidence pack as an installation qualification record."
status: "open"
---
# Backlog Entry: 0000317 - installation check as qualification evidence

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Feature Pipeline
**Related:** 0000293, 0000309

---

## Problem

Nothing in Framework confirms that an install is complete and correct. Two tools come close, and neither covers the whole install:

- `ravintio-refresh-setup` reconstructs the flags and runs setup again. It doesn't verify the result.
- `ravintio-framework/scripts/skill-drift-check.mjs` compares installed `SKILL.md` copies with the source. It checks skills only.

A regulated team must show that a tool works as installed before they rely on it. GAMP 5 calls this installation qualification. Today the team has no record to show.

RAVINTIO Zero backlog 0000283 plans an update command and a `doctor` command for the same gap.

## Suggested Action

Add an installation check to `setup.sh` and `setup.ps1`. Name it an installation check, not `doctor`. It reports on these points:

- whether setup ran for the tool
- whether each hook file can run, and whether the tool's settings wire it
- whether installed skills match the pack
- whether the flags in `.ravintio-setup-flags` match the wiring
- leftovers from an older pack, such as old-name files or retired hooks

The check never changes a file outside its report. It writes a dated report into the evidence pack, with the pack version, the tool, and each result. That report serves as the installation qualification record.

## Wanted outcome

- The check exits non-zero when any item fails, and names the item.
- A clean install produces a report with every item passed.
- A removed or unwired hook makes the check fail.
- `setup.sh` and `setup.ps1` give the same results.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It needs its own design, including where the evidence pack lives.
