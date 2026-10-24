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

### Command position

Each rule matches only where a tool name starts a command or a string that holds one. The lint calls this the command position. The tool name must follow one of these, with optional whitespace between:

- the start of the line
- `|`, `;`, `&&`, `||`, `(`, `$(`, or a backtick
- a single or double quote, which covers test data such as `"grep -rn 'foo' src/"`

A rule also needs whitespace or an option after the tool name. So `timeout-minutes:` in a YAML assertion and `"timeout":` in a JSON fixture never match `timeout`. A word inside prose never matches, because the word does not follow one of the positions above. Lines whose first non-blank character is `#` are skipped.

### Scan scope and counts

The lint scans 132 files: 97 `test-*.sh`, 33 `regression/test-*.sh`, 1 `helpers/assert.sh`, and `run-tests.sh`. It reports the lines below today, measured on 2026-10-24 with the patterns above.

| Rule | Lines matched today | Note |
|---|---|---|
| `grep` with an `-r` or `-R` option and no `-H`, `-l`, `-L`, or `-c` option | 2 | Both are payload strings: `"grep -rn 'foo' src/"` at line 109 of `test-0000032-req-009-shell-guard-path-parity.sh` and of its `regression/` copy. The other seven `grep -r` lines use `-l` or `-H` and pass. |
| `sed -i` with no attached suffix, or `sed -i ''` | 10 | All are payload strings. Every real command uses `sed -i.bak`, which GNU and BSD both accept (15 lines). The 10 sit in `test-0000032-req-008-shell-writer-detection.sh` (lines 31, 33, 134, 181), `test-0000032-req-009-shell-guard-path-parity.sh` (line 303), and the `regression/` copies of both. |
| `shasum` in a file with no `sha256sum` command | 11 | In 2 suites: `test-0000023-req-003-copilot-setup-self-copy.sh` (2) and `test-0000030-req-004-install-clean-up-and-retired-flags.sh` (9). No file holds a `sha256sum` fallback today. |
| Assignment whose value starts `planifest-framework/` | 8 | In 1 suite: `test-0000010-framework-quality-improvements.sh` lines 14 to 20 and 98. The 40 other lines that mention `planifest-framework/` run inside a `cd`-ed temporary workspace or inside quoted prose, and the rule does not match them. |
| `timeout`, `readlink -f`, `stat -c`, `date -d`, `xargs -r`, `grep -P` | 0 | Each is GNU only. The lint keeps the rule so they stay out. `timeout-minutes:` (2 lines in `test-0000031-req-001-003-ci-jobs.sh`) is not a match. |

The lint finds 31 lines today: 2 `grep -r`, 10 `sed -i`, 11 `shasum`, and 8 path literals. P3 fixes the 19 `shasum` and path lines. P3 marks the 12 payload lines with `# portable-ok: payload string`, and the lint then reports 0. The count excludes `mktemp -d -t prefix`, which GNU and BSD both accept (55 lines).

## Functional Requirements
- FR-009.1: Each suite finds the repository root from its own location, as `run-tests.sh` does with `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"`. No suite reads a path that depends on the working directory.
- FR-009.2: P3 changes `test-0000010-framework-quality-improvements.sh` to build every path from `$SCRIPT_DIR`. It also diagnoses the intermittent `test-0000035-req-001` failure and fixes its cause. If the cause is not a working-directory dependence, P3 records the finding in a backlog entry.
- FR-009.3: A new suite, `test-0000037-req-009-portability-lint.sh`, scans `test-*.sh`, `regression/test-*.sh`, `helpers/*.sh`, and `run-tests.sh`. It skips comment lines. It applies the rules in the table above, each in command position. The scan skips any file named `test-0000037-req-009-portability-lint.sh`, so the suite and its `regression/` copy never flag their own fixture lines. The fixture lines exist only in a temporary directory that the self-test writes at run time (FR-009.7).
- FR-009.4: A flagged line carries a suppression marker, `# portable-ok: {reason}`, when the unportable form is deliberate. Payload strings that hold `sed -i` or `grep -rn` as test data always use the marker, with the reason `payload string`. P3 adds it to all 12 payload lines. The lint recognises no other exemption. The marker sits on the flagged line, or on the line directly above when shell syntax stops a trailing comment (a quoted continuation, for example).
- FR-009.4a: The lint marker and the Windows skip guard are separate mechanisms, and neither replaces the other. `# portable-ok:` silences one lint rule on one line at lint time and does not change what the suite runs. `SKIP (windows):` (req-010) skips a whole suite or check on Windows at run time and does not silence the lint. A line that needs both carries both.
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
  - Amended (P1): The 0 findings include the 12 payload lines (10 `sed -i` and 2 `grep -rn`), each carrying `# portable-ok: payload string`. The baseline table gives the count.
  - Amended (P1): The target is decidable. The lint scans 132 files, skips its own file by name, and today reports 31 findings. After P3 it reports 0 findings and the 12 marked payload lines. P4 checks both numbers.
  - Verified by: execution - P4 runs the lint over the real suites and re-adds a bare `grep -rn` line

## Split step

Split step: keep. The working-directory fix and the lint are one story and one release. The lint is the guard that keeps the fix true. Three criteria cover both. If P3 finds the intermittent failure needs its own fix, the split step applies then.

## Dependencies
- `planifest-framework/tests/run-tests.sh` is the model for `SCRIPT_DIR` resolution. It needs no change.
- `planifest-framework/tests/helpers/assert.sh` gains `sha256_of`.
- req-010 (Windows Git Bash leg, stream-04) consumes the lint and the portable suites. A suite that fails on Git Bash for a portability reason uses the `SKIP (windows):` guard, with a recorded reason, to skip on Windows. It does not use `# portable-ok:`, which only silences the lint (FR-009.4a).
- Backlog 0000089 and 0000191 bullet 3 are the source entries.

## Files P3 changes
- Changed: `planifest-framework/tests/test-0000010-framework-quality-improvements.sh` (paths and its "run from repo root" header comment)
- Changed: `planifest-framework/tests/test-0000023-req-003-copilot-setup-self-copy.sh` and `planifest-framework/tests/test-0000030-req-004-install-clean-up-and-retired-flags.sh` (use `sha256_of`)
- Changed: `planifest-framework/tests/helpers/assert.sh` (add `sha256_of`)
- Changed if the diagnosis shows a cause: `planifest-framework/tests/test-0000035-req-001-fast-path-scope-record.sh`
- New: `planifest-framework/tests/test-0000037-req-009-portability-lint.sh`
- New: a fixture for the lint self-test, inside the new suite (written to a temporary directory at run time), so no new fixture file lands in the repository
