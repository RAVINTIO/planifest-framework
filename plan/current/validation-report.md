# Validation report: 0000036-pipeline-friction-and-gate-fixes

Phase: P4. Run mode: autonomous. Build target: local.

## Result

All checks pass after one self-correct cycle. Every acceptance criterion has a covering test.

## Checks run

| Step | Check | Result |
|------|-------|--------|
| 0 | Library audit | Not applicable. There is no dependency manifest. |
| 1 | Semantic correctness | Pass after cycle 1 (one uncovered criterion found and closed). |
| 2 | Lint | Pass. `node --check` on 6 changed `.mjs` files and `bash -n` on 29 changed `.sh` files. No `.ps1` file changed, and `pwsh` is not installed, so nothing was parse-checked. |
| 3 | Type-check | Not applicable. The code is plain JavaScript. |
| 4 | Test | Pass. `env -u CLAUDE_PROJECT_DIR bash planifest-framework/tests/run-tests.sh` |
| 5 | Build | Not applicable. There is no build step. |

Test summary:

- Feature suites: 97 passed, 0 failed.
- Regression suite: 33 passed, 0 failed.
- Failing suites: none.

## Coverage table

Suites live in `planifest-framework/tests/`. "0033-003" means `test-0000033-req-003-gates-as-loops.sh` and its regression copy. "0033-001" means `test-0000033-req-001-run-mode-script.sh`.

