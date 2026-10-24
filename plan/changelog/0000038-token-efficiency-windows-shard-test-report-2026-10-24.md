# Test Report (0000038-token-efficiency-windows-shard, 2026-10-24)

**Feature:** Token efficiency and Windows shard fix
**Plan date:** 2026-10-24

## 1. Tests Run This Plan (P4 Results)

| Test file | Requirement ID(s) | Status |
|-----------|-------------------|--------|
| `test-0000038-req-001-stable-windows-timing.sh` | req-001 | pass |
| `test-0000038-req-002-model-values.sh` | req-002 | pass |
| `test-0000038-req-003-quiet-test-output.sh` | req-003 | pass |
| `test-0000038-req-004-phase-scoped-orchestrator.sh` | req-004 | pass |
| `test-0000038-req-004-installed-reference-links.sh` | req-004 | pass |
| `test-0000038-req-005-context-reset-at-gates.sh` | req-005 | pass |
| `test-0000038-req-006-decomposition-size-floor.sh` | req-006 | pass |
| `test-0000038-req-007-partial-reads.sh` | req-007 | pass |

**Summary:** the full suite ran 152 suites: 152 passed, 0 failed, 0 skipped. The last post-P6 revalidation recorded 117 feature suites and 35 regression suites.

## 2. Regression Pack State

**Total promoted tests:** 35
**Passed:** 35
**Failed:** 0

The pack under `planifest-framework/tests/regression/` is unchanged by this feature.

## 3. Newly Promoted Tests (This Feature)

None. No test file carried a `# REGRESSION-CANDIDATE:` tag for this feature.

## 4. Summary

**Overall test health:** Healthy. Windows shard 1, which failed on PR #64, passed on the PR #65 CI run.
