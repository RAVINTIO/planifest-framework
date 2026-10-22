---
title: "ADR 017: Migration records owned by the migrator"
summary: "The planifest-migrator skill owns plan/_migrations/ and is its only writer. Orchestrator resume detection reads the records and never writes them. No other skill, script, or hook writes there."
status: "proposed"
version: "0.1.0"
---
# ADR-017 - Migration records owned by the migrator

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

ADR-016 creates `plan/_migrations/` as new persistent data. The framework rule says one component owns each piece of data. Every data ownership mapping needs an ADR.

Two skills touch the records. The migrator runs a migration and knows its outcome. Orchestrator resume detection lists pending migrations at session start. P3 of this feature also writes records for this repo, as ADR-019 describes.

## Decision

1. The `planifest-migrator` skill owns `plan/_migrations/`. It is the only writer of a record.
2. Orchestrator resume detection reads records to decide what is pending. It never writes, edits, or deletes one.
3. P3 of this feature writes this repo's records by following the migrator's Record step. It writes nothing the migrator wouldn't write.
4. No hook, script, or other skill writes to `plan/_migrations/`. P7 doesn't archive it, and no cleanup step deletes it.
5. The human on the loop may delete a record by hand to force a re-run. The migrator then writes a fresh one.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Orchestrator writes records after the migrator returns | The orchestrator already tracks session state | The orchestrator would need the outcome and both counts passed back. Two writers could disagree. | The migrator holds the outcome, so it writes. |
| A script writes records | Deterministic, testable in a fixture | Adds a sanctioned script for a six-field file. The outcome still comes from the migrator's dialogue. | Not worth a Hard Limit 8 carve-out. |
| Shared ownership by both skills | Flexible | Breaks the one-owner rule. No single place defines the write. | One owner keeps the format in one skill. |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | The migrator skill states the record format and its Record step. The orchestrator skill reads records in Resume Detection step 1 only. |

## Consequences

**Positive:**
- One skill defines and writes the format, so the format can't drift between writers.
- Resume detection stays read-only, so a session start never changes run state.

**Negative:**
- A record fix outside a migration run needs a hand edit by the human on the loop, or a deleted record and a re-run.

**Risks:**
- A future skill could start writing records. The data ownership list in `design.md` and this ADR name the migrator as sole writer, and the docs agent carries the mapping into component docs.

## Related ADRs

- ADR-016 - depends-on: defines the data this ADR assigns.
- ADR-018 - related-to: the reader side of the mapping.
- ADR-019 - related-to: P3 writes this repo's records through the migrator's Record step.

## Supersedes

- None

## Superseded By

- None
