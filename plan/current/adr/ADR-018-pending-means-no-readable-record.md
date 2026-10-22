---
title: "ADR 018: Pending means no readable record"
summary: "A migration is pending when plan/_migrations/{stem}.md is missing or can't be read. A record can't be read when its frontmatter fails to parse or its migration, outcome, or date field is missing or wrong. Resume detection reads only top-level migration files, ignores subfolders and orphan records, and a re-run with the same outcome leaves the record unchanged."
status: "proposed"
version: "0.1.0"
---
# ADR-018 - Pending means no readable record

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

Under 0000005 ADR 005, a migration was pending when its file sat at the top level of `migrations/`. ADR-015 keeps every file there, so file location no longer answers the question. ADR-016 gives each project a record per migration.

Resume detection needs a rule that is strict enough to parse and safe when a record is damaged. It must also handle a leftover `_done/` folder from a refresh over an older copy, and a record whose migration has gone.

## Decision

1. A migration is any top-level `*.md` file in `planifest-framework/migrations/`. Resume detection never reads `_done/` or any other subfolder.
2. A migration is pending when `plan/_migrations/{stem}.md` doesn't exist.
3. A migration is also pending when its record can't be read. A record can't be read when any of these hold:
   - it has no YAML frontmatter, or the frontmatter doesn't parse
   - `migration` is missing or doesn't equal `{stem}.md`
   - `outcome` is missing or isn't one of the three values
   - `date` is missing or isn't `YYYY-MM-DD`
4. When resume detection meets a record it can't read, it names the file and treats the migration as pending.
5. A record with no matching migration file is ignored. It never makes anything pending.
6. Resume detection invokes the migrator for each pending migration in file-name order, before other phase work.
7. A readable record stops the migration from running. If the human on the loop asks for a re-run and the outcome matches the record, the migrator leaves the record unchanged.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Any record file counts, readable or not | Simplest check | A damaged or empty file silently hides a migration forever. | Fails open on run state. |
| An unreadable record blocks the session | Forces a fix | A single bad hand edit stops all work. The fix is a rescan anyway. | Treating it as pending reaches the same fix with no stop. |
| Check every field, counts and version included | Strictest | A record with a stray count value forces a full rescan. Those fields are audit data, not run state. | The three checked fields decide run state. The others don't. |
| Rewrite the record on every re-run | Fresh `date` each time | Two runs give two different files, which breaks idempotence. | Leaving a matching record unchanged keeps re-runs clean. |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Orchestrator Resume Detection step 1 applies the rule. The migrator skill states it. `pipeline-reference.md` and `project-operations.md` describe it and drop the `_done` filter commands. |

## Consequences

**Positive:**
- A damaged record fails safe. The migration runs again and the scan decides.
- A leftover `_done/` folder downstream changes nothing.
- Orphan records from a removed migration cause no noise.
- Re-runs are idempotent, so two runs leave one record with the same content.

**Negative:**
- A record with a typo in `outcome` triggers a full rescan rather than a quick fix.
- The rule lives as skill text, not code, so an agent applies it by reading.

**Risks:**
- An agent may skip the field checks and count any file as a record. The req-007 suite checks that both skills state the unreadable-record rule (AC-007.2).
- A rescan of a damaged `skipped` record asks the human on the loop again (R-014). That is the intended effect.

## Related ADRs

- ADR-015 - depends-on: files stay at the top level, so subfolders are never migrations.
- ADR-016 - depends-on: defines the record fields this rule checks.
- ADR-017 - related-to: resume detection is the read-only side of the ownership mapping.

## Supersedes

- None

## Superseded By

- None
