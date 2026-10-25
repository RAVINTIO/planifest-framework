---
title: "ADR 010: Pack owns consumer marker files"
summary: "The ravintio-framework component owns the pack tree, the consumer marker files, the generated boot-file blocks, and migration records. Consumers read them. The migration helper stays in that component."
status: "accepted"
version: "0.1.0"
---
# ADR-010 - Pack owns consumer marker files

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Component:** ravintio-framework
**Date:** 2026-10-25

## Context

The feature changes files and no database. Hard Limit 5 says one component owns each piece of data. The execution plan Data Model Summary lists three entities: the pack tree, the consumer marker files, and the migration records.

The marker files live in the consumer repo. They are `.ravintio-session`, `.ravintio-manifest`, and `.ravintio-setup-flags`. Setup writes them, and the refresh-setup skill reads the flags file. The rename also changes the generated boot-file blocks, which setup writes between the `ravintio-overrides` markers.

The migration helper in `.sh` and `.ps1` form writes to the consumer repo. It moves `planifest-overrides/`, renames the workflow, removes the old `.planifest-session` marker, and moves the old pack to `.ravintio-backup/planifest-framework/`. The migrator skill records each outcome under `plan/_migrations/`.

Someone must own these files, or the rename cannot say who may change them.

## Decision

The `ravintio-framework` component owns all of the following:

- the pack tree
- the consumer marker files `.ravintio-session`, `.ravintio-manifest`, and `.ravintio-setup-flags`
- the generated boot-file blocks
- the migration records, which the migrator skill writes

Consumers read these files and never write them by hand.

The migration helper is part of `ravintio-framework`. Its writes to consumer files stay inside this ownership. The helper moves and removes old-name files. Setup writes the new markers.

The `setup-hook-integration` component owns only its hook wiring tests under `src/setup-hook-integration/`. It writes no marker and no migration record.

This ADR governs req-002, req-006, req-008, and req-009.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| The consumer repo owns its markers | Matches where the files sit | Setup, the gate hook, and refresh-setup all write or read them. A consumer-owned marker has no component to hold its format. | The pack defines the marker names and formats. Consumers only read them. |
| Migration records belong to a separate component | Keeps history apart from setup | Adds a component for one folder of Markdown files. The migrator skill already writes them. | The writer and the owner must match under Hard Limit 5. |
| Split the migration helper into its own component | Isolates the riskiest writes | The helper needs the marker names and the pack layout. A split forces two components to agree on both. | The helper changes only what the pack created. One owner keeps the old and new names in one place. |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | Owns the pack tree, the marker files, the boot-file blocks, the migration helper, and the migration records. |
| setup-hook-integration | Owns only its wiring tests. Path references change, and it writes no marker. |

## Consequences

**Positive:**
- Each marker has one owner, so req-002 and req-008 change names in one place.
- The human on the loop sees one component to review for every file the migration touches.
- The helper cannot write to data that another component owns.

**Negative:**
- A consumer that edits a marker by hand breaks the contract. Setup overwrites the edit on the next run.
- The migration helper and the pack share one review and one release. A helper defect blocks the whole rename.

**Risks:**
- The helper could touch a consumer file the pack never created. The helper rewrites only the pack's own names and refuses symbolic links, and req-006 tests both.
- Migration records for this source repo could read as a consumer outcome. This repo writes its own record with outcome `not applicable`, and req-009 covers it.

## Related ADRs

- ADR-005 - related-to (the helper moves the old pack to a backup and never deletes it)
- ADR-006 - related-to (the migrator maps old paths and sets the Applies when check)
- ADR-004 - related-to (setup reads the old marker names once)

## Supersedes

- None.

## Superseded By

- None.
