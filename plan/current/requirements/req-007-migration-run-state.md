---
title: "Requirement: req-007 - migration-run-state"
summary: "Migration files stay in planifest-framework/migrations/, and each project records its own runs in plan/_migrations/."
status: "draft"
version: "0.1.0"
---
# Requirement: req-007 - migration-run-state

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Source:** US-007 (backlog 0000126)
**Priority:** must-have

## User Story

As the human on the loop, I see every migration stay in `planifest-framework/migrations/` with its run state recorded in `plan/_migrations/`, so that the framework repo and each downstream project track their own runs.

## Functional Requirements

### FR-007.1 Migration files never move

- Every migration file sits at the top level of `planifest-framework/migrations/`. The migrator never moves, renames, or deletes a migration file.
- P3 moves the six files in `planifest-framework/migrations/_done/` back to `planifest-framework/migrations/`, with their names unchanged:
  - `0001-date-format.md`
  - `0002-british-english.md`
  - `0003-archive-dirname.md`
  - `migrate-adoption-mode-and-about-md.md`
  - `migrate-product-yml-component-paths.md`
  - `retroactive-release-tags.md`
- P3 deletes `planifest-framework/migrations/_done/.gitkeep`, so `_done/` no longer exists.
- The helper scripts `migrate-archive-dirname.sh` and `migrate-archive-dirname.ps1` stay where they are. They now sit beside `0003-archive-dirname.md`.
- A migration is any top-level `*.md` file in `planifest-framework/migrations/`. Helper scripts and subfolders, such as `_progress/` or a leftover `_done/`, are not migrations.
- `planifest-framework/component.yml` keeps `migrationPath: "planifest-framework/migrations/"`.

### FR-007.2 Run record format

- Each project writes one record per migration at `plan/_migrations/{stem}.md`. `{stem}` is the migration file name without `.md`. For example, `0001-date-format.md` gets `plan/_migrations/0001-date-format.md`.
- A record holds YAML frontmatter with these fields:

  | Field | Value |
  |-------|-------|
  | `migration` | the migration file name, such as `0001-date-format.md`. It must equal `{stem}.md`. |
  | `outcome` | `applied`, `not applicable`, or `skipped` |
  | `date` | the run date as `YYYY-MM-DD` |
  | `framework-version` | the `version` value in `planifest-framework/component.yml` at the run |
  | `corrections-applied` | a whole number, `0` or more |
  | `corrections-skipped` | a whole number, `0` or more |

- The body after the frontmatter is one sentence that states the scan result. The orchestrator and migrator never read the body.
- The migrator sets `outcome` from the scan result:
  - `applied`: the scan ran, and the human on the loop confirmed each batch. A clean scan with no findings also gets `applied`, with both counts at `0`.
  - `not applicable`: the migration doesn't apply to this project. This repo uses it for the two downstream-only migrations.
  - `skipped`: the human on the loop answered `none` or skipped the migration. This matches the migrator's Hard Limit 3.
- A `not applicable` record counts as a record, the same as the other two outcomes.

### FR-007.3 Pending rule

- A migration is pending when `plan/_migrations/{stem}.md` doesn't exist.
- A migration is also pending when its record can't be read. A record can't be read when any of these hold:
  - the file has no YAML frontmatter, or the frontmatter doesn't parse
  - `migration` is missing or doesn't equal `{stem}.md`
  - `outcome` is missing or isn't one of the three values
  - `date` is missing or isn't `YYYY-MM-DD`
- When resume detection finds a record it can't read, it names the record file and treats the migration as pending.
- A record in `plan/_migrations/` with no matching migration file is ignored. It never makes a migration pending.

### FR-007.4 Migrator behaviour

- `planifest-framework/skills/planifest-migrator/SKILL.md` replaces Step 5 (Archive) with a Record step. The step writes the record from FR-007.2 through **Write**.
- The migrator creates `plan/_migrations/` on its first record. It never needs the folder to exist beforehand.
- A scan with findings writes no record until the human on the loop answers every batch. Until then, the migration stays pending, and the next session runs it again.
- The completion report names the record path in place of the `_done/` path.
- The migrator description in the frontmatter says that it records the migration, not that it archives it.
- Each migration file replaces its own move-to-`_done/` instruction with an instruction to record the outcome. Six files carry that instruction:
  - `0001-date-format.md`
  - `0002-british-english.md`
  - `0003-archive-dirname.md`
  - `migrate-product-yml-component-paths.md`
  - `migrate-0.31.0-rerun-setup-for-shell-write-guard.md`
  - `migrate-remove-context-mode-and-telemetry.md`
- `migrate-adoption-mode-and-about-md.md` and `retroactive-release-tags.md` also drop their `_done/` text. `retroactive-release-tags.md` drops its `mkdir` and `mv` commands for `_done/`.
- A migration section headed `## Archive` takes the heading `## Record`.

### FR-007.5 Idempotence

- If a readable record already exists, resume detection doesn't list the migration, and the migrator doesn't run it.
- If the human on the loop asks for a re-run, the migrator runs the scan again. A second run with nothing left to fix gives the same outcome.
- If the re-run outcome equals the outcome in the record, the migrator leaves the record file unchanged. Two runs leave one record with the same content.

