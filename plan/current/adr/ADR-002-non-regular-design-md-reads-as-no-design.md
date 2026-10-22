---
title: "ADR 002: A non-regular design.md reads as no design"
summary: "The write gate calls lstatSync on plan/current/design.md before any read. A folder, FIFO, symbolic link, other non-regular file, or a throwing lstatSync reads as no design. A failed open or read of a regular file still fails open. This narrows 0000003 ADR 005."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - A non-regular design.md reads as no design

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

`evaluateWrite` in `path-rules.mjs` calls `existsSync` on `plan/current/design.md` and then `readFileSync` inside a `try`. The `catch` allows the write, under 0000003 ADR 005 (hooks fail open on unexpected errors). Backlog 0000143 found two gaps:

- A folder at `design.md` passes `existsSync`. The read throws `EISDIR`, and the `catch` admits any `src/` write.
- A FIFO at `design.md` passes `existsSync`. The read waits for a writer, so the hook stalls until the tool's hook timeout ends it (risk R-006).

Both `gate-write.mjs` and `shell-write-guard.mjs` reach this code. A planted folder or FIFO therefore turns the write gate off for any agent that can create one under `plan/current/`, which is an always-permitted path.

`existsSync` returns false on any error today, including `EACCES`. A failed check therefore already blocks as no design. The P1 correction in the design keeps that block: making a throwing `lstatSync` fail open would turn today's block into a pass.

req-008 serves US-008. It requires this ADR to narrow 0000003 ADR 005 and to record the new reading of a symbolic link.

## Decision

- **Check first:** `evaluateWrite` calls `lstatSync` on `plan/current/design.md` before any open or read of that path.
- **Routes:**

| `lstatSync` outcome | Route |
|---------------------|-------|
| Throws `ENOENT` or `ENOTDIR` | No design, as today. `scopeVerdict` judges the write. |
| Returns a regular file | Open, check, and read, then run the component-path check, as today. |
| Returns any other type | No design. `scopeVerdict` judges the write, and each block gains the "not a regular file" line. |
| Throws any other error, such as `EACCES` | No design. `scopeVerdict` judges the write, with no extra line, because the gate never learned the type. |

- **Symbolic links:** A link at `design.md` reads as no design, even when it points at a regular file. `lstatSync` doesn't follow it, and its target could be a FIFO or a device. This is a change: today a link to a valid design admits writes the design covers.
- **Open guard:** The gate opens a regular `design.md` once, with `O_RDONLY | O_NONBLOCK | O_NOFOLLOW`, using each flag only where `fs.constants` defines it. It calls `fstatSync` on the descriptor before it reads. If the descriptor isn't a regular file, the route is "any other type". This closes the window between `lstatSync` and the open, where another process could swap the file for a FIFO or a link. `O_NONBLOCK` stops the open waiting on a FIFO. `O_NOFOLLOW` makes the open fail on a swapped-in link.
- **Fail-open line:** If the open, `fstatSync`, or read of a file that `lstatSync` showed as regular throws, the write passes, as 0000003 ADR 005 requires. An `ELOOP` from `O_NOFOLLOW` falls on this side, so a swap after `lstatSync` passes. That mirrors today's behaviour for any read error.
- **Narrowing:** This ADR narrows 0000003 ADR 005 for the `design.md` step of `evaluateWrite` only. Every other unexpected error in the hooks still exits 0. `check-design.mjs` and `ratchet-check.mjs` keep their reads, and backlog 0000161 tracks them.
- **Reason text:** The added line reads `[Planifest] plan/current/design.md is not a regular file, so the gate treats it as no design.` and goes after the reason `scopeVerdict` returns. `scopeVerdict` stays unchanged, so the enforcement list still runs before the record (0000035 ADR 004).

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep `existsSync`, and treat `EISDIR` in the `catch` as no design | Smallest change | A FIFO still stalls the hook, because the read never throws. A device can hang the same way. | Leaves R-006 open |
| Use `statSync`, which follows links, so a link to a regular design still counts | Keeps working for a project that links `design.md` from elsewhere | A link to a FIFO stalls the open. The target can change between the check and the read. | The design names a link as non-regular, and no project in scope links `design.md` |
| Fail open when `lstatSync` throws a non-`ENOENT` error | Matches 0000003 ADR 005 as written | Turns today's `EACCES` block into a pass, so an unreadable `plan/current` would admit any write | Corrected at P1. It weakens the gate. |
| Block every write when `design.md` isn't a regular file, with no `scopeVerdict` route | One plain rule | A current Fast Path scope record could no longer admit its listed paths while a stray folder sits at `design.md` | Treating it as missing gives the same verdicts a human on the loop already knows |
| Read with a timeout in a worker thread | Bounds any slow read, including network volumes | Adds a thread per hook call and more latency. The FIFO still blocks the worker. | Too heavy for one file, and the open guard already stops the wait |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | The `design.md` step of `evaluateWrite` gains `lstatSync`, the guarded open, and `fstatSync`. `gate-write.mjs` and `shell-write-guard.mjs` gain the rule with no change of their own. The req-008 suite covers a folder, a FIFO, a link, scope-record cases, `EACCES`, and an unreadable regular file. |

## Consequences

**Positive:**
- A planted folder or FIFO at `design.md` can no longer admit a `src/` write or stall the session.
- The block reason names why `design.md` didn't count, so the human on the loop can fix it.

**Negative:**
- A project that keeps `design.md` as a symbolic link, such as a shared plan folder, now has every `src/` write blocked until it replaces the link with a file.
- A gate decision now costs one `lstatSync`, one open, and one `fstatSync` before the read, against one `existsSync` and one read today (risk R-011).

**Risks:**
- A file swapped between `lstatSync` and the open still passes, because that open fails and fails open. The window is microseconds and needs a racing writer, but the gap stays.
- On Windows, `fs.constants` lacks `O_NONBLOCK` and `O_NOFOLLOW`. The guard there rests on `lstatSync` and `fstatSync`, so a swap in the window proves less.
- A future change treats the new branch as a general fail-closed rule and blocks on other read errors (risk R-005). The suite asserts the mode `000` case still exits 0.

## Related ADRs

- ADR-001 - depends-on. The check uses Node built-ins only.
- ADR-003 - related-to. Both change `evaluateWrite`, and stream 01 builds them in sequence.
- 0000003 ADR 005 (exit zero failure mode) - narrows. A non-regular `design.md` or a throwing `lstatSync` no longer fails open.
- 0000035 ADR 004 (Fast Path enforcement path list) - depends-on. The enforcement list still runs before the scope record on this route.
- 0000035 ADR 005 (links resolved segment by segment, fail closed) - related-to. Both draw a fail-closed line inside the root.

## Supersedes

- None

## Superseded By

- None
