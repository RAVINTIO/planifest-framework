---
title: "ADR 004: Quiet mode counts a suite failed on exit code or a FAIL line"
summary: "In quiet mode run-tests.sh captures each suite to a temporary file. A suite fails when it exits non-zero, ends by signal or timeout, or prints a FAIL line while exiting 0. Each FAIL line carries the suite name, which is the only suite marker, and a trap on INT and TERM prints the running suite if the runner is stopped. Default output stays byte-identical."
status: "accepted"
version: "0.1.0"
---
# ADR-004 - Quiet mode counts a suite failed on exit code or a FAIL line

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Component:** planifest-framework
**Date:** 2026-10-24

## Context

`run-tests.sh` runs each suite with `bash "$file"` and trusts its exit status. In default mode every suite streams to the terminal, so a human sees every `FAIL:` line. Quiet mode hides the stream. If quiet mode trusted only the exit status, a suite that printed `FAIL:` and exited 0 would read as green, and nobody could see why.

A suite prints `  FAIL: {message}` through `helpers/assert.sh`. Most suites end with a non-zero exit when `FAIL` is above zero, but a suite can lose that exit through `|| true`, a subshell, or a crash after the last assertion.

Constraints (req-003, NFR-003, NFR-005):
- Default output must stay byte-identical.
- Shard variables must keep working.
- Quiet output holds only `FAIL` lines, the failed-suite list, and the totals.

## Decision

1. `--quiet` is the only new flag. Any other argument still reads as today.
2. In quiet mode `run_suite` runs `bash "$file"` with stdout and stderr redirected to a `mktemp` file. It records the exit code in `rc`. It deletes the file on exit through a trap.
3. A suite counts as failed when any of these holds:
   - `rc` is non-zero. This covers a signal (128 plus the signal number) and a timeout (124 from an outside `timeout` wrapper).
   - The captured output has a line that matches `^[[:space:]]*FAIL:` and `rc` is 0.
   - The runner could not create or read the capture file. The runner treats this as failed and prints the reason. It never reads an unreadable capture as a pass.
4. For a failed suite the runner prints each captured `FAIL:` line, prefixed with the suite name. If `rc` is non-zero and there is no `FAIL:` line, it prints one synthetic line, `FAIL: {suite} exited {rc} with no FAIL line`. A signal or timeout appears in that line as the exit code.
5. The runner prints no `PASS` line and no suite header. It prints the failed-suite list and the totals block, with the same wording as default mode.
6. The runner adds no timeout of its own. A timeout counts as failed only when something outside the runner ends the suite, and the runner then sees a non-zero code.
6a. Quiet mode sets a `trap` on `INT` and `TERM`. If something ends the runner itself, a hung suite stays visible. On either signal the trap:
   - prints the running suite's name and its captured `FAIL:` lines, in the format of rule 4
   - prints the failed-suite list, with the running suite added
   - removes the capture file
   - exits non-zero
   The trap adds no timeout and runs only in quiet mode.
6b. The suite-name prefix on each `FAIL:` line is the only suite marker in quiet mode. The trap output uses the same format.
7. The default branch keeps the current code path untouched, so default output is byte-identical. An integration test compares default output before and after on a fixture suite directory.
8. The refactor, validate, and codegen skills run the full suite with `--quiet`. On a failure they rerun only the failing suite in full, with `bash {suite}`.

Decision (P2): in quiet mode a suite fails on a non-zero exit, a signal or timeout, or a `^[[:space:]]*FAIL:` line with exit 0 / reason: it makes hiding the stream unable to hide a failure.

Decision (P2): the runner adds no timeout of its own / reason: a runner timeout is a new gate behaviour and the requirement asks only that an external timeout counts as failed.

Decision (P2): a capture error counts as a failed suite / reason: unknown never reads as a pass.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Trust the exit code only | Simple | Hides FAIL with exit 0 | A hidden failure is the main risk |
| Pipe through `grep -v PASS` | No capture file | Cannot see the exit code through the pipe without `PIPESTATUS`, and mixes streams | Loses the exit code on some shells |
| Filter in each skill | No runner change | Every caller repeats the logic | Wrong place |
| Add a runner timeout | Catches hangs | New behaviour with a limit to tune | Out of scope |
| Print the whole capture on failure | Full detail | Large output, which defeats the saving | The skills rerun the one suite instead |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `run-tests.sh`, a new integration test, and three skill edits |

## Consequences

**Positive:**
- Each full run adds a few lines to context instead of thousands.
- A FAIL with exit 0 now fails the run in quiet mode.

**Negative:**
- Quiet mode and default mode can disagree for a suite that prints `FAIL:` and exits 0. Quiet mode is stricter.
- Output shows only after a suite ends, so a long suite looks silent.

**Risks:**
- A suite that prints `FAIL:` as test data (for example when it tests a fixture runner) reads as failed in quiet mode. A P3 scan of the existing suites checks for this. For any suite found, the change may alter only the printed text. It never alters an assertion or an exit path.
- Capture files on Windows Git Bash use `/tmp` paths. The `mktemp` call matches the other suites.

## Related ADRs

- ADR-001 - depends-on (Bash only)
- The Git Bash cap that feature 0000037 set - related-to (the shard and CI legs call the runner without the flag)

## Supersedes

- None.

## Superseded By

- None.
