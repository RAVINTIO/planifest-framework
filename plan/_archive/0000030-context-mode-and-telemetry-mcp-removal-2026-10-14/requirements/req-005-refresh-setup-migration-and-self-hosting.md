---
title: "Requirement: req-005 - Refresh-setup, migration, and self-hosting"
summary: "Update refresh-setup, remove this repo's own wiring last, and ship a downstream migration."
status: "active"
version: "0.1.0"
---
# Requirement: req-005 - Refresh-setup, migration, and self-hosting

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Source:** US-003
**Priority:** must-have

## User Story

As the human on the loop of a project that already installed either integration, I re-run setup and the stale hooks and settings entries disappear, so that no tool call runs a hook whose file no longer exists.

This requirement covers refresh-setup, the downstream migration, and this repository's own install.

## Functional Requirements
- Remove the Context Mode and Telemetry detection rows from `planifest-framework/skills/planifest-refresh-setup/SKILL.md`. Add one note: setup ignores the three retired flags, so a refresh never offers them.
- Write `planifest-framework/migrations/migrate-remove-context-mode-and-telemetry.md` for downstream projects. It explains what was removed, says that re-running setup does the clean-up, and lists what a person should check by hand: Tier 1 adapter configs, leftover `plan/.telemetry-*` folders, and boot files they don't regenerate.
- Commit the migration file last in P3, after every other code change. It targets downstream installs only.
- Remove this repository's own install in one final P3 step, in this order:
  1. Remove the telemetry entries from `.claude/settings.json`.
  2. Delete `.claude/hooks/telemetry/` and the installed `check-telemetry-*.mjs` and `phase-enum.mjs` copies under `.claude/hooks/enforcement/`.
  3. Delete `.claude/telemetry-enabled` if present, and `plan/.telemetry-failures/`.
  4. Remove `--structured-telemetry-mcp` from `planifest-overrides/setup-config/claude-code.md`.
  5. Remove the `emit-phase-start / emit-phase-end` bullet from the root `CLAUDE.md`, and the same text from any boot-file source that generates it.

## Acceptance Criteria
- [ ] `planifest-refresh-setup` no longer detects or offers either integration.
- [ ] The migration file exists, and it is the last commit of P3.
- [ ] After the final step, this repository's `.claude/settings.json` references no missing file, and a prompt in a new session runs no telemetry hook.

## Dependencies
- REQ-001 to REQ-004 complete first.
