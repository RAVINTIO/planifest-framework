---
title: "ADR 016: Per-project migration run records"
summary: "Each project records each migration run in its own file at plan/_migrations/{stem}.md. The record holds YAML frontmatter with six fields and one of three outcomes: applied, not applicable, or skipped. The record sits under plan/, outside plan/current/, so the write gate admits it before a feature exists and P7 never archives it."
status: "proposed"
version: "0.1.0"
---
# ADR-016 - Per-project migration run records

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

ADR-015 stops migration files from moving, so the folder no longer shows run state. Each project needs its own record of what ran.

The record must meet four needs:

- The framework repo and each downstream project keep separate state.
- Migrations run at session start, before a feature exists. `gate-write` must admit the write without `plan/.orchestrator-active` or `plan/current/design.md`.
- P7 archives `plan/current/`. A record must outlive the feature that wrote it.
- The orchestrator reads records at every session start. The format must parse without judgement.

0000032 ADR 004 put the always-permitted prefixes in `path-rules.mjs`. `plan/` is one of them.

The migrator has three end states today. It completes after confirmed batches, it completes on a clean scan, or the human on the loop answers `none` under its Hard Limit 3.

## Decision

1. Each project writes one record per migration at `plan/_migrations/{stem}.md`. `{stem}` is the migration file name without `.md`.
2. A record holds YAML frontmatter with these fields:

   | Field | Value |
   |-------|-------|
   | `migration` | the migration file name. It must equal `{stem}.md`. |
   | `outcome` | `applied`, `not applicable`, or `skipped` |
   | `date` | the run date as `YYYY-MM-DD` |
   | `framework-version` | the `version` in `planifest-framework/component.yml` at the run |
   | `corrections-applied` | a whole number, `0` or more |
   | `corrections-skipped` | a whole number, `0` or more |

3. The body is one sentence that states the scan result. No agent parses the body.
4. The three outcomes mean:
   - `applied`: the scan ran and the human on the loop answered each batch. A clean scan also gets `applied`, with both counts at `0`.
   - `not applicable`: the migration doesn't apply to this project.
   - `skipped`: the human on the loop answered `none` or skipped the migration.
5. Every outcome counts as a record. No outcome means "findings waiting". ADR-019 covers that case.
6. The migrator replaces its Archive step with a Record step that writes through **Write**. It creates `plan/_migrations/` on its first record.
7. `plan/_migrations/` stays under the always-permitted `plan/` prefix. Stream-01 keeps it admitted with no sentinel and no design.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| One ledger file for all migrations | One file to read | Concurrent or partial writes damage every entry. Each run rewrites the whole file, so idempotence is harder to show. | One file per migration keeps each record independent. |
| Records under `plan/current/` | Inside the feature's own folder | P7 archives `plan/current/`, so records vanish after each feature. Writes need the sentinel or a design. | Migrations run before a feature exists and must persist. |
| Records under `planifest-framework/` | Next to the migrations | `setup.sh` copies the folder downstream, which brings back the shared-state problem. | Defeats the purpose of ADR-015. |
| A fourth outcome such as `findings` | Shows a part-run migration | Breaks the rule that no record means pending (ADR-018). Needs its own resume rule. | Three outcomes cover every end state. A part-run migration stays pending. |
| JSON or YAML file in place of Markdown frontmatter | Stricter parse | Breaks the Markdown convention every other `plan/` artifact follows. | Frontmatter gives the same fields and a readable body. |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | The migrator skill gains a Record step and the record format. `path-rules.mjs` keeps admitting `plan/_migrations/`. |

## Consequences

**Positive:**
- Each project tracks its own runs, so the framework repo and a downstream project can differ.
- Records survive P7, because they sit outside `plan/current/`.
- The write gate admits a record at session start with no feature in progress.
- `framework-version` and the two counts give an audit trail per run.

**Negative:**
- `plan/` gains a second persistent folder next to `plan/_archive/` and `plan/backlog/`.
- A downstream project with no records sees every migration as pending once, after its first refresh (R-003).

**Risks:**
- A stream-01 change to the always-permitted prefixes could block record writes. The req-007 suite writes a record with no sentinel and no design to catch it.
- A hand edit can break a record. ADR-018 treats that record as pending, so the next scan rewrites it.

## Related ADRs

- ADR-015 - depends-on: run state moves here because files stop moving.
- ADR-017 - related-to: assigns ownership of `plan/_migrations/`.
- ADR-018 - extends: defines the pending rule over these records.
- 0000032 ADR 004 - depends-on: the always-permitted `plan/` prefix in `path-rules.mjs`.

## Supersedes

- None

## Superseded By

- None
