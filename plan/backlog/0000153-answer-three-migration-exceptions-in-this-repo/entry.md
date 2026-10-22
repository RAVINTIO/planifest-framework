---
title: "Backlog Entry: 0000153 - Answer three migration exceptions in this repo"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000153 - Answer three migration exceptions in this repo

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-22

---

## Problem

Three migrations in this repo have no `plan/_migrations/` record. Each scan found work that needs an answer from the human on the loop:

- `0001-date-format.md`: about 506 dates outside `DD MMM YYYY` in 283 files. The target clashes with the house `YYYY-MM-DD` rule.
- `0002-british-english.md`: about 870 American spellings in 307 files, mostly "artifact" and "artifacts".
- `retroactive-release-tags.md`: two release commits on `main` have no tag. They are v0.14.0 at `6c145b5` and v0.15.0 at `928f1d4`.

Until each one has a record, the migrator lists it as pending in every session. AC-010.1 of 0000035 req-010 stays open until then.

## Suggested Action

For each migration, the human on the loop picks an outcome: `applied`, `not applicable`, or `skipped`. The migrator then writes the record. `skipped` may fit `0001-date-format.md`. If it does, consider retiring that migration in the framework source.

## Why Deferred

The 0000035 `scope.md` keeps AC-010.1 open for the human on the loop. ADR-019 says a scan with findings records nothing until the human confirms. The exception lines sit in the 0000035 `build-log.md` P3 block.
