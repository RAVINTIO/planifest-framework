---
title: "Discovery - 0000037-green-ci-before-ship"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000037-green-ci-before-ship

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only; decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so; coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds 36 feature folders and `docs/about.md` exists. No `planifest-overrides/instructions/external-versioning.md`. |
| Git pre-flight | Started on `main`, level with `origin/main` after `git fetch` (head `94b6de3`). The human on the loop confirmed the backlog fill. Branch `feat/0000037-green-ci-before-ship` created and pushed. |
| Skills inbox | empty (`.gitkeep` only) |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`): `0.34.0`. `product.yml` reads `0.34.0` under `versionPolicy: max-component-version`. `planifest-framework/component.yml` reads `0.34.1` after the Fast Path fix in `94b6de3`.
- Prior features (`plan/_archive/`), latest five:
  - 0000032 governance continuity and write gate scope (2026-10-17)
  - 0000033 human-on-the-loop run mode (2026-10-19)
  - 0000034 backlog and ship overrides (2026-10-19)
  - 0000035 write gate scope and path hardening (2026-10-22)
  - 0000036 pipeline friction and gate fixes (2026-10-23)
- Constraining ADRs (unless superseded):
  - 0000031-ADR-001: the suite runs on `ubuntu-latest` and `macos-latest`, and `test_setup.ps1` runs under PowerShell 7 on `windows-latest`. Windows PowerShell 5.1 and Git Bash on Windows are not tested. Backlog 0000092 and 0000093 change this decision.
  - 0000031-ADR-002: new CI jobs stay in this repository's workflow, never in the consumer copy at `planifest-framework/hooks/planifest.yml`.
  - 0000031-ADR-003: CI jobs keep the `pull_request` trigger, with `permissions: contents: read`, no secrets, and `timeout-minutes: 10`.
  - 0000032-ADR-003: ship Step 12 is a blocking context clear after P9.
  - 0000033-ADR-011: P8 and P9 run a scoped clean-tree check.
  - 0000036-ADR-005: `skill-drift-check.mjs` warns and never blocks.
- Component and data-ownership map (`docs/component-registry.md`):
  - `planifest-framework` owns the standards, skills, hooks, scripts, templates, and tests under `planifest-framework/`.
  - `setup-hook-integration` owns `setup.sh`, `setup.ps1`, skill sync, and the hook adapters under `src/setup-hook-integration/`.
- Repo instructions: five files in `planifest-overrides/instructions/`, `custom-001` to `custom-005`.
- Stale backlog entries found: 0000073 and 0000075 describe gaps that 0000033 closed (`archive-current.mjs` and the P8 and P9 clean-tree checks).

## Record Samples

| Source | Value relied on | Rows sampled | Usable rows | Usable rate |
|--------|-----------------|--------------|-------------|-------------|
| `gh run list --branch main` (CI run history for `main`) | `conclusion` of the latest `main` run, as 0000191 suggests for GUTD | last 10 rows requested | 0 (the list is empty) | 0/10 (0%) |
| `gh run list` (all branches) | `conclusion` of `pull_request` runs | last 10 rows | 10 (event `pull_request` on every row, 5 success, 4 failure, 1 cancelled) | 10/10 (100%) |
| `.github/workflows/planifest.yml` `on:` block | trigger events | 1 file | 1 (`pull_request` on `main` and `master` only) | 1/1 (100%) |

The workflow never runs on a push to `main`, so `main` has no CI run of its own. A GUTD check has to read the checks of the last merged pull request, or the workflow needs a `push` trigger. 0000031-ADR-003 currently rules out the second option.
