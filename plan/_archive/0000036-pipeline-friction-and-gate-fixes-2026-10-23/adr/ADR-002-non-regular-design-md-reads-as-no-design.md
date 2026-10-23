---
title: "ADR 002: A non-regular design.md reads as no design"
summary: "The write gate calls lstatSync on plan/current/design.md before any read. A folder, FIFO, symbolic link, other non-regular file, or a throwing lstatSync reads as no design. So does a file swapped or removed before the open, or a file over 1 MiB. A regular file whose open throws EACCES or EPERM, or whose read throws, still fails open. Any other open or fstat error reads as no design. This narrows 0000003 ADR 005."
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
- **Swap after `lstatSync`:** If the open or `fstatSync` of a file that `lstatSync` showed as regular throws any error other than `EACCES` or `EPERM`, the route is "any other type". Each block then gains the "not a regular file" line. The file changed in the window, or it isn't a file the gate can read. The list is open-ended, and these are the known codes:
  - `ELOOP` (the `O_NOFOLLOW` error on Linux and macOS) or `EMLINK` (the FreeBSD one), for a swapped-in link
  - `ENOENT` or `ENOTDIR`, for a file or folder that someone removed or replaced
  - `ENXIO` on Linux, or errno -102 on macOS, for a swapped-in Unix socket

  The gate reads the error as a block, not a pass, so a code it doesn't know can't fail open. This differs from `main`, where the gate follows a swapped-in link and a deletion fails open (P5 security review, finding 1). The P5 re-review found that a socket swap failed open under the earlier list of four codes (N-1).
- **Size cap:** After `fstatSync`, a regular `design.md` larger than 1 MiB (1048576 bytes) reads as no design. The check runs before the read. `scopeVerdict` judges the write, and each block gains the line `[Planifest] plan/current/design.md is over the 1 MiB size cap, so the gate treats it as no design.` A file at or under the cap is read for at most the size `fstatSync` gave, so a file that grows after the check can't push the read past the cap. Without the cap, a sparse file past Node's string limit throws in the read and fails open with no race (P5 security review, finding 2, backlog 0000178).
- **Fail-open line:** If the open or `fstatSync` of a regular file throws `EACCES` or `EPERM`, the write passes, as 0000003 ADR 005 requires. The same holds when the read throws, because the descriptor already names a regular file by then.
- **Narrowing:** This ADR narrows 0000003 ADR 005 for the `design.md` step of `evaluateWrite` only. Every other unexpected error in the hooks still exits 0. `check-design.mjs` and `ratchet-check.mjs` keep their reads, and backlog 0000161 tracks them.
- **Kept bypass:** An agent can run `chmod 000 plan/current/design.md`. The guarded open then throws `EACCES` on a file that `lstatSync` showed as regular, and the gate fails open with no race. This feature keeps that bypass under 0000003 ADR 005. Backlog 0000162 tracks it.
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
| planifest-framework | The `design.md` step of `evaluateWrite` gains `lstatSync`, the guarded open, and `fstatSync`. `gate-write.mjs` and `shell-write-guard.mjs` gain the rule with no change of their own. The step also gains the 1 MiB size cap. The req-008 suite covers these cases:<br>- a folder, a FIFO, and a link<br>- scope-record cases<br>- `EACCES` and an unreadable regular file<br>- a swap after `lstatSync`, a socket among them<br>- an oversize file |

## Consequences

**Positive:**
- A planted folder or FIFO at `design.md` can no longer admit a `src/` write or stall the session.
- The block reason names why `design.md` didn't count, so the human on the loop can fix it.

**Negative:**
- A project that keeps `design.md` as a symbolic link, such as a shared plan folder, now has every `src/` write blocked until it replaces the link with a file.
- A gate decision now costs one `lstatSync`, one open, and one `fstatSync` before the read, against one `existsSync` and one read today (risk R-011).
- A `design.md` over 1 MiB blocks every write it would cover until someone trims it.

**Risks:**
- A `chmod 000` on `design.md` turns the gate off for any agent that can run it, because the open throws `EACCES` and fails open. This needs no race. Backlog 0000162 tracks the fix.
- A file swapped between `lstatSync` and the open for another regular file still reads as that file. The gate then judges the write against the new content. `plan/` is always permitted, so this gives an agent no power it lacks.
- On Windows, `fs.constants` lacks `O_NONBLOCK` and `O_NOFOLLOW`. The guard there rests on `lstatSync` and `fstatSync`, so a swap in the window proves less.
- A future change treats the new branch as a general fail-closed rule and blocks on other read errors (risk R-005). The suite asserts the mode `000` case still exits 0.

## Related ADRs

- ADR-001 - depends-on. The check uses Node built-ins only.
- ADR-003 - related-to. Both change `evaluateWrite`, and stream 01 builds them in sequence.
- 0000003 ADR 005 (exit zero failure mode) - narrows. A non-regular `design.md`, a throwing `lstatSync`, a swap before the open, or an oversize file no longer fails open.
- 0000035 ADR 004 (Fast Path enforcement path list) - depends-on. The enforcement list still runs before the scope record on this route.
- 0000035 ADR 005 (links resolved segment by segment, fail closed) - related-to. Both draw a fail-closed line inside the root.

## Supersedes

- None

## Superseded By

- None
