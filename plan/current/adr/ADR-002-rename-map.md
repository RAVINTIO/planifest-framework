---
title: "ADR 002: Rename map"
summary: "One map moves every Planifest name to RAVINTIO. Prose uses RAVINTIO in block capitals. Identifiers, markers, and variables use lowercase ravintio or the RAVINTIO_ prefix. History and vendored text stay as written."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - Rename map

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Component:** ravintio-framework (renamed from planifest-framework)
**Date:** 2026-10-25

## Context

The org and the ecosystem name the product RAVINTIO Framework. The pack, its skills, its variables, its markers, and its prose still say Planifest. The rename needs one map so every file, script, and message uses the same new name.

RAVINTIO Zero made the same move in 0000160 ADR 001. That map is the prior art. This repo differs in two ways. The release is 0.37.0 and not a major version. The pack also owns consumer marker files, so some old names need a read path.

The map governs req-001 (paths and identifiers), req-003 (environment variables), req-004 (brand prose), and req-008 (emitted names).

## Decision

Adopt the single rename map in design.md's Engineering Layer. The writing rule depends on where the word appears.

- Prose writes RAVINTIO in block capitals. The first use in a file or message is "RAVINTIO Framework". Later uses in the same file or message are "RAVINTIO" (req-004).
- Paths, file names, skill names, and ids use lowercase `ravintio`.
- Environment variables use the `RAVINTIO_` prefix in place of `PLANIFEST_`.

### Rename map

| Old | New |
|-----|-----|
| "Planifest Framework" in prose | "RAVINTIO Framework" |
| Bare "Planifest" in prose | "RAVINTIO Framework" on first use, then "RAVINTIO" |
| `planifest-framework/`, `planifest-overrides/` | `ravintio-framework/`, `ravintio-overrides/` |
| The 21 `planifest-*` skills | `ravintio-*` skills |
| `planifest.yml` (workflow and hook file) | `ravintio.yml` |
| `refresh-planifest-framework-dir.ps1` | `refresh-ravintio-framework-dir.ps1` |
| `product.yml` and `component.yml` ids | `ravintio-framework` |
| `PLANIFEST_*` variables | `RAVINTIO_*` variables |
| `.planifest-session`, `.planifest-manifest`, `.planifest-setup-flags` | `.ravintio-session`, `.ravintio-manifest`, `.ravintio-setup-flags` |
| `planifest-overrides` boot-file markers | `ravintio-overrides` boot-file markers |
| `@planifest` npm scope | `@ravintio` npm scope |
| `[Planifest]` log prefix | `[RAVINTIO]` log prefix |
| `Planifest Strict Pipeline` workflow name | `RAVINTIO Strict Pipeline` |
| `github.com/planifest/...` repo links | `github.com/RAVINTIO/ravintio-framework` |

### Rules for applying the map

- The `planifest-docs` sibling links stay as written. The brand guard allowlists them.
- Vendored upstream text under `external-skills/` stays as written. Only pack-authored lines change.
- `plan/_archive/`, `plan/changelog/`, `plan/_migrations/`, and shipped migration bodies stay as written (see ADR-009).
- Old names that setup still reads in 0.x are a separate decision (see ADR-004).
- The rename runs as one scripted pass (see ADR-008).
- Req-001 sets the one remaining exception. `src/setup-hook-integration/component.yml` carries no brand in its `id` or `name`, so those values stay.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|--------------|
| Title-case "Ravintio" in prose | Reads as an ordinary word | Differs from the RAVINTIO org and the ecosystem docs, which use block capitals | The brand is RAVINTIO in block capitals, and one spelling lets the brand guard check it |
| Rename prose only and keep `planifest` identifiers | No consumer migration and a smaller diff | Paths and brand disagree, readers see two names, and the brand guard cannot enforce one name | The human on the loop wants paths to match the brand |
| Use a short `rvf` prefix for identifiers | Shorter paths and variables | A third name that matches neither the org nor the prose, and nobody searching for RAVINTIO finds it | It adds a new name to learn and gains little |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | Renamed from `planifest-framework`. Every path, id, variable, marker, and prose line that holds the old name changes |
| setup-hook-integration | Hook wiring tests and path references move to the new names. Its own `id` and `name` stay |

## Consequences

**Positive:**
- Paths, skills, variables, and prose all use one brand name.
- A reviewer can check any rename against one table.
- The brand guard has one spelling to enforce.

**Negative:**
- Every consumer on 0.36.0 must run the migration and update their links, branch protection, and any `PLANIFEST_*` setting.
- Repo links fail until the human on the loop renames the GitHub repo after the merge.
- A human on the loop who searches old docs for "Planifest" finds history only.

**Risks:**
- A name built or split across strings escapes the replace. Req-005 lists those names first, and the brand guard catches the rest.
- A consumer sets a `PLANIFEST_*` variable other than `PLANIFEST_SESSION_ID`. That setting loses effect silently. The design records this as an assumption.

## Related ADRs

- ADR-001 - related-to (the rename changes no part of the stack)
- ADR-003 - related-to (the rename ships as a minor version)
- ADR-004 - related-to (the old-name reads that this map leaves in place)
- ADR-007 - depends-on (the brand guard enforces this map)
- ADR-008 - related-to (the scripted pass applies this map)
- ADR-009 - related-to (the history paths this map skips)
- RAVINTIO Zero 0000160 ADR 001 - related-to (prior art for this map)

## Supersedes

- None.

## Superseded By

- None.
