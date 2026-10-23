# Test Report (0000036-pipeline-friction-and-gate-fixes, 2026-10-23)

**Feature:** Pipeline friction and gate fixes
**Plan date:** 2026-10-23

## 1. Tests Run This Plan (P4 Results)

Every functional requirement appears here. The counts come from the P7 run of each suite, after the P5 and P6 fixes.

| Test file | Requirement ID(s) | Status |
|-----------|-------------------|--------|
| `test-0000036-req-001-rerun-setup-migration.sh` | req-001 | pass (75 assertions) |
| `test-0000036-req-002-skill-drift-check.sh` | req-002 | pass (88 assertions) |
| `test-0000036-req-003-ship-commit-subjects.sh` | req-003 | pass (21 assertions) |
| `test-0000033-req-001-run-mode-script.sh` | req-004 | pass (101 assertions) |
| `test-0000036-req-005-hard-limits-cited-by-name.sh` | req-005 | pass (12 assertions) |
| `test-0000033-req-003-gates-as-loops.sh` | req-006 | pass (98 assertions) |
| `test-0000036-req-007-story-split-step.sh` | req-007 | pass (19 assertions) |
| `test-0000036-req-008-non-regular-design-md.sh` | req-008 | pass (66 assertions) |
| `test-0000036-req-009-permitted-names-in-enforcement-paths.sh` | req-009 | pass (39 assertions) |
| `test-0000036-req-010-run-tests-clears-project-dir.sh` | req-010 | pass (37 assertions) |
| `test-0000036-req-011-escaped-hook-output.sh` | req-011 | pass (43 assertions) |

**Summary:** 11 suites run: 11 passed, 0 failed, 0 skipped. The full `run-tests.sh` run passes 97 feature suites and 33 regression suites.

req-004 and req-006 extend existing 0000033 suites rather than adding new ones. These existing suites also changed in this run and pass: `test-0000023-req-002-marker-commit-lifecycle.sh`, `test-0000032-req-001-marker-clear-before-tag.sh`, `test-0000033-req-005-ship-without-asking-and-final-report.sh`, `test-0000035-req-007-migration-run-state.sh`, `test-0000035-req-010-migration-records-for-this-repo.sh`, and the seven suites req-010 lists, each with its regression copy where one exists.

## 2. Regression Pack State

**Total promoted tests:** 33
**Passed:** 33
**Failed:** 0

