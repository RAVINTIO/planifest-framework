---
title: "Feature Brief - Context Mode and Telemetry MCP removal"
summary: "Remove the Context Mode MCP and Telemetry MCP integrations from the framework, and clean up installs that already have them."
status: "draft"
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
- Remove the `--context-mode-mcp` and `--structured-telemetry-mcp` install paths from `setup.sh`, `setup.ps1`, and `setup/claude-code.*`, including Tier 1 adapter installs.
- Keep both flags as accepted no-ops that print a one-line notice.
- Make setup remove stale settings entries and the `.claude/hooks/context-mode/` and `.claude/hooks/telemetry/` folders on re-run.
- Delete `src/context-mode-hooks/` and its `product.yml` `components[]` item. Update the `product.yml` header comment.
- Delete `standards/telemetry-standards.md`, `docs/context-mode.md`, and `docs/0008b--feature--structured-telemetry-framework-integration.md`.
- Remove telemetry instructions from every skill, including the orchestrator's Telemetry section and every per-phase `Telemetry` line requirement.
- Remove the `Telemetry` field and the telemetry-gap summary row from `templates/build-log.template.md`.
- Remove context mode and telemetry references from boot templates, `README.md`, getting-started and reference guides, and living `docs/`.
- Delete or rewrite the tests that cover the removed features. Update the regression manifest.
- Add a migration file under `planifest-framework/migrations/` that explains the removal to downstream projects.
- Record superseded ADRs in `docs/decisions-index.md`.

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
| Residual references | 0 matches for `context-mode`, `context_mode`, `structured-telemetry`, and `telemetry` outside `plan/_archive/`, `plan/changelog/`, the migration file, and the setup no-op notice | `git grep` over the tree at P4 |
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

Left for the Scope Lock Challenge to derive.

**Happy path:**

> 

**First-run path:**

> 

**Error / sad path:**

> 

**Cross-session continuity:**

> 

## Acceptance Criteria

- [ ] A fresh `setup.sh claude-code` install contains no Context Mode or Telemetry hook files or settings entries.
- [ ] Passing `--context-mode-mcp` or `--structured-telemetry-mcp` prints a one-line removal notice, and setup exits 0.
- [ ] Re-running setup on a project with both integrations installed removes their settings entries and hook folders, and leaves every other hook entry intact.
- [ ] No skill, template, standard, or living doc instructs an agent to emit, check, or record telemetry.
- [ ] `src/context-mode-hooks/` no longer exists, and `product.yml` lists two components.
- [ ] A migration file under `planifest-framework/migrations/` describes the removal and the clean-up step.
- [ ] The full test suite and CI pass.
