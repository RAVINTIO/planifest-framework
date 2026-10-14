---
title: "Requirement: req-002 - Telemetry hook and setup removal"
summary: "Delete the Telemetry MCP hooks, backstops, helper scripts, install paths, and CI job."
status: "active"
version: "0.1.0"
---
# Requirement: req-002 - Telemetry hook and setup removal

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Source:** US-002
**Priority:** must-have

## User Story

As the human on the loop, I run the pipeline with no Telemetry MCP hooks, backstops, setup flag, standard, or pipeline instructions, so that no phase spends effort on emission or failure checks.

This requirement covers the code half of US-002. REQ-003 covers the text half.

## Functional Requirements
- Delete `planifest-framework/hooks/telemetry/` (9 modules).
- Delete `hooks/enforcement/check-telemetry-failures.mjs`, `check-telemetry-receipts.mjs`, and `phase-enum.mjs`. Only telemetry code imports `phase-enum.mjs`. Codegen confirms this with a search before deleting it.
- Delete `planifest-framework/scripts/verify-telemetry-hooks.mjs` and `planifest-framework/tests/helpers/controllable-backend.mjs`.
- Remove every telemetry install and wiring path from these files:
  - `setup.sh` and `setup.ps1`, including the Tier 1 telemetry copy and the `.claude/telemetry-enabled` sentinel write
  - `setup/claude-code.sh` and `setup/claude-code.ps1`
  - `setup/opencode.sh` and `setup/opencode.ps1`
- Remove telemetry calls and references from the Tier 1 adapters: `hooks/adapters/cursor.mjs`, `cline.mjs`, and `opencode/index.ts`.
- Remove telemetry comments from `hooks/enforcement/read-stdin.mjs`. Its behaviour does not change.
- Remove the `validate-telemetry-schema` job from `.github/workflows/planifest.yml`.
- Remove the telemetry line from `.gitignore`.
- Delete or rewrite every test that asserts telemetry behaviour. Update `tests/regression/regression-manifest.json` so no entry points at a deleted test.

## Acceptance Criteria
- [ ] None of the deleted files exist, and no remaining file imports or calls any of them.
- [ ] A fresh `setup.sh` run for `claude-code`, `cursor`, and `opencode` in fixture projects creates no `telemetry` folder, no `.claude/telemetry-enabled`, and no entry that runs a telemetry hook.
- [ ] `planifest-framework/tests/run-tests.sh` passes, and CI has no `validate-telemetry-schema` job.

## Dependencies
- REQ-004 (retired flags) must land in the same change set, so setup never rejects `--structured-telemetry-mcp` or `--backend-url`.
- REQ-005 owns this repo's own installed copies under `.claude/`. REQ-002 must not touch them.
