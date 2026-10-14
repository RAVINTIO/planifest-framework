---
title: "Feature Brief - Context Mode and Telemetry MCP removal"
summary: "Remove the Context Mode MCP and Telemetry MCP integrations from the framework, and clean up installs that already have them."
status: "approved"
version: "0.1.0"
---
# Feature Brief - Context Mode and Telemetry MCP removal

**Feature ID:** 0000030-context-mode-and-telemetry-mcp-removal

> Drafted by the orchestrator at P0 from the human on the loop's decisions on 2026-10-14. The P0 exchanges in `build-log.md` record each decision.

## Business Goal

Planifest carries two optional MCP integrations, Context Mode and Telemetry. The human on the loop has decided to drop both. Together they reach about 200 tracked files across hooks, setup scripts, skills, standards, docs, and tests. They have driven several features of fixes (0000018, 0000024, 0000026, 0000027, 0000028). Removing them shrinks the framework and the skill text every agent loads. It also stops downstream projects running hooks for MCP servers they may not have.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| Context Mode removal | As the human on the loop, I install Planifest without any Context Mode MCP hooks, flag, component, or docs, so that the framework carries no code for an MCP server it no longer supports. | must-have | 1 |
| Telemetry removal | As the human on the loop, I run the pipeline with no Telemetry MCP hooks, backstops, setup flag, standard, or pipeline instructions, so that no phase spends effort on emission or failure checks. | must-have | 1 |
| Existing install clean-up | As the human on the loop of a project that already installed either integration, I re-run setup and the stale hooks and settings entries disappear, so that no tool call runs a hook whose file no longer exists. | must-have | 1 |

## Waves

One wave. Three features sit within the decomposition limit.

| Wave | Features Included | Ships When |
|------|-------------------|------------|
| 1 | Context Mode removal, Telemetry removal, Existing install clean-up | All three stories pass their acceptance criteria |

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| `planifest-framework` | component-pack | existing | Skills, templates, standards, hooks, and setup scripts. Loses `hooks/context-mode/`, `hooks/telemetry/`, the two telemetry backstops, and `standards/telemetry-standards.md`. |
| `setup-hook-integration` | component-pack | existing | The installation layer. Stops installing both integrations, and removes them from projects that already have them. |
| `context-mode-hooks` | component-pack | existing (removed by this feature) | Manifest and docs for the Context Mode hooks. Deleted, along with its `components[]` item in `product.yml`. |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| `.claude/settings.json` hook entries (downstream projects) | `setup-hook-integration` | None |
| `plan/current/build-log.md` | `planifest-framework` (orchestrator) | P8 build-assessment agent (read only) |
| `product.yml` | `planifest-framework` (ship-agent) | `scripts/product-version.mjs` (read only) |

### Integration Points

| From | To | Method | Contract |
|------|-----|--------|----------|
| `setup.sh` / `setup.ps1` | `.claude/settings.json` and Tier 1 adapter configs | File write | Hook entries stay idempotent. Stale Context Mode and Telemetry entries are removed. |
| `planifest-refresh-setup` | `setup.sh` / `setup.ps1` | CLI flags | The old flags are still accepted, with a notice, so a refresh rebuilt from an older install marker succeeds. |

## Stack

| Concern | Decision |
|---------|----------|
| Language | Bash, PowerShell, JavaScript (Node `.mjs` hooks), Markdown |
| Runtime | Node for hooks, Bash and `pwsh` for setup |
| Framework | none |
| Frontend | none |
| Database | none |
| ORM | none |
| Testing | Bash test scripts under `planifest-framework/tests/`, with the regression manifest |
| IaC | none |
| Cloud | none |
| Compute | none |
| CI | GitHub Actions (`.github/workflows/planifest.yml`) |
| Build target | local |

## Scope Boundaries

### In Scope
- Delete `planifest-framework/hooks/context-mode/` and `planifest-framework/hooks/telemetry/`.
- Delete `check-telemetry-failures.mjs` and `check-telemetry-receipts.mjs` from `hooks/enforcement/`.
- Remove the `--context-mode-mcp` and `--structured-telemetry-mcp` install paths from `setup.sh`, `setup.ps1`, `setup/claude-code.*`, and `setup/opencode.sh`, including the Tier 1 adapter installs (Cursor, Windsurf, Cline).
- Keep `--context-mode-mcp`, `--structured-telemetry-mcp`, and `--backend-url` as accepted no-ops. Each prints a one-line notice, skips any value validation, and never reaches the install marker.
- Make setup remove stale state on every run, for every tool it installs:
  - settings entries under any hook event whose command path points at a removed Planifest hook (hand-added hooks stay, and each removal is listed)
  - the `context-mode/` and `telemetry/` hook folders
  - `.claude/telemetry-enabled`, `plan/.telemetry-failures/`, and `plan/.telemetry-receipts/`