| REQ-ID | AC | Covered by test | Pass/Fail |
|--------|----|-----------------|-----------|
| req-001 | AC-001.1 migration file, header, files named, applied record | `test-0000036-req-001-rerun-setup-migration.sh` (header, Background, record checks) | Pass |
| req-001 | AC-001.2 policy defines setup-delivered files | `test-0000036-req-001-rerun-setup-migration.sh` (FR-001.6 policy section) | Pass |
| req-001 | AC-001.3 suite passes, nine migrations in 0000035 suites | `test-0000036-req-001-rerun-setup-migration.sh`, `test-0000035-req-007-migration-run-state.sh` (nine files), `test-0000035-req-010-migration-records-for-this-repo.sh` (nine records) | Pass |
| req-002 | AC-002.1 compare, exit 0, 1, 2, ignore added folders | `test-0000036-req-002-skill-drift-check.sh` (match, stale, missing, nothing installed, unknown tool, exit 2) | Pass |
| req-002 | AC-002.2 Resume Detection runs script, recommends refresh | `test-0000036-req-002-skill-drift-check.sh` ("orchestrator Resume Detection runs the check") and the script-never-writes section | Pass |
| req-002 | AC-002.3 suite covers six cases | `test-0000036-req-002-skill-drift-check.sh` | Pass |
| req-003 | No placeholder in any commit subject, feature ID in body | `test-0000036-req-003-ship-commit-subjects.sh` (placeholder scan, body `-m` checks) | Pass |
| req-003 | Suite fails on placeholder or over 72 characters, subjects pass `commit-msg` | `test-0000036-req-003-ship-commit-subjects.sh` (fixture scan, `commit-msg` exit 0 per subject) | Pass |
| req-004 | Bare or one list-item anchor prints `autonomous`, other rules unchanged | 0033-001 ("0000036 req-004" section) | Pass |
| req-004 | Orchestrator and build-log template show bare anchor in fenced block | 0033-001 (`TPL_BLOCK`, `ORCH_BLOCK`) | Pass |
| req-004 | Indented, other prefix, later-commit list item print `interactive` | 0033-001 (prefix loop, R15 to R19) | Pass |
| req-005 | Every citation names rule and source, no renumbering | `test-0000036-req-005-hard-limits-cited-by-name.sh` (repo scan of `planifest-framework/` and `docs/`) | Pass |
| req-005 | Dispatch standards state Write-or-Edit in both prompts and the self-contained rule | `test-0000036-req-005-hard-limits-cited-by-name.sh` | Pass |
| req-005 | Suite fails on a bare citation and names file and line | `test-0000036-req-005-hard-limits-cited-by-name.sh` (fixture scan) | Pass |
| req-006 | Absent key or file reads `report-only` outside autonomous, other keys unchanged | 0033-003 (Toggle Protocol assertions) | Pass |
| req-006 | Five locations state the default (Toggle Protocol, template, orchestrator, standards, architecture overview) | 0033-003. The architecture overview assertion was missing and was added in cycle 1. | Pass |
| req-006 | 0033-003 and its regression copy assert the new default | `test-0000033-req-003-gates-as-loops.sh` and `regression/` copy, 98 passed each | Pass |
| req-007 | Three skills carry the split step | `test-0000036-req-007-story-split-step.sh` (spec agent, critic, loop runner, ratchet fixture) | Pass |
| req-007 | Suite fails without `Split step:`, fourth-criterion trigger, or two-concerns question | `test-0000036-req-007-story-split-step.sh` (`check_common` per skill) | Pass |
| req-008 | Folder, FIFO, symlink at `design.md` block with no-design reason and not-a-regular-file line, both hooks | `test-0000036-req-008-non-regular-design-md.sh` | Pass |
| req-008 | FIFO exits inside the 5-second limit | `test-0000036-req-008-non-regular-design-md.sh` (`TIMED_OUT` = no) | Pass |
| req-008 | Unreadable regular `design.md` still exits 0, ADR records the rule | `test-0000036-req-008-non-regular-design-md.sh` (scope-record route and fail-open cases). ADR text is outside test scope. | Pass |
| req-009 | Enforcement-folder `CLAUDE.md` exits 2 in no-design, record, and uncovered-design states, both hooks | `test-0000036-req-009-permitted-names-in-enforcement-paths.sh` | Pass |
| req-009 | `src/a/CLAUDE.md` exits 0 in all states | `test-0000036-req-009-permitted-names-in-enforcement-paths.sh` (`OUTSIDE_TARGET`) | Pass |
| req-009 | Suite covers both targets with and without `design.md`, and the covering design admits the file | `test-0000036-req-009-permitted-names-in-enforcement-paths.sh` | Pass |
| req-010 | Suite sees `CLAUDE_PROJECT_DIR` unset under `run-tests.sh` | `test-0000036-req-010-run-tests-clears-project-dir.sh` (probe suite) | Pass |
| req-010 | Every suite naming a hook clears the variable before first `node` | `test-0000036-req-010-run-tests-clears-project-dir.sh` (loop over `tests/` and `tests/regression/`) | Pass |
| req-010 | Suite checks both and names the failing file | `test-0000036-req-010-run-tests-clears-project-dir.sh` (assertion label holds the path) | Pass |
| req-011 | Removed criterion and em dash target show `\n`, `\x1b`, `\u{202E}` in stdout and stderr, no raw character | `test-0000036-req-011-escaped-hook-output.sh` (ratchet-check and em-dash-guard sections) | Pass |
| req-011 | `shown()` at cap is a prefix of the escaped text and never ends inside an escape or pair | `test-0000036-req-011-escaped-hook-output.sh` (`shown()` cuts and cap sweep) | Pass |
| req-011 | Cases cover control character, U+202E, and over-200-character value per hook output | `test-0000036-req-011-escaped-hook-output.sh` | Pass |

No requirement file lacks an `## Acceptance Criteria` section.

## Self-correct cycles

```
Cycle 1:
  Check: semantic correctness (test coverage)
  Error: AC "Toggle Protocol, template, orchestrator, standards, and docs/architecture-overview.md each state the new default" had no assertion for docs/architecture-overview.md.
  Root cause: test gap. The doc text was correct (line 122 of docs/architecture-overview.md) but no test checked it.
  Fix: added one assert_contains to planifest-framework/tests/test-0000033-req-003-gates-as-loops.sh and the same assertion to planifest-framework/tests/regression/test-0000033-req-003-gates-as-loops.sh.
  Result: pass (both suites 98 passed, 0 failed. Full run 97 and 33 passed, 0 failed.)
```

Files changed in P4:

- `planifest-framework/tests/test-0000033-req-003-gates-as-loops.sh`
- `planifest-framework/tests/regression/test-0000033-req-003-gates-as-loops.sh`
- `plan/current/validation-report.md`

## Notes

- Verify by execution (step 6) was not part of this task brief and is not run here.
- Backlog entries filed: none.
