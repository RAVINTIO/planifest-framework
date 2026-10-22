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
- `gate-write.mjs:39` calls `judgeWrite`, which calls `evaluateWrite` at `path-rules.mjs:820`. `shell-write-guard.mjs:700` reaches the same code through `evaluateWrite`, so both hooks share the defect.

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
- A non-regular `design.md` follows `scopeVerdict` in full (`path-rules.mjs:702-742`). `scopeVerdict` returns these outcomes in order. Each names the state of the scope record:
  1. No record: the write blocks with `NO_DESIGN_REASON` alone.
  2. Any record state, and the target is an enforcement path: the write blocks with the enforcement-path reason, whatever the record lists. This check runs before the record is read.
  3. A stale or invalid record, which the gate ignores: the write blocks with `NO_DESIGN_REASON` plus the line naming why.
  4. A current record, and the target is non-ASCII: the write blocks with the non-ASCII reason.
  5. A current record that lists the target: the write is admitted with the Fast Path notice. A listed non-enforcement path such as `src/a.js` therefore passes.
  6. A current record that doesn't list the target: the write blocks as not listed in the record.
- Every block on the non-regular route carries the "not a regular file" line. That covers outcomes 1, 2, 3, 4, and 6. `evaluateWrite` appends the line after the route's own reason, so the human on the loop always sees why `design.md` didn't count. Outcome 5 is an admit, so it carries no such line.
- A throwing `lstatSync`, such as `EACCES`, follows `scopeVerdict` as a missing design does. It carries no "not a regular file" line, because the gate never learned the file type. Its reasons match today's missing-design reasons.
- The added line reads `[Planifest] plan/current/design.md is not a regular file, so the gate treats it as no design.` and ends with a newline. The line is appended to the reason that `scopeVerdict` returns, so `scopeVerdict` itself stays unchanged.
- The read of a regular `design.md` opens the file once, with `O_NONBLOCK` and `O_NOFOLLOW` where `fs.constants` defines them. It calls `fstatSync` on that descriptor before it reads. If the descriptor isn't a regular file, the route is "any other type". This closes the gap between the `lstatSync` call and the open.
- After `lstatSync` shows a regular file, the open and `fstatSync` outcomes decide the route:

| Open or `fstatSync` outcome | Route |
|-----------------------------|-------|
| The open throws `ELOOP`, `EMLINK`, `ENOENT`, or `ENOTDIR` | No design. The file was swapped or removed after `lstatSync`. `scopeVerdict` judges the write, and each block gains the "not a regular file" line. |
| The open throws any other error, such as `EACCES` | Fail open, as `path-rules.mjs:780-781` does today. |
| `fstatSync` shows a non-regular file | No design, as "any other type". |
| `fstatSync` shows a regular file over 1 MiB (1048576 bytes) | No design. `scopeVerdict` judges the write, and each block gains the size-cap line. |
| `fstatSync` shows a regular file at or under 1 MiB | Read at most that many bytes, then run the component-path check. |

- `ELOOP` is the `O_NOFOLLOW` error on Linux and macOS. `EMLINK` is the FreeBSD one.
- The size check runs before the read. The read never takes more than the cap, even when the file grows after `fstatSync`.
- The size-cap line reads `[Planifest] plan/current/design.md is over the 1 MiB size cap, so the gate treats it as no design.` and ends with a newline. Like the "not a regular file" line, it goes after the reason `scopeVerdict` returns, and an admit carries no such line.
- A regular `design.md` whose `fstatSync` or read throws still fails open, as `path-rules.mjs:780-781` does today.
- The change touches only the `design.md` step of `evaluateWrite`. The sentinel check, the always-permitted step, and the component-path check keep their order and text.

### Decision record

- An ADR in this feature's P2 set narrows 0000003 ADR 005 for this case only. It states that a non-regular file or a failed `lstatSync` reads as no design. A swap before the open and a file over the size cap read as no design too. Any other failure after `lstatSync` shows a regular file still fails open.
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
- A scope-record case places a folder at `plan/current/design.md` with a current Fast Path scope record that lists `src/a.js`. A **Write** to `src/a.js` exits 0 with the Fast Path notice. A **Write** to an unlisted `src/b.js` exits 2 with the not-listed reason followed by the "not a regular file" line. A third case targets an enforcement path under the same record and asserts the enforcement-path reason followed by the same line.
- A stale-record case places a folder at `plan/current/design.md` with a scope record whose branch or `HEAD` no longer matches. A **Write** to `src/a.js` exits 2 with `NO_DESIGN_REASON`, the line naming why the record was ignored, and the "not a regular file" line.
- A search-permission case removes search permission from `plan/current` (mode `600`), so `lstatSync` throws `EACCES`. A **Write** to `src/a.js` exits 2 with `NO_DESIGN_REASON` and no "not a regular file" line. The suite skips this case under root.
- A control case with a regular, readable design that lists the target exits 0.
- A timed case runs `gate-write.mjs` with a regular `design.md` and asserts it finishes under 500 ms (NFR-001).
- A regular `design.md` with mode `000` exits 0, when the suite runs as a non-root account. The suite skips this case under root.
- A swap harness imports `path-rules.mjs` with a wrapped `fs.lstatSync`, published through `syncBuiltinESMExports`. Right after `lstatSync` returns for a regular `design.md`, it changes the file once. It then calls `evaluateWrite` on `src/a.js`. It runs three modes:
  - `link` swaps in a link to a design that lists `src/`, so the open throws `ELOOP`
  - `rm` removes the file, so the open throws `ENOENT`
  - `notdir` replaces `plan/current` with a file, so the open throws `ENOTDIR`
- Each swap mode blocks (exit 2) with `NO_DESIGN_REASON` followed by the "not a regular file" line.
- An oversize case extends a design that lists `src/` to 2 MiB with `truncate -s 2M`. A **Write** to `src/a.js` exits 2 from both hooks, with `NO_DESIGN_REASON` followed by the size-cap line and no "not a regular file" line.
- Two boundary cases check the cap. A `design.md` of exactly 1048576 bytes exits 0, and one of 1048577 bytes exits 2.
- A source check asserts that `path-rules.mjs` still imports no `node:child_process` (0000035 ADR 001).
- The same source check covers NFR-003 over five files: `path-rules.mjs`, `gate-write.mjs`, `shell-write-guard.mjs`, `em-dash-guard.mjs`, and `ratchet-check.mjs`. Each imports only `node:` modules, `./path-rules.mjs`, and `./read-stdin.mjs`. The one `git` spawn in `ratchet-check.mjs` passes by name (backlog 0000128), and any other `node:child_process` use fails.

### Non-functional

- NFR-001 (execution plan) sets the 500 ms target. The timed case above, `gate-write.mjs` with a regular `design.md` under 500 ms, is the one measurement for every hook change in this feature. The other cases assert no timing.
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