### FR-007.6 Orchestrator resume detection

- `planifest-framework/skills/planifest-orchestrator/SKILL.md` Resume Detection step 1 lists each top-level `*.md` file in `planifest-framework/migrations/`. It reports as pending each one with no readable record under FR-007.3.
- Step 1 invokes `planifest-migrator` for each pending migration, in file-name order, before any other phase work.
- Step 1 never reads `_done/` and never treats a file in a subfolder as a migration.

### FR-007.7 Downstream projects

- A downstream project treats all eight migrations as applicable. Each scan decides the outcome.
- A project with no `plan/_migrations/` folder sees every migration as pending. Each scan runs, and a compliant project gets a clean scan and an `applied` record.
- Nothing seeds records from an old `_done/` folder.
- A framework refresh that copies `planifest-framework/` over an older copy can leave an old `_done/` folder behind. Resume detection ignores it under FR-007.6.
- `setup.sh` and `setup.ps1` don't copy `planifest-framework/migrations/` and don't read `_done/`. They need no change.

### FR-007.8 Write gate

- `plan/_migrations/` sits under the always-permitted `plan/` prefix in `path-rules.mjs`. It isn't under `plan/current/`, so a record write needs neither `plan/.orchestrator-active` nor `plan/current/design.md`.
- Migrations run at session start, before a feature exists. The gate must keep admitting record writes then.
- P7 archives only `plan/current/`, so records stay in `plan/_migrations/` across features.

### FR-007.9 Records in this repo

- In P3, this repo runs the scans of the six migrations returning from `_done/` and writes each record from the result.
- If a scan has findings, P3 brings them to the human on the loop in batches and writes the record after the answer. In `autonomous` mode, this follows the exception list in `planifest-framework/standards/autonomous-run-standards.md`.
- P3 writes `not applicable` records for the two downstream-only migrations without running them:
  - `migrate-0.31.0-rerun-setup-for-shell-write-guard.md`
  - `migrate-remove-context-mode-and-telemetry.md`
- The record body for each of the two names the reason: this repo is the framework source.

### FR-007.11 Judging AC-007.3 in this repo

- In this repo, AC-007.3 passes only once every one of the six scans is clean, or the human on the loop has answered each finding. The two downstream-only migrations count through their `not applicable` records.
- An answer of apply gives an `applied` record. An answer of `none` gives a `skipped` record.
- If any scan has findings in an `autonomous` run, that migration stays pending and gets no record. P3 writes one build-log line in the form `Exception waiting (P3, human review): {migration}: {findings}` for each such migration.
- While an `Exception waiting` line stands for a migration, P4 reports AC-007.3 as open and waiting on the human on the loop. No agent forces a record to close it.
- AC-007.3 closes once the human on the loop answers the findings and the migrator writes the record.

### FR-007.10 Documentation and tests

- `planifest-framework/pipeline-reference.md` "Check for pending migrations" describes the record rule. It drops the `grep -v _done` and `-notmatch '_done'` commands.
- `planifest-framework/project-operations.md` says that a pending migration is one with no record in `plan/_migrations/`.
- `README.md` describes `migrations/` as the framework's migrations, with run state kept in `plan/_migrations/`.
- The `docs/decisions-index.md` entry for 0000005 ADR 005 no longer says that applied migrations go to `_done/`.
- These suites drop their `_done/` expectations and check the new layout:
  - `planifest-framework/tests/test-0000005-framework-governance.sh` and `planifest-framework/tests/regression/test-0000005-framework-governance.sh` (req-014 block)
  - `planifest-framework/tests/test-0000032-req-011-rerun-setup-migration.sh` (the `DONE_COPY` check, the `## Archive` section, and the `_done/` text check)
- A new suite `planifest-framework/tests/test-0000035-req-007-migration-run-state.sh` checks AC-007.1 to AC-007.3.

## Acceptance Criteria

- [ ] AC-007.1: No migration file moves when it runs, and `_done/` no longer exists. All eight migration files sit at the top level of `planifest-framework/migrations/`, and no skill, migration, test, or doc tells an agent to move one.
- [ ] AC-007.2: Resume detection lists as pending only migrations with no readable record in `plan/_migrations/`. The orchestrator and migrator skills state the record format, the three outcomes, and the unreadable-record rule.
- [ ] AC-007.3: This repo holds a record for each of the eight migrations, from a scan run here. Each record passes the FR-007.3 checks, and the two downstream-only migrations hold `not applicable`.

## Dependencies

- `path-rules.mjs` always-permitted `plan/` prefix (stream-01 changes this file in req-001 and req-003 to req-006). Stream-01 must keep `plan/_migrations/` admitted without a sentinel or design.
- `planifest-framework/standards/autonomous-run-standards.md` exception list, for P3 findings in this repo.
- Shares `planifest-framework/skills/planifest-orchestrator/SKILL.md` with stream-01, which may edit the Fast Path section. This requirement edits only Resume Detection step 1.
