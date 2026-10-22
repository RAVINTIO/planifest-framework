# Test Report (0000035-write-gate-scope-and-path-hardening, 2026-10-22)

**Feature:** Write gate scope and path hardening
**Plan date:** 2026-10-22

## 1. Tests Run This Plan (P4 Results)

Every functional requirement appears here. The counts come from the P7 run of each suite, after the P5 and P6 fixes.

| Test file | Requirement ID(s) | Status |
|-----------|-------------------|--------|
| `test-0000035-req-001-fast-path-scope-record.sh` | req-001 | pass (171 assertions) |
| `test-0000035-req-002-product-yml-in-p7.sh` | req-002 | pass (74 assertions) |
| `test-0000035-req-003-links-judged-by-real-target.sh` | req-003 | pass (55 assertions) |
| `test-0000035-req-004-root-when-cwd-deleted.sh` | req-004 | pass (34 assertions) |
| `test-0000035-req-005-ratchet-check-shared-root.sh` | req-005 | pass (31 assertions) |
| `test-0000035-req-006-no-planted-root-marker.sh` | req-006 | pass (23 assertions) |
| `test-0000035-req-007-migration-run-state.sh` | req-007 | pass (113 assertions) |
| `test-0000035-req-008-sanctioned-scripts.sh` | req-008 | pass (293 assertions) |
| `test-0000035-req-009-fast-path-enforcement-paths.sh` | req-009 | pass (127 assertions) |
| `test-0000035-req-010-migration-records-for-this-repo.sh` | req-010 | pass (48 assertions) |

**Summary:** 10 suites run: 10 passed, 0 failed, 0 skipped. The full `run-tests.sh` run passes 88 feature suites with 8,244 passing assertions.

Two criteria stay open by design. req-002 AC-3 (`product.yml` reads `0.33.0` at P9) closes at P7 Step 5b. req-010 AC-010.1 waits for the human on the loop to answer three migration scans. The suites pass, because each checks the open case as the requirement defines it.

These existing suites changed in this run and pass: `test-0000005-framework-governance.sh`, `test-0000016-pipeline-governance.sh`, `test-0000017-req-002-ratchet-approve.sh`, `test-0000032-req-006-outside-repository-pass.sh`, `test-0000032-req-011-rerun-setup-migration.sh`, and `test-regression-pack.sh`, each with its regression copy where one exists.

## 2. Regression Pack State

**Total promoted tests:** 35 in `regression-manifest.json`
**Passed:** 33 suites in the `run-tests.sh` regression run, plus the separate `test-gate-write-windows.sh` checks
**Failed:** 0

| Test file | Source feature | Promoted by | Promotion date | Status |
|-----------|---------------|-------------|----------------|--------|
| `test-0000016-pipeline-governance.sh` | 0000016 | agent | 2026-07-26 | pass |
| `test-0000005-framework-governance.sh` | 0000005 | agent | 2026-08-01 | pass |
| `test-0000006-build-assessment.sh` | 0000006 | agent | 2026-08-01 | pass |
| `test-0000009-rail-tightening.sh` | 0000009 | agent | 2026-08-01 | pass |
| `test-0000017-req-001-regression-promotion.sh` | 0000017 | agent | 2026-08-01 | pass |
| `test-0000017-req-002-ratchet-approve.sh` | 0000017 | agent | 2026-08-01 | pass |
| `test-0000017-req-005-scope-lock-suggested-answers.sh` | 0000017 | agent | 2026-08-01 | pass |
| `test-0000017-req-006-structured-discovery-pass.sh` | 0000017 | agent | 2026-08-01 | pass |
| `test-0000017-req-007-change-agent-archive.sh` | 0000017 | agent | 2026-08-01 | pass |
| `test-0000018-req-007-discovery-md-hard-limit.sh` | 0000018 | agent | 2026-08-01 | pass |
| `test-0000019-req-002-component-yml-matcher.sh` | 0000019 | agent | 2026-08-01 | pass |
| `test-commit-msg-hook.sh` | 0000005 | agent | 2026-08-01 | pass |
| `test-gate-write-windows.sh` | 0000003 | agent | 2026-08-01 | pass |
| `test-regression-pack.sh` | 0000017 | agent | 2026-08-01 | pass |
| `test-0000032-req-001` to `req-009` and `req-012` (10 suites) | 0000032 | human | 2026-10-19 | pass |
| `test-0000033-req-001`, `002`, `003`, `005`, `012`, `013`, and `017` (7 suites) | 0000033 | human | 2026-10-19 | pass |
| `test-0000035-req-002-product-yml-in-p7.sh` | 0000035 | agent | 2026-10-22 | pass |
| `test-0000035-req-008-sanctioned-scripts.sh` | 0000035 | agent | 2026-10-22 | pass |

## 3. Newly Promoted Tests (This Feature)

Promoted during Step 4 of this P7 run, in `autonomous` mode.

| Test file | Promoted by | Decision rationale |
|-----------|-------------|-------------------|
| `test-0000035-req-002-product-yml-in-p7.sh` | agent | It builds its own fixture repos and asserts no state of this repo, so it stays valid after later releases. It guards the P7 `product.yml` step. |
| `test-0000035-req-008-sanctioned-scripts.sh` | agent | It guards the sanctioned-script list and the input rules of `set-product-release.mjs` and `promote-to-regression.sh`, which later features must not weaken. |

## 4. Summary

**Overall test health:** ✅ Healthy. Every suite passes. `test_setup.ps1` runs on CI only, because PowerShell isn't installed locally. No change in this run touched a PowerShell file.
