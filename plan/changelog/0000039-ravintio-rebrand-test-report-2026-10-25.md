# Test Report (0000039-ravintio-rebrand, 2026-10-25)

**Feature:** RAVINTIO rebrand
**Plan date:** 2026-10-25

## 1. Tests Run This Plan (P4 Results)

| Test file | Requirement ID(s) | Status |
|-----------|-------------------|--------|
| `test-0000039-req-001-pack-paths-and-identifiers.sh` | req-001 | pass |
| `test-0000039-req-002-runtime-names.sh` | req-002 | pass |
| `test-0000039-req-003-environment-variables.sh` | req-003 | pass |
| `test-0000039-req-004-brand-prose.sh` | req-004 | pass |
| `test-0000039-req-005-history-and-split-name-protection.sh` | req-005 | pass |
| `test-0000039-req-006-consumer-migration.sh` | req-006 | pass |
| `test-0000039-req-007-brand-guard.sh` | req-007 | pass |
| `test-0000039-req-008-emitted-names.sh` | req-008 | pass |
| `test-0000039-req-009-migration-ordering-and-old-paths.sh` | req-009 | pass |
| `test-0000039-req-010-version-bump.sh` | req-010 | pass |

**Summary:** the post-P6 revalidation ran 162 suites: 162 passed, 0 failed, 0 skipped. CI run 40195111057 at a19f3b1d passed every job, including the Windows PowerShell 5.1 run of the `.ps1` helper cases.

At P7, after the promotion below, the full suite ran 163 suites. 162 passed. The req-005 suite failed one assertion, because the changelog edit was not yet committed and the suite rejects any uncommitted change under `plan/changelog/`. The P7 commit clears it, and the P7 build-log block records the rerun.

## 2. Regression Pack State

**Total promoted tests:** 36
**Passed:** 36
**Failed:** 0

The pack under `ravintio-framework/tests/regression/` gains one suite from this feature. Every other entry is unchanged.

## 3. Newly Promoted Tests (This Feature)

| Test file | Promoted by | Decision rationale |
|-----------|-------------|-------------------|
| `test-0000039-req-007-brand-guard.sh` | agent | It guards a standing rule: the retired brand word stays out of live paths and lines. Its allowlist already covers the regression copy, and the copy passes 6 of 6. |

Not promoted:

- `test-0000039-req-005-history-and-split-name-protection.sh`: it checks one rename pass against the pre-pass commit.
- `test-0000039-req-006-consumer-migration.sh`: the helpers ship only through 0.x, and the Windows PowerShell 5.1 CI job names its feature path.

## 4. Summary

**Overall test health:** ✅ Healthy
