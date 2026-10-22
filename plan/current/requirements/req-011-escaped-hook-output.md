---
title: "Requirement: req-011 - escaped-hook-output"
summary: "ratchet-check and em-dash-guard print quoted text through shown(), and shown() cuts only between whole escapes and characters at its length cap."
status: "draft"
version: "0.1.0"
---
# Requirement: req-011 - escaped-hook-output

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Source:** US-011 (backlog 0000149)
**Priority:** should-have

## User Story

As the human on the loop, I see every hook message escape the text it quotes, so that a crafted criterion or path can't forge or hide hook output.

## Functional Requirements

### Current behaviour (verified at `f834ab2`)

- `ratchet-check.mjs:267` prints each removed criterion raw, as `  removed: "${l}"`. A criterion that holds U+202E or an ESC sequence prints those characters as they are. Its path lines already go through `shown()` (`ratchet-check.mjs:255`).
- `em-dash-guard.mjs:120` prints the target raw, as `'${relTarget}'`. A target that holds a newline starts a new stderr line. `em-dash-guard.mjs` imports nothing from `path-rules.mjs` today (`:41-43`).
- `shown()` (`path-rules.mjs:120-130`) escapes first and then calls `escaped.slice(0, max)` at `:129`. The cut can fall inside an escape, leaving for example a bare `\u{20`. It can also fall between the two halves of a surrogate pair, leaving a lone surrogate.

### `shown()` cut

- `shown(p, max)` builds its output from whole units. A unit is one escape sequence, such as `\n`, `\x1b`, or `\u{202E}`, or one unescaped code point.
- It appends units in order while the output stays within `max` UTF-16 code units, and stops before the first unit that would pass `max`.
- The output is always a prefix of the full escaped text, at most `max` code units long. It never ends inside an escape or a surrogate pair.
- Escape forms, the `CONTROL_RE` class (`path-rules.mjs:118`), and the default `max` of 80 stay as they are. Output under the cap is unchanged.
- `shown()` adds no ellipsis or other marker at the cut. Callers that add their own marker, such as the `...` in the "too long to judge" warning (`path-rules.mjs:100`), keep it.

### Hook output

- `ratchet-check.mjs` prints each removed criterion as `  removed: "${shown(l, 200)}"`.
- `em-dash-guard.mjs` imports `shown` from `./path-rules.mjs` and prints the target as `'${shown(relTarget, 200)}'`.
- Both caps match the 200-character cap of the Fast Path notice (0000035 req-001).
- The line-number list in the em dash reason holds only numbers the hook makes, so it stays as it is.
- `setup.sh` (`:344-349`) and `setup.ps1` (`:461`) copy every `.mjs` file in `hooks/enforcement/`. The installed `em-dash-guard.mjs` therefore finds `path-rules.mjs` beside it.
- Existing suites that match exact block text, such as `test-0000032-req-007-stderr-block-reasons.sh` and its regression copy, keep passing. Text under the caps doesn't change. If a suite asserts a cut value, P3 updates that suite with the change.

### Tests

- A new suite, `planifest-framework/tests/test-0000036-req-011-escaped-hook-output.sh`, clears `CLAUDE_PROJECT_DIR` (req-010).
- For `shown()`, the suite imports `path-rules.mjs` with `node --input-type=module` and checks these cases:
  - a cap that falls inside `\u{202E}`, which returns the text before the escape
  - a cap that falls inside `\x1b`, which returns the text before the escape
  - a cap that falls between the halves of U+1F600, which returns the text before the character
  - an input under the cap, which returns the full escaped text
- For `ratchet-check.mjs`, the suite builds an active-loop fixture as the 0000017 req-002 suite does. It removes a criterion that holds the cases listed under Input Validation, then asserts the block output.
- For `em-dash-guard.mjs`, the suite writes em dash content to a scoped target whose name holds the same cases, then asserts the block output.
- Each assertion checks both stdout and stderr. Neither holds a raw control character, U+202E, or a second line that starts with `[Planifest]`.

### Non-functional

- NFR-001 sets the 500 ms target. The timed case in the req-008 suite measures it for this change. This requirement adds no timing test of its own.
- `em-dash-guard.mjs` gains only the `./path-rules.mjs` import, which uses Node built-ins only and spawns no process (0000035 ADR 001).

## Acceptance Criteria

- [ ] A removed criterion and an em dash target that hold `\n`, ESC, or U+202E appear in both hooks' stdout and stderr as `\n`, `\x1b`, and `\u{202E}`, with no raw character.
- [ ] `shown()` output at its cap is a prefix of the full escaped text and never ends inside an escape or a surrogate pair.
- [ ] Suite cases cover each hook output with a control character, U+202E, and a value over its 200-character cap.

## Dependencies

- `planifest-framework/hooks/enforcement/path-rules.mjs`, `shown()`. Req-008 and req-009 also change this file, so one stream 01 agent builds them in sequence.
- `planifest-framework/hooks/enforcement/ratchet-check.mjs` and `em-dash-guard.mjs` (edited here).
- Every caller of `shown()` in `gate-write`, `shell-write-guard`, `ratchet-check`, and `path-rules.mjs` gets the new cut with no change of its own.
- 0000035 req-001, which defined `shown()` and its escape forms (findings G-S11 and G-N3).
- Backlog 0000148 (ratchet misses criteria with line separators), which stays out of scope.

## Input Validation

- [ ] Input source: a removed criterion line from a `plan/current/` artifact, read by `ratchet-check.mjs`.
- [ ] Input source: the hook stdin field `tool_input.file_path` or `tool_input.path`, read by `em-dash-guard.mjs`.
- [ ] Allowed character pattern: any character outside `[\p{Cc}\p{Cf}\p{Zl}\p{Zp}]` prints as it is. Each character in that class prints as its escape. Nothing is stripped.
- [ ] maximum length: 200 UTF-16 code units of escaped text per value, cut between whole units.
- [ ] Failure behaviour: an unexpected error still exits 0 (0000003 ADR 005). A block keeps exit 2.
- [ ] Logging policy: sanitised value only in output. Neither hook prints the raw value.
