# Test Report (0000032-governance-continuity-and-write-gate-scope, 2026-10-17)

**Feature:** Governance continuity and write-gate scope
**Plan date:** 2026-10-17

## 1. Tests Run This Plan (P4 Results)

Every functional requirement appears here.

| Test file | Requirement ID(s) | Status |
|-----------|-------------------|--------|
| `test-0000032-req-001-marker-clear-before-tag.sh` | req-001 | pass |
| `test-0000032-req-002-resume-from-archive-evidence.sh` | req-002 | pass |
| `test-0000032-req-003-no-run-triage-message.sh` | req-003 | pass |
| `test-0000032-req-004-handover-note-routing.sh` | req-004 | pass |
| `test-0000032-req-005-blocking-context-clear.sh` | req-005 | pass |
| `test-0000032-req-006-outside-repository-pass.sh` | req-006 | pass |
| `test-0000032-req-007-stderr-block-reasons.sh` | req-007 | pass |
| `test-0000032-req-008-shell-writer-detection.sh` | req-008 | pass |
| `test-0000032-req-009-shell-guard-path-parity.sh` | req-009 | pass |
| `test_setup.sh` (shell guard registration cases) | req-010 | pass |
| `test-0000032-req-011-rerun-setup-migration.sh` | req-011 | pass |
| `test-0000032-req-012-write-or-edit-boot-rule.sh` | req-012 | pass |

**Summary:** 12 tests run: 12 passed, 0 failed, 0 skipped.

The P4 re-run 2 ran `run-tests.sh` with 59 feature suites and 14 regression suites. All passed with `CLAUDE_PROJECT_DIR` unset and set. The P7 run on 2026-10-19 repeated the 0000032 suites with `CLAUDE_PROJECT_DIR` unset, and all passed.

## 2. Regression Pack State

**Total promoted tests:** 24
**Passed:** 24
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

## 3. Newly Promoted Tests (This Feature)

Promoted during Step 4 of this P7 run.

| Test file | Promoted by | Decision rationale |
|-----------|-------------|-------------------|
| `test-0000032-req-001-marker-clear-before-tag.sh` | human | Guards the P9 marker clear before the tag. |
| `test-0000032-req-002-resume-from-archive-evidence.sh` | human | Guards resume of an interrupted close-out. |
| `test-0000032-req-003-no-run-triage-message.sh` | human | Guards the no-run message and post-P9 triage rule. |
| `test-0000032-req-004-handover-note-routing.sh` | human | Guards track routing in handover notes. |
| `test-0000032-req-005-blocking-context-clear.sh` | human | Guards the blocking context clear after P9. |
| `test-0000032-req-006-outside-repository-pass.sh` | human | Guards the gate-write repository root. |
| `test-0000032-req-007-stderr-block-reasons.sh` | human | Guards the stderr block reason. |
| `test-0000032-req-008-shell-writer-detection.sh` | human | Guards the shell-write guard detection corpus. |
| `test-0000032-req-009-shell-guard-path-parity.sh` | human | Guards path parity between the shell guard and gate-write. |
| `test-0000032-req-012-write-or-edit-boot-rule.sh` | human | Guards the Write or Edit boot-file rule. |

The test for req-011 carries no candidate tag, so it stays out of the pack.

## 4. Summary

**Overall test health:** ✅ Healthy
