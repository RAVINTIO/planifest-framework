---
title: "Discovery - pending (proposed 0000030-context-mode-and-telemetry-mcp-removal)"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - pending (proposed 0000030-context-mode-and-telemetry-mcp-removal)

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only; decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so; coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds 29 feature folders, and `docs/about.md` exists |
| Git pre-flight | Started on merged branch `feat/0000029-...` (PR #56 merged 2026-08-22). Human confirmed all PRs merged. Checked out `main`, set upstream to `origin/main`, fast-forwarded to `6a50af1`. Created `feat/pending` locally. The human asked not to push until the scope and feature ID are settled. |
| Skills inbox | `planifest-framework/skills-inbox/` absent: empty |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md` and `product.yml`): `0.28.1`. `product.yml` declares `id: "planifest-framework"` and `versionPolicy: "max-component-version"`.
- Prior features (`plan/_archive/`): 0000001 to 0000029 plus `backlog-triage-2026-07-11`. The most relevant:
  - 0000001 context-mode-enforcement-hooks: introduced `hooks/context-mode/`.
  - 0000008 context-mode-plugin-routing-rules.
  - 0000017 ratchet-forgery-detection-and-telemetry-schema-spec.
  - 0000018 telemetry-emission-consistency: removed the `--context-mode-mcp` coupling from telemetry gating.
  - 0000024 declared-product-id-for-telemetry: made `product.yml` `id` mandatory so telemetry events stay attributable.
  - 0000026 context-hook-and-telemetry-backstop-fixes.
  - 0000027 backlog-batch-governance-tooling-fixes: telemetry receipt backstop.
  - 0000028 telemetry-hardening-and-enforcement-fixes.
  - 0000029 context-mode-removal-and-boot-file-regeneration-fix: dropped context-mode from boot-file templates only.
- Constraining ADRs (unless superseded):
  - 0000003 ADR-005: hook-driven emission is fire-and-forget.
  - 0000016 ADR-002 (decisions index, telemetry guidance centralised in `telemetry-standards.md`).
  - 0000017 ADR-002: the three context-mode hooks are Node `.mjs`.
  - 0000018 ADR-001 and ADR-002: unified telemetry signal, failure markers and interactive recovery.
  - 0000024 ADR-001: `product.yml` `id` is the declared product ID, motivated by telemetry.
  - 0000026 ADR-001 and 0000027 ADR-001: telemetry receipt backstop.
  - 0000028 ADR-001 and ADR-002: retry semantics, shared module placement.
- Component / data-ownership map (`product.yml`, `src/`):
  - `planifest-framework` (`planifest-framework/component.yml`): skills, templates, standards, hooks, setup scripts.
  - `setup-hook-integration` (`src/setup-hook-integration/`).
  - `context-mode-hooks` (`src/context-mode-hooks/`): manifest and docs for `planifest-framework/hooks/context-mode/`.

## Footprint scan (raw)

- `planifest-framework/hooks/context-mode/`: `block-bash.mjs`, `block-grep.mjs`, `block-webfetch.mjs`.
- `planifest-framework/hooks/telemetry/`: 9 modules (`emit-event.mjs`, `emit-phase-start.mjs`, `emit-phase-end.mjs`, `resolve-phase.mjs`, `context-pressure.mjs`, `emit-event-receipt.mjs`, `get-flag-path.mjs`, `read-product-id.mjs`, `record-telemetry-failure.mjs`).
- `planifest-framework/hooks/enforcement/`: `check-telemetry-failures.mjs` and `check-telemetry-receipts.mjs` are telemetry backstops.
- `setup.sh`, `setup.ps1`, `setup/claude-code.sh`, `setup/claude-code.ps1`: install and wire both hook families, and parse `--context-mode-mcp` and `--structured-telemetry-mcp`.
- `planifest-framework/standards/telemetry-standards.md`, `docs/context-mode.md`, `docs/0008b--feature--structured-telemetry-framework-integration.md`.
- 15 skill files mention telemetry, including the orchestrator's Telemetry section and the build log's per-phase `Telemetry` field.
- About 160 tracked files outside `plan/_archive/` and `plan/changelog/` mention telemetry. About 50 mention context mode.
- Tests: `test-setup-telemetry.sh`, the 0000018 regression tests, and several setup tests assert on these flags and hooks.
- Repo-level state: `plan/.telemetry-failures/` (empty), `CLAUDE.md` Hook Enforcement section lists `emit-phase-start / emit-phase-end`.

## Backlog pickup

- Discarded on human instruction (2026-10-14): `0000022`, `0000056`, `0000066`, `0000067`, `0000068`, `0000069`, `0000070`, `0000072`.
- 27 entries remain. The human redirected this run to the removal before deciding on them, so they are left untouched for now.
