---
title: "Backlog Entry: 0000301 - remove the bundled third-party skills"
summary: "Delete external-skills/, skill-sync, and --include-full-skill-library, and offer a migration path for skills a developer wants to keep."
status: "open"
---
# Backlog Entry: 0000301 - remove the bundled third-party skills

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline (not Fast Path, because it touches `setup.sh`, `setup.ps1`, and boot Hard Limit 8)
**Related:** 0000272, 0000302, 0000263

---

## Context

A review of the sibling repo RAVINTIO Zero on 2026-10-31 compared the two packs' skill libraries. Zero removed its bundled library. Framework targets regulated industries, such as those that follow GAMP 5. There, every piece of installed agent guidance needs a known source, a known licence, and a named approver. The human doesn't want Framework to bundle third-party skills.

## Problem

Framework ships and fetches skills that nobody reviewed for this use:

- **The bundle.** `ravintio-framework/external-skills/` holds 372 skill folders. Their `attribution.txt` files declare 358 MIT and 14 Apache-2.0.
- **Wrong licence records.** 152 of the MIT folders say "original work" with copyright holder "Unknown". Their `attribution.txt` carries Apache-2.0 licence text.
- **Wrong count.** `external-skills/README.md` line 4 says 200 skills.
- **Unchecked fetches.** `scripts/skill-sync.sh` and `scripts/skill-sync.ps1` fetch from `anthropics/skills` with no approval or licence check. That repo includes source-available skills that aren't open source.
- **Automatic sync.** `setup.sh` runs `skill-sync.sh sync` at the end of every tool setup (lines 1418 to 1422), and `setup.ps1` does the same.

## Suggested Action

Remove the bundle and every route to it:

- Delete `ravintio-framework/external-skills/`.
- Delete `scripts/skill-sync.sh` and `scripts/skill-sync.ps1`.
- Remove the `add-skill`, `remove-skill`, `preserve-skill`, and `unpreserve-skill` subcommands from setup.
- Remove `copy_external_skills` from `setup.sh`, its twin from `setup.ps1`, and the sync step at the end of setup.
- Retire `--include-full-skill-library`. Setup exits 1 and names the retired flag, as Zero 0000196 req-002 does.

Update every reference to the flag or the bundle:

- the Hard Limit 8 text in the generated `CLAUDE.md`, `templates/standard-boot.md`, and `templates/cursor-boot.md`
- the 0.37.0 migration (`.md`, `.sh`, and `.ps1`) and `refresh-ravintio-framework-dir.ps1`, which pass the flag
- the flag inference in `skills/ravintio-refresh-setup/SKILL.md` line 68
- the `plan/current/external-skills/` line in `ravintio-framework/.gitignore`
- `tool-setup-reference.md`, the `src/setup-hook-integration/docs/` contracts, and `docs/decisions-index.md`
- about 20 test files, which mention the flag, the bundle, or skill sync

Delete `tests/test-attribution-validation.sh` and `tests/test-skill-sync-security.sh`. The three regression copies that mention the flag change only with human sign-off.

Add a migration that lists the external skills installed in each tool folder. For each one the developer keeps, it offers a move into `ravintio-overrides/capability-skills/` with a draft provenance record left unapproved (see 0000302).

## Prerequisite

Fix 0000272 first. Until then, the re-run can delete developers' own skill folders that the setup manifest lists wrongly.

## Licence

Removal ends the duty to carry the bundled licence texts. Past release tags keep their attribution files, so earlier releases stay compliant.

## Zero precedent

- 0000030 framework cut-down (`zero/plan/changelog/0000030-framework-cut-down-2026-08-22.md`)
- 0000034 setup hardening
- 0000196 setup argument checks

## Wanted outcome

A fresh install and a re-run install no third-party skill. Setup rejects the retired flag by name. Every kept skill sits in `ravintio-overrides/capability-skills/` awaiting human approval.

## Why Deferred

The human asked for it on 2026-10-31. It touches setup, boot files, a migration, and regression tests, so it needs the Change Pipeline.
