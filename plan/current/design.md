# Design - 0000030-context-mode-and-telemetry-mcp-removal

## Feature
- Problem: Planifest carries two optional MCP integrations, Context Mode and Telemetry, that the human on the loop has decided to drop. They reach about 200 tracked files, and downstream installs keep running their hooks.
- Adoption mode: standard-iterative
- Feature ID: 0000030-context-mode-and-telemetry-mcp-removal
- Version: 0.28.1 → 0.29.0
- Run mode: continuous, P1 to P9 without stopping (human instruction, 2026-10-14). This includes the P9 gate, which the orchestrator otherwise always stops at.
- Discovery: see `plan/current/discovery.md` (raw P0 findings; do not embed them here; this document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As the human on the loop, I install Planifest without any Context Mode MCP hooks, flag, component, or docs, so that the framework carries no code for an MCP server it no longer supports.
  - US-002: As the human on the loop, I run the pipeline with no Telemetry MCP hooks, backstops, setup flag, standard, or pipeline instructions, so that no phase spends effort on emission or failure checks.
  - US-003: As the human on the loop of a project that already installed either integration, I re-run setup and the stale hooks and settings entries disappear, so that no tool call runs a hook whose file no longer exists.
- Acceptance criteria confirmed: 7 (see `feature-brief.md`)
- Constraints:
  - `plan/_archive/` and `plan/changelog/` are immutable history.
  - Setup never fails on `--context-mode-mcp`, `--structured-telemetry-mcp`, or `--backend-url`.
  - Bash and PowerShell setup paths stay in parity.
  - `build-log.md` and the `product.yml` `id` field stay.
- Integrations: none added. Two removed: Context Mode MCP and Telemetry MCP (`structured-telemetry-mcp`).

## Architecture Layer
- Latency target: not applicable (no runtime service). Setup must not get slower in a way a person would notice.
- Availability target: not applicable.
- Scalability target: not applicable.
- Security: no auth surface. Clean-up removes only entries whose command path points at a removed Planifest hook, so it cannot delete a hand-added hook. `settings.json` writes go through a temporary file and a rename. No data classification change.
- Data privacy: no regulated data. Removing telemetry stops events that carried `product_id` and session IDs leaving the machine.
- Observability: removed by design. `build-log.md` and the P8 build assessment remain the run record.
- Cost boundary: not constrained.

## Engineering Layer
- Stack: Bash, PowerShell, Node `.mjs` hooks, Markdown / no database / no ORM / no IaC / no cloud / no compute / CI: GitHub Actions (`.github/workflows/planifest.yml`) / Build target: local
- Components:
  - `planifest-framework`: skills, templates, standards, hooks, and setup scripts. Loses the two hook folders, two backstops, and the telemetry standard.
  - `setup-hook-integration`: the installation layer. Stops installing both integrations and cleans them out of existing installs.
  - `context-mode-hooks`: deleted, with its `product.yml` `components[]` item.
- Data ownership:
  - `setup-hook-integration` → hook entries in each tool's settings file, installed hook folders, the install marker, `.claude/telemetry-enabled`
  - `planifest-framework` (orchestrator) → `plan/current/build-log.md`, `plan/.telemetry-failures/`, `plan/.telemetry-receipts/` (removed by setup clean-up)
  - `planifest-framework` (ship-agent) → `product.yml`
- Deployment: framework source copied into downstream repos. Downstream projects pick up the change by refreshing `planifest-framework/` and re-running setup, guided by the new migration file.
- API versioning: not applicable. CLI flags stay accepted as no-ops for backward compatibility.

## Scope
- In: see `feature-brief.md` In Scope, which includes Scope Lock clarifications A to I. In summary:
  - Delete `hooks/context-mode/`, `hooks/telemetry/`, both telemetry backstops, `telemetry-standards.md`, `docs/context-mode.md`, the 0008b telemetry doc, and `src/context-mode-hooks/`.
  - Remove both install paths from `setup.sh`, `setup.ps1`, `setup/claude-code.*`, `setup/opencode.sh`, and the Tier 1 adapter installs.
  - Accept the three retired flags as no-ops with a notice.
  - Add an always-on, path-matched setup clean-up with the error handling captured at Scope Lock.
  - Remove telemetry from every skill, the build-log template, boot templates, guides, and living docs.
  - Update `planifest-refresh-setup`, the P0 product-id rationale, the decisions index, and the tests.
  - Remove this repo's own wiring in one final step. Commit the downstream migration file last.
- Out:
  - Editing `plan/_archive/` or `plan/changelog/`.
  - Removing `build-log.md`, the P8 build assessment, or the `product.yml` `id` field.
  - Replacing either integration.
  - Other enforcement hooks, beyond removing telemetry calls.
- Deferred: nothing.

## Assumptions
- No downstream project depends on telemetry events beyond what the framework itself consumed. Impact if wrong: that project loses data with no replacement. The migration file names the removal so its owner can decide.
- `pwsh` isn't installed on this machine, so PowerShell changes get only a static check plus CI. Impact if wrong: a PowerShell-only bug ships. CI runs `pwsh` if the workflow includes it, and the P4 agent confirms which.
- The 27 remaining backlog entries are unaffected apart from passing mentions. Impact if wrong: an entry describes code that no longer exists, and backlog pickup catches it.

## Risks
- R-001 Self-hosting break: deleting hook files before this repo's own `.claude/settings.json` entries leaves every prompt calling a missing file. Likelihood medium, impact high. Mitigation: settings entries go first, in one final step.
- R-002 Residual references: with about 200 files involved, some mention is missed. Likelihood high, impact low. Mitigation: an allowlist-checked `git grep` at P4.
- R-003 Clean-up over-reach: path matching removes a hook a person wrote. Likelihood low, impact medium. Mitigation: match on exact removed Planifest paths, list every removal, and test with a hand-added hook fixture.
- R-004 PowerShell drift: `setup.ps1` diverges from `setup.sh` with no live run here. Likelihood medium, impact medium. Mitigation: parity tests that compare both scripts' source, plus CI.
- R-005 Migration runs mid-run in this repo: resume detection runs pending migrations first. Likelihood low, impact medium. Mitigation: commit the migration file last, and target it at downstream installs only.

## Dependencies
- Upstream: none.
- Downstream: every project that consumes `planifest-framework/`, especially those installed with `--context-mode-mcp` or `--structured-telemetry-mcp` (for example `ovelunor`).

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| REQ-001 - context-mode-removal | planifest-codegen-agent | Deletes hooks, component, docs, and setup wiring, with tests |
| REQ-002 - telemetry-hook-and-setup-removal | planifest-codegen-agent | Deletes hook code and setup install paths, with tests |
| REQ-003 - telemetry-pipeline-text-removal | planifest-docs-agent | Mostly skill, template, and standard prose. Codegen owns any test edits |
| REQ-004 - install-clean-up-and-retired-flags | planifest-codegen-agent | New setup behaviour in Bash and PowerShell, test-driven against fixtures |
| REQ-005 - refresh-setup-migration-and-self-hosting | planifest-codegen-agent | Skill edit, migration file, and this repo's final wiring step, in strict order |

The spec-agent sets the final requirement list at P1. This map is re-evaluated at each phase gate.

## Repo Instructions
From `planifest-overrides/instructions/`:
- `custom-001-local-git-only.md` (Git Permissions): you may fetch, pull, push, and create PRs without asking. Work on a `feat/` branch, push as you commit, and use no worktrees. Committing to `main` and merging PRs are human-only. Report any failed remote command. Commit granularly after every meaningful artifact write.
- `custom-002-prefer-subagent-decomposition.md`: split long or multi-unit tasks into parallel subagents by default. State the reason when a task can't be split.
- `custom-003-git-up-to-date-shorthand.md`: "GUTD" means check out `main`, pull, and report untracked files.
- Human instruction this session: don't push `feat/` until the scope and feature ID are settled. Both are now settled, so pushing resumes per `custom-001` once this design is confirmed.

## Confirmation
Human confirmed this design before proceeding: pending // Date and Time confirmed: pending
