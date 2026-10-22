---
title: "ADR 015: Migration files never move"
summary: "Every migration file stays at the top level of planifest-framework/migrations/. The migrator never moves, renames, or deletes one, and the _done/ folder goes away. P3 returns the six files in _done/ by a Write copy, a cmp byte check, and git rm. This replaces the archive-to-_done part of 0000005 ADR 005."
status: "proposed"
version: "0.1.0"
---
# ADR-015 - Migration files never move

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

0000005 ADR 005 made migrations Markdown files in `planifest-framework/migrations/`. The migrator moves each file to `migrations/_done/` when it completes. The folder location is the run state.

That state lives in the framework folder, and `setup.sh` copies the framework folder into every downstream project. The framework repo and each downstream project can't hold different run states for the same migration. Backlog 0000126 records the problem. A file in `_done/` here reads as applied everywhere the folder is copied.

Six files sit in `_done/` today. Two downstream-only migrations sit at the top level, because this repo never runs them.

Hard Limit 8 requires changes through **Write** or **Edit**. A shell `mv` or `rm` breaks it.

## Decision

1. Migration files never move. Every migration file sits at the top level of `planifest-framework/migrations/`. The migrator never moves, renames, or deletes one.
2. A migration is any top-level `*.md` file in `planifest-framework/migrations/`. Helper scripts and subfolders are not migrations.
3. The `_done/` folder goes away. P3 returns its six files to the top level with their names unchanged and deletes `_done/.gitkeep`.
4. P3 returns each file in three steps:
   1. It writes the exact old content at the new path with **Write**.
   2. It checks that the new file is byte-identical to the old one with `cmp` or `git diff --no-index`.
   3. It removes the old file with `git rm`.
5. If the byte check fails, P3 keeps the old file. It rewrites the copy once and checks again. A second failure logs an `Exception waiting (P3, human review)` line and leaves both files in place.
6. P3 never uses `mv` or `rm` for these files.
7. `migrationPath` in `planifest-framework/component.yml` stays `planifest-framework/migrations/`.

Run state moves out of the framework folder. ADR-016 records where it goes.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep `_done/` and stop copying it downstream | Smallest change to the migrator | `setup.sh` would need a filter. A refresh over an older copy still leaves `_done/` behind. Run state stays in the shipped folder. | Run state still can't differ per project. |
| Keep `_done/` here and record downstream state elsewhere | No change to this repo's layout | Two state models, one per kind of project. The framework repo tests a layout no downstream project uses. | Two rules for one question breed drift. |
| Return the files with `git mv` | One command per file, history kept | `git mv` writes files outside **Write**. The shell guard passes git commands, so nothing enforces the boundary. | Hard Limit 8 allows only **Write** and **Edit** for content changes. |
| Return the files with `cp` then `rm` | Familiar | Both commands break Hard Limit 8. | Hard Limit 8. |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `migrations/` loses `_done/`. The migrator drops its Archive step. Six migration files drop their move instruction. Tests and docs drop `_done/` expectations. |

## Consequences

**Positive:**
- The shipped framework folder carries no run state, so every project starts from the same migration set.
- A migration path never changes, so links and references to a migration stay valid.
- The return path for the six files stays inside Hard Limit 8 and checks each copy byte for byte.

**Negative:**
- Git sees each return as a new file plus a delete, not a rename, unless its rename detection pairs them.
- Every reference to `migrations/_done` in skills, migrations, tests, and docs must change in the same release (R-015).

**Risks:**
- A framework refresh over an older copy can leave an old `_done/` folder downstream. ADR-018 makes resume detection ignore subfolders, so the leftover changes nothing.
- A missed `_done/` reference sends an agent to a folder that no longer exists. The req-007 suite checks that `_done/` is absent and that no skill, migration, test, or doc tells an agent to move a migration.

## Related ADRs

- 0000005 ADR 005 - related-to: this ADR replaces its archive-to-`_done/` mechanism and keeps its Markdown migration format.
- 0000033 ADR 010 - related-to: the same Hard Limit 8 reasoning ruled out shell deletes for the P7 archive.
- ADR-016 - extends: records where run state lives once files stop moving.
- ADR-018 - related-to: defines which files count as migrations for resume detection.

## Supersedes

- The archive-to-`_done/` part of 0000005 ADR 005. That ADR sits in the archive, so this run doesn't edit it. `docs/decisions-index.md` changes under req-007 FR-007.10.

## Superseded By

- None
