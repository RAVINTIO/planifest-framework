# Changelog (0000035-write-gate-scope-and-path-hardening, 22 Oct 2026)

**Feature:** Write gate scope and path hardening
**Pipeline run:** P0 to P9 in `autonomous` mode. No phases skipped.
**PR:** https://github.com/planifest/planifest-framework/pull/61 (draft, 11 exceptions waiting)

## What Was Built

Planifest 0.33.0 lets every sanctioned route pass the write gate, closes five ways to slip a write past it, and keeps migration run state per project. It folds in ten backlog entries in one wave.

- **Fast Path scope record (0000062, 0000081, 0000125):** a Fast Path change lists its target paths in `plan/.fast-path-scope`. `gate-write` and the shell-write guard admit only those paths, and print a notice for each admitted write. The record binds to the branch and `HEAD`, and Fast Path removes it before the commit.
- **Fast Path enforcement list:** `FAST_PATH_ENFORCEMENT_PATHS` names every hook, script, setup, and wiring path, plus `.git/` and the CI workflow. A scope record never admits one, and never admits a non-ASCII target.
- **`product.yml` set at P7 (0000124):** the new `set-product-release.mjs` sets `version` and `feature` before the archive, so Step 9 tags the right release.
- **Sanctioned scripts:** Hard Limit 8 in both boot templates names the seven framework scripts that skill steps may run to write files, with their exact invocations.
- **Links judged by their real target (0000106, 0000117):** the gates resolve every link and judge each target two ways, with `..` collapsed as text and with `..` resolved through links. A resolution error inside the repository blocks with exit 2.
- **Root found when the cwd is gone (0000107):** the gates use `CLAUDE_PROJECT_DIR`, then the nearest existing parent.
- **`ratchet-check` from any folder (0000109):** the ratchet uses the shared root and target rules.
- **No planted root (0000114):** a `.git` or `planifest-framework/` marker under an always-permitted name never becomes a root.
- **Migration run state per project (0000126):** migration files never move. Each project records each run in `plan/_migrations/`. This repo holds five records, and three migrations wait for the human on the loop.
- **Acceptance-criteria limit:** `consistency-check.mjs` allows up to 10 criteria per requirement and warns from 4.

P5 found and closed two High bypasses in this feature's own link handling and Unicode matching. Two fresh-context re-review rounds confirmed 19 fixes.

## Artifacts Produced

- `design.md`, `discovery.md`, `feature-brief.md`, `execution-plan.md`, `scope.md`, `risk-register.md`, `domain-glossary.md`
- `requirements/req-001` to `req-010`
- 16 ADRs in `adr/`
- `streams/` for three streams
- Critic verdicts: `design-critic-p1*.md`, `design-critic-p2*.md`, `cross-model-review*.md`
- `validation-report.md`, `verification-report.md`, `security-report.md`, `drift-report.md`, `deviation-review.md`
- `recommendations.md`, `iteration-log.md`, `build-log.md`, and three loop-state files

## Decisions

- ADR-001: the stack is unchanged, and gate code runs on Node built-ins with no spawn.
- ADR-002: the Fast Path scope record is self-authorisation with a visible trail.
- ADR-003: scope record staleness comes from the branch and `HEAD`, read from git files.
- ADR-004: a concrete Fast Path enforcement list covers hook wiring.
- ADR-005: links resolve segment by segment, judged two ways, and fail closed inside the root.
- ADR-006: the root comes from `CLAUDE_PROJECT_DIR`, then the nearest existing parent.
- ADR-007: `ratchet-check` uses the shared root and target rules.
- ADR-008: root markers under always-permitted names don't count.
- ADR-010: a script sets `product.yml` in P7.
- ADR-011: Hard Limit 8 names the sanctioned scripts.
- ADR-012: the acceptance-criteria limit is 10, with a warning from 4.
- ADR-015: migration files never move.
- ADR-016: each project keeps its own migration run records.
- ADR-017: the migrator owns the migration records.
- ADR-018: a migration is pending until it has a readable record.
- ADR-019: records come from scans and are never seeded.

## Skipped Phases

None
