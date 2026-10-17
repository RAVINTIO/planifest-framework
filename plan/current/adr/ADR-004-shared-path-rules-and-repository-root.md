---
title: "ADR 004: Shared path rules and repository root"
summary: "One module, path-rules.mjs, holds the gated-path rules for gate-write.mjs and the shell guard. The root is the first folder above cwd that holds planifest-framework/ or .git, found with no git spawn. Targets outside the root pass."
status: "accepted"
version: "0.1.0"
---
# ADR-004 - Shared path rules and repository root

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Component:** planifest-framework
**Date:** 2026-10-17

## Context

`gate-write.mjs` resolves every target against `cwd` and looks up `plan/` and `design.md` under `cwd`. That causes two faults.

- A target outside `cwd` falls through to its raw path. The hook then gates it, so a write to `/tmp` or another repository blocks when no design exists.
- If a session starts in a subfolder, or the agent runs `cd`, the hook finds no `design.md`. It then blocks every gated write.

The new shell guard (req-008 and req-009) must block exactly when `gate-write.mjs` blocks a **Write** to the same path. Two copies of the rules would drift apart. Hooks must also finish in under 200 ms per call (design NFR). They must stay dependency-free and fail open (0000003-ADR-005).

`gate-write.mjs` lowercases and forward-slashes every path before it compares them (0000009-ADR-005). The sentinel check for `plan/current/` (0000005-ADR-003) runs first, inside the same hook. A-003 and A-004 in the execution plan record the root and real-path rules, and the human on the loop confirmed both.

## Decision

- A new module, `planifest-framework/hooks/enforcement/path-rules.mjs`, holds every gated-path rule. `gate-write.mjs` and `shell-write-guard.mjs` import it and keep no copy of their own.
- It lives in `hooks/enforcement/`, so every install that copies `gate-write.mjs` copies it too (0000028-ADR-002).
- The repository root is the first folder above `cwd`, inclusive, that holds `planifest-framework/` or `.git`. The walk spawns no process. If no such folder exists, the root is `cwd`.
- Both sides of the comparison use real paths. The root is a real path, and the target resolves against the real path of `cwd`.
- A missing target resolves through the real path of its nearest existing parent, with the remaining segments appended.
- The comparison resolves `..` first and matches whole path segments. It keeps the 0000009-ADR-005 normalisation.
- A target outside the root passes with exit 0 and no output.
- The module looks up `plan/.orchestrator-active` and `plan/current/design.md` from the root, not from `cwd`.
- The shared rules keep the current check order. The `plan/current/` sentinel check comes first, then always-permitted paths, then `design.md` existence, then component paths.
- A failure inside the root walk never throws to the caller. The hook falls back to `cwd` or exits 0.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Find the root with `git rev-parse --show-toplevel` | Matches git's own view, including worktrees and `GIT_DIR` | Spawns a process on every **Write**, **Edit**, and Bash call. Fails when git isn't installed. | The spawn cost puts the 200 ms limit at risk on slow runners. The walk gives the same answer for every layout Planifest supports. |
| Keep `cwd` as the root | No change to resolution | `cwd` moves after a `cd` or a subfolder start, so the hook loses `design.md` | This is the fault the feature fixes. |
| Copy the rules into each hook | Each hook stands alone | Two copies drift, and req-009 needs exact parity | Parity is an acceptance criterion. Drift would let a shell write pass where **Write** blocks. |
| Compare normalised paths with no real-path step | No file-system calls | A symbolic link such as macOS `/tmp` makes an in-repository path look outside | That would let an in-repository write bypass the gate. |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Gains `path-rules.mjs`. `gate-write.mjs` loses its inline rules and imports them. `shell-write-guard.mjs` imports the same rules. |

## Consequences

**Positive:**
- Writes outside the repository never block, with or without a design.
- A session started in a subfolder still finds `plan/current/design.md`.
- The shell guard and `gate-write.mjs` cannot disagree about a path.
- Backlog 0000081 (Fast Path through `gate-write`) can build on one module.

**Negative:**
- A nested folder holding its own `.git` becomes the root for paths inside it. The hook then gates those paths against the nested folder's `plan/`.
- Each hook now makes a few extra file-system calls for the walk and the real-path step.
- A broken import of `path-rules.mjs` fails before the hook's own `try`, so both hooks stop enforcing at once (0000028-ADR-004).

**Risks:**
- A downstream install that copies only `gate-write.mjs` by hand would lose the module. Both setup scripts copy every `*.mjs`, which covers the supported path.
- A git worktree holds a `.git` file, not a folder. The walk must accept either, or a worktree session falls back to `cwd`.

## Related ADRs

- 0000003-ADR-004 - extends (the gate model now lives in a shared module)
- 0000003-ADR-005 - depends-on (fail open on unexpected errors)
- 0000005-ADR-003 - related-to (the sentinel check moves into the shared rules)
- 0000009-ADR-005 - extends (normalisation now follows a real-path step)
- 0000028-ADR-002 - depends-on (module placement in `hooks/enforcement/`)
- ADR-005 - related-to
- ADR-006 - related-to (the shell guard uses these rules)

## Supersedes

- None

## Superseded By

- None
