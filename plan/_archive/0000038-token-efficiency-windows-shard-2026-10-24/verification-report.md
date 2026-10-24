# Verify-by-Execution Report
**Toggle:** on
**Software exercised:** `run-tests.sh` on fixture suites in a temp folder, the real `auto-trigger-orchestrator.mjs` hook, `setup.sh claude-code` on a temp copy of the framework, and one `haiku` subagent.

| Requirement | Criterion | Method | Outcome | Observation evidence |
|-------------|-----------|--------|---------|---------------------|
| req-001 | Each timed check makes one untimed warm-up call before one timed call, in the three suites and their regression copies | Ran all six files, read the warm-up code in each | verified | All six exit 0 with no `FAIL:`. Each holds a warm-up comment and call (req-003 and req-007 in `run_hook`, req-009 in the `spawnSync` loop at lines 313 to 314). Warm-up then timed hook call took 47, 46 and 49 ms |
| req-001 | A call of 200 ms or more fails the check and nothing retries | Ran a stub that sleeps 300 ms through the same millisecond clock and `-lt 200` test | verified | Stub took 357 ms and the test returned `no`. The req-009 best-of-three loop is gone |
| req-001 | The 200 ms limit is unchanged and the suites pass | grep for the limit in all six files, ran them | verified | The limit reads 200 in every timed assertion. No other limit found. Suites pass |
| req-002 | Claude Code column, skeleton and skill `model:` lines hold only accepted values | grep of installed `agent-dispatch-standards.md` | verified | Skeleton lines 126 and 129 read `model: "haiku"` |
| req-002 | A fixture with `claude-haiku-4-5` makes the new test fail | Not run here. Covered by the unit test, which P4 CI ran | not-verifiable | Unit criterion. Not exercised by execution in this pass |
| req-002 | One `haiku` subagent reports a Haiku model | Dispatched `Agent` with `model: "haiku"` and asked for its exact model ID | verified | The subagent answered `claude-haiku-5-5` |
| req-003 | One failing suite prints its `FAIL` line, the failed list and totals, with no `PASS` line or header | `run-tests.sh --quiet` on five fixture suites (pass, fail, exit-0-with-FAIL, SIGKILL, silent exit 7) | verified | Output was `test-b-fail.sh: FAIL: boom` plus the list and totals. No `PASS:` line or `---` header printed. Exit 1 |
| req-003 | A non-zero suite with no `FAIL` line is listed and the run exits non-zero | Same run | verified | `test-e-silent.sh: FAIL: ... exited 7 with no FAIL line`, listed, exit 1 |
| req-003 | A signalled suite, and a `FAIL`-printing exit-0 suite, count as failed | Same run, plus TERM sent to a quiet run mid-suite | verified | `test-d-signal.sh exited 137` and `test-c-exit0.sh: FAIL: hidden` are listed. After TERM the runner printed `test-f.sh: FAIL: ... was running when the runner stopped`, the failed list, and exited 143 |
| req-003 | Without `--quiet`, output is byte-identical to baseline | Ran `5966840` runner and the current runner on the same fixtures, `cmp` | verified | `cmp` reported identical output. Both exit 1 |
| req-003 | Quiet mode works with shard variables | `PLANIFEST_SHARD_INDEX=2 PLANIFEST_SHARD_COUNT=2` with `--quiet` on two fixtures | verified | `Shard 2 of 2` line printed and `Suites run: 1`, exit 0 |
| req-003 | Refactor, validate and codegen skills name quiet mode and a full rerun of only the failing suite | grep of the three `SKILL.md` files | verified | Refactor lines 19 and 45 to 48, validate line 50, codegen line 121 each hold `run-tests.sh --quiet` and the rerun instruction |
| req-004 | Moved sections sit in two reference files and the Framework Index lists both | `setup.sh claude-code` into a temp project, then listed files and links | verified | `references/phase-0-assess-and-coach.md` and `references/adoption-modes.md` exist. Index lines 247 and 248 list them. Both `./references/` links in `SKILL.md` resolve |
| req-004 | The orchestrator loads both at P0 and Resume Detection reloads them | grep of installed `SKILL.md` | verified | Line 128 (resume at P0) and lines 140 and 141 (load at P0) name both files |
| req-004 | `SKILL.md` is under 41,500 bytes | `wc -c` on the installed file | verified | 40,788 bytes |
| req-004 | Moved text matches baseline byte for byte, and none stays in `SKILL.md` | Not re-run here. Covered by the unit tests in the P4 CI run | not-verifiable | Unit criterion. Not exercised by execution in this pass |
| req-005 | Context Hygiene recommends `/compact` or a new session, names `plan/current/` and the build log, never needs `pause.md`, is advisory | Read the installed `SKILL.md` line 238 | verified | Text: "After each passed phase gate (advisory): recommend `/compact` or a new session. Name `plan/current/` and the build log as the resume state. This never needs `pause.md`. It is advisory and doesn't block a phase. In `continuous` and `autonomous` runs, carry on and don't wait for an answer." |
| req-005 | The blocking after-P9 reset is unchanged | Full local suite ran 152 of 152 at run 2 (build log) | not-verifiable | Pinned by existing tests. Not re-run in this pass |
| req-006 | `custom-002` and the dispatch template state the floor, the exempt roles and the maker-checker rule | grep of the installed `CLAUDE.md` (line 59) and installed `agent-dispatch-standards.md` (line 121) | verified | Both read "Size floor: dispatch a subagent only when the unit needs its own reads or many tool calls..." and name all nine exempt roles, and "The floor never removes a maker-checker split or a TDD step." |
| req-006 | Parallel critic and Scope Lock dispatches unchanged | Not re-run here. Pinned by existing tests | not-verifiable | Unit criterion |
| req-007 | `standard-boot.md` holds the directive, and setup writes it into the generated boot file | `setup.sh claude-code` into a temp project, grep `CLAUDE.md` | verified | Line 20: "Read large files in part: For a file over about 20 KB, search it or read the section you need with an offset and a limit." |
| req-007 | Every other line of `standard-boot.md` is unchanged and the full suite passes | Not re-run here. Build log records 152 of 152 | not-verifiable | Covered by P4 runs 1 and 2 |

## Summary

- verified: 18
- failed: 0
- not-verifiable: 5 (all unit-level criteria already covered by the suite, not re-executed here)

## Incident

The first `setup.sh claude-code` call ran with the repo's script path, so it used the repo as its project root. It rewrote the tracked file `planifest-overrides/setup-config/claude-code.md` (flags `[]`, new timestamp) and regenerated the ignored `CLAUDE.md` and `.claude/`. I restored the tracked file by hand with Edit. The ignored generated files are now built without `--strict-orchestrator`. The human on the loop may want to re-run `setup.sh claude-code --strict-orchestrator` in the repo. The verified install used a separate temp copy.
