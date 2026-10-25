---
title: "Requirement: req-002 - runtime-names"
summary: "Setup state files, boot-file markers, and the old-pack stop use RAVINTIO names, and setup reads the old names once."
status: "draft"
version: "0.1.0"
---
# Requirement: req-002 - runtime-names

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Source:** US-001
**Priority:** must-have

## User Story

As a human on the loop, I re-run setup in a consumer repo and see only RAVINTIO state files and blocks, so that the pack matches the RAVINTIO org and nothing appears twice.

## Functional Requirements
- Setup and the hooks write `.ravintio-session`, `.ravintio-manifest`, and `.ravintio-setup-flags` in place of the `.planifest-*` files. This covers `setup.sh`, `setup.ps1`, `setup/*.sh`, `setup/*.ps1`, and the `planifest-refresh-setup` skill (renamed in req-001).
- Setup and the refresh-setup skill read an old `.planifest-setup-flags` once, carry its flags into the new marker, and remove it. Setup reads an old `.planifest-manifest` once to remove the old installed skill folders, then removes the file. This is the pruning of stale `planifest-*` skill copies.
- Setup recognises the old boot-file markers `<!-- planifest-overrides:instructions:start -->` and `<!-- planifest-overrides:instructions:end -->`. It replaces that block with the `ravintio-overrides` form.
- Setup recognises the old ignore-file headers `# Planifest - Token Reduction` and `# Planifest - Indexing Exclusions`. It replaces each block with the RAVINTIO header. No block appears twice after a re-run.
- While `planifest-framework/` or `planifest-overrides/` exists, setup stops before it writes anything. The message names the consumer migration `migrate-0.37.0-ravintio-rename`.
- The old-name reads stay through 0.x and go at 1.0.0 (design decision, 2026-10-25).
- Split step, in two answers. At drafting the answer was split: the names that hooks and generated files emit went to req-008. At the fourth criterion the answer was keep: all four remaining criteria cover the state setup leaves in a consumer repo.
- A repo with no old pack and no old markers gets only `.ravintio-*` markers and new-form blocks. Setup prints no migration message.

## Acceptance Criteria
- [ ] After setup runs on a fixture with `.planifest-setup-flags` and `.planifest-manifest`, only the `.ravintio-*` files remain. The new flags marker holds the old flags, the old installed skill folders are gone, and no `.planifest-*` marker is left. Verified by: integration
- [ ] After setup runs twice on a fixture with the old boot-file markers and the old ignore-file headers, each block appears exactly once, in the RAVINTIO form. The suites pass under Bash 3.2 and Bash 5. Verified by: integration
- [ ] When `planifest-framework/` or `planifest-overrides/` exists, `setup.sh` and `setup.ps1` exit non-zero, write nothing, and name `migrate-0.37.0-ravintio-rename` in the message. Verified by: integration
- [ ] Setup on a repo with no old pack and no old markers writes only `.ravintio-*` markers and new-form blocks, and prints no migration message. Verified by: integration

## Dependencies
- req-001-pack-paths-and-identifiers renames the setup scripts and skill folders that this requirement edits.
- req-006-consumer-migration supplies the migration that the stop message names.
- req-008-emitted-names covers the names setup writes into generated files.
- 0000035 ADR 010 sets the pattern for a migration record with outcome `not applicable` in this source repo.
