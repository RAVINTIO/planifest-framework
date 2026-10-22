---
title: "ADR 001: Stack unchanged, gate code on Node built-ins with no spawn"
summary: "0000035 keeps the declared stack. Every gate change in stream 01 lands in the existing path-rules.mjs module and the hooks that import it, on Node built-ins only and with no process spawn."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Stack unchanged, gate code on Node built-ins with no spawn

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

The design declares this stack:

- JavaScript ES modules on Node built-ins
- Bash and PowerShell setup scripts
- Markdown skills
- GitHub Actions CI and a local build target

The design states "Stack unchanged". It declares no database, ORM, IaC, cloud, or compute.

Stream 01 changes the write gates in six ways (req-001, req-003 to req-006, and req-009). Each change touches `planifest-framework/hooks/enforcement/path-rules.mjs`. That module is the shared home for path and root rules (0000032 ADR 004). `gate-write.mjs` and `shell-write-guard.mjs` already import it. req-005 adds `ratchet-check.mjs` as a third importer.

Two of the new rules read state that git tools usually report:

- the current branch and `HEAD` commit for the scope record (req-001)
- the real target of a path through symbolic links (req-003)

The design lists 0000032 ADR 004 as a constraint: hooks use Node built-ins only, with no process spawn. A spawn of `git` would add latency to every hook call and depend on `git` being on the path.

## Decision

- **Stack:** The stack stays as the design declares it. Stream 01 adds no language, runtime, library, or service.
- **One module:** Every new rule lives in `path-rules.mjs`. The hooks call it and hold no copy of the rules. This covers the scope record reader, the git-state reader, `resolveTarget`, the changed `resolveRoot`, and the changed `markedRoot`.
- **Node built-ins only:** The new code uses `node:fs` and `node:path`. It reads git state from files under `.git` (ADR-003). It resolves links with `lstatSync` and `readlinkSync` (ADR-005).
- **No spawn:** `path-rules.mjs` imports no `node:child_process`. A suite source check asserts this.
- **Existing spawn left alone:** The `git status` call in `ratchet-check.mjs` predates this feature. Backlog 0000128 tracks it, and this run does not change it.
- **Tests:** Each requirement gets a Bash suite under `planifest-framework/tests/`, run through `run-tests.sh` and the existing CI jobs.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Spawn `git rev-parse` for branch and `HEAD` | Git handles every ref store, including reftable | Adds a process per hook call. Breaks 0000032 ADR 004. Fails where `git` is not on the path. | Breaks a declared constraint |
| Add an npm package for git refs or path resolution | Tested parsing code | Hooks install by copy with no `npm install` step (0000028 ADR 002). A dependency changes the stack. | Deviates from the declared stack |
| Put each new rule in the hook that first needs it | Smaller diff per hook | `gate-write.mjs` and `shell-write-guard.mjs` drift apart (risk R-019). `ratchet-check.mjs` keeps its own root logic (0000109). | Shared rules are the fix for both defects |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `path-rules.mjs` grows. `gate-write.mjs`, `shell-write-guard.mjs`, and `ratchet-check.mjs` call the shared rules. Six new suites. |
| setup-hook-integration | No change. Setup already copies every `*.mjs` in `hooks/enforcement/` (0000028 ADR 002). |

## Consequences

**Positive:**
- Both write gates and the ratchet reach the same verdict on the same path, because they run the same code.
- Hook latency stays bounded by file-system calls, with no process start.

**Negative:**
- The gate must parse git files itself, which covers less than `git` does. A reftable ref store reads as unreadable (ADR-003).
- A fault in `path-rules.mjs` now affects three hooks, not two (risk R-018).

**Risks:**
- A future change adds a spawn to `path-rules.mjs` for convenience. The source check on `node:child_process` catches it.

## Related ADRs

- ADR-002, ADR-003, ADR-004, ADR-005, ADR-006, ADR-007, ADR-008 - related-to. Each records a rule that lives in `path-rules.mjs`.
- 0000032 ADR 004 (shared path rules and repository root) - depends-on
- 0000028 ADR 002 (shared module placement and install topology) - depends-on

## Supersedes

- None

## Superseded By

- None
