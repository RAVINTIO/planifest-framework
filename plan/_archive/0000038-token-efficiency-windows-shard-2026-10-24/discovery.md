---
title: "Discovery - 0000038-token-efficiency-windows-shard"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000038-token-efficiency-windows-shard

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only; decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so; coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds prior feature folders, and `docs/about.md` exists |
| Git pre-flight | Branch `feat/0000038-token-efficiency-windows-shard`, cut from `main` at `2c99dd0` after a pull. `main` matched `origin/main`. PR #64 is merged. |
| Skills inbox | empty |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`, `product.yml`, `planifest-framework/component.yml`): `0.35.0`
- Prior features (`plan/_archive/`):
  - `0000033-human-on-the-loop-run-mode` (2026-10-19)
  - `0000034-backlog-and-ship-overrides` (2026-10-19)
  - `0000035-write-gate-scope-and-path-hardening` (2026-10-22)
  - `0000036-pipeline-friction-and-gate-fixes` (2026-10-23)
  - `0000037-green-ci-before-ship` (2026-10-24)
- Constraining ADRs (unless superseded): 0000037 ADR 003 (CI runs on `pull_request` only). 0000036 ADR-005 (skill drift check). 0000032 ADR-003 (blocking context reset after P9).
- Component / data-ownership map (`docs/`): one component, `planifest-framework`. It owns its skills, standards, templates, hooks, scripts, and tests. Product id `planifest-framework`.
- Repo instructions (`planifest-overrides/instructions/`): `custom-001` to `custom-005`. They cover local-git-only, subagent decomposition, GUTD, immediate backlog filing, and the P9 push-and-PR rule.

## Record Samples

| Source | Value relied on | Rows sampled | Usable rows | Usable rate |
|--------|-----------------|--------------|-------------|-------------|
| PR #64 CI run `40090446386`, Windows shard 1 log | `req-007` ratchet-check timing assertion | 1 run | 1 | 1/1 (100%). The call took 203 ms against a 200 ms limit in `test-0000032-req-007-stderr-block-reasons.sh` line 189. A copy sits in `tests/regression/`. |
| Backlog 0000230 usage profile | model mix, query source, tool result bytes | 1 week, 6,430 requests | 6,430 | The profile ran in rapid-prototypes. This run can't re-read its raw telemetry. |
