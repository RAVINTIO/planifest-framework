---
title: "ADR 011: The portability lint matches in command position"
summary: "The portability lint is its own suite. It matches a tool name only in command position, including after a quote. It scopes the path rule to assignments and checks shasum per file for a sha256sum fallback. A portable-ok marker records each exemption. The suite skips its own file by basename, and a sha256_of helper replaces bare shasum."
status: "accepted"
version: "0.1.0"
---
# ADR-011 - The portability lint matches in command position

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Component:** planifest-framework
**Date:** 2026-10-24

## Context

GNU and BSD tools differ. A suite that passes on Linux can fail on macOS, and the reverse. Backlog 0000089 and 0000191 record failures of this kind. Nothing flags them before CI.

A plain text search for tool names gives false positives. `timeout-minutes:` in a YAML assertion is not the `timeout` command. A word in prose is not a command. Payload strings in test data hold `sed -i` and `grep -rn` on purpose, usually inside quotes.

The measured baseline on 2026-10-24 found 31 lines across 132 files. That is 2 `grep -r`, 10 `sed -i`, 11 `shasum`, and 8 path literals. The 8 path lines sit in one suite. The other 40 lines that mention `planifest-framework/` run inside a `cd`-ed temporary workspace or in quoted prose.

No file holds a `sha256sum` fallback, so suites that call `shasum` fail on minimal Linux images. The new suite and its `regression/` copy also hold fixture lines that the lint must not flag in itself.

## Decision

1. The lint is its own suite, `test-0000037-req-009-portability-lint.sh`, so `run-tests.sh` finds it with no change.
2. A rule matches only in command position. The tool name must follow the start of the line, `|`, `;`, `&&`, `||`, `(`, `$(`, a backtick, or a single or double quote. Whitespace may sit between. A rule also needs whitespace or an option after the tool name.
3. Quotes count as command position so that payload strings are visible to the lint. The marker then handles them.
4. The path rule matches only an assignment whose value starts `planifest-framework/`. It ignores lines inside a `cd`-ed workspace and quoted prose.
5. The `shasum` rule checks per file. It flags `shasum` in a file that holds no `sha256sum` command.
6. The marker `# portable-ok: {reason}` silences one rule on one line. It sits on the flagged line, or on the line directly above when shell syntax stops a trailing comment. The lint recognises no other exemption.
7. The marker does not replace the Windows `SKIP (windows):` guard from req-010. The marker acts at lint time. The guard acts at run time. A line that needs both carries both.
8. The scan skips any file named `test-0000037-req-009-portability-lint.sh`, matched by basename. This covers the suite and its `regression/` copy. The self-test writes its fixture lines to a temporary directory at run time.
9. `helpers/assert.sh` gains `sha256_of`. It tries `sha256sum` and falls back to `shasum -a 256`. The two suites that call `shasum` use it.
10. Each finding prints `{file}:{line}: {rule}: {text}`. The suite fails when any finding remains.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Match tool names anywhere on a line | Catches every use | Flags `timeout-minutes:` and prose, so people stop trusting it | The false-positive rate defeats the lint. |
| Match only at the start of a line | Few false positives | Misses `|`, `&&`, and payload strings | Most real uses sit after a pipe or an operator. |
| Run `shellcheck` | Maintained tool | It does not know GNU and BSD option differences for these tools | It checks syntax, not portability. |
| Flag every `planifest-framework/` path | Simple rule | Flags 40 legitimate lines | Assignment scope isolates the real defect. |
| Exclude payload lines by file or folder | No markers needed | Hides real uses in the same files | A line-level marker records why. |
| A global `shasum` ban | Short rule | Rejects files that already hold a fallback | The per-file check allows the helper. |
| Add the lint to an existing suite | Fewer files | `run-tests.sh` would report one failure for unrelated causes | A separate suite names the cause. |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Gains the lint suite. `helpers/assert.sh` gains `sha256_of`. P3 adds 12 `# portable-ok: payload string` markers and fixes the 19 `shasum` and path lines. |

## Consequences

**Positive:**
- A GNU or BSD difference fails locally before CI.
- Each exemption carries a recorded reason.
- The lint scans its own tree without flagging itself.
- `sha256_of` gives suites one portable hash call.

**Negative:**
- Treating a quote as command position flags payload strings, so P3 must add 12 markers.
- A rule can miss a form it does not list, such as a new GNU-only option.
- The self-exclusion by basename means a renamed lint suite would flag its own fixture lines.

**Risks:**
- The lint flags legitimate use or misses a difference (R-015). Mitigation: the fixture self-test covers each rule, the portable forms, and the marker.
- A person adds the marker to silence a real defect. Mitigation: the reason is mandatory and visible in review.

## Governs

- req-009 (FR-009.3 to FR-009.7, AC-009.2, AC-009.3)

## Related ADRs

- ADR-009 - related-to: the wired-command suite stays under this lint.
- ADR-010 - related-to: the migration diff suite stays under this lint.
- 0000031 ADR 001 - related-to: req-010 consumes the lint and the portable suites.

## Supersedes

- None.

## Superseded By

- None.
