---
title: "Requirement: req-005 - ratchet-check-shared-root"
summary: "ratchet-check.mjs finds the repository root and the target path with the shared path rules, so it guards plan/current/ from any subfolder."
status: "draft"
version: "0.1.0"
---
# Requirement: req-005 - ratchet-check-shared-root

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Source:** US-005 (backlog 0000109)
**Priority:** must-have

## User Story

As the human on the loop, I rely on `ratchet-check` to find the active loop from any subfolder, so that a weakening write is blocked wherever the agent runs it.

## Functional Requirements

### Shared root and path

- `planifest-framework/hooks/enforcement/ratchet-check.mjs` imports `resolveRoot` and `resolveTarget` from `path-rules.mjs`. It keeps no root or path logic of its own.
- The hook takes `cwd` from the stdin `cwd` field. It falls back to `process.cwd()`, then to `CLAUDE_PROJECT_DIR`, as `gate-write.mjs` does under req-004.
- The hook finds `plan/current/`, `plan/current/.ratchet-approve`, and `plan/ratchet-audit-log.md` under the root from `resolveRoot`, not under `process.cwd()`.
- The hook resolves `file_path` with `resolveTarget(root, cwd, file_path)`. A relative `file_path` resolves against `cwd`.
- The hook calls `resolveTarget` through `resolveTargetBoth`, which also returns the placement with `..` collapsed as text, as the **Write** tool places it (P5 finding G-S01). The hook guards each placement that lands on a `plan/current/` artifact and blocks if either check blocks.
- The hook reads the current file content from the root plus `relPath`, not from `resolve(filePath)`.
- The `plan/current/` and `.md` checks, and the exemptions for `loop-state-*`, `ratchet-log.md`, and `build-log.md`, compare the normalised `relPath`. That uses the 0000009 ADR 005 forward-slash and lower-case form.
- The hook passes with exit 0 in these cases:
  - `resolveRoot` returns `null`
  - `resolveTarget` returns `outside`
  - `resolveTarget` returns `unresolvable`, because `gate-write.mjs` already blocks that write with exit 2
- The weakening rules, the approval format, the audit log, and the block output stay as they are.
- The block output passes each path it prints through `shown` from `path-rules.mjs`, cut to `MAX_PATH_CHARS` (P5 re-review finding G-N1). A path that holds a control character can't then forge a line of hook output. A path with no control character prints whole, as before.
- The uncommitted-marker backstop keeps its `git status` call. This requirement does not change it (see backlog 0000128).

### Tests

- A new suite, `planifest-framework/tests/test-0000035-req-005-ratchet-check-shared-root.sh`, builds a fixture under `mktemp -d` with an active `plan/current/loop-state-x.md`. It also writes a `plan/current/` artifact with an `## Acceptance Criteria` section.
- The suite runs `ratchet-check.mjs` with its process working directory and the stdin `cwd` both set to a subfolder such as `src/`. The `file_path` is relative, such as `../plan/current/req.md`, and an `Edit` removes a `- [ ]` line.
- The suite repeats the case from the root to show that the result matches.
- The suite also checks that an approval line in `.ratchet-approve` still lets the write pass from the subfolder.
- The existing ratchet suites still pass.
- The ratchet now reads `CLAUDE_PROJECT_DIR`, so a Claude Code session can move its root. The existing ratchet suites therefore unset that variable (P3 deviation, build log). That covers these suites:
  - `test-0000016-pipeline-governance.sh`
  - `test-0000017-req-002-ratchet-approve.sh`
  - the regression copy of each

### Non-functional

- Each `ratchet-check.mjs` call stays under 500 ms on a 10-hop link chain.
- The new code in this requirement uses Node built-in modules only and spawns no process. The existing `git status` spawn in `ratchet-check.mjs` predates this feature, and backlog 0000128 tracks it.

## Acceptance Criteria

- [ ] From a project subfolder, during an active loop, an **Edit** that removes an acceptance criterion exits 2. The ratchet reason goes to stderr.
- [ ] From the same subfolder, a relative `file_path` resolves against the stdin `cwd`, and a write that adds a criterion exits 0.
- [ ] `ratchet-check.mjs` imports `resolveRoot` and `resolveTarget` from `path-rules.mjs` and holds no call to `process.cwd()` outside the cwd fallback.

## Dependencies

- Consumes `path-rules-resolveRoot-deleted-cwd` from req-004. Build req-004 first.
- Consumes `path-rules-resolveTarget-links` from req-003. Build req-003 first.
- All six requirements in this stream change or import `planifest-framework/hooks/enforcement/path-rules.mjs`. One agent builds them in sequence.
- `setup.sh` and `setup.ps1` already copy every `*.mjs` in `hooks/enforcement/`, so the import resolves in every install (0000028 ADR 002).

## Input Validation

- [ ] Input source: the hook stdin `cwd` and `tool_input.file_path` fields.
- [ ] Allowed character pattern: any path text. The hook uses both only as paths.
- [ ] maximum length: the `MAX_PATH_CHARS` and `MAX_PATH_SEGMENTS` limits in `path-rules.mjs`. A longer path passes with exit 0, as in `gate-write.mjs`.
- [ ] Failure behaviour: a non-string `file_path` passes with exit 0.
- [ ] Logging policy: the block reason shows the root-relative path, as today.
