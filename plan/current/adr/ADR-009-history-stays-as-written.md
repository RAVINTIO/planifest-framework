---
title: "ADR 009: History stays as written"
summary: "The rename leaves history byte-identical. Archives, changelogs, migration records, shipped migration bodies, and backlog reference documents keep the old name, old ids, and sibling repo names."
status: "accepted"
version: "0.1.0"
---
# ADR-009 - History stays as written

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Component:** ravintio-framework
**Date:** 2026-10-25

## Context

The rename changes every live path, identifier, and prose line from Planifest to RAVINTIO Framework. The repository also holds records of what happened under the old name. Those records are evidence of past work.

- `plan/_archive/` holds one folder per shipped feature.
- `plan/changelog/` holds release notes.
- `plan/_migrations/` holds the record of each migration this repository ran.
- `plan/backlog/*/_reference/` holds historical reviews.
- `planifest-framework/migrations/` holds shipped migration bodies that consumers have already run or will run.

Some live suites read these records. For example, `test-0000037-req-008-migration-branch-diff.sh` reads git tags and the shipped migration names. `test-0000036-req-001-rerun-setup-migration.sh` matches needles inside the 0.34.0 migration body. A rewrite of the history changes what those suites read.

Old feature ids `0000001` to `0000038`, their ADR ids, and old backlog ids appear across the history. Sibling repo names also appear, such as `planifest-docs`, RAVINTIO Zero, and the `C:\d\planifest\framework\` path.

NFR-003 in the execution plan requires that existing history files stay byte-identical. Req-005 lists the protected inventory.

## Decision

Keep history byte-identical. The scripted rename pass skips these paths and never opens them for writing.

- `plan/_archive/`, `plan/changelog/`, and `plan/_migrations/`.
- `plan/backlog/*/_reference/`.
- The bodies of the shipped files in `planifest-framework/migrations/`. The folder moves with the pack. The file names and bodies stay.
- Old feature, ADR, and backlog ids, wherever they appear.
- Sibling repo names and paths: `planifest-docs` links, RAVINTIO Zero, and the `C:\d\planifest\framework\` path.

The history-reading suites keep the old names on the lines that read history. The split-name needles in the req-005 Protected inventory keep the old names where they match an unchanged migration body. Each protected line gets a brand-guard allowlist entry under ADR-007.

The measurement is this command, which must print nothing:

`git diff --name-status --diff-filter=MDR main...HEAD -- plan/_archive plan/changelog plan/_migrations`

Files this feature adds count as additions. That covers its archive folder, its changelog entry, and its migration record. Only modified, deleted, and renamed files fail the check.

Decision (P2): history stays byte-identical, with protected lines in history-reading suites on the allowlist / reason: a record of past work is evidence, and a rewrite cannot be checked against its source.

This governs req-005. It also sets the protected-path input to req-007 and the skip list for the pass in ADR-008.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Rewrite history too, so the brand guard needs no allowlist | One rule for the whole tree. No allowlist entries to keep fresh. | Thousands of edited records. Old ids and sibling names get damaged. Shipped migration bodies change after consumers ran them. History-reading suites fail. | Rewritten history no longer matches what happened. NFR-003 forbids it. |
| Rewrite only the changelogs | Release notes read as RAVINTIO. Smaller diff than a full rewrite. | A changelog entry for 0.30.0 would name a product that did not exist then. It breaks the same byte-identical rule as a full rewrite. | A changelog is a dated record. A partial rewrite gives the same defects at lower scale. |
| Move history to a separate branch or repository | The working tree holds no old name. The brand guard needs no history exclusion. | Suites that read `plan/_archive/` and `plan/_migrations/` break. Ship and migrator skills lose their paths. Links to old records fail. | It changes the layout every pipeline skill relies on. The cost is far larger than an allowlist. |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework (renamed from planifest-framework) | The rename pass reads a protected list and skips history paths. Suite lines that read history keep the old names. |
| setup-hook-integration | None for history. Hook and setup text rename as live files. The migrator reads shipped migration bodies unchanged. |

## Consequences

**Positive:**
- The record of past work stays accurate. A reader of a 0.30.0 changelog entry sees the name that existed then.
- Consumers who already ran a shipped migration see the same body on every later read.
- The NFR-003 check is one command with an empty-output pass condition.

**Negative:**
- A search for the old name still finds hits in history. A human on the loop who greps for `planifest` must read the allowlist to tell protected hits from missed ones.
- The brand guard carries allowlist entries for history-reading suite lines. A stale entry fails the guard, so the maintainer who changes a protected line must also edit the entry.
- Old and new names sit side by side in `ravintio-framework/migrations/`. A new reader may think the old text is a missed rename.

**Risks:**
- The pass edits a protected path by mistake. The NFR-003 command and the req-005 split-name suite both catch this before ship.
- A history-reading suite is left off the protected list. The suite fails after the pass, so the risk is a red check and not a silent pass.

## Related ADRs

- ADR-007 - related-to (the allowlist holds the protected lines)
- ADR-008 - related-to (the scripted pass reads the protected list)
- ADR-006 - related-to (the migrator maps old paths while shipped bodies keep them)

## Supersedes

- None.

## Superseded By

- None.
