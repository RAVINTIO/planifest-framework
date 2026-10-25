---
title: "Feature Brief - ravintio-rebrand"
summary: "Rename the Planifest framework pack to RAVINTIO Framework, with a consumer migration and a brand guard."
status: "draft"
version: "0.1.0"
---
# Feature Brief - ravintio-rebrand

**Feature ID:** 0000039-ravintio-rebrand

> The orchestrator drafted this brief from backlog entry 0000237 and the pre-P0 triage. The human on the loop confirms it with the design.

## Business Goal

The GitHub org is now `RAVINTIO`, and the ecosystem names this product RAVINTIO Framework. This repo still says Planifest in about 590 live files, 21 skill names, 30 variables, and the pack folder itself. The rename makes this pack match RAVINTIO Zero, which renamed in its feature 0000160.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| Pack rename | As a human on the loop, I see RAVINTIO Framework in every live path, identifier, and prose line, so that the pack matches the RAVINTIO org. | must-have | 1 |
| Consumer migration | As a human on the loop with a consumer repo on 0.36.0, I run one migration that moves it to the RAVINTIO pack and keeps a backup of the old pack, so that I upgrade without losing files. | must-have | 1 |
| Brand guard | As a human on the loop, I get a failing test when a live file brings back the old name, so that the rename stays complete. | must-have | 1 |

## Waves

| Wave | Features Included | Ships When |
|------|-------------------|------------|
| 1 | All three | The suite passes on every CI leg and the brand guard is green |

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| `planifest-framework`, renamed `ravintio-framework` | component-pack | existing | The pack: skills, hooks, scripts, setup, templates, standards, migrations, and tests |
| `setup-hook-integration` | component-pack | existing | Hook wiring tests under `src/setup-hook-integration/` |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| Pack files and consumer marker files | `ravintio-framework` | consumer repos, read only |

### Integration Points

| From | To | Method | Contract |
|------|-----|--------|----------|
| `setup.sh`, `setup.ps1` | consumer tool config | file write | settings wiring, boot file, skills, marker files |
| consumer migration | consumer repo | file move | old pack to backup, overrides to new folder |

## Stack

Unchanged: Bash, PowerShell 5.1 and 7, and Node (`.mjs`) scripts. Bash test suites, GitHub Actions CI, and `Build target: local`.

## Scope Boundaries

### In Scope
- Rename every live path, identifier, variable, marker, and prose line from Planifest to RAVINTIO.
- A consumer migration with `.sh` and `.ps1` helpers that never deletes the old pack.
- A brand guard test with a path and line allowlist.

### Out of Scope
- `plan/_archive/`, `plan/changelog/`, `plan/_migrations/`, and applied migrations.
- Sibling repos, including RAVINTIO Zero and the `planifest-docs` site.
- The local clone folder name.

### Deferred
- `gh repo rename ravintio-framework` runs after the human on the loop merges the PR.

## Non-Functional Requirements

| NFR | Target | Measurement |
|-----|--------|-------------|
| Completeness | 0 unallowlisted `planifest` hits in live files | brand guard |
| Regression | 0 failing suites on every CI leg | CI on the PR |

## Constraints and Assumptions

### Constraints
- Version 0.37.0, a minor bump. The human on the loop set it on 2026-10-25.
- History stays byte-identical.

### Assumptions
- Consumers set no `PLANIFEST_*` variable except `PLANIFEST_SESSION_ID`.

## Scenario Paths

The human on the loop accepted these four at the P0 Scope Lock Challenge on 2026-10-25.

**Happy path:**

> In this repo, the scripted pass renames everything. The brand guard finds no stray name, and every CI leg passes. A consumer on 0.36.0 runs the migration, then setup. The consumer ends on 0.37.0 with the old pack in `.ravintio-backup/`. The human on the loop merges, then the repo rename runs.

**First-run path:**

> A fresh consumer install gets the RAVINTIO pack directly, with no migration and no backup. In this repo, the first setup run after the rename replaces the `planifest-*` skill copies and rewires the hooks. The "Applies when" check skips the migration here.

**Error / sad path:**

> The most likely failure is a consumer left half moved. The helper stops at the failed step and names it. It reports what already moved and deletes nothing. A re-run finishes the move.

**Cross-session continuity:**

> Only uncommitted work is at risk. This run resumes from the branch and `plan/current/`. The rename and the setup re-run land in one commit, so a resumed session sees either all old names or all new ones. An interrupted consumer migration re-runs safely.

## Acceptance Criteria

- [ ] No live file or path holds the old name, except allowlisted lines.
- [ ] A consumer on 0.36.0 runs the migration and setup and ends on the RAVINTIO pack with a backup of the old pack.
- [ ] Every suite passes on every CI leg.
