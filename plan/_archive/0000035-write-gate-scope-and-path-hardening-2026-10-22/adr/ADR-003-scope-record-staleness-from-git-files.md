---
title: "ADR 003: Scope record staleness from branch and HEAD read from git files"
summary: "The scope record stores the branch and HEAD commit it was written at. The gate reads both from .git files with no spawn, and ignores the record when either differs or git state can't be read."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - Scope record staleness from branch and HEAD read from git files

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

A scope record left by an interrupted Fast Path keeps admitting writes to its paths (risk R-002). The design asks the requirements to bound the record's life, for example by the branch or a timestamp. P0 confirmed the branch and `HEAD` commit as the binding.

The gate must read both values without spawning `git` (ADR-001). Git stores them in several layouts:

- `.git` is a folder in a normal clone, and a file with a `gitdir:` line in a worktree or submodule (risk R-008).
- A branch ref is a loose file, or a line in `packed-refs` (risk R-007).
- `HEAD` names a ref, or holds a bare commit when detached.
- A worktree keeps shared refs under the folder that `commondir` names.

The agent that writes the record also reads both values. The binding therefore bounds staleness only. It is not a security control (req-001).

## Decision

- **Binding:** The record stores `branch` and `head`. The gate ignores a record whose branch differs, compared exactly. It also ignores a record whose `head` differs, compared in lower case.
- **Reader:** `path-rules.mjs` gains a git-state reader, artifact `path-rules-readGitState`. It follows these steps:
  1. Find the nearest `.git` at or above the root.
  2. If `.git` is a file, follow its `gitdir:` line.
  3. Read `HEAD`. A ref gives the branch. A bare commit gives `(detached)`.
  4. Look the ref up as a loose file in the git folder, then in `commondir`, then in `packed-refs`.
- **Size caps:** Each git file is capped at 4 KiB, and `packed-refs` at 4 MiB. A larger file makes the state unreadable.
- **Fail closed on unreadable state:** If any step fails, the gate ignores the record. Causes include a reftable store and an unborn branch. An ignored record admits nothing, so the write gets the normal no-design block with one added line that says why.
- **Once per process:** Each hook process reads the record and the git state at most once per root.
- **Recovery:** If the agent commits or switches branch mid-change, it rewrites the record. The next Fast Path overwrites any stale record.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| A timestamp with a fixed time to live | No git parsing | A record stays live across a branch switch inside the window. The right window length is a guess. | Branch and `HEAD` track the change itself |
| Bind to the branch only | One value to read | A record survives every commit on the branch, so a later change inherits it. | Too weak to bound staleness |
| Spawn `git rev-parse` | Covers every ref store | Breaks 0000032 ADR 004 and adds a process per call | Breaks a declared constraint |
| Treat unreadable git state as current | Fewer false blocks on unusual repos | An unreadable state would let a stale record admit writes | Fails open on a gate decision |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `path-rules.mjs` gains the git-state reader. The req-001 suite covers stale branch, stale `HEAD`, a worktree `.git` file, and a `packed-refs` ref. |

## Consequences

**Positive:**
- A record from an interrupted Fast Path stops working at the next commit or branch switch.
- Worktrees, submodules, packed refs, and a detached `HEAD` all work with no spawn.

**Negative:**
- A repo on the reftable ref store, or on an unborn branch, can't use the scope record. Fast Path then falls back to the Change Pipeline.
- An agent must rewrite the record after any mid-change commit.

**Risks:**
- Git changes a file layout the reader depends on. The reader then reports unreadable state and blocks, which fails closed. The suite fixture shows the break.
- A `packed-refs` file near 4 MiB slows each hook call. The req-001 timing case checks 10,000 lines under 500 ms.

## Related ADRs

- ADR-001 - depends-on. No spawn rules out `git rev-parse`.
- ADR-002 - extends. This ADR bounds the life of the record that ADR-002 defines.
- 0000032 ADR 004 (shared path rules and repository root) - depends-on

## Supersedes

- None

## Superseded By

- None
