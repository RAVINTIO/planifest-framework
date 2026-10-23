---
title: "Discovery - 0000036-pipeline-friction-and-gate-fixes"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000036-pipeline-friction-and-gate-fixes

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only; decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so; coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds prior feature folders, and `docs/about.md` exists |
| Git pre-flight | `main` up to date with `origin/main` at `5c7859a` (PR #61 merge), clean tree, no open PRs. Branch `feat/0000036-pipeline-friction-and-gate-fixes` created from `main`. |
| Skills inbox | empty (`.gitkeep` only) |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`): `0.33.0`. `product.yml` reads `0.33.0` and names `0000035-write-gate-scope-and-path-hardening`.
- Prior features (`plan/_archive/`):
  - `0000033-human-on-the-loop-run-mode` (2026-10-19): `autonomous` run mode, gates as loops, and `run-mode.mjs`.
  - `0000034-backlog-and-ship-overrides` (2026-10-19): two instruction overrides.
  - `0000035-write-gate-scope-and-path-hardening` (2026-10-22): the Fast Path scope record, path hardening, and migration records in `plan/_migrations/`.
- Constraining ADRs (unless superseded):
  - 0000035 ADR-001 and 0000032 ADR-004: hooks use Node built-ins only, with no process spawn.
  - 0000003 ADR-005: hooks fail open and exit 0 on unexpected errors, including a failed `design.md` read.
  - 0000033 ADR-009: Fast Path never admits an enforcement path.
  - 0000029 ADR-001: boot files are build outputs. Setup writes them from `templates/standard-boot.md` and `templates/cursor-boot.md`.
- Component and data-ownership map (`docs/`, `product.yml`):
  - `planifest-framework` (`planifest-framework/component.yml`, `0.33.0`) owns the hooks, scripts, skills, standards, templates, migrations, and tests.
  - `setup-hook-integration` (`src/setup-hook-integration/component.yml`) owns the setup integration docs and tests.
- Setup copies skills and hooks into `.claude/` with `cp` (`setup.sh:77`, `:91`, `:340-348`). It injects `assets/` and `references/` into each installed skill (`setup.sh:117-140`). `.claude/` is git-ignored. No script compares installed copies with source.
- State of each pulled-in entry against `main`:
  - 0000158: no 0.33.0 migration exists. `standards/framework-update-policy.md` never mentions setup. The 0.31.0 precedent is `migrations/migrate-0.31.0-rerun-setup-for-shell-write-guard.md`, tested by `test-0000032-req-011-rerun-setup-migration.sh`.
  - 0000154: seven installed `SKILL.md` files differ from source: adr-agent, change-agent, codegen-agent, migrator, orchestrator, ship-agent, and spec-agent.
  - 0000160: the ship skill embeds `{feature-id}` in three subjects (`SKILL.md:157`, `:244`, `:364`). `hooks/commit-msg` blocks any subject over 72 characters with exit 1. 0000035 hit the block at P9.
  - 0000127: `scripts/run-mode.mjs:60` and `:134` match only a line that starts with `Run mode confirmed: autonomous`. The diff check at `:154-155` matches the same bare form. The orchestrator skill (`:458`) and the build-log template show no exact line format.
  - 0000157: `templates/standard-boot.md:14` and `templates/cursor-boot.md` number the Write-or-Edit rule as Hard Limit 8. The orchestrator skill (`:27`) numbers the build-log rule as Hard Limit 8 and cites it at `:328` and `:567`. `standards/agent-dispatch-standards.md` doesn't state the file-write rule.
  - 0000122: `skills/planifest-loop-runner/SKILL.md:26-43` reads an absent `design_critic` as `off` outside `autonomous`. `templates/loop-toggles.template.yml:28` matches. `test-0000033-req-003-gates-as-loops.sh` asserts the `off` default. No script reads the toggle.
  - 0000139: only `templates/feature-brief.template.md:27` asks for a split above 3 criteria. `scripts/consistency-check.mjs:65-72` warns from 4 to 10 and fails above 10. The spec agent, the design critic, and the loop runner carry no split step.
  - 0000143: `hooks/enforcement/path-rules.mjs:774-781` reads `design.md` inside a `try` that allows the write on any error. A folder throws `EISDIR` and the write passes. A FIFO blocks until the hook times out.
  - 0000159: `path-rules.mjs:772` returns allowed for an always-permitted file name before `isEnforcementPath` runs. `isEnforcementPath` runs only in `scopeVerdict` when `design.md` is absent.
  - 0000155: `tests/run-tests.sh` doesn't clear `CLAUDE_PROJECT_DIR`. 21 suite files clear it themselves, 14 in `tests/` and 7 in `tests/regression/`. Four gate-related suites don't.
  - 0000149: `ratchet-check.mjs:267` and `em-dash-guard.mjs:120` print raw text. `shown()` at `path-rules.mjs:122-133` cuts after escaping, so it can split an escape.
- Test command: `bash planifest-framework/tests/run-tests.sh`. CI runs it on Ubuntu and macOS (`.github/workflows/planifest.yml:79`).

## Record Samples

None. The design reads no existing records.
