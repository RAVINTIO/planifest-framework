---
title: "Requirement: req-009 - migration-ordering-and-old-paths"
summary: "The migrator finds the rename migration after the pack copy, runs older migrations against the new paths, and skips the rename in this source repo."
status: "draft"
version: "0.1.0"
---
# Requirement: req-009 - migration-ordering-and-old-paths

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Source:** US-002
**Priority:** must-have

## User Story

As a human on the loop with a consumer repo on an older version, I get older migrations and the rename migration in a coherent order, so that no migration reads a path that has moved.

## Functional Requirements
- Fact 1: the orchestrator lists pending migrations from `planifest-framework/migrations/` and runs them in file-name order. After the rename it lists `ravintio-framework/migrations/`.
- Fact 2: `migrate-0.37.0-ravintio-rename.md` sorts before `migrate-adoption-mode-and-about-md.md`, `migrate-product-yml-component-paths.md`, `migrate-remove-context-mode-and-telemetry.md`, and `retroactive-release-tags.md`. Shipped migration bodies stay byte-identical and name `planifest-framework/` paths.
- Fact 3: an installed 0.36.0 orchestrator scans only `planifest-framework/migrations/`. It cannot find the rename migration in the copied `ravintio-framework/`. So the consumer runs the helper by hand, from the upgrade steps, before setup. The new orchestrator then finds the migration pending, because the helper writes no record.
- Keep file-name order. Resolve the old paths instead of moving the rename migration to the end.
  - The orchestrator and the `ravintio-migrator` skill read pending migrations from `ravintio-framework/migrations/`.
  - When the migrator runs a migration shipped before 0.37.0, it reads `planifest-framework/` as `ravintio-framework/`, `planifest-overrides/` as `ravintio-overrides/`, and `planifest-` skill names as `ravintio-`. It applies the mapping to paths it reads and writes, never to the shipped file.
  - The migrator never reads `.ravintio-backup/` as a live pack.
- The migrator runs `migrate-0.37.0-ravintio-rename.md` in a consumer repo as a check pass. The helper has already run, so the pass confirms the old folders are gone, runs the helper again to confirm it does nothing, and records `applied`.
- The migrator reads the `**Applies when:**` line near the top of a migration. If the condition is false, it skips Steps 2 to 4, reports `Skipped:` with the reason, and records `not applicable` with both counts at `0`. This source repo gets that record at `plan/_migrations/migrate-0.37.0-ravintio-rename.md`, per 0000035 ADR 010.
- The condition names the backup folder as well as the two old folders (req-006). After a hand-run helper, only the backup remains, so the condition is true and the check pass records `applied`. The migrator reads the backup's presence only. It never reads files inside it.
- A fresh consumer install has no old pack and no backup, so its `Applies when:` condition is false too. The migrator writes the same `not applicable` record there, so the migration never shows as pending.
- The orchestrator reports each migration it skips for a false `Applies when:` condition. It does not skip one silently.
- The migrator's framework source check reads `id: "ravintio-framework"` in the root `product.yml`, in place of `id: "planifest-framework"`.
- Split step: this requirement holds the migrator and orchestrator behaviour. The helper's file moves belong to req-006.

## Acceptance Criteria
- [ ] In a fixture consumer repo on 0.36.0 with unrecorded older migrations, the migrator runs them in file-name order against `ravintio-framework/` and `ravintio-overrides/` paths and never reads `.ravintio-backup/`. Verified by: integration
- [ ] After the helper has run, the migrator confirms the rename migration with a no-op helper rerun and writes an `applied` record. Verified by: integration
- [ ] In this source repo and in a fresh consumer install, the migrator reads `Applies when:` as false, reports `Skipped:`, and writes a `not applicable` record. Verified by: integration

## Dependencies
- req-006 (consumer-migration) provides the migration file, its `Applies when:` line, and the helpers.
- req-001 (pack-paths-and-identifiers) renames the migrator and orchestrator skills and the migrations folder.
- 0000035 ADR 010 sets the rule that this repo keeps a run record for every migration it ships.
- RAVINTIO Zero 0000160 ADR 003 defines the `Applies when:` field and its skip rule.
