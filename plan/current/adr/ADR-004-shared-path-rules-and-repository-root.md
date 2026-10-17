---
title: "ADR 004: Shared path rules and repository root"
summary: "One module, path-rules.mjs, holds the gated-path rules for gate-write.mjs and the shell guard. The root is the nearest planifest-framework/ folder, else the nearest .git, found by a walk from CLAUDE_PROJECT_DIR or cwd with no git spawn. Targets outside the root pass."
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

`gate-write.mjs` lowercases and forward-slashes every path before it compares them (0000009-ADR-005). The sentinel check for `plan/current/` (0000005-ADR-003) runs first, inside the same hook. A-003 and A-004 in the execution plan record the root and real-path rules. The human on the loop confirmed both at P1. The P5 fixes for F1, N-4, and N-5 later changed the root rule in A-003, so it goes back to the human on the loop for reconfirmation at P9.

## Decision

- A new module, `planifest-framework/hooks/enforcement/path-rules.mjs`, holds every gated-path rule. `gate-write.mjs` and `shell-write-guard.mjs` import it and keep no copy of their own.
- It lives in `hooks/enforcement/`, so every install that copies `gate-write.mjs` copies it too (0000028-ADR-002).
- A marker walk climbs from a start folder, inclusive, and returns the first match in this order. The walk spawns no process.
  1. The nearest folder that holds `planifest-framework/`.
  2. The nearest folder that holds `.git`. A `.git` file counts, for worktrees.
- The repository root is chosen in this order.
  1. The result of the walk from `CLAUDE_PROJECT_DIR`, when the variable names a folder and the walk finds a marker. Claude Code sets it to the project folder.
  2. The result of the walk from `cwd`.
  3. `cwd`, when neither walk finds a marker.
- `CLAUDE_PROJECT_DIR` is a start point, never the root itself. Set to `src/`, it once made `../lib/` and `../.claude/` look outside the root. Set to the repository's parent, it locked out every write (security finding N-4).
- The walk from `CLAUDE_PROJECT_DIR` wins when both walks find a different root. An agent can change `cwd` with `cd`, and anything outside the root is writable. It can't change the hook's environment. With `cwd` first, an agent could `cd` into another repository and write to this one by absolute path.
- The walk takes the nearest `planifest-framework/`, not the outermost. With the outermost, a marker, sentinel, and `design.md` planted above the repository moved the root up and ungated it. A lone planted marker above locked out every write. A nested monorepo install judged its paths against the outer design (security finding N-5).
- A marked folder that sits inside `plan/` or `docs/` of a higher marked folder is never the root. Those prefixes are always permitted, so anyone can plant a marker there. Without this rule, `touch plan/x/.git` and a `cd plan/x` moved the root and let a write to the real `src/` pass (security finding F1).
- A target is unjudgeable when its resolved path is over 4096 characters or 256 segments. Both hooks warn on stderr and pass it before any file-system walk. Resolving such a path took 15 to 45 seconds, past the hook timeout (security finding F7).
- The limits apply to `resolve(base, target)`, which is string work with no file-system call. A long raw path that normalises to a short one, such as `src/other/` with 300 `./` segments, is judged like the short path (security finding N-3).
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
| Trust `CLAUDE_PROJECT_DIR` as the root | Claude Code sets it, and an agent can't change it | A value of `src/`, the parent folder, or an unrelated folder moves the root. Paths in the repository then pass or block wrongly. | Security finding N-4. The walk from the variable keeps its tamper resistance and fixes these values. |
| Prefer the walk from `cwd` when the two walks differ | A wrong `CLAUDE_PROJECT_DIR` that names another repository can't move the root | An agent can `cd` into another repository, or into a folder where it planted a marker, and write here by absolute path | The agent controls `cwd`. Only the human on the loop controls the variable. |
| Take the outermost `planifest-framework/` folder | A nested `.git` inside an install can't take over | A marker planted above the repository moves the root and ungates it | Security finding N-5. The `plan/` and `docs/` exclusion already covers markers planted inside the repository. |
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
- A nested folder holding its own `.git` becomes the root for paths inside it, unless a higher folder holds `planifest-framework/` or the nested folder sits inside `plan/` or `docs/`. The hook then gates those paths against the nested folder's `plan/`.
- A nested folder holding its own `planifest-framework/` is the root for paths inside it, so a monorepo package judges its paths against its own `design.md`.
- A crafted path over the length limits passes with a warning. The operating system rejects most such paths, and the boot-file rule covers the rest.
- Each hook now makes a few extra file-system calls for the walk and the real-path step.
- A broken import of `path-rules.mjs` fails before the hook's own `try`, so both hooks stop enforcing at once (0000028-ADR-004).

**Risks:**
- A downstream install that copies only `gate-write.mjs` by hand would lose the module. Both setup scripts copy every `*.mjs`, which covers the supported path.
- A git worktree holds a `.git` file, not a folder. The walk must accept either, or a worktree session falls back to `cwd`.
- A `CLAUDE_PROJECT_DIR` that names a different marked repository moves the root to that repository. Writes to the session's own repository then pass. Only the human on the loop can set the variable that way. Test suites unset it before they run the hooks.
- With `CLAUDE_PROJECT_DIR` unset, as in tools other than Claude Code, `cwd` decides. An agent that runs `cd` into another marked folder can then write to this repository by absolute path. Judging each target against both walks would close this gap, but the shell guard takes one root per command today.
- A repository whose own path runs through a `plan/` or `docs/` folder is skipped when a marker sits above that folder. Someone could plant that marker, because it sits outside the root.

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