| Test file | Source feature | Promoted by | Promotion date | Status |
|-----------|---------------|-------------|----------------|--------|
| `test-0000016-pipeline-governance.sh` | 0000016-pipeline-governance-and-loop-engineering | agent | 2026-07-26 | pass |
| `test-0000005-framework-governance.sh` | 0000005-framework-governance | agent | 2026-08-01 | pass |
| `test-0000006-build-assessment.sh` | 0000006-build-assessment-phase | agent | 2026-08-01 | pass |
| `test-0000009-rail-tightening.sh` | 0000009-framework-rail-tightening | agent | 2026-08-01 | pass |
| `test-0000017-req-001-regression-promotion.sh` | 0000017-ratchet-forgery-detection-and-telemetry-schema-spec | agent | 2026-08-01 | pass |
| `test-0000017-req-002-ratchet-approve.sh` | 0000017-ratchet-forgery-detection-and-telemetry-schema-spec | agent | 2026-08-01 | pass |
| `test-0000017-req-005-scope-lock-suggested-answers.sh` | 0000017-ratchet-forgery-detection-and-telemetry-schema-spec | agent | 2026-08-01 | pass |
| `test-0000017-req-006-structured-discovery-pass.sh` | 0000017-ratchet-forgery-detection-and-telemetry-schema-spec | agent | 2026-08-01 | pass |
| `test-0000017-req-007-change-agent-archive.sh` | 0000017-ratchet-forgery-detection-and-telemetry-schema-spec | agent | 2026-08-01 | pass |
| `test-0000018-req-007-discovery-md-hard-limit.sh` | 0000018-telemetry-emission-consistency | agent | 2026-08-01 | pass |
| `test-0000019-req-002-component-yml-matcher.sh` | 0000019-self-description-and-session-hygiene-fixes | agent | 2026-08-01 | pass |
| `test-commit-msg-hook.sh` | 0000005-framework-governance | agent | 2026-08-01 | pass |
| `test-gate-write-windows.sh` | 0000003-hook-based-enforcement | agent | 2026-08-01 | pass |
| `test-regression-pack.sh` | 0000017-ratchet-forgery-detection-and-telemetry-schema-spec | agent | 2026-08-01 | pass |
| `test-0000032-req-001-marker-clear-before-tag.sh` | 0000032-governance-continuity-and-write-gate-scope | human | 2026-10-19 | pass |
| `test-0000032-req-002-resume-from-archive-evidence.sh` | 0000032-governance-continuity-and-write-gate-scope | human | 2026-10-19 | pass |
| `test-0000032-req-003-no-run-triage-message.sh` | 0000032-governance-continuity-and-write-gate-scope | human | 2026-10-19 | pass |
| `test-0000032-req-004-handover-note-routing.sh` | 0000032-governance-continuity-and-write-gate-scope | human | 2026-10-19 | pass |
| `test-0000032-req-005-blocking-context-clear.sh` | 0000032-governance-continuity-and-write-gate-scope | human | 2026-10-19 | pass |
| `test-0000032-req-006-outside-repository-pass.sh` | 0000032-governance-continuity-and-write-gate-scope | human | 2026-10-19 | pass |
| `test-0000032-req-007-stderr-block-reasons.sh` | 0000032-governance-continuity-and-write-gate-scope | human | 2026-10-19 | pass |
| `test-0000032-req-008-shell-writer-detection.sh` | 0000032-governance-continuity-and-write-gate-scope | human | 2026-10-19 | pass |
| `test-0000032-req-009-shell-guard-path-parity.sh` | 0000032-governance-continuity-and-write-gate-scope | human | 2026-10-19 | pass |
| `test-0000032-req-012-write-or-edit-boot-rule.sh` | 0000032-governance-continuity-and-write-gate-scope | human | 2026-10-19 | pass |
| `test-0000033-req-001-run-mode-script.sh` | 0000033-human-on-the-loop-run-mode | human | 2026-10-19 | pass |
| `test-0000033-req-002-exception-list.sh` | 0000033-human-on-the-loop-run-mode | human | 2026-10-19 | pass |
| `test-0000033-req-003-gates-as-loops.sh` | 0000033-human-on-the-loop-run-mode | human | 2026-10-19 | pass |
| `test-0000033-req-005-ship-without-asking-and-final-report.sh` | 0000033-human-on-the-loop-run-mode | human | 2026-10-19 | pass |
| `test-0000033-req-012-archive-script-without-glob-delete.sh` | 0000033-human-on-the-loop-run-mode | human | 2026-10-19 | pass |
| `test-0000033-req-013-clean-close-out.sh` | 0000033-human-on-the-loop-run-mode | human | 2026-10-19 | pass |
| `test-0000033-req-017-join-owner-and-reconciliation.sh` | 0000033-human-on-the-loop-run-mode | human | 2026-10-19 | pass |
| `test-0000035-req-002-product-yml-in-p7.sh` | 0000035-write-gate-scope-and-path-hardening | agent | 2026-10-22 | pass |
| `test-0000035-req-008-sanctioned-scripts.sh` | 0000035-write-gate-scope-and-path-hardening | agent | 2026-10-22 | pass |

## 3. Newly Promoted Tests (This Feature)

None. No 0000036 suite carries a `# REGRESSION-CANDIDATE:` tag. The three tagged 0000033 suites are already in the pack.

## 4. Summary

**Overall test health:** ✅ Healthy
