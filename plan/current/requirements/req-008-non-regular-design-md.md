---
title: "Requirement: req-008 - non-regular-design-md"
summary: "The write gate checks the file type of plan/current/design.md before it opens it, and treats a folder, FIFO, link, or other non-regular file as no design."
status: "draft"
version: "0.1.0"
---
# Requirement: req-008 - non-regular-design-md

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Source:** US-008 (backlog 0000143)
**Priority:** should-have

## User Story

As the human on the loop, I rely on the write gate to treat a folder or FIFO at `design.md` as no design, so that neither one admits a `src/` write.

## Functional Requirements

### Current behaviour (verified at `f834ab2`)

- `evaluateWrite` in `planifest-framework/hooks/enforcement/path-rules.mjs:774-782` calls `existsSync(designPath)` and then `readFileSync` inside a `try`.
- A folder at `plan/current/design.md` passes `existsSync`. The read then throws `EISDIR`, and the `catch` at `path-rules.mjs:780-781` allows the write.
- A FIFO at the same path passes `existsSync`. The read waits for a writer, so the hook stops only when the tool's hook timeout ends it.
- `gate-write.mjs:40` and `shell-write-guard.mjs:700` both reach this code through `evaluateWrite`, so both hooks share the defect.

### File-type check

- `evaluateWrite` calls `lstatSync` on `plan/current/design.md` before any open or read of that path. The existing `node:fs` import at `path-rules.mjs:50` already holds `lstatSync`. Any further names come from `node:fs` too.
- The outcome of that call decides the route:

| `lstatSync` outcome | Route |
|---------------------|-------|
| Throws `ENOENT` or `ENOTDIR` | No design, as today. `scopeVerdict` judges the write. |
| Returns a regular file | Read the design and run the component-path check, as today. |
| Returns any other type | No design. `scopeVerdict` judges the write. |
| Throws any other error, such as `EACCES` | No design. `scopeVerdict` judges the write. Today `existsSync` returns false on any error, so this keeps today's block. |

- "Any other type" covers a folder, FIFO, socket, block or character device, and a symbolic link. A link counts as non-regular even when it points at a regular file. A link can point at a FIFO or a device, and `lstatSync` doesn't follow it.
- A non-regular `design.md` takes the same `scopeVerdict` route as a missing one. A current Fast Path scope record therefore still admits its listed paths, and the enforcement list still runs first (0000035 ADR 004).
- With a current Fast Path scope record, a non-regular `design.md` follows `scopeVerdict` in full (`path-rules.mjs:702-742`). The checks run in this order:
  1. An enforcement path blocks, whatever the record lists.
  2. A record the gate ignores (stale or invalid) blocks with `NO_DESIGN_REASON` plus the line naming why.
  3. A non-ASCII target blocks.
  4. A target the record lists is admitted, with the Fast Path notice. A listed non-enforcement path such as `src/a.js` therefore passes.
  5. Any other target blocks as not listed in the record.
- With no record, `scopeVerdict` returns `NO_DESIGN_REASON` alone, and the route below adds the "not a regular file" line.
- When the non-regular route blocks, the reason is `NO_DESIGN_REASON` with one line added. The added line reads `[Planifest] plan/current/design.md is not a regular file, so the gate treats it as no design.` and ends with a newline.
- The read of a regular `design.md` opens the file once, with `O_NONBLOCK` and `O_NOFOLLOW` where `fs.constants` defines them. It calls `fstatSync` on that descriptor before it reads. If the descriptor isn't a regular file, the route is "any other type". This closes the gap between the `lstatSync` call and the open.
- A regular `design.md` whose open, `fstatSync`, or read throws still fails open, as `path-rules.mjs:780-781` does today.
- The change touches only the `design.md` step of `evaluateWrite`. The sentinel check, the always-permitted step, and the component-path check keep their order and text.

### Decision record

- An ADR in this feature's P2 set narrows 0000003 ADR 005 for this case only. It states that a non-regular file or a failed `lstatSync` reads as no design. A failure after `lstatSync` shows a regular file still fails open.
- The ADR also records that a symbolic link at `design.md` now reads as no design.

### Out of scope

- `check-design.mjs:58-62` and `ratchet-check.mjs` read files the same way. Backlog 0000161 tracks them.

### Tests

- A new suite, `planifest-framework/tests/test-0000036-req-008-non-regular-design-md.sh`, builds a fixture under `mktemp -d` with `plan/.orchestrator-active` and no Fast Path scope record. It clears `CLAUDE_PROJECT_DIR` (req-010).
- The suite places each of these at `plan/current/design.md` and runs `gate-write.mjs` and `shell-write-guard.mjs` on a `src/` target:
  - a folder
  - a FIFO made with `mkfifo`
  - a symbolic link to a regular design that lists the target
- For the FIFO case, the suite runs each hook under a 5-second limit and fails if the limit ends the hook.
- A scope-record case places a folder at `plan/current/design.md` with a current Fast Path scope record that lists `src/a.js`. A **Write** to `src/a.js` exits 0 with the Fast Path notice. A **Write** to an unlisted `src/b.js` exits 2 with the not-listed reason.
- A control case with a regular, readable design that lists the target exits 0.
- A timed case runs `gate-write.mjs` with a regular `design.md` and asserts it finishes under 500 ms (NFR-001).
- A regular `design.md` with mode `000` exits 0, when the suite runs as a non-root account. The suite skips this case under root.
- A source check asserts that `path-rules.mjs` still imports no `node:child_process` (0000035 ADR 001).

### Non-functional

- Each hook call stays under 500 ms in every case above.
- The change uses Node built-in modules only and spawns no process.

## Acceptance Criteria

- [ ] With a folder, a FIFO, or a symbolic link at `plan/current/design.md` and no scope record, a **Write** to `src/a.js` exits 2. Stderr holds the no-design reason and the "not a regular file" line, from both `gate-write.mjs` and `shell-write-guard.mjs`.
- [ ] With a FIFO at `plan/current/design.md`, each hook exits on its own inside the suite's 5-second limit, so the FIFO never holds it.
- [ ] A regular `design.md` that can't be read still exits 0, and the P2 ADR records the narrowed fail-open rule.

## Dependencies

- `planifest-framework/hooks/enforcement/path-rules.mjs`, `evaluateWrite` (`:759-797`). Req-009 and req-011 also change this file, so stream 01 builds req-008, req-009, and req-011 in sequence with one agent.
- `scopeVerdict` (`path-rules.mjs:702`) and `NO_DESIGN_REASON` (`path-rules.mjs:72-74`), unchanged.
- 0000003 ADR 005 (fail open), narrowed by this feature's P2 ADR.
- 0000035 ADR 001 (Node built-ins, no process spawn) and ADR 004 (the enforcement list runs before the record).
- Req-010, whose suite check requires this requirement's suite to clear `CLAUDE_PROJECT_DIR`.
