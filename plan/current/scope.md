---
title: "Scope - write gate scope and path hardening"
summary: "Defines what 0000035 delivers, what it leaves out, and that nothing is deferred."
status: "active"
version: "0.1.0"
---
# Scope - write gate scope and path hardening

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Version:** 0.33.0

> Release size follows the three-story rule, with no `release-budget.yml`. This run carries seven stories in one wave, by the choice of the human on the loop.

## In Scope

- Backlog entries 0000062, 0000081, 0000106, 0000107, 0000109, 0000114, 0000117, 0000124, 0000125, and 0000126.
- A Fast Path scope record at `plan/.fast-path-scope` (US-001):
  - It lists the target paths of one Fast Path change.
  - `gate-write` and the shell-write guard accept it in place of `plan/current/design.md` and match each write against the listed paths.
  - It never admits an enforcement path, whatever it lists.
  - It stores the branch and `HEAD` commit it was written at, and the gate ignores it once either changes.
  - `planifest-framework/workflows/fast-path.md` writes it before the change and deletes it in the Fast Path commit.
- A `product.yml` update in P7 (US-002):
  - The ship agent sets `version` and `feature` before Step 6 archives `design.md`.
  - It commits the update with the archive.
  - A close-out suite checks that both values match the tag and feature.
  - `product.yml` is set to `0.33.0` and `0000035-write-gate-scope-and-path-hardening`.
- Link resolution in `path-rules.mjs` (US-003):
  - The gates judge a write by its real target.
  - A dangling link, a `..` after a link, a link loop, and a chain past the hop limit are covered.
  - A resolution error for a path inside the repo root blocks with exit 2 and a reason on stderr.
- Root lookup when the working directory is gone (US-004):
  - `resolveRoot` checks `CLAUDE_PROJECT_DIR` first.
  - If it is unset, `resolveRoot` falls back to the nearest existing parent.
- `ratchet-check.mjs` imports the shared rules from `path-rules.mjs` (US-005) and finds the active loop from any subfolder.
- A root marker rule in `markedRoot` (US-006): the gates ignore a planted `.git` under an always-permitted name.
- Migration run state per project (US-007):
  - Migration files stay in `planifest-framework/migrations/`.
  - Each project writes one record per migration in `plan/_migrations/`.
  - A migration with no record is pending.
  - The `_done/` folder goes away and its six files return beside the others.
  - The migrator skill and orchestrator resume detection read and write the records.
- A `plan/_migrations/` record for each of the eight existing migrations in this repo, written from a scan run here in P3. The two downstream-only migrations get a `not applicable` record.
- Tests for each story under `planifest-framework/tests/`, run through `run-tests.sh`.
- Version `0.32.0` to `0.33.0` in `planifest-framework/component.yml`.
- Setup integration docs under `src/setup-hook-integration/`, only if setup behaviour changes.

## Out of Scope

- Shell-guard parser entries 0000105, 0000108, 0000115, and 0000116. They wait on 0000119.
- A hook that enforces the post-P9 refusal (0000112).
- Running the two downstream-only migrations in this repo.
- Seeding migration records from the old `_done/` folder. Each record comes from a scan.
- Changes to the gate rule for root files. `product.yml` is handled by moving the ship agent step, not by relaxing the gate.
- Any change to the always-permitted path list or to which paths count as enforcement paths.
- New run modes, release budgets, or changes to the three-story rule.

## Deferred

Nothing deferred.
