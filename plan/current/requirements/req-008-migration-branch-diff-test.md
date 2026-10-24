---
title: "Requirement: req-008 - migration-branch-diff-test"
summary: "A test compares an unreleased re-run-setup migration's file list with the release diff."
status: "draft"
version: "0.1.0"
---
# Requirement: req-008 - migration-branch-diff-test

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Source:** US-008 (backlog 0000186)
**Priority:** should-have

## User Story

As a framework maintainer, I run a test that compares a re-run-setup migration's file list with the release diff, so that a wrong list fails the suite.

## Functional Requirements
- FR-008.1: Target selection. The test targets the re-run-setup migration with the highest version in `planifest-framework/migrations/`, matched by `migrate-{version}-rerun-setup*.md`. Today that is `migrate-0.34.0-rerun-setup.md`. This feature ships `migrate-0.35.0-rerun-setup.md`, so the test targets that file once it exists.
- FR-008.2: Unreleased only. The test compares only when the target's version is higher than every `v*` tag. A migration whose release tag exists is frozen, because it can cover several releases (the 0.34.0 migration covers 0.33.0 and 0.34.0) and a single tag range does not describe it. The test prints a skip line that names the reason.
- FR-008.3: Range. The base is the highest `v*` tag below the target's version. For the 0.35.0 migration the base is `v0.34.0`. The head is `HEAD`. The test runs `git diff --name-only {base}..HEAD` from the repository root.
- FR-008.4: Filter. The test keeps only setup-delivered files, as `planifest-framework/standards/framework-update-policy.md` defines them. It never filters by `bundle_templates` or `bundle_standards`. The kept paths are:
  - `skills/*/` files that setup copies (`SKILL.md`, `scripts/`, `assets/`, `references/`)
  - `templates/` and `schemas/` files
  - top-level `standards/` files, and sub-path files that a `bundle_standards` entry names
  - `hooks/enforcement/`, `hooks/adapters/`, and `workflows/` files
  - The test drops `standards/reference/` and the git hooks in `hooks/`.
- FR-008.5a: No tags. If no `v*` tag exists at all, as in a CI clone, the test prints `SKIP: no v* tags fetched` and exits 0. A fixture repository with no tags covers this case.
- FR-008.5: Skip. If the base tag is absent (`git rev-parse -q --verify refs/tags/{base}` fails), the test prints `SKIP` with the tag name and exits 0. A shallow clone passes this way. The skip is never a failure and never silent.
- FR-008.6: List parsing. The test reads the migration's Background section and takes each backticked path that starts with a setup-delivered folder name. It resolves the path against `planifest-framework/`.
- FR-008.7: Failure output names each path in the diff but missing from the list, and each path in the list but missing from the diff.
- FR-008.8: Before the real migration exists, P3 proves the comparison with a fixture check. The fixture is a temporary git repository with a tagged base and a migration one version above it. Its passing and failing cases match AC-008.1.
- FR-008.9: The positive path against this repository first runs in the post-P6 revalidation, locally, with the `v*` tags present. CI skips the check until backlog 0000199 lands.

## Acceptance Criteria
- [ ] AC-008.1: Against a fixture git repository with tags `v0.1.0` and a migration versioned `0.2.0`, the check passes when the migration lists exactly the setup-delivered files that changed. It fails and names the path when the list omits a changed skill. It fails and names the path when the list names an unchanged file. (Verified by: shell suite with fixture repository)
  - Verified by: integration - shell suite with a fixture repository
- [ ] AC-008.2: Against a fixture where the base tag is absent, the check prints `SKIP` and the suite exits 0. Against a fixture whose target migration already has its release tag, the check also skips with a stated reason. (Verified by: shell suite with fixture repository)
  - Verified by: integration - shell suite with a fixture repository
- [ ] AC-008.3: Against this repository, the check targets the highest-version migration. After P6 writes `migrate-0.35.0-rerun-setup.md`, the check compares it with `git diff --name-only v0.34.0..HEAD` and passes. It skips if `v0.34.0` is absent. (Verified by: shell suite and verify-by-execution at P4)
  - Amended (P1): The positive path against this repository verifies in the post-P6 revalidation, as a local run with the `v*` tags present. The P6 file does not exist at P4 or P5, and the revalidation excludes the verify-by-execution step. Before the file exists, the P3 fixture check (FR-008.8) proves the comparison. CI skips the check until backlog 0000199 lands.
  - Verified by: execution - post-P6 revalidation, local run with tags present, plus the P3 fixture check

## Split step

Split step: keep. Selection, range, filter, and skip all serve one outcome, a wrong list fails the suite. A reader could not ship the filter without the comparison.

## Dependencies
- `planifest-framework/standards/framework-update-policy.md` defines setup-delivered files.
- `planifest-framework/migrations/migrate-0.35.0-rerun-setup.md` does not exist yet. The orchestrator writes it at the end of P6. The post-P6 revalidation exercises AC-008.3 as a local run with tags present. Until the file exists, the check targets the frozen 0.34.0 migration and skips, and the P3 fixture check proves the comparison.
- `planifest-framework/tests/test-0000036-req-001-rerun-setup-migration.sh` stays as it is. The new suite adds the diff check beside it.
- Backlog 0000199 records that CI fetches no tags, so the check skips in CI until that entry lands.

## Files P3 changes
- New: `planifest-framework/tests/test-0000037-req-008-migration-branch-diff.sh`
- New (by the orchestrator at P6, listed for the P3 test's data): `planifest-framework/migrations/migrate-0.35.0-rerun-setup.md`