- Remove settings entries before deleting hook folders. Write `settings.json` through a temporary file and a rename.
- If `settings.json` is not valid JSON, leave it untouched, name the parse error, skip only the clean-up, and finish the install. If Node is missing, skip the clean-up with a warning and exit 0.
- Remove the Context Mode and Telemetry detection rows from `planifest-refresh-setup`.
- Keep the orchestrator's P0 hard-stop on `product.yml` `id`, with a new rationale: versioning and archive attribution.
- Remove this repo's own telemetry hook wiring from `.claude/settings.json`, then the installed files, in one final step. Remove the `emit-phase-start / emit-phase-end` line from the root `CLAUDE.md` in the same step.
- Delete `src/context-mode-hooks/` and its `product.yml` `components[]` item. Update the `product.yml` header comment.
- Delete `standards/telemetry-standards.md`, `docs/context-mode.md`, and `docs/0008b--feature--structured-telemetry-framework-integration.md`.
- Remove telemetry instructions from every skill, including the orchestrator's Telemetry section and every per-phase `Telemetry` line requirement.
- Remove the `Telemetry` field and the telemetry-gap summary row from `templates/build-log.template.md`.
- Remove context mode and telemetry references from boot templates, `README.md`, getting-started and reference guides, and living `docs/`.
- Delete or rewrite the tests that cover the removed features. Update the regression manifest.
- Add a migration file under `planifest-framework/migrations/` that explains the removal to downstream projects. It targets downstream installs only, and is committed last so this repo's resume detection never runs it mid-run.
- Record superseded ADRs in `docs/decisions-index.md`, including 0000024 ADR-001 as partly superseded.

### Out of Scope
- Editing anything under `plan/_archive/` or `plan/changelog/`. Those are historical records.
- Removing `plan/current/build-log.md` or the P8 build assessment.
- Removing the `id` field from `product.yml`.
- Replacing either integration with something else.
- Other enforcement hooks (`gate-write`, `ratchet-check`, `em-dash-guard`, and the rest) beyond removing telemetry calls from them.

### Deferred
- Nothing deferred.

## Non-Functional Requirements

| NFR | Target | Measurement |
|-----|--------|-------------|
| Residual references | 0 matches for `context-mode`, `context_mode`, `structured-telemetry`, and `telemetry` outside an exact allowlist: `plan/_archive/`, `plan/changelog/`, `plan/current/`, `plan/backlog/`, the setup clean-up and retired-flag blocks, their tests, the migration file, and the `planifest-refresh-setup` removed-flag note | `git grep` over the tree at P4, checked against the allowlist |
| Setup idempotency | A second setup run changes no file | Run setup twice in a fixture project and diff |
| Clean-up correctness | A fixture with both integrations installed has 0 stale entries or folders after one re-run | Test against a fixture `settings.json` |
| Test suite | All remaining tests pass | `planifest-framework/tests/` runner and CI |

## Constraints and Assumptions

### Constraints
- `plan/_archive/` and `plan/changelog/` are immutable history.
- Setup must never fail on the old flags, because `planifest-refresh-setup` replays flags from the install marker.
- The bash and PowerShell setup paths stay in parity.

### Assumptions
- No downstream project depends on telemetry events for anything beyond what the framework itself consumed.
- The 27 remaining backlog entries are unaffected, apart from passing mentions.

## Scenario Paths

Captured by the Scope Lock Challenge on 2026-10-14. The human on the loop accepted all four drafts.

**Happy path:**

> You run setup, fresh or as a re-run. The install has no Context Mode or Telemetry hooks or entries. Old flags print a notice, and setup exits 0. A second run changes nothing. Phases run with no telemetry text, field, or checks.

**First-run path:**

> A flagless first install wires only the enforcement hooks. The always-on clean-up finds nothing and prints nothing. The marker records only live flags.

**Error / sad path:**

> Old flags never fail setup. The clean-up removes only entries that point at a removed Planifest hook, and lists each one. A malformed `settings.json` stays untouched, and setup names the error and skips only the clean-up. With no Node, setup skips the clean-up, warns, and exits 0.

**Cross-session continuity:**

> Setup is idempotent and removes entries before folders, so a re-run recovers. Each removal step in this repo is its own commit. This repo's own telemetry wiring goes in one final step, entries before files.

## Acceptance Criteria

- [ ] A fresh `setup.sh claude-code` install contains no Context Mode or Telemetry hook files or settings entries.
- [ ] Passing `--context-mode-mcp`, `--structured-telemetry-mcp`, or `--backend-url` prints a one-line removal notice, and setup exits 0.
- [ ] Re-running setup on a project with both integrations installed removes their settings entries and hook folders for every installed tool, and leaves every other hook entry intact.
- [ ] No skill, template, standard, or living doc instructs an agent to emit, check, or record telemetry.
- [ ] `src/context-mode-hooks/` no longer exists, and `product.yml` lists two components.
- [ ] A migration file under `planifest-framework/migrations/` describes the removal and the clean-up step.
- [ ] The full test suite and CI pass.
