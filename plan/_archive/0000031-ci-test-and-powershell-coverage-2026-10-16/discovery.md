---
title: "Discovery - 0000031-ci-test-and-powershell-coverage"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000031-ci-test-and-powershell-coverage

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only; decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so; coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds prior features, and `docs/about.md` exists |
| Git pre-flight | Branch `feat/0000031-ci-tests-and-governance-lapses`, cut from `main` at `6c53e7f`. `main` matched `origin/main` after a pull on 2026-10-15. |
| Skills inbox | empty |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`, `product.yml`): `0.29.0`. Product id `planifest-framework`, `versionPolicy: max-component-version`.
- Prior features (`plan/_archive/`): latest are `0000028-telemetry-hardening-and-enforcement-fixes` (2026-08-08), `0000029-context-mode-removal-and-boot-file-regeneration-fix` (2026-08-09), and `0000030-context-mode-and-telemetry-mcp-removal` (2026-10-14).
- Constraining ADRs: see `docs/decisions-index.md`. The ADR for feature 0000019 keeps `self-description-check` in this repo's workflow only, never in the consumer copy at `planifest-framework/hooks/planifest.yml`.
- Component map (`docs/component-registry.md`): one component, `planifest-framework`.
- CI today (`.github/workflows/planifest.yml`): two Ubuntu jobs on `pull_request` to `main` or `master`. They run the code/doc parity check and `self-description-check.mjs`. No job runs `planifest-framework/tests/run-tests.sh` or `setup.ps1`.
- Test assets: `planifest-framework/tests/run-tests.sh`, `test_setup.sh`, `test_setup.ps1`, `test-gate-write-windows.mjs`, and per-feature `test-*.sh` scripts.
- Repo instructions: `custom-001` (git permissions, push allowed, no commits to `main`), `custom-002` (subagent decomposition), and `custom-003` (GUTD shorthand).
