---
title: "Requirement: req-004 - root-when-cwd-deleted"
summary: "resolveRoot finds the repository root from CLAUDE_PROJECT_DIR or the nearest existing parent when the working directory no longer exists."
status: "draft"
version: "0.1.0"
---
# Requirement: req-004 - root-when-cwd-deleted

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Source:** US-004 (backlog 0000107)
**Priority:** must-have

## User Story

As the human on the loop, I rely on the gates to find the repository root when the working directory no longer exists, so that they never fail open on a write into `src/`.

## Functional Requirements

### Root lookup

- `resolveRoot(cwd)` checks `CLAUDE_PROJECT_DIR` before it checks whether `cwd` exists. If the variable names a folder and the walk from it finds a marker, that marked root wins, as today.
- If `cwd` is not a folder, `resolveRoot` walks up from `cwd` with `dirname` to the nearest existing folder. It starts the marker walk from the real path of that folder.
- If that walk finds no marker, the root is the real path of the nearest existing folder. This keeps the 0000032 rule that the root is cwd when no marker exists.
- `resolveRoot` returns `null` only when `cwd` is not a non-empty string. It never throws.
- The changed lookup is artifact `path-rules-resolveRoot-deleted-cwd`.
- Relative targets from a deleted `cwd` resolve against the `cwd` text, through its nearest existing parent with the missing segments appended.

### Hook cwd fallback

- `gate-write.mjs` and `shell-write-guard.mjs` use the `cwd` field from stdin when it is a non-empty string.
- If stdin has no such field and `process.cwd()` throws, each hook uses `CLAUDE_PROJECT_DIR` as `cwd`. If that is unset too, the hook passes with exit 0 as today.

### Superseded behaviour

- The 0000032 req-006 fail-open case "a `cwd` that doesn't exist exits 0" no longer holds. The assertion at `planifest-framework/tests/test-0000032-req-006-outside-repository-pass.sh` lines 364 to 366 changes to expect exit 2 for `src/a.js`. The suite comment names this requirement as the reason.
- The P3 agent records this change in the build log as a deliberate deviation from 0000032 req-006 (Hard Limit 7).

### Tests

- A new suite, `planifest-framework/tests/test-0000035-req-004-root-when-cwd-deleted.sh`, builds a git fixture under `mktemp -d` with no design. It passes a `cwd` field that names a folder the suite has deleted.
- The suite runs `gate-write.mjs` and `shell-write-guard.mjs` with `CLAUDE_PROJECT_DIR` set to the fixture, and again with it unset.
- With the variable unset, the deleted folder sits inside the fixture, so the nearest existing parent finds the fixture's marker.
- The suite also covers a deleted `cwd` with no marker above it, where the root is the nearest existing folder.

### Non-functional

- Each hook call stays under 500 ms with a deleted `cwd` 20 segments deep.
- `path-rules.mjs` uses Node built-in modules only and spawns no process.

## Acceptance Criteria

- [ ] With a deleted `cwd` and `CLAUDE_PROJECT_DIR` set to the fixture, a write to `src/x.js` exits 2. Both `gate-write.mjs` and the shell-write guard give that result.
- [ ] With a deleted `cwd` inside the fixture and `CLAUDE_PROJECT_DIR` unset, the walk from the nearest existing parent finds the fixture. A write to `src/x.js` exits 2.
- [ ] The 0000032 req-006 deleted-cwd assertion expects exit 2, and the full suite passes.

## Dependencies

- All five requirements in this stream change `planifest-framework/hooks/enforcement/path-rules.mjs`. One agent builds them in sequence.
- req-005 consumes `path-rules-resolveRoot-deleted-cwd` in `ratchet-check.mjs`. Build req-004 before req-005.
- req-006 changes `markedRoot`, which `resolveRoot` calls. The two changes touch different functions and can land in either order.
- `planifest-framework/tests/test-0000032-req-006-outside-repository-pass.sh` (one assertion changes).

## Input Validation

- [ ] Input source: the hook stdin `cwd` field and the `CLAUDE_PROJECT_DIR` environment variable.
- [ ] Allowed character pattern: any path text. The hook uses both values only as paths to walk and never prints or runs them.
- [ ] maximum length: the existing `MAX_PATH_CHARS` and `MAX_PATH_SEGMENTS` limits on the resolved target. A target past either limit keeps its warn-and-allow result (0000032 finding F7).
- [ ] The walk up to the nearest existing folder stops at the file-system root, so it ends within `MAX_PATH_SEGMENTS` steps.
- [ ] Failure behaviour: a `cwd` that is not a non-empty string gives `null`, and the hook passes with exit 0.
- [ ] Logging policy: neither value appears in hook output.
