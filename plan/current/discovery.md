---
title: "Discovery - 0000035-write-gate-scope-and-path-hardening"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000035-write-gate-scope-and-path-hardening

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only; decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so; coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds prior feature folders, and `docs/about.md` exists |
| Git pre-flight | `main` up to date with `origin/main`, clean tree, no open PRs. Branch `feat/0000035-write-gate-scope-and-path-hardening` created from `main` at `2253e80`. |
| Skills inbox | empty (`.gitkeep` only) |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`): `0.32.0`. `product-version.mjs` derives `0.32.0`.
- `product.yml` top-level `version` reads `0.30.0` and `feature` reads `0000031-ci-test-and-powershell-coverage`. Both are stale, which is the symptom backlog 0000124 describes.
- Prior features (`plan/_archive/`):
  - `0000032-governance-continuity-and-write-gate-scope` (2026-10-17): shared `path-rules.mjs`, the shell-write guard, and block reasons on stderr.
  - `0000033-human-on-the-loop-run-mode` (2026-10-19): `autonomous` run mode. Its ADR 009 let Fast Path admit changes with no `src/` target.
  - `0000034-backlog-and-ship-overrides` (2026-10-19): two instruction overrides.
- Constraining ADRs (unless superseded):
  - 0000032 ADR 004: `path-rules.mjs` constraints. Node built-ins only, no process spawn, root markers `planifest-framework/` then `.git`, real paths on both sides, 0000009 ADR 005 normalisation.
  - 0000032 ADR 006: the shell-write guard is a heuristic reader.
  - 0000003 ADR 005: `gate-write` fails open when it can't read `design.md`.
  - 0000005 ADR 003: the `plan/current/**` sentinel check and its exemptions.
  - 0000033 ADR 009: Fast Path admits changes with no `src/` target but never an enforcement path.
- Component and data-ownership map (`docs/`, `product.yml`):
  - `planifest-framework` (`planifest-framework/component.yml`, `0.32.0`) owns the hooks, scripts, skills, standards, templates, and workflows.
  - `setup-hook-integration` (`src/setup-hook-integration/component.yml`, `0.6.0`) owns the setup integration docs and tests.
- State of each pulled-in entry against the code on `main`:
  - 0000062: `workflows/fast-path.md` already admits changes with no `src/` target (0000033 ADR 009). The routing gap is closed. The write-gate half remains, and 0000125 covers it.
  - 0000081 and 0000125: `evaluateWrite` returns `NO_DESIGN_REASON` for every path outside the allowlist when `plan/current/design.md` is absent. Fast Path never writes `design.md`.
  - 0000124: ship Step 9 edits `product.yml` after P7 Step 6 has archived `design.md`.
  - 0000106 and 0000117: `toRootRelative` resolves `..` as text through `path.resolve`, then calls `realPathOf`. `realPathOf` follows links only on the existing part of the path, so a dangling link's target is never judged.
  - 0000107: `resolveRoot` returns `null` when cwd is not a folder, before it checks `CLAUDE_PROJECT_DIR`. `judgeWrite` then returns `{ allowed: true, outside: true }`.
  - 0000109: `ratchet-check.mjs` (258 lines) does not import `path-rules.mjs`.
  - 0000114: `markedRoot` distrusts a marker only below a `plan/` or `docs/` prefix, not below an always-permitted basename.

## Record Samples

None. The design reads no existing records.
