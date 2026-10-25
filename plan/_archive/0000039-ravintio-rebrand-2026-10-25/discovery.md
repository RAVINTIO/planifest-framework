---
title: "Discovery - 0000039-ravintio-rebrand"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000039-ravintio-rebrand

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only; decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so; coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds feature folders up to `0000038-token-efficiency-windows-shard-2026-10-24`, and `docs/about.md` exists |
| Git pre-flight | Branch `feat/0000039-ravintio-rebrand`, level with `origin`. `main` matched `origin/main` at triage (2026-10-25). Open PR #70 (chore, backlog only) doesn't touch this scope. |
| Skills inbox | `planifest-framework/skills-inbox/` is absent, so the scan found nothing |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`, `product.yml`): `0.36.0`. Latest tag `v0.36.0`. `product.yml` has `id: "planifest-framework"` and `versionPolicy: "max-component-version"`.
- Prior features (`plan/_archive/`): 0000030 to 0000038 are the latest nine, dated 2026-10-14 to 2026-10-24. 0000038 cut session context cost and fixed Windows test timing.
- Constraining ADRs (unless superseded):
  - 0000031 ADR-003 and 0000037 ADR-012 to ADR-014: CI runs on `pull_request` only, with Windows shards and both PowerShell legs.
  - 0000035 ADR-010: this repo keeps a run record for every migration it ships (`test-0000035-req-010`).
  - 0000036 ADR-005: the skill drift check compares source and installed skills by name.
  - 0000027 ADR-003: the skill-scope test for any new skill.
- Component / data-ownership map (`docs/component-registry.md`): two components. `planifest-framework` owns the pack. `setup-hook-integration` (`src/setup-hook-integration/`) owns the hook wiring tests.
- Repo instructions (`planifest-overrides/instructions/`): five files, `custom-001` to `custom-005`. They cover local-git-only, subagent decomposition, GUTD, backlog filing, and P9 push and PR.

### Rename inventory (tracked files, approximate)

- 2,465 tracked files. 1,190 have `planifest` in the path. 1,170 of those sit under `planifest-framework/`, and 771 of those under `external-skills/`.
- Outside history, about 590 files hold the word: `planifest` on about 1,980 lines, `Planifest` on about 290, and `PLANIFEST` on about 145. Tests hold more than half (145 files).
- History, left as written: `plan/_archive/` (961 files, about 8,289 hits) and `plan/changelog/` (64 files, about 419). `plan/_migrations/` records name migration files only.
- Named paths: `planifest-framework/`, `planifest-overrides/`, 21 `planifest-*` skills, `.github/workflows/planifest.yml`, `planifest-framework/hooks/planifest.yml`, `refresh-planifest-framework-dir.ps1`, and six backlog `_reference/planifest-framework-*.md` files.
- About 30 distinct `PLANIFEST_*` variables. Only `PLANIFEST_SESSION_ID` (OpenCode adapter) reaches consumers at run time. The rest are set and read by the pack's own setup, scripts, CI, and tests.
- Consumer-visible names:
  - marker files `.planifest-session`, `.planifest-manifest`, and `.planifest-setup-flags` (the refresh-setup skill reads the last one)
  - boot-file markers `<!-- planifest-overrides:instructions:start -->` and `:end -->`
  - ignore-file headers `# Planifest - Token Reduction` and `# Planifest - Indexing Exclusions`, which setup greps for idempotence
  - `core.hooksPath planifest-framework/hooks`, and `ROOT_MARKERS` in `hooks/enforcement/path-rules.mjs`
  - the consumer workflow name `Planifest Strict Pipeline`, which branch protection may require
  - the `@planifest` npm scope in the OpenCode plugin path
  - the `[Planifest]` log prefix
- Split and built names a bulk replace would miss or break:
  - `planifest-$s-agent` and brace expansions such as `skills/planifest-{adr-agent,...}`
  - placeholders `planifest-{skill-name}` and globs `planifest-*`
  - the regex `/^\[planifest\]/i`
  - `planifest_0000037_req008_XXXXXX` mktemp templates
  - mojibake copies of the old dash after `Planifest` in the `setup.sh` heredoc, around lines 788 to 957
  - no `"planifest""-framework"` adjacent-quote split turned up in live code
- History readers: 18 suites read git history, tags, or diffs. About 25 read the archive, changelog, or `_migrations`. `test-0000037-req-008` builds fixture repos with `planifest-framework/` paths.
- External links: `github.com/planifest/planifest-framework` and `github.com/planifest/framework` (three each), and the sibling docs site `planifest.github.io/planifest-docs/` (about nine links).
- Tests: `bash planifest-framework/tests/run-tests.sh`, plus `tests/test_setup.ps1`. CI pins no Bash version, so the macOS leg may run Bash 3.2.

### Prior art: RAVINTIO Zero 0000160 and 0000164

- 0000160 ADR-001: one rename map. Prose uses RAVINTIO in block capitals, identifiers lowercase `ravintio`, and variables `RAVINTIO_`. History stays as written.
- 0000160 ADR-002: only names that consumers set keep a legacy fallback. The new name wins, with no warning. 0000164 ADR-005 moved the removal point to 1.0.0.
- 0000160 ADR-003: a consumer migration with `.sh` and `.ps1` helpers. It moves the old pack to `.ravintio-backup/` and never deletes it. A security High on PowerShell 5.1 junctions forced that design. An "Applies when" check stops the pack source repo running its own migration.
- 0000160 ADR-004: a brand guard test with a path and line allowlist. It must read lines with `done <<< "$(...)"`, because Bash 3.2 drops lines from `done < <(...)`.
- 0000164 ADR-005: the rename shipped as a minor release (0.12.0), not 1.0.0.
- The GitHub repo rename ran after merge. 0000160 needed six P3 fix cycles. Most came from split literals, history readers, and Bash 3.2.

## Record Samples

None. The design reads no existing records.
