---
title: "Scope - 0000039-ravintio-rebrand"
summary: "Defines explicit boundaries of what is in scope and out of scope."
status: "active"
version: "0.1.0"
---
# Scope - 0000039-ravintio-rebrand

**Skill:** [spec-agent](../skills/spec-agent-SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Wave:** not waved
**Version:** 0.37.0

## In Scope

- Pack paths and identifiers. Rename `planifest-framework/` to `ravintio-framework/` and `planifest-overrides/` to `ravintio-overrides/`. Rename the 21 `ravintio-*` skills, the workflow file `ravintio.yml`, and the `product.yml` and `component.yml` ids. Maps to req-001-pack-paths-and-identifiers (US-001).
- Runtime names. Rename the markers `.ravintio-session`, `.ravintio-manifest`, and `.ravintio-setup-flags`. Rename the `<!-- ravintio-overrides:instructions:start -->` marker, the `@ravintio` npm scope, the `[RAVINTIO]` log prefix, and the `RAVINTIO Strict Pipeline` workflow name. Setup replaces the old boot-file markers and ignore-file headers so no block appears twice. Setup reads and then removes `.planifest-setup-flags`. Maps to req-002-runtime-names (US-001).
- Environment variables. Rename `PLANIFEST_*` to `RAVINTIO_*` with no fallback, except that setup reads `PLANIFEST_SESSION_ID` when `RAVINTIO_SESSION_ID` is unset, with no warning. Maps to req-003-environment-variables (US-001).
- Brand prose. Write `RAVINTIO Framework` in docs, README files, skills, templates, and link text. Point repo links to `github.com/RAVINTIO/ravintio-framework`. Change only pack-authored lines under `external-skills/`. Update live backlog entry prose. Maps to req-004-brand-prose (US-001).
- History and split-name protection. List every split or built old name, every history-reading suite, and the `setup.sh` mojibake lines before the scripted pass. Give each a test or a protected-list entry. Keep `plan/_archive/`, `plan/changelog/`, `plan/_migrations/`, and shipped migration bodies byte-identical. Keep `plan/backlog/*/_reference/` documents as written. Maps to req-005-history-and-split-name-protection (US-001).
- Setup refusal while `planifest-framework/` or `planifest-overrides/` exists. The message names the migration. Maps to req-002-runtime-names (US-001), and req-006-consumer-migration supplies the migration it names.
- Consumer migration `migrate-0.37.0-ravintio-rename.md` with `.sh` and `.ps1` helpers. The helpers move the overrides folder, rename the workflow, remove old markers, stop git tracking of the old pack, and move it to `.ravintio-backup/planifest-framework/`. They refuse symbolic links and junctions, never delete, stop on a clash before moving anything, and can run again safely. The migration warns about branch protection. An "Applies when" check skips this repo, which writes its own `plan/_migrations/` record with outcome `not applicable`. Maps to req-006-consumer-migration (US-002).
- Brand guard suite. A Bash suite reads `git ls-files` minus the history paths and `plan/current/`. It fails on any `planifest` hit in a path or line, in any case. Allowlist entries each carry a path regex, a line regex, and a reason. A stale entry fails. A second case plants the old name and expects a failure. The suite passes on Bash 3.2 and Bash 5. Maps to req-007-brand-guard (US-003).
- Hook wiring tests in `setup-hook-integration` with updated path references. Maps to req-002-runtime-names (US-001).
- The scripted bulk rename in P3. One pass uses `git mv` and a replace that skips the protected list. The script lives in the scratchpad and never in the repo. Follow-up fixes use Edit. Maps to req-001-pack-paths-and-identifiers (US-001), with the protected list owned by req-005-history-and-split-name-protection.
- The 0.37.0 minor version bump in `product.yml`, `ravintio-framework/component.yml`, and `docs/about.md`, with old-name reads kept through 0.x. Maps to req-010-version-bump (US-004).

- P2 clarification for the runtime-names line: setup also reads `.planifest-manifest` once and removes it. The helper removes only `.planifest-session` (ADR-004, req-006).

## Out of Scope

- `plan/_archive/`, `plan/changelog/`, `plan/_migrations/` records, and the bodies of shipped migrations. These stay byte-identical.
- Sibling repos, including RAVINTIO Zero and `planifest-docs`. The `planifest-docs` links stay, with allowlist entries.
- The local clone folder and the `C:\d\planifest\framework\` path in the refresh script. The script file itself is renamed.
- Vendored upstream text under `external-skills/`. It stays as written.
- Historical review documents under `plan/backlog/*/_reference/`. They stay as written, with brand-guard allowlist entries.
- Old feature ids, ADR ids, backlog ids, and sibling repo names. They stay as written.
- A major version bump. Backlog 0000237 proposed one, and the human on the loop set a minor bump on 2026-10-25.
- Every other backlog entry. Live backlog entries change only their brand words, and the pipeline picks up no backlog entry besides 0000237.

## Deferred

- The `gh repo rename ravintio-framework` command and the `origin` update run after the human on the loop merges the PR. Blocked until it runs: links to `github.com/RAVINTIO/ravintio-framework` do not resolve, because the repo still has the old name.
- Removal of old-name reads at 1.0.0. That covers `PLANIFEST_SESSION_ID`, the old boot-file markers and ignore-file headers, `.planifest-setup-flags`, and `.planifest-manifest`. Blocked until it ships: setup carries the old-name fallbacks, and the brand guard keeps allowlist entries for them.
