---
title: "Drift Report - 0000035-write-gate-scope-and-path-hardening"
summary: "P6 drift checks for feature 0000035. Three low domain-term drifts in the glossary and the migrator skill. No boundary, ADR, or dependency drift."
status: "active"
---
# Drift Report - 0000035-write-gate-scope-and-path-hardening

**Skill:** [docs-agent](../../planifest-framework/skills/planifest-docs-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Date:** 2026-10-22

The P6 docs agent ran these checks after it updated the living docs. It flags drift and changes no code.

## Summary

| Check | Result | Evidence |
|-------|--------|----------|
| API endpoints | Not applicable | The design declares no API, and no OpenAPI spec exists. |
| Data ownership | Not applicable | No component owns a database. File ownership matches the design. See the ADR compliance rows for ADR-016 and ADR-017. |
| Domain terms | Drift, low | Three items. See [domain terms](#domain-terms). |
| Component boundaries | Pass | See [component boundaries](#component-boundaries). |
| ADR compliance | Pass | 16 ADRs spot-checked. See [ADR compliance](#adr-compliance). |
| Dependency direction | Pass | See [dependency direction](#dependency-direction). |

## Domain terms

Source: `plan/current/domain-glossary.md`. Compared against `planifest-framework/hooks/enforcement/path-rules.mjs`, `planifest-framework/scripts/set-product-release.mjs`, and `planifest-framework/skills/planifest-migrator/SKILL.md`.

| Term | Result | Evidence |
|------|--------|----------|
| `CLAUDE_PROJECT_DIR` | Drift, low | `domain-glossary.md` line 27 says the gates read it "when the working directory no longer exists". `resolveRoot` in `path-rules.mjs` lines 310 to 321 checks it first on every call. 0000035-ADR-006 sets that order. |
| Placement, `unresolvable` | Drift, low | `path-rules.mjs` lines 36 to 38 and 364 to 400 use "placement" for the physical and text targets, and `unresolvable` as a result status. P5 finding G-S01 added both. The glossary names neither term. |
| Human on the loop | Drift, low | The glossary term is "human on the loop". `planifest-migrator/SKILL.md` lines 44, 46, 87, and 91 say "the human". |
| Resolution error | Pass, note | The glossary lists it under concepts without a clear name. The code names it `ResolutionError` at `path-rules.mjs` line 145. The glossary could promote it to a term. |
| Scope record | Pass | `FAST_PATH_SCOPE_FILE = "plan/.fast-path-scope"` at line 476. `parseScopeRecord` at line 579. |
| Enforcement path | Pass | `FAST_PATH_ENFORCEMENT_PATHS` at line 494 and `isEnforcementPath` at line 537. |
| Always-permitted path | Pass | `ALWAYS_PERMITTED_PREFIXES` at line 56 and `ALWAYS_PERMITTED_FILES` at line 57. |
| Root marker | Pass | `ROOT_MARKERS = ["planifest-framework", ".git"]` at line 68, in the glossary order. |
| Planted marker | Pass | `plantedAt` at line 253, used by `markedRoot`. |
| Hop limit, link loop | Pass | `MAX_LINK_HOPS = 40` at line 178. The loop and over-limit cases throw a `ResolutionError`. |
| Root | Pass | `resolveRoot` at line 310. |
| `product.yml` update | Pass | `set-product-release.mjs` sets `version` and `feature`. Its `POLICIES` constant at line 66 lists the three `versionPolicy` values. |
| Migration record, pending migration, `not applicable` record | Pass | The migrator skill uses `plan/_migrations/{stem}.md`, the three outcomes, and the pending rule at lines 27 to 55. |
| Scan, migrator | Pass | The migrator skill has a Scan step at line 65 and a Record step at line 93. |

## Component boundaries

| Item | Result | Evidence |
|------|--------|----------|
| `src/` components | Pass | `src/setup-hook-integration/component.yml` is the only manifest under `src/`. The design declares `setup-hook-integration`. |
| `planifest-framework` | Pass | Its manifest sits at `planifest-framework/component.yml`, as in earlier features. The version reads `0.33.0`, which matches the design. |
| Extra components | Pass | No `src/` folder lacks a manifest, and the design declares no other component. |

## ADR compliance

| ADR | Result | Evidence |
|-----|--------|----------|
| ADR-001 | Pass | `path-rules.mjs` lines 52 and 53 import only `node:fs` and `node:path`. No `node:child_process` import exists. |
| ADR-002 | Pass | Caps at lines 477 and 478: 16 KiB and 64 paths. `.gitignore` line 24 lists `plan/.fast-path-scope`. |
| ADR-003 | Pass | `readGitState` at line 619. The caps at lines 479 and 480 are 4 KiB and 4 MiB. `DETACHED` at line 486. |
| ADR-004 | Pass | `foldWide` at line 526 applies NFKC and a full case fold. `NON_ASCII_RE` at line 530. `tests/test-0000035-req-009-fast-path-enforcement-paths.sh` checks the list against `fast-path.md`. |
| ADR-005 | Pass | `resolveTargetBoth` at line 368. `judgeWrite` at lines 824 to 851 blocks when either placement blocks. `shell-write-guard.mjs` line 65 imports `resolveTarget` only. |
| ADR-006 | Pass | `resolveRoot` checks `CLAUDE_PROJECT_DIR` first, then walks from `nearestExisting`. `hookCwd` at line 428 takes stdin `cwd`, then `process.cwd()`, then `CLAUDE_PROJECT_DIR`. |
| ADR-007 | Pass | `ratchet-check.mjs` line 60 imports `resolveRoot` and `resolveTargetBoth` from `path-rules.mjs`. Line 211 passes an unresolvable target. |
| ADR-008 | Pass | `plantedAt` at line 253 checks each segment against `ALWAYS_PERMITTED_FILES`. `markedRoot` filters distrusted markers and keeps walking. |
| ADR-010 | Pass | `planifest-ship-agent/SKILL.md` line 116 runs the step before Step 6. `set-product-release.mjs` exits 4 at line 431, 5 at line 462, and 0 at line 465. |
| ADR-011 | Pass, note | `standard-boot.md` and `cursor-boot.md` each hold one identical `Sanctioned scripts:` sentence that names the seven scripts. `set-product-release.mjs` clears `CLAUDE_PROJECT_DIR` at lines 148 to 153 and opens files with `O_NOFOLLOW`. The local, gitignored `CLAUDE.md` keeps the old text until setup runs again, as req-008 accepts. No migration tells a downstream project to re-run setup, so backlog 0000158 tracks that gap. |
| ADR-012 | Pass | `consistency-check.mjs` lines 12 to 13 and 65 to 70 set the limit at 10 with a warning band. |
| ADR-015 | Pass | `planifest-framework/migrations/` holds eight top-level `*.md` files and two helper scripts. No `_done/` folder exists. |
| ADR-016 | Pass | The migrator skill writes `plan/_migrations/{stem}.md` with the six fields. |
| ADR-017 | Pass | The migrator skill line 27 names itself the only writer. No hook or script under `planifest-framework/` writes to `plan/_migrations/`. |
| ADR-018 | Pass | The migrator skill pending rule at lines 48 to 55 matches the ADR. |
| ADR-019 | Pass, note | `plan/_migrations/` holds five records. The other three, `0001-date-format.md`, `0002-british-english.md`, and `retroactive-release-tags.md`, had scan findings. Build log lines 192 to 194 record each one as `Exception waiting (P3, human review)`, so each stays pending as the ADR requires. |

## Dependency direction

| Import | Declared in `docs/dependency-graph.md` | Result |
|--------|----------------------------------------|--------|
| `gate-write.mjs` imports `path-rules.mjs` and `read-stdin.mjs` | Yes | Pass |
| `shell-write-guard.mjs` imports `path-rules.mjs` and `read-stdin.mjs` | Yes | Pass |
| `ratchet-check.mjs` imports `path-rules.mjs` and `read-stdin.mjs` | Yes, added in 0000035 | Pass |
| `set-product-release.mjs` imports `resolveRoot` from `../hooks/enforcement/path-rules.mjs` | Yes, added in 0000035 | Pass |
| `check-design.mjs`, `em-dash-guard.mjs`, `auto-trigger-orchestrator.mjs`, and `check-orchestrator-presence.mjs` import `read-stdin.mjs` | Yes, through the shared-module node | Pass |
| Other scripts in `planifest-framework/scripts/` | Node built-ins only | Pass |

No import crosses a component boundary. `src/setup-hook-integration/docs/dependencies.md` still matches the graph, because setup copies every `*.mjs` in `hooks/enforcement/`.

## Follow-up

The three domain-term drifts are low. A later glossary or migrator edit can fix them. This report changes no code, glossary, or skill.

Backlog filed: 0000158.
