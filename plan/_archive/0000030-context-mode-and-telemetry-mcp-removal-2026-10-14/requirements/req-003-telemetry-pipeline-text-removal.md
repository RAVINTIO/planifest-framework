---
title: "Requirement: req-003 - Telemetry pipeline text removal"
summary: "Remove telemetry instructions from skills, templates, standards, guides, and living docs."
status: "active"
version: "0.1.0"
---
# Requirement: req-003 - Telemetry pipeline text removal

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Source:** US-002
**Priority:** must-have

## User Story

As the human on the loop, I run the pipeline with no Telemetry MCP hooks, backstops, setup flag, standard, or pipeline instructions, so that no phase spends effort on emission or failure checks.

This requirement covers the text half of US-002. REQ-002 covers the code half.

## Functional Requirements
- Remove every telemetry instruction from the 15 Planifest skills under `planifest-framework/skills/`. That includes each `## Telemetry` section, `emit_event` snippets, `spec_gap` events, and failure-marker checks.
- In the orchestrator skill:
  - remove the Telemetry section, Hard Limit 8's `Telemetry` field rule, and the `CLAUDE.md` emit-phase hook bullet text
  - keep the Phase 0 step 3b hard-stop on `product.yml` `id`, and give it a new rationale: versioning and archive attribution
  - point the 0000027-ADR-003 skill-scope note at nothing telemetry-specific
- Remove the `Telemetry` row from both phase blocks in `templates/build-log.template.md`, and remove the telemetry-gap summary row.
- Remove telemetry and Context Mode text from `templates/standard-boot.md`.
- Delete `standards/telemetry-standards.md`, `docs/0008b--feature--structured-telemetry-framework-integration.md`, and `docs/0008c--feature--structured-telemetry-mcp-changes.md`.
- Remove references from `README.md`, `getting-started.md`, `pipeline-reference.md`, `project-operations.md`, `tool-setup-reference.md`, `standards/reference/backend-stack-evaluation.md`, `planifest-framework/component.yml`, and `refresh-planifest-framework-dir.ps1`.
- Update the living docs: `docs/about.md`, `architecture-overview.md`, `component-registry.md`, `dependency-graph.md`, and `src/setup-hook-integration/` docs and manifest.
- In `docs/decisions-index.md`, mark the telemetry and Context Mode ADRs as superseded by this feature. Mark 0000024 ADR-001 as partly superseded: the `id` stays, and telemetry no longer motivates it.

## Acceptance Criteria
- [ ] No skill, template, standard, guide, or living doc tells an agent to emit, check, or record telemetry.
- [ ] The NFR-001 allowlist-checked `git grep` reports zero matches outside the allowlist.
- [ ] The P0 product-id hard-stop still exists in the orchestrator skill, and its prompt text no longer mentions telemetry.

## Dependencies
- REQ-002, so the text never describes code that still exists, or the reverse, at the P4 check.
