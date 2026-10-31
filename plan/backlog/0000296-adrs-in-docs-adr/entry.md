---
title: "Backlog Entry: 0000296 - keep ADRs in docs/adr with repo-wide numbers"
summary: "Move ADRs out of the archive into docs/adr, number them from a counter file, and migrate the existing ones."
status: "open"
---
# Backlog Entry: 0000296 - keep ADRs in docs/adr with repo-wide numbers

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-31

---

## Context

This entry is a copy of RAVINTIO Zero backlog entry 0000280, filed on 2026-10-31. Both packs store ADRs the same way, so the human asked for the entry in both. The evidence below is Framework's own.

## Problem

P2 Architecture Decisions writes each ADR to `plan/current/adr/ADR-{NNN}-{title}.md`, and P7 Archive moves it to `plan/_archive/{feature}/adr/`. The archive is the only home of an ADR's text. On 2026-10-31, 36 archived features held 198 ADR files.

- **Numbers repeat.** Each feature numbers from ADR-001, so a decision is known only as "0000031 ADR-001". The header of `docs/decisions-index.md` already tracks cross-feature chains, such as "ADR-012 and ADR-013 amend 0000031 ADR-001" and "ADR-015 partly supersedes 0000005 ADR-005". Those chains are hard to follow with repeated numbers.
- **The archive isn't a permanent home.** An ADR stays valid after its run ends, but the archive holds run history. A future archive cleanup would remove decisions that still bind. Zero lost the ADRs of 29 features this way, when one feature emptied its archive.
- **The index is the only safeguard.** `docs/decisions-index.md` lists every archived feature today. Nothing checks that it stays complete.

## Suggested Action

- Make `docs/adr/` the permanent home of every ADR. Name each file `{number}-{slug}.md`, for example `0042-rename-map.md`.
- Add a counter file, `docs/adr/.next-id`, that works like `plan/backlog/.next-id`. Reserve ADR numbers from it with the pack's id reservation script and a counter path. Choose the number width at pickup.
- Change the workflow that writes ADRs:
  - In P2, `ravintio-adr-agent` reserves a number from `docs/adr/.next-id` for each new ADR and commits the counter on its own, as for backlog ids.
  - The ADR goes straight to `docs/adr/`, with status `proposed`. Ship sets it to `accepted`.
  - A superseding or amending ADR names the one it changes, and the old ADR gets "Superseded by {number}" or "Amended by {number}". Nobody deletes an ADR.
  - P6 Documentation updates `docs/decisions-index.md` with one row per new ADR. P7 Archive links to `docs/adr/` instead of moving copies.
- Add a migration in `ravintio-framework/migrations/` that moves existing ADRs:
  - It assigns repo-wide numbers in feature order, then ADR order within a feature.
  - It rewrites "supersedes", "amends", and "narrows" references to the new numbers.
  - It replaces archived copies with links, and rebuilds `docs/decisions-index.md` from `docs/adr/`.
  - It sets `docs/adr/.next-id` to one past the highest number.
  - Its `Applies when:` condition covers the pack source too, since this repo holds 198 archived ADRs.

## Wanted outcome

Every ADR lives in `docs/adr/` under a unique repo-wide number, and the index lists all of them. Tests check these conditions:

- `ravintio-adr-agent` reserves ADR numbers from `docs/adr/.next-id` and never reuses one.
- No ADR file remains under `plan/_archive/*/adr/` after the migration. Each archive links to its ADRs in `docs/adr/`.
- Every file in `docs/adr/` has one row in `docs/decisions-index.md`, and every row points at an existing file.
- Every "supersedes", "amends", and "narrows" reference names an existing ADR number.
- Running the migration twice changes nothing the second time.

## Open questions

- ADR titles for features 0000001 to 0000010 were inferred from filenames at bootstrap. Should the migration flag them for human review?
- Should an ADR that belongs to one component live in `src/{component}/docs/adr/` instead, with its own counter?

## Why Deferred

The human asked for it on 2026-10-31. It needs its own design and a migration.
