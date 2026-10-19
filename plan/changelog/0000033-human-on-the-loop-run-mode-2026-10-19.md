# Changelog (0000033-human-on-the-loop-run-mode, 19 Oct 2026)

**Feature:** Human-on-the-loop run mode
**Pipeline run:** P0 to P9 completed in `continuous` mode. No phases skipped.
**PR:** pending, updated after the PR is raised in Step 10

## What Was Built

Planifest 0.32.0 adds an `autonomous` run mode. The human on the loop sets intent at P0 and reviews the result after P9. No gate waits for them in between, unless an item is on a declared exception list. Merging, schema changes, destructive operations, and credentials stay human-gated in every mode.

The run folds in 11 backlog entries:

- 0000078: the `autonomous` mode, the exception list, gates as loops with fresh-context checkers, a changed approach at a cap, and one final report.
- 0000076 and 0000101: P0 asks only real forks, confirms in one turn, and samples the existing records a design depends on.
- 0000103: a release budget in size points replaces the fixed three-story rule when a repo sets one.
- 0000104 and 0000082: always-parallel work units in every phase, parallel requirement streams, and an orchestrator-owned join with a reconciliation script.
- 0000075 and 0000073: P7 archives with `archive-current.mjs` and no glob delete, and P8 and P9 end with a clean-tree check.
- 0000086: the docs agent reruns the P4 checks after P6 edits.
- 0000059: choice prompts name who acts in each option.
- 0000062: Fast Path admits changes with no `src/` target, except enforcement code and the exception list.

P5 security review added `run-mode.mjs`, which decides `autonomous` from git history, and hardened both other scripts against symbolic-link and forgery attacks.

## Artifacts Produced

- `design.md`, `feature-brief.md`, `discovery.md`, and `build-log.md`
- `execution-plan.md`, 18 requirements, `scope.md`, `risk-register.md`, and `domain-glossary.md`
- 15 ADRs in `adr/`
- `security-report.md`, `iteration-log.md`, and `recommendations.md`
- 19 new test suites, three new scripts, four new standards files, and four new templates under `planifest-framework/`

## Decisions

- ADR-001: Stack unchanged, with new detail in standards files.
- ADR-002: `autonomous` becomes a third run-mode value.
- ADR-003: A declared exception list, with gross deviations classified by the reversal assessor.
- ADR-004: Gates run as loops with fresh-context checkers in `autonomous`.
- ADR-005: An approach budget of 3 per loop instance.
- ADR-006: P7 to P9 ship without asking in `autonomous`, with a draft PR while an exception waits.
- ADR-007: P0 asks only real forks and confirms in one turn.
- ADR-008: A release budget in size points.
- ADR-009: Fast Path admits changes with no `src/` target.
- ADR-010: An archive script replaces the glob delete.
- ADR-011: The P9 marker-step commit carries the build report, and leftovers are committed or listed.
- ADR-012: The docs agent revalidates after P6.
- ADR-013: A `parallel_streams` toggle and per-stream state files.
- ADR-014: The orchestrator owns joins, and a script reconciles them.
- ADR-015: The framework owns run state, and the product owns `planifest-overrides/`.

## Skipped Phases

None
