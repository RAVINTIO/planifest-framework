---
title: "Requirement: req-011 - rerun-setup-migration"
summary: "A 0.31.0 migration tells downstream projects to re-run setup so they gain the shell guard and the stderr block reasons."
status: "draft"
version: "0.1.0"
---
# Requirement: req-011 - rerun-setup-migration

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Source:** US-004
**Priority:** should-have

## User Story

As the human on the loop, I want a migration that tells downstream projects to re-run setup, so that they gain the shell guard and the new hook messages.

## Functional Requirements

### Migration (AC-11)

- A new file, `planifest-framework/migrations/migrate-0.31.0-rerun-setup-for-shell-write-guard.md`, follows the layout of `migrate-remove-context-mode-and-telemetry.md`. It has a header block, then the "Background", "What This Migration Does", and "Migrator Instructions" sections.
- The migration tells the migrator to do these steps:
  1. Confirm that `planifest-framework/component.yml` reports `0.31.0` or later. If it's older, stop and ask the human on the loop to refresh `planifest-framework/` first.
  2. Re-run setup for each tool the project uses, with its usual flags. `planifest-refresh-setup` rebuilds those flags.
  3. For Claude Code, check that `.claude/settings.json` holds exactly one `Bash` group that runs `shell-write-guard.mjs`.
  4. Archive the migration to `migrations/_done/`.
- The migration's "Background" names both gains: the Bash hook from req-008, and block reasons on stderr from req-007.

### Tests

- A new Bash suite, `planifest-framework/tests/test-0000032-req-011-rerun-setup-migration.sh`, checks the migration file's location and content.

### Verified by

- `planifest-framework/migrations/migrate-0.31.0-rerun-setup-for-shell-write-guard.md` exists outside `_done/`. It names version `0.31.0`, `shell-write-guard`, and re-running setup.

## Acceptance Criteria

- [ ] A 0.31.0 migration exists in `planifest-framework/migrations/`, outside `_done/`. It names version `0.31.0`, `shell-write-guard`, and re-running setup.
- [ ] The migration's "Background" names both gains, the Bash hook and the stderr block reasons.

## Dependencies

- Req-008: the shell guard that the re-run installs.
- Req-010: the setup registration that the re-run applies.
- Req-007: the stderr block reasons that the re-run installs.
- The ship step bumps `planifest-framework/component.yml` to `0.31.0`, which the migration checks for.
