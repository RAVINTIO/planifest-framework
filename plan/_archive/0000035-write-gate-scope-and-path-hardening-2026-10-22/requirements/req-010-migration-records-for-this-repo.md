---
title: "Requirement: req-010 - migration-records-for-this-repo"
summary: "In P3, this repo runs the scans of its six returning migrations and records each result in plan/_migrations/. The two downstream-only migrations get not applicable, and a scan with findings records nothing until the human on the loop answers."
status: "draft"
version: "0.1.0"
---
# Requirement: req-010 - migration-records-for-this-repo

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Source:** US-010 (backlog 0000126)
**Priority:** must-have

## User Story

> One requirement doc = one user story.

As the human on the loop, I see this repo hold a run record for each of its eight migrations, from a scan run here, so that the framework repo shows its own migration state.

## Functional Requirements

- This requirement runs the migrations once in this repo, under the framework rules that [req-007](req-007-migration-run-state.md) sets. Req-007 owns the file layout, the record format in FR-007.2, the pending rule in FR-007.3, and the migrator's Record step. This requirement owns this repo's records and the exception flow for their findings. ADR-019 records the decision.
- The cases for this requirement live in their own suite, `planifest-framework/tests/test-0000035-req-010-migration-records-for-this-repo.sh`, because each requirement owns its suite. The req-007 suite keeps the framework cases.

### FR-010.1 Records in this repo

- In P3, this repo runs the scans of the six migrations returning from `_done/` and writes each record from the result.
- If a scan has findings, P3 brings them to the human on the loop in batches and writes the record after the answer. In `autonomous` mode, this follows the exception list in `planifest-framework/standards/autonomous-run-standards.md`.
- P3 writes `not applicable` records for the two downstream-only migrations without running their Migrator Instructions:
  - `migrate-0.31.0-rerun-setup-for-shell-write-guard.md`
  - `migrate-remove-context-mode-and-telemetry.md`
- For these two, the scan run here is the target check. P3 reads the `**Target:**` line at the top of each file. Both lines name a downstream project. This repo is the framework source, so the target check decides `not applicable`. The migrator skill defines the check in Step 1b.
- "From a scan run here" in the story and in AC-010.1 therefore covers all eight migrations. Six get a full scan, and two get the target check.
- The record body for each of the two names the reason: this repo is the framework source.

### FR-010.2 Judging AC-010.1 in this repo

- In this repo, AC-010.1 passes only once every one of the six scans is clean, or the human on the loop has answered each finding. The two downstream-only migrations count through their `not applicable` records.
- An answer of apply gives an `applied` record. An answer of `none` gives a `skipped` record.
- If any scan has findings in an `autonomous` run, that migration stays pending and gets no record. P3 writes one build-log line in the form `Exception waiting (P3, human review): {migration}: {findings}` for each such migration.
- While an `Exception waiting` line stands for a migration, P4 reports AC-010.1 as open and waiting on the human on the loop. No agent forces a record to close it.
- AC-010.1 closes once the human on the loop answers the findings and the migrator writes the record.

## Acceptance Criteria

- [ ] AC-010.1: This repo holds a record for each of the eight migrations, from a scan run here. Each record passes the req-007 FR-007.3 checks, and the two downstream-only migrations hold `not applicable`.
- [ ] AC-010.2: The body of each of the two `not applicable` records names the reason: this repo is the framework source.
- [ ] AC-010.3: For each migration whose scan has findings in an `autonomous` run, this repo holds no record, and the build log holds one `Exception waiting (P3, human review): {migration}: {findings}` line.

## Dependencies

- [req-007](req-007-migration-run-state.md) sets the record format, the pending rule, and the migrator's Record step that writes each record. Stream 03 builds req-007 first.
- `planifest-framework/standards/autonomous-run-standards.md` exception list, for P3 findings in this repo.
- No dependency on req-001 to req-006, req-008, or req-009.
