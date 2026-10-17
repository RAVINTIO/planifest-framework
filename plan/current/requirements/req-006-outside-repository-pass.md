---
title: "Requirement: req-006 - outside-repository-pass"
summary: "A shared path-rules module finds the repository root, and gate-write uses it to pass every target outside that root."
status: "draft"
version: "0.1.0"
---
# Requirement: req-006 - outside-repository-pass

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Source:** US-003
**Priority:** must-have

## User Story

As an agent, I want `gate-write` to ignore paths outside the repository, so that a write outside the repository never needs a design.

## Functional Requirements

### Shared path rules (AC-6, used by req-008 and req-009)

- A new module, `planifest-framework/hooks/enforcement/path-rules.mjs`, holds every path rule `gate-write.mjs` uses today. It lives in `hooks/enforcement/` so that every install that copies `gate-write.mjs` also copies it (0000028-ADR-002).
- The module exports these functions. The names are a proposal, and the implementer may rename them.
  - `resolveRoot(cwd)` returns the repository root.
  - `toRootRelative(root, cwd, target)` returns the target's path relative to the root, or `null` when the target is outside the root.
  - `evaluateWrite(root, relPath)` returns either an allow result or a block result with a reason string.
- `resolveRoot` walks up from `cwd` to the first folder that holds `planifest-framework/` or `.git`. It spawns no process. If no such folder exists, the root is `cwd` (ADR-004).
- `resolveRoot` returns the real path of the root, with symbolic links resolved. `toRootRelative` resolves `target` against the real path of `cwd`. Both sides of the comparison therefore use real paths, so a symbolic link such as macOS `/tmp` cannot make an in-repository path look outside.
- If the target doesn't exist yet, `toRootRelative` resolves the real path of its nearest existing ancestor and appends the remaining segments.
- `toRootRelative` resolves `..` segments before the comparison. It compares whole path segments, so `/repo-other/a.js` is outside a root of `/repo`.
- `evaluateWrite` applies the current `gate-write.mjs` checks in the current order:
  1. The sentinel check for `plan/current/**`, with the existing `feature-brief.md` and always-permitted basename exemptions.
  2. The always-permitted prefixes and basenames.
  3. The `design.md` existence check.
  4. The component-path check, which keeps the existing fail-open warning when `design.md` has no parseable paths section.
- `evaluateWrite` looks up `plan/.orchestrator-active` and `plan/current/design.md` under the root, not under `cwd`.
- The block reason strings keep their current wording. The out-of-design reason names the root-relative path.
- `path-rules.mjs` stays dependency-free and uses only Node built-in modules. A failure inside `resolveRoot` never throws to the caller.

### gate-write scope (AC-6)

- `planifest-framework/hooks/enforcement/gate-write.mjs` imports its rules from `path-rules.mjs` and keeps no copy of them.
- If `toRootRelative` returns `null`, `gate-write.mjs` exits 0 with no output. This holds with or without `plan/current/design.md` and with or without the sentinel.
- `gate-write.mjs` keeps its stdin contract. It reads `tool_input.path` or `tool_input.file_path`, and accepts both the Planifest common envelope and raw Claude Code input.

### Fail-open (NFR)

- `gate-write.mjs` exits 0 with no stdout on each of these inputs:
  - stdin that isn't valid JSON
  - JSON with no `file_path` and no `path`
  - JSON whose `file_path` isn't a string
  - a `cwd` that doesn't exist
- `resolveRoot` walks the folder tree and spawns no process, so `gate-write.mjs` stays inside the 200 ms limit that req-007 times.

### Tests

- A new Bash suite, `planifest-framework/tests/test-0000032-req-006-outside-repository-pass.sh`, runs `gate-write.mjs` with JSON on stdin and checks the exit code, stdout, and stderr. `run-tests.sh` finds it by its `test-*.sh` name.
- The suite builds its fixtures under `mktemp -d`. It creates a `.git` folder inside the fixture with `git init`, so the walk-up finds the fixture root and never the host repository.
- The existing suites for `gate-write.mjs` still pass. That includes `test-gate-write-windows.sh`.

### Verified by

- In a git fixture with no `design.md`, a **Write** to an absolute path outside the fixture exits 0 with empty stdout and stderr.
- In the same fixture with a `design.md` whose component paths don't cover the target, a **Write** outside the fixture exits 0.
- In a fixture that isn't a git repository, the root falls back to `cwd`. A **Write** outside `cwd` exits 0, and a **Write** to `cwd/src/a.js` with no `design.md` exits 2.
- In a git fixture, with `cwd` set to a subfolder, a **Write** to `{root}/src/a.js` with no `design.md` exits 2. This shows that the root is the walked-up repository root, not `cwd`.
- With `cwd` at the git root, a `..` path that leaves the root, such as `../outside/a.js` or `src/../../outside/a.js`, exits 0.
- A `..` path that stays inside the root, such as `docs/../src/a.js`, is gated like `src/a.js`.
- A sibling folder whose name starts with the root's name, such as `{root}-other/a.js`, exits 0.
- With `cwd` set to a symbolic link that points at the git root, a **Write** to `{link}/src/a.js` with no `design.md` exits 2.
- `gate-write.mjs` exits 0 with no stdout on malformed stdin, on JSON with no target path, on a non-string `file_path`, and on a `cwd` that doesn't exist.
- `gate-write.mjs` imports `path-rules.mjs`. Neither file defines the always-permitted lists twice.
- After `setup.sh claude-code`, `.claude/hooks/enforcement/path-rules.mjs` exists next to `gate-write.mjs`.
- With planted `plan/x/.git` and `plan/x/planifest-framework/` and `cwd` set to `plan/x`, a **Write** to the real `src/x.js` with no `design.md` exits 2. A planted `docs/y/z/.git` does the same (security finding F1).
- The outermost folder holding `planifest-framework/` is the root, ahead of a nearer `.git`. A nested `.git` outside `plan/` and `docs/` is still its own root when no `planifest-framework/` sits above it.
- With `CLAUDE_PROJECT_DIR` set to a folder, that folder is the root. A `CLAUDE_PROJECT_DIR` that doesn't exist falls back to the walk. Every suite that runs the hooks unsets the variable first.
- A **Write** to a 20,000-segment path, or a path over 4096 characters, exits 0 with a stderr warning within 2 seconds. A 200-segment path is still judged (security finding F7).

## Acceptance Criteria

- [ ] `gate-write.mjs` exits 0 for a target outside the repository root, with or without `design.md`. Tests cover a `..` path that leaves the root and a sibling folder that shares the root's name prefix.
- [ ] The root is the first folder above `cwd` that holds `planifest-framework/` or `.git`, or `cwd` when none exists. Real paths decide the comparison, so a subfolder or symbolic-link `cwd` still gates in-repository paths.
- [ ] `gate-write.mjs` takes its rules from `path-rules.mjs`, which setup installs beside it, and fails open on malformed input.

## Dependencies

- None upstream in this feature. Req-007, req-008, and req-009 depend on `path-rules.mjs` and on the repository root rule from this requirement.
- ADR-004 records the shared module and the walk-up root rule.
- The 0000031 CI jobs run the new suite on Linux and Windows.
