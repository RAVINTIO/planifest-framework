# Test Report (0000037-green-ci-before-ship, 2026-10-24)

**Feature:** Green CI before ship
**Plan date:** 2026-10-24

## 1. Tests Run This Plan (P4 Results)

Every functional requirement appears here. P4 and the post-P6 revalidation ran the full suite. The last run, at P6, passed 142 of 142 suites. CI on PR #64 at head `e850a71` passed all 13 checks, including seven Windows Git Bash shards and Windows PowerShell 5.1.

| Test file | Requirement ID(s) | Status |
|-----------|-------------------|--------|
| `test-0000037-req-001-p9-ci-check.sh` | req-001 | pass |
| `test-0000037-req-002-gutd-ci-check.sh` | req-002 | pass |
| `test-0000037-req-003-credential-scan.sh` | req-003 | pass |
| `test-0000037-req-003-archive-held-back.sh` | req-003 | pass |
| `test-0000037-req-004-pr-body-scan.sh` | req-004 | pass |
| `test-0000037-req-005-post-p6-revalidation.sh` | req-005 | pass |
| `test-0000037-req-006-verified-by-and-p3-scan.sh` | req-006 | pass |
| `test-0000037-req-007-wired-command.sh` | req-007 | pass |
| `test-0000037-req-008-migration-branch-diff.sh` | req-008 | pass (the real comparison ran against `v0.34.0..HEAD`) |
| `test-0000037-req-009-portability-lint.sh` | req-009 | pass (0 findings) |
| `test-0000037-req-010-windows-git-bash-leg.sh` | req-010 | pass |
| `test-0000037-req-011-windows-powershell-coverage.sh` | req-011 | pass |

**Summary:** 142 suites ran in the final local run: 142 passed, 0 failed, 0 skipped. Some suites skip single checks on Windows with a recorded reason, listed in `planifest-framework/tests/README.md`. Verify by execution: 24 rows passed, 0 failed, and 9 not verifiable locally (`plan/_archive/0000037-green-ci-before-ship-2026-10-24/verification-report.md`).

## 2. Regression Pack State

**Total promoted tests:** 35
**Passed:** 35
**Failed:** 0

The 33 suites promoted before this feature passed in the P6 revalidation run. The two promoted at this P7 passed on their own (165 and 143 assertions). The source, promoter, and date of every entry sit in `planifest-framework/tests/regression/regression-manifest.json`.

| Test file | Source feature | Promoted by | Promotion date | Status |
|-----------|---------------|-------------|----------------|--------|
| `test-0000037-req-003-credential-scan.sh` | 0000037-green-ci-before-ship | agent | 2026-10-24 | pass |
| `test-0000037-req-003-archive-held-back.sh` | 0000037-green-ci-before-ship | agent | 2026-10-24 | pass |
| 33 earlier entries | 0000003 to 0000035 | agent or human | see the manifest | pass |

## 3. Newly Promoted Tests (This Feature)

| Test file | Promoted by | Decision rationale |
|-----------|-------------|-------------------|
| `test-0000037-req-003-credential-scan.sh` | agent | It runs the scan script and checks its contract, which stays stable when skill wording changes. |
| `test-0000037-req-003-archive-held-back.sh` | agent | It runs the real archive script and scan-then-commit on fixtures, and proves no key reaches a commit. |

Not promoted: the req-001, req-002, and req-004 suites, which assert skill text and would break on a rewording.

## 4. Summary

**Overall test health:** ✅ Healthy. Every suite passes locally and in CI on all platforms.
