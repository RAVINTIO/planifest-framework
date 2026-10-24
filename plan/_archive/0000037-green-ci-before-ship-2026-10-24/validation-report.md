# Validation report: 0000037-green-ci-before-ship

## Semantic correctness (P4 step 1)

Three criteria have no covering test. Semantic validation fails until each one has a test or an amended criterion. The other 27 criteria are covered and pass, and three are deferred to verify-by-execution.

Criteria without an ID are numbered in order. For example, AC 001.1 is the first criterion of `req-001`.

## Coverage table

| REQ-ID | AC | Type | Covered by test | Pass/Fail |
|--------|----|------|-----------------|-----------|
| REQ-001 | 001.1 PR line, wait window, check mapping | integration | `test-0000037-req-001-p9-ci-check.sh` | Pass |
| REQ-001 | 001.2 red retry, exception line, P9 blocked | integration | `test-0000037-req-001-p9-ci-check.sh` | Pass |
| REQ-001 | 001.3 resumed P9 rereads checks, no second PR | integration | `test-0000037-req-001-p9-ci-check.sh` | Pass |
| REQ-002 | 002.1 last merged PR checks reported | integration | `test-0000037-req-002-gutd-ci-check.sh` | Pass |
| REQ-002 | 002.2 no `main` run, no-merged-PR wording | integration | `test-0000037-req-002-gutd-ci-check.sh` | Pass |
| REQ-002 | 002.3 unreadable status, unknown never passes | integration | `test-0000037-req-002-gutd-ci-check.sh` | Pass |
| REQ-003 | 003.1 scanner behaviour and exit codes | integration | `test-0000037-req-003-credential-scan.sh` | Pass |
| REQ-003 | 003.2 autonomous commit held on match | integration | `test-0000037-req-003-credential-scan.sh` | Pass |
| REQ-003 | 003.3 held-back file stays staged, shows in clean-tree check | integration | None (partial, see below) | Fail (uncovered) |
| REQ-004 | 004.1 title and body scanned before `gh pr create` | integration | `test-0000037-req-004-pr-body-scan.sh` | Pass |
| REQ-004 | 004.2 one regeneration, hold, exception line | integration | `test-0000037-req-004-pr-body-scan.sh` | Pass |
| REQ-004 | 004.3 PR text cites paths and results only | integration | `test-0000037-req-004-pr-body-scan.sh` | Pass |
| REQ-005 | 005.1 revalidation runs after P6 commit | integration | `test-0000037-req-005-post-p6-revalidation.sh` | Pass |
| REQ-005 | 005.2 revalidation cap and exception line | unit | `test-0000037-req-005-post-p6-revalidation.sh` | Pass |
| REQ-005 | 005.3 orchestrator and standard name revalidation | unit | `test-0000037-req-005-post-p6-revalidation.sh` | Pass |
| REQ-006 | 006.1 template and spec agent fill `Verified by:` | unit | `test-0000037-req-006-verified-by-and-p3-scan.sh` | Pass |
| REQ-006 | 006.2 codegen scans for unmapped IDs before P3 closes | integration | `test-0000037-req-006-verified-by-and-p3-scan.sh` | Pass |
| REQ-006 | 006.3 missing `Verified by` passes as `unspecified` | integration | `test-0000037-req-006-verified-by-and-p3-scan.sh` | Pass |
| REQ-007 | AC-007.1 `gate-write` command wiring | integration | `test-0000037-req-007-wired-command.sh` | Pass |
| REQ-007 | AC-007.2 `shell-write-guard` command wiring | integration | `test-0000037-req-007-wired-command.sh` | Pass |
| REQ-007 | AC-007.3 `auto-trigger-orchestrator` stdout and negative fixture | integration | `test-0000037-req-007-wired-command.sh` | Pass |
| REQ-008 | AC-008.1 migration list matches branch diff | integration | `test-0000037-req-008-migration-branch-diff.sh` | Pass |
| REQ-008 | AC-008.2 SKIP cases | integration | `test-0000037-req-008-migration-branch-diff.sh` | Pass |
| REQ-008 | AC-008.3 check against this repository | execution | Deferred | Deferred to verify by execution |
| REQ-009 | AC-009.1 suites run from three directories | execution | Deferred | Deferred to verify by execution |
| REQ-009 | AC-009.2 portability lint rules and marker | integration | `test-0000037-req-009-portability-lint.sh` | Pass |
| REQ-009 | AC-009.3 real suites report 0 findings | execution | Deferred | Deferred to verify by execution |
| REQ-010 | 010.1 Git Bash leg matrix and workflow settings | integration | `test-0000037-req-010-windows-git-bash-leg.sh` | Pass |
| REQ-010 | 010.2 `Test suite (windows-latest)` check passes on PR | e2e | None | Fail (uncovered) |
| REQ-010 | 010.3 skip guards match skip table rows | integration | `test-0000037-req-010-windows-git-bash-leg.sh` | Pass |
| REQ-011 | 011.1 `setup-powershell-51` job settings | integration | `test-0000037-req-011-windows-powershell-coverage.sh` | Pass |
| REQ-011 | 011.2 `test_setup.ps1` assertions | e2e | `test-0000037-req-011-windows-powershell-coverage.sh` (text part) | Pass |
| REQ-011 | 011.3 architecture overview names 5.1 and the new job | integration | None | Fail (uncovered) |

