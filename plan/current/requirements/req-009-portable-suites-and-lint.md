---
title: "Requirement: req-009 - portable-suites-and-lint"
summary: "Every suite runs from any working directory, and a lint flags unportable tool use."
status: "draft"
version: "0.1.0"
---
# Requirement: req-009 - portable-suites-and-lint

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Source:** US-009 (backlog 0000089 and 0000191 bullet 3)
**Priority:** should-have

## User Story

As a framework maintainer, I run any suite from any working directory, and a lint flags unportable tool use, so that a GNU and BSD difference fails locally before CI.

## Measured baseline (2026-10-24, macOS, BSD tools)

The measurement ran every suite on its own: 97 `test-*.sh` files plus 33 under `regression/`, 130 in all. Each ran from a given directory with its absolute path.

| Working directory | Suites that fail |
|---|---|
| Repository root | 0 of 130 |
| `planifest-framework/tests/` | 1 of 130 (`test-0000010-framework-quality-improvements.sh`) |
| `/tmp` (outside the repository) | 2 of 130 (`test-0000010-framework-quality-improvements.sh`, and `test-0000035-req-001-fast-path-scope-record.sh` once, passing on rerun) |

`test-0000010` fails because lines 14 to 20 and 98 hold paths relative to the repository root, such as `planifest-framework/templates/requirement.template.md`. The `test-0000035-req-001` failure did not repeat on rerun from `/tmp` (171 passed, 0 failed), so it counts as an intermittent failure for P3 to diagnose.

The lint rules below match these lines today in the suites, `regression/`, and `helpers/`, after dropping comments:

| Rule | Lines matched today | Note |
|---|---|---|
| `grep -r` or `-rn` without `-H`, unless `-l`, `-L`, or `-c` is present | 0 | The five `grep -r` lines use `-l`. Two other mentions are payload strings, not commands. |
| `sed -i` with no attached suffix, or `sed -i ''` | 0 in commands, 10 in payload strings | Every command uses `sed -i.bak`, which GNU and BSD both accept. The 10 payload lines sit in `test-0000032-req-008-shell-writer-detection.sh` (4), `test-0000032-req-009-shell-guard-path-parity.sh` (1), and the `regression/` copies of both (5). P3 marks each with `# portable-ok: payload string`. |
| `shasum` with no `sha256sum` fallback | 11, in 2 suites | `test-0000023-req-003-copilot-setup-self-copy.sh` (2) and `test-0000030-req-004-install-clean-up-and-retired-flags.sh` (9). |
| Path literal that starts `planifest-framework/` and is not under a `$SCRIPT_DIR`-derived variable | 8, in 1 suite | `test-0000010-framework-quality-improvements.sh` lines 14 to 20 and 98. |
| `timeout`, `readlink -f`, `stat -c`, `date -d`, `xargs -r`, `grep -P` | 0 | Each is GNU only. The lint keeps the rule so they stay out. |

So the lint finds 29 lines today: 11 `shasum`, 8 path literals, and 10 `sed -i` payload lines. P3 fixes the 19 `shasum` and path lines. P3 marks the 10 payload lines, and the lint then reports 0. The count excludes `mktemp -d -t prefix`, which GNU and BSD both accept (55 lines).

