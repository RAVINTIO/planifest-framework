---
title: "Scope - Context Mode and Telemetry MCP removal"
summary: "Defines explicit boundaries of what is in scope and out of scope."
status: "active"
version: "0.1.0"
---
# Scope - Context Mode and Telemetry MCP removal

**Skill:** [spec-agent](../skills/spec-agent-SKILL.md)
**Feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Wave:** 1
**Version:** 0.29.0

> All three sections must be present. If "Deferred" is empty, state "Nothing deferred."

## In Scope

- req-001-context-mode-removal (US-001): delete `hooks/context-mode/`, `src/context-mode-hooks/` with its `product.yml` `components[]` item and header comment, `docs/context-mode.md`, the Context Mode install paths in every setup script, and its tests.
- req-002-telemetry-hook-and-setup-removal (US-002): delete `hooks/telemetry/`, `check-telemetry-failures.mjs`, `check-telemetry-receipts.mjs`, `phase-enum.mjs`, `scripts/verify-telemetry-hooks.mjs`, `tests/helpers/controllable-backend.mjs`, and the telemetry tests.
- req-002: remove the telemetry install paths from `setup.sh`, `setup.ps1`, `setup/claude-code.*`, `setup/opencode.*`, and the Tier 1 adapters (`cursor.mjs`, `cline.mjs`, `opencode/index.ts`).
- req-002: remove the `validate-telemetry-schema` job from `.github/workflows/planifest.yml`.
- req-003-telemetry-pipeline-text-removal (US-002): remove telemetry instructions from all 15 Planifest skills, `templates/build-log.template.md` (the Telemetry field and the gap summary row), and `templates/standard-boot.md`.
- req-003: delete `standards/telemetry-standards.md` and the 0008b and 0008c structured-telemetry docs.
- req-003: update `README.md`, getting-started, pipeline-reference, project-operations, tool-setup-reference, living `docs/`, and `src/setup-hook-integration/docs`.
- req-003: keep the orchestrator P0 `product.yml` `id` hard-stop with a new rationale (versioning and archive attribution). Record superseded ADRs in `docs/decisions-index.md`, with 0000024 ADR-001 as partly superseded.
- req-004-install-clean-up-and-retired-flags (US-003): accept `--context-mode-mcp`, `--structured-telemetry-mcp`, and `--backend-url` as no-ops with a one-line notice and exit 0. Never write them to the install marker.
- req-004: add an always-on, path-matched clean-up across every hook event and every installed tool. Remove settings entries before hook folders.
- req-004: remove `.claude/telemetry-enabled`, `plan/.telemetry-failures/`, and `plan/.telemetry-receipts/`.
- req-004: leave a malformed `settings.json` untouched, name the parse error, and skip only the clean-up. If Node is missing, skip the clean-up with a warning and exit 0.
- req-004: write `settings.json` through a temporary file and a rename. Keep hand-added hooks and list each removal. Keep Bash and PowerShell in parity.
- req-005-refresh-setup-migration-and-self-hosting (US-003): remove the `planifest-refresh-setup` detection rows for both integrations.
- req-005: remove this repo's own telemetry wiring from `.claude/settings.json` and the installed `.claude/hooks` copies in one final step, entries before files. In the same step, remove the `emit-phase-start / emit-phase-end` line from the root `CLAUDE.md` and the flags in `planifest-overrides/setup-config/claude-code.md`.
- req-005: add a downstream-only migration file under `planifest-framework/migrations/`, committed last.
- Update the regression manifest so no entry points at a deleted test.

## Out of Scope

- Editing `plan/_archive/` or `plan/changelog/`. Both are immutable history.
- Editing `planifest-framework/external-skills/`. Third-party skills there use "telemetry" in its generic sense.
- Removing `plan/current/build-log.md`, the P8 build assessment, or the `product.yml` `id` field.
- Replacing either integration with another one.
- Changing other enforcement hooks (`gate-write`, `ratchet-check`, `em-dash-guard`), beyond removing telemetry calls.
- Running the migration file in this repo.

## Deferred

Nothing deferred.
