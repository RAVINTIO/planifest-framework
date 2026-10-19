# Test Report (0000033-human-on-the-loop-run-mode, 2026-10-19)

**Feature:** Human-on-the-loop run mode
**Plan date:** 2026-10-19

## 1. Tests Run This Plan (P4 Results)

Every functional requirement appears here. The P7 rerun of `planifest-framework/tests/run-tests.sh` gave the same result as P4 and post-P6 revalidation.

| Test file | Requirement ID(s) | Status |
|-----------|-------------------|--------|
| `test-0000033-req-001-autonomous-run-mode.sh` | req-001 | pass |
| `test-0000033-req-001-run-mode-script.sh` | req-001 | pass |
| `test-0000033-req-002-exception-list.sh` | req-002 | pass |
| `test-0000033-req-003-gates-as-loops.sh` | req-003 | pass |
| `test-0000033-req-004-escalation-changes-approach.sh` | req-004 | pass |
| `test-0000033-req-005-ship-without-asking-and-final-report.sh` | req-005 | pass |
| `test-0000033-req-006-on-the-loop-visibility.sh` | req-006 | pass |
| `test-0000033-req-007-choice-prompts-name-the-actor.sh` | req-007 | pass |
| `test-0000033-req-008-p0-real-forks-only.sh` | req-008 | pass |
| `test-0000033-req-009-sample-existing-records.sh` | req-009 | pass |
| `test-0000033-req-010-release-budget.sh` | req-010 | pass |
| `test-0000033-req-011-lightweight-track-for-no-src.sh` | req-011 | pass |
| `test-0000033-req-012-archive-script-without-glob-delete.sh` | req-012 | pass |
| `test-0000033-req-013-clean-close-out.sh` | req-013 | pass |
| `test-0000033-req-014-revalidate-after-p6.sh` | req-014 | pass |
| `test-0000033-req-015-parallel-streams-toggle-and-state.sh` | req-015 | pass |
| `test-0000033-req-016-always-parallel-work-units.sh` | req-016 | pass |
| `test-0000033-req-017-join-owner-and-reconciliation.sh` | req-017 | pass |
| `test-0000033-req-018-subagent-count-and-wall-clock.sh` | req-018 | pass |

**Summary:** 19 tests run: 19 passed, 0 failed, 0 skipped. The full feature run covers 78 suites, and all 78 pass.

## 2. Regression Pack State

**Total promoted tests:** 31
**Passed:** 31
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

## 3. Newly Promoted Tests (This Feature)

Promoted during Step 4 of this P7 run. The human on the loop confirmed seven of the 19 tagged candidates.

| Test file | Promoted by | Decision rationale |
|-----------|-------------|-------------------|
| `test-0000033-req-001-run-mode-script.sh` | human | Runs `run-mode.mjs` against temporary repos, including the textconv and replace-ref attacks. |
| `test-0000033-req-002-exception-list.sh` | human | Guards the exception list and the standing rules that outrank overrides. |
| `test-0000033-req-003-gates-as-loops.sh` | human | Guards the checker keys that `autonomous` can't turn off. |
| `test-0000033-req-005-ship-without-asking-and-final-report.sh` | human | Guards the branch check, the force-push ban, and the human-only merge. |
| `test-0000033-req-012-archive-script-without-glob-delete.sh` | human | Runs `archive-current.mjs`, including the symbolic-link attacks. |
| `test-0000033-req-013-clean-close-out.sh` | human | Guards the credential check on leftover commits. |
| `test-0000033-req-017-join-owner-and-reconciliation.sh` | human | Runs `stream-reconcile.mjs` and checks its read limits. |

The other 12 candidates mostly check skill wording. They stay in the feature suites.

## 4. Summary

**Overall test health:** ✅ Healthy