## Functional Requirements
- FR-009.1: Each suite finds the repository root from its own location, as `run-tests.sh` does with `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"`. No suite reads a path that depends on the working directory.
- FR-009.2: P3 changes `test-0000010-framework-quality-improvements.sh` to build every path from `$SCRIPT_DIR`. It also diagnoses the intermittent `test-0000035-req-001` failure and fixes its cause. If the cause is not a working-directory dependence, P3 records the finding in a backlog entry.
- FR-009.3: A new suite, `test-0000037-req-009-portability-lint.sh`, scans `test-*.sh`, `regression/test-*.sh`, `helpers/*.sh`, and `run-tests.sh`. It skips comment lines. It applies the rules in the table above.
- FR-009.4: A flagged line carries a suppression marker, `# portable-ok: {reason}`, when the unportable form is deliberate. Payload strings that hold `sed -i` as test data always use the marker, with the reason `payload string`. The lint recognises no other exemption. The marker sits on the flagged line, or on the line directly above when shell syntax stops a trailing comment (a quoted continuation, for example).
- FR-009.5: P3 adds a `sha256_of` function to `helpers/assert.sh`. It tries `sha256sum` and falls back to `shasum -a 256`. The two suites that call `shasum` use it.
- FR-009.6: Each finding prints `{file}:{line}: {rule}: {text}`. The suite fails when any finding remains.
- FR-009.7: The lint carries a fixture self-test. One fixture file holds a line for each rule. The self-test proves the lint flags each and that the marker silences it.

## Acceptance Criteria
- [ ] AC-009.1: Each suite passes when started from the repository root, from `planifest-framework/tests/`, and from a temporary directory outside the repository. The new suite proves it for `test-0000010-framework-quality-improvements.sh` by running it from a temporary directory. P4 proves it for all 130 by running each from the three directories, with 0 failures in each. (Verified by: shell suite and verify-by-execution at P4)
  - Amended (P1): P4 runs every suite from the three directories, with 0 failures in each. The count of 130 is the baseline only. This feature adds five suites (req-007 to req-011), so P4 runs 135.
  - Verified by: execution - P4 runs every suite from the three directories
- [ ] AC-009.2: Against its fixture file, the lint flags one line for each rule (`grep -r` without `-H`, `sed -i` without an attached suffix, `shasum` without a fallback, a bare `planifest-framework/` path, and the GNU-only tools). It flags none of the portable forms (`grep -rlE`, `sed -i.bak`, `grep -rnHE`), and the `portable-ok` marker silences a line. (Verified by: shell suite with fixture file)
  - Verified by: integration - shell suite with a fixture file
- [ ] AC-009.3: Against the real suites after P3, the lint reports 0 findings. Re-adding a bare `grep -rn pattern dir` line to any suite makes the lint suite fail and name the file and line. (Verified by: shell suite and verify-by-execution at P4)
  - Amended (P1): The 0 findings include the 10 `sed -i` payload lines, each carrying `# portable-ok: payload string`. The baseline table gives the count.
  - Verified by: execution - P4 runs the lint over the real suites and re-adds a bare `grep -rn` line

## Split step

Split step: keep. The working-directory fix and the lint are one story and one release. The lint is the guard that keeps the fix true. Three criteria cover both. If P3 finds the intermittent failure needs its own fix, the split step applies then.

## Dependencies
- `planifest-framework/tests/run-tests.sh` is the model for `SCRIPT_DIR` resolution. It needs no change.
- `planifest-framework/tests/helpers/assert.sh` gains `sha256_of`.
- req-010 (Windows Git Bash leg, stream-04) consumes the lint and the portable suites. A suite that fails on Git Bash for a portability reason can use the lint's marker only with a recorded reason.
- Backlog 0000089 and 0000191 bullet 3 are the source entries.

## Files P3 changes
- Changed: `planifest-framework/tests/test-0000010-framework-quality-improvements.sh` (paths and its "run from repo root" header comment)
- Changed: `planifest-framework/tests/test-0000023-req-003-copilot-setup-self-copy.sh` and `planifest-framework/tests/test-0000030-req-004-install-clean-up-and-retired-flags.sh` (use `sha256_of`)
- Changed: `planifest-framework/tests/helpers/assert.sh` (add `sha256_of`)
- Changed if the diagnosis shows a cause: `planifest-framework/tests/test-0000035-req-001-fast-path-scope-record.sh`
- New: `planifest-framework/tests/test-0000037-req-009-portability-lint.sh`
- New: a fixture for the lint self-test, inside the new suite (written to a temporary directory at run time), so no new fixture file lands in the repository
