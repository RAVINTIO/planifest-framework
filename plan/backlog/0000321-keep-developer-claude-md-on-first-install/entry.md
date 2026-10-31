---
title: "Backlog Entry: 0000321 - keep the developer's CLAUDE.md on first install"
summary: "Back up or warn before setup overwrites an existing boot file that setup didn't write."
status: "open"
---
# Backlog Entry: 0000321 - keep the developer's CLAUDE.md on first install

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Change Pipeline
**Related:** none

---

## Problem

`write_boot_file` in `ravintio-framework/setup.sh` (line 211) overwrites an existing boot file, such as `CLAUDE.md` or `AGENTS.md`. It keeps no backup and gives no warning. It prints only `~ CLAUDE.md (regenerated from template)`.

This behaviour is deliberate. 0000029 ADR-001 treats boot files as build outputs, and `ravintio-overrides/instructions/` holds local customisation. The decision assumes setup wrote the file in the first place.

On a first install, that assumption fails. A developer adds Framework to a repo that already has a hand-written `CLAUDE.md`. Setup replaces it, and the developer's instructions are gone. If the file was never committed, git can't bring it back. Setup should never destroy a project record without a trace.

RAVINTIO Zero backlog 0000290 covers the same gap.

## Suggested Action

- Before `write_boot_file` replaces a file, check whether setup wrote it. A marker line in the template would show this.
- If setup didn't write it, copy it to a backup, such as `CLAUDE.md.pre-ravintio`, and print the backup path.
- Suggest moving its content into `ravintio-overrides/instructions/`.
- Keep the current behaviour for files that setup wrote.
- Make the same change in `setup.ps1`.

## Wanted outcome

- A first install over a hand-written `CLAUDE.md` leaves a backup with the original bytes.
- Setup prints the backup path.
- A re-run over a setup-written boot file makes no backup.
- `setup.sh` and `setup.ps1` behave the same.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It amends the intent of 0000029 ADR-001, so it needs its own decision.
