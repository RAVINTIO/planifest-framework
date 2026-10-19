---
title: "Discovery - 0000033-human-on-the-loop-run-mode"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000033-human-on-the-loop-run-mode

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only; decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so; coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds 32 feature folders, and `docs/about.md` exists |
| Git pre-flight | Branch `feat/0000033-human-on-the-loop-run-mode`, created from `main` at `54aeda8` after PR #58 merged. `main` matched `origin/main`. |
| Skills inbox | `planifest-framework/skills-inbox/` is absent: empty |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`): `0.31.0`. `planifest-framework/component.yml` and `product-version.mjs` agree. `product.yml` caches `0.30.0` in its `version` field, but its `max-component-version` policy derives `0.31.0`.
- Prior features (`plan/_archive/`): most recent three:
  - `0000030-context-mode-and-telemetry-mcp-removal` (2026-10-14): dropped the Context Mode and Telemetry MCP integrations.
  - `0000031-ci-test-and-powershell-coverage` (2026-10-16): CI on Linux, macOS, and PowerShell 7.
  - `0000032-governance-continuity-and-write-gate-scope` (2026-10-17): session markers cleared in P9, blocking context clear after P9, and the Bash shell-write guard.
- Constraining ADRs (unless superseded):
  - 0000006-ADR-003: parallelism directives live in skill text, not code.
  - 0000012-ADR-005: `plan/.run-mode` persists the run mode. Any value other than `continuous` reads as `interactive`.
  - 0000014-ADR-008: one question at a time, framework-wide.
  - 0000016-ADR-003: loop toggles in `planifest-overrides/loop-toggles.yml`.
  - 0000016-ADR-006: verifiers are fresh-context, REJECT-default subagents.
  - 0000016-ADR-007: deterministic caps, reversal budget, and ratchet.
  - 0000023-ADR-001: the `continuous_run` exception applies to the P1 to P6 gates.
  - 0000025-ADR-003: Scope Lock answers are drafted and presented as a batch.
  - 0000032-ADR-003: blocking context clear after P9.
- Component and data-ownership map (`docs/component-registry.md`):
  - `planifest-framework`: skills, standards, templates, hooks, and scripts. Owns every file this feature changes.
  - `setup-hook-integration` (`src/setup-hook-integration/`): setup scripts and hook adapters. This feature doesn't need to change it.
- Repo instructions (`planifest-overrides/instructions/`): three files.
  - `custom-001-local-git-only.md`: fetch, pull, push, and `gh pr create` without asking. Committing to `main` and merging stay human-only.
  - `custom-002-prefer-subagent-decomposition.md`: default to parallel subagents for independent units of work.
  - `custom-003-git-up-to-date-shorthand.md`: the `GUTD` shorthand.
- Backlog: 58 entries before pickup. The human chose 11 for this run. See `build-log.md`.
