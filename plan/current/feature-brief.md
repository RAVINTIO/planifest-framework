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
| Sanctioned scripts in Hard Limit 8 (0000124) | US-008: As the human on the loop, I rely on Hard Limit 8 to name every framework script that may write files, so that an agent never writes past the gates through any other script, and each named script writes only its own file. | must-have | 1 |
| Fast Path enforcement paths (0000081, 0000125, 0000062) | US-009: As the human on the loop, I rely on Fast Path never admitting a write to an enforcement path, so that a scope record can't unwire or change the gates. | must-have | 1 |
| Migration records for this repo (0000126) | US-010: As the human on the loop, I see this repo hold a run record for each of its eight migrations, from a scan run here, so that the framework repo shows its own migration state. | must-have | 1 |

## Waves

| Wave | Features Included | Ships When |
|------|-------------------|------------|
| 1 | All ten | Every acceptance criterion passes and the full suite passes on CI |

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
| `gate-write.mjs`, `shell-write-guard.mjs`, `ratchet-check.mjs` | `path-rules.mjs` | ES module import | `resolveRoot`, `resolveTarget`, `resolveTargetBoth`, `evaluateWrite`, `judgeWrite` |
| Orchestrator resume detection | `plan/_migrations/` | file read | one record per migration |

## Stack

| Concern | Decision |
|---------|----------|
| Language | JavaScript (ES modules), Bash, PowerShell, Markdown |
| Runtime | Node.js built-ins only for hooks (0000032 ADR 004) |
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
- 0000032 ADR 004 path-rules constraints hold.
- 0000033 ADR 009: Fast Path never admits an enforcement path.
- Hard Limit 8: changes go through **Write** or **Edit**.

### Assumptions
- Claude Code passes `CLAUDE_PROJECT_DIR` to hooks. 0000118 has not checked this in a live session.

## Scenario Paths

**Happy path:**

> A Fast Path change declares its target paths in `plan/.fast-path-scope`, then edits them with **Write** and **Edit**. The gate admits matching writes, blocks the rest, and never admits an enforcement path. The Fast Path commit deletes the record. At release, `product.yml` names the version and feature before the archive step. Writes through links or a deleted working directory are blocked, and a planted `.git` doesn't become a root. Migration files stay put, and resume detection lists only migrations with no `plan/_migrations/` record. A `not applicable` entry counts as a record.

**First-run path:**

> A project with no `plan/_migrations/` folder sees every migration as pending on first refresh. The migrator creates the folder on its first record. Each scan runs, and a compliant project gets a record with nothing to change. Downstream projects treat the two downstream-only migrations as applicable, and each scan decides. With no scope record, Fast Path writes stay blocked until the change declares one. A stale `product.yml` stays as it is until the next P7 corrects it.

**Error / sad path:**

> The most likely failure is a stale `plan/.fast-path-scope` left by an interrupted Fast Path. The next Fast Path overwrites it. A link loop, a chain past the hop limit, or any resolution error inside the repo root blocks the write with exit 2 and a reason on stderr. Only errors outside path resolution still fail open. A migration record that can't be read counts as pending, and the migrator rescans. A scan with findings records nothing until the human on the loop confirms the fix.

**Cross-session continuity:**

> The scope record stores the branch and `HEAD` commit it was written at. The gate ignores the record once either one changes. A migration counts as applied only once its record exists, so an interrupted one shows as pending and runs again. A migration re-run and the P7 `product.yml` update each give the same result when run twice.

## Acceptance Criteria

- [ ] US-001: With a scope record listing `planifest-overrides/instructions/x.md`, a **Write** to that path passes and a **Write** to an unlisted path is blocked.
- [ ] US-009: A scope record that lists an enforcement path, such as `planifest-framework/hooks/`, never admits a write there.
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
- [ ] US-010: This repo holds a record for each of the eight migrations, from a scan run here.
- [ ] US-008: `standard-boot.md` and `cursor-boot.md` each hold one `Sanctioned scripts:` sentence in Hard Limit 8, and both name the same seven scripts.
- [ ] US-008: `set-product-release.mjs` exits 2 and writes nothing when any argument breaks its Input Validation rules.
- [ ] US-009: The enforcement list in `workflows/fast-path.md` matches `FAST_PATH_ENFORCEMENT_PATHS`.
- [ ] US-010: The two downstream-only migrations hold `not applicable` records that name this repo as the framework source.