## Summary

| Result | Count |
|--------|-------|
| Covered | 27 |
| Deferred to verify by execution | 3 |
| Uncovered | 3 |
| Total | 33 |

## Uncovered criteria

- **REQ-003, AC 003.3.** The criterion says a held-back file "shows in the clean-tree check". The suite asserts the guard wording (`by path only`, `stays uncommitted`) and the resume wording. No assertion checks the clean-tree listing. The ship skill describes the listing at line 198, so the text exists, but no test checks it.
- **REQ-010, AC 010.2.** The governing type is `e2e`, so it is not deferred. The evidence is a CI check read through `gh pr checks`, and no suite reads CI results. The criterion also names the check `Test suite (windows-latest)`. Commit `5d43543` split that job into seven shard checks named `Test suite (windows-latest, shard N of 7)`. The current PR shows all seven passing, but the name in the criterion no longer matches. The criterion needs its check names amended, or the CI result needs recording at the gate.
- **REQ-011, AC 011.3.** No suite reads `docs/architecture-overview.md` for this feature, so the criterion has no test. The doc text also fails the criterion. Line 156 still reads "Windows PowerShell 5.1 has no CI coverage (0000031-ADR-001)" and does not list the new job. The doc needs an edit, and a suite needs to check it.

## Deferred to verify by execution

- **REQ-008, AC-008.3.** Governing type `execution`. The post-P6 revalidation runs the check against this repository.
- **REQ-009, AC-009.1.** Governing type `execution`. P4 runs every suite from three directories.
- **REQ-009, AC-009.3.** Governing type `execution`. P4 runs the lint over the real suites and re-adds a bare `grep -rn` line.

## Suite results

Each mapped suite ran once from `planifest-framework/tests/`. No suite failed.

| Suite | Exit code | Result |
|-------|-----------|--------|
| `test-0000037-req-001-p9-ci-check.sh` | 0 | 56 passed, 0 failed |
| `test-0000037-req-002-gutd-ci-check.sh` | 0 | 33 passed, 0 failed |
| `test-0000037-req-003-credential-scan.sh` | 0 | 37 passed, 0 failed |
| `test-0000037-req-004-pr-body-scan.sh` | 0 | 32 passed, 0 failed |
| `test-0000037-req-005-post-p6-revalidation.sh` | 0 | 16 passed, 0 failed |
| `test-0000037-req-006-verified-by-and-p3-scan.sh` | 0 | 22 passed, 0 failed |
| `test-0000037-req-007-wired-command.sh` | 0 | 22 passed, 0 failed |
| `test-0000037-req-008-migration-branch-diff.sh` | 0 | 20 passed, 0 failed |
| `test-0000037-req-009-portability-lint.sh` | 0 | 30 passed, 0 failed |
| `test-0000037-req-010-windows-git-bash-leg.sh` | 0 | 34 passed, 0 failed |
| `test-0000037-req-011-windows-powershell-coverage.sh` | 0 | 37 passed, 0 failed |

## Weak coverage (counted as covered)

These criteria have a test, but the test checks text or fixture presence rather than behaviour.

- **REQ-005, AC 005.1 and REQ-006, AC 006.2.** The fixture checks confirm files exist. The docs agent and codegen agent behaviour is checked as skill text only.
- **REQ-010, AC 010.1.** The "no diff" clause of the consumer workflow is checked by absence of text, not by a diff.
- **REQ-011, AC 011.1 and 011.2.** The static workflow and text checks pass. The live CI results (the 5.1 job passing and the PowerShell 7 job passing `test_setup.ps1`) are not asserted by any suite. CI shows both checks passing on the current PR.

## Self-correct cycle 1 (P4, orchestrator, 2026-10-24T02:42:20Z)

The three uncovered criteria above are now covered.

| REQ-ID | AC | Fix | Result |
|--------|----|-----|--------|
| REQ-003 | AC 003.3 | `test-0000037-req-003-credential-scan.sh` stages a credential file in a temporary repository and runs the scan (exit 1). It checks that the clean-tree command lists the file as staged (`A `) and that no matched value prints. | 41 passed, 0 failed |
| REQ-010 | AC 010.2 | An `Amended (P4)` line names the seven shard checks. The CI run on PR #64 at `5d43543` passes all seven, and `verification-report.md` records it. | covered by CI (e2e) |
| REQ-011 | AC 011.3 | `docs/architecture-overview.md` lists `setup-powershell-51` and names Windows PowerShell 5.1 as supported. The req-011 suite asserts both, and that the old no-coverage line is gone. | 40 passed, 0 failed |

After cycle 1: 30 covered, 3 deferred to verify by execution, 0 uncovered.
