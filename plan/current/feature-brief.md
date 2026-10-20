---
title: "Feature Brief - write gate scope and path hardening"
summary: "Lets Fast Path and P9 write through the gate, hardens how the gates resolve roots and paths, and moves migration run state into plan/_migrations/."
status: "approved"
version: "0.1.0"
---
# Feature Brief - write gate scope and path hardening

**Feature ID:** 0000035-write-gate-scope-and-path-hardening

> Written by the orchestrator from ten backlog entries the human on the loop pulled in at P0 on 2026-10-21. The human on the loop chose one single wave.

## Business Goal

Two framework rules contradict the write gate. Fast Path writes no design, and P9 runs after the design is archived, so the gate blocks both. Agents then reach for shell writes or ask the human on the loop to copy files by hand. Five gaps also let a write reach a gated path through symbolic links, a deleted working directory, or a planted root marker. Separately, migration run state lives inside the framework folder, so the framework repo can't hold a migration that is pending downstream. This feature makes every sanctioned route pass the gate, closes the five gaps, and gives each project its own migration record.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| Fast Path scope record (0000081, 0000125, 0000062) | US-001: As the human on the loop, I see a Fast Path change written through **Write** and **Edit** against a declared scope record, so that Fast Path never needs a shell workaround or a hand copy. | must-have | 1 |
| `product.yml` matches the release (0000124) | US-002: As the human on the loop, I see `product.yml` name the released version and feature after every run, so that an `explicit` version policy never blocks a correct release. | must-have | 1 |
| Links judged by their real target (0000106, 0000117) | US-003: As the human on the loop, I rely on the gates to judge where a write lands after symbolic links resolve, so that a link under `plan/` can't carry a write into `src/`. | must-have | 1 |
| Root found when cwd is gone (0000107) | US-004: As the human on the loop, I rely on the gates to find the repository root when the working directory no longer exists, so that they never fail open on a write into `src/`. | must-have | 1 |
| Ratchet check from any folder (0000109) | US-005: As the human on the loop, I rely on `ratchet-check` to find the active loop from any subfolder, so that a weakening write is blocked wherever the agent runs it. | must-have | 1 |
| No planted root under a permitted name (0000114) | US-006: As the human on the loop, I rely on the gates to ignore a `.git` marker planted under an always-permitted name, so that a moved folder can't become a new root. | must-have | 1 |
| Migration run state per project (0000126) | US-007: As the human on the loop, I see every migration stay in `planifest-framework/migrations/` with its run state recorded in `plan/_migrations/`, so that the framework repo and each downstream project track their own runs. | must-have | 1 |

## Waves

| Wave | Features Included | Ships When |
|------|-------------------|------------|
| 1 | All seven | Every acceptance criterion passes and the full suite passes on CI |

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| `planifest-framework` | component-pack | existing | Hooks, scripts, skills, workflows, templates, migrations, and tests |
| `setup-hook-integration` | component-pack | existing | Setup integration docs and quirks, if setup behaviour changes |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| `plan/_migrations/` run records | `planifest-framework` (migrator skill) | orchestrator resume detection, read only |
| `plan/.fast-path-scope` | `planifest-framework` (Fast Path workflow) | `gate-write` and the shell-write guard, read only |
| `product.yml` | `planifest-framework` (ship agent) | `product-version.mjs`, read only |

### Integration Points

| From | To | Method | Contract |
|------|-----|--------|----------|
| `gate-write.mjs`, `shell-write-guard.mjs`, `ratchet-check.mjs` | `path-rules.mjs` | ES module import | `resolveRoot`, `toRootRelative`, `evaluateWrite`, `judgeWrite` |
| Orchestrator resume detection | `plan/_migrations/` | file read | one record per migration |

## Stack

| Concern | Decision |
|---------|----------|
| Language | JavaScript (ES modules), Bash, PowerShell, Markdown |
| Runtime | Node.js built-ins only for hooks (0000032 ADR-004) |
| Framework | none |
| Frontend | none |
| Database | none |
| ORM | none |
| Testing | Bash suites under `planifest-framework/tests/` via `run-tests.sh` |
| IaC | none |
| Cloud | none |
| Compute | none |
| CI | GitHub Actions |
| Build target | local |

## Scope Boundaries

### In Scope
- Backlog entries 0000062, 0000081, 0000106, 0000107, 0000109, 0000114, 0000117, 0000124, 0000125, and 0000126.
- Setting `product.yml` to the current release.
- A run record in `plan/_migrations/` for each of the eight existing migrations in this repo.

### Out of Scope
- Shell-guard parser entries 0000105, 0000108, 0000115, and 0000116. They wait on 0000119.
- A hook that enforces the post-P9 refusal (0000112).
- Running the two downstream-only migrations in this repo.

### Deferred
- Nothing deferred.

## Non-Functional Requirements

| NFR | Target | Measurement |
|-----|--------|-------------|
| Hook latency | Each hook call stays under 500 ms on a 10-hop link chain | Suite timing on CI |
| Fail behaviour | Unexpected hook errors still exit 0. Every new block path exits 2 with its reason on stderr. | Suite assertions |
| Dependencies | Node built-ins only, no process spawn in hooks | Suite source check |

## Constraints and Assumptions

### Constraints
- 0000032 ADR-004 path-rules constraints hold.
- 0000033 ADR-009: Fast Path never admits an enforcement path.
- Hard Limit 8: changes go through **Write** or **Edit**.

### Assumptions
- Claude Code passes `CLAUDE_PROJECT_DIR` to hooks. 0000118 has not checked this in a live session.

## Scenario Paths

**Happy path:**

> Drafted at the Scope Lock Challenge.

**First-run path:**

> Drafted at the Scope Lock Challenge.

**Error / sad path:**

> Drafted at the Scope Lock Challenge.

**Cross-session continuity:**

> Drafted at the Scope Lock Challenge.

## Acceptance Criteria

- [ ] US-001: With a scope record listing `planifest-overrides/instructions/x.md`, a **Write** to that path passes and a **Write** to an unlisted path is blocked.
- [ ] US-001: A scope record that lists an enforcement path, such as `planifest-framework/hooks/`, never admits a write there.
- [ ] US-001: `workflows/fast-path.md` writes the record before the change and deletes it in the Fast Path commit.
- [ ] US-002: A suite runs the close-out order and checks that `product.yml` `version` and `feature` match the tag and feature.
- [ ] US-002: `product.yml` reads `0.33.0` and `0000035-write-gate-scope-and-path-hardening` at P9.
- [ ] US-003: A write through a dangling link under `plan/` whose target is in `src/` is blocked with no design.
- [ ] US-003: `plan/l/../../../src/x.js`, with `plan/l` a link deeper into the repo, is judged as `src/x.js`.
- [ ] US-004: With a deleted cwd and `CLAUDE_PROJECT_DIR` set, a write into `src/` is blocked. With it unset, the root comes from the nearest existing parent.
- [ ] US-005: From a project subfolder, during an active loop, a write that removes an acceptance criterion is blocked.
- [ ] US-006: After `mkdir -p plan/w/.git && mv plan/w src/claude.md`, a write from `src/claude.md` to `../other/x.js` is blocked.
- [ ] US-007: No migration file moves when it runs, and `_done/` no longer exists.
- [ ] US-007: Resume detection lists as pending only migrations with no record in `plan/_migrations/`.
- [ ] US-007: This repo holds a record for each of the eight migrations, from a scan run here.
