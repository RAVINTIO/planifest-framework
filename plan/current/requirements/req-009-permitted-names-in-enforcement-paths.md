---
title: "Requirement: req-009 - permitted-names-in-enforcement-paths"
summary: "The write gate's always-permitted file-name shortcut skips any path inside the Fast Path enforcement list, so such a path takes the normal design or scope route."
status: "draft"
version: "0.1.0"
---
# Requirement: req-009 - permitted-names-in-enforcement-paths

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Source:** US-009 (backlog 0000159)
**Priority:** should-have

## User Story

As the human on the loop, I rely on the write gate to judge a permitted file name inside an enforcement folder like any other path, so that the name can't bypass the enforcement list.

## Functional Requirements

### Current behaviour (verified at `f834ab2`)

- `evaluateWrite` returns `{ allowed: true }` at `path-rules.mjs:772` when `isAlwaysPermitted(relPath)` holds.
- `isAlwaysPermitted` (`path-rules.mjs:422-427`) holds when the last segment is in `ALWAYS_PERMITTED_FILES` (`path-rules.mjs:55-60`), or the path starts with `plan/` or `docs/`.
- `isEnforcementPath` (`path-rules.mjs:521-533`) runs only inside `scopeVerdict` (`path-rules.mjs:706`), which runs only when `design.md` is absent.
- A write to `planifest-framework/hooks/enforcement/CLAUDE.md` therefore passes at `:772`, with or without a design, and never meets the enforcement list.

### Gate change

- The always-permitted file-name shortcut at `path-rules.mjs:772` applies only when `isEnforcementPath(relPath)` is false.
- A path whose last segment is an always-permitted name and that `isEnforcementPath` matches takes the normal route:
  - With a regular `design.md`, the component-path check judges it, as for any other path.
  - With no design, `scopeVerdict` judges it. The enforcement-path block then applies whenever a scope record exists (0000035 ADR 004).
- The `plan/` and `docs/` prefix shortcut keeps its current behaviour. US-009 and backlog 0000159 name only the file-name shortcut, and the planning paths must stay writable before P0 completes.
- The sentinel check at `path-rules.mjs:763-770` keeps its file-name exemption. A `**/` enforcement entry can match below `plan/current/`, but the `plan/` prefix shortcut still admits that path. Its verdict therefore stays as before.
- Matching uses `isEnforcementPath` as it stands, with its case and compatibility folding (`foldWide`, `path-rules.mjs:510`). The gate keeps no second copy of the enforcement list.
- `shell-write-guard.mjs:700` calls `evaluateWrite`, so the shell guard gains the same rule with no change of its own.
- The comment block above `evaluateWrite` (`path-rules.mjs:744-758`) states the new condition on step 1.

### Unchanged paths

- An always-permitted file name outside every enforcement path still returns `{ allowed: true }` at step 1, with or without a design. An example is `src/setup-hook-integration/CLAUDE.md`.
- Every path that isn't an always-permitted name gets the same verdict as before.

### Tests

- A new suite, `planifest-framework/tests/test-0000036-req-009-permitted-names-in-enforcement-paths.sh`, builds a fixture under `mktemp -d` with `plan/.orchestrator-active`. It clears `CLAUDE_PROJECT_DIR` (req-010).
- The suite runs `gate-write.mjs` and `shell-write-guard.mjs` on each target below, in three fixture states:
  - no `design.md` and no scope record
  - no `design.md` and a current scope record that lists the target
  - a regular `design.md` whose `## Component Paths` section doesn't cover the target
- The targets are these:
  - `planifest-framework/hooks/enforcement/CLAUDE.md`, inside an enforcement folder
  - `.claude/hooks/enforcement/AGENTS.md`, inside an installed hook folder (`**/hooks/enforcement/`)
  - `planifest-framework/hooks/enforcement/Claude.MD`, a case variant
  - `src/a/CLAUDE.md`, outside every enforcement path
- A fourth state, a design that covers `planifest-framework/`, admits `planifest-framework/hooks/enforcement/CLAUDE.md`. This shows the normal route can still admit the path.

### Non-functional

- NFR-001 sets the 500 ms target. The timed case in the req-008 suite measures it for this change. This requirement adds no timing test of its own.
- The change uses Node built-in modules only and spawns no process.

## Acceptance Criteria

- [ ] A **Write** to `planifest-framework/hooks/enforcement/CLAUDE.md` exits 2 with no design and with a scope record that lists it. It exits 2 under a design that doesn't cover it. Both hooks give the same result.
- [ ] A **Write** to `src/a/CLAUDE.md` exits 0 in all three fixture states, as it does today.
- [ ] The req-009 suite covers both targets with and without `design.md`, and checks the design that covers `planifest-framework/` admits the enforcement-folder file.

## Dependencies

- `planifest-framework/hooks/enforcement/path-rules.mjs`: `evaluateWrite`, `isAlwaysPermitted`, and `isEnforcementPath`. Req-008 and req-011 also change this file, so one stream 01 agent builds them in sequence.
- `FAST_PATH_ENFORCEMENT_PATHS` and its matching (0000035 req-009, ADR 004), unchanged.
- 0000033 ADR 009 (Fast Path never admits an enforcement path).
- Req-010, whose suite check requires this requirement's suite to clear `CLAUDE_PROJECT_DIR`.
