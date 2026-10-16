---
title: "Requirement: req-003 - write-gate-scope"
summary: "gate-write passes paths outside the repository, and every enforcement hook that blocks writes its reason to stderr."
status: "draft"
version: "0.1.0"
---
# Requirement: req-003 - write-gate-scope

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Source:** US-003
**Priority:** must-have

## User Story

As an agent, I see `gate-write` ignore paths outside the repository and show its block reason, so that I can act on a block without reading the hook's source.

## Functional Requirements

### Shared path rules (AC-6, used by req-004)

- A new module, `planifest-framework/hooks/enforcement/path-rules.mjs`, holds every path rule `gate-write.mjs` uses today. It lives in `hooks/enforcement/` so that every install that copies `gate-write.mjs` also copies it (0000028-ADR-002).
- The module exports these functions. The names are a proposal, and the implementer may rename them.
  - `resolveRoot(cwd)` returns the repository root.
  - `toRootRelative(root, cwd, target)` returns the target's path relative to the root, or `null` when the target is outside the root.
  - `evaluateWrite(root, relPath)` returns either an allow result or a block result with a reason string.
- `resolveRoot` runs `git rev-parse --show-toplevel` with `cwd` as its working directory. If git is missing, fails, or prints nothing, the root is `cwd`.
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

### Block reasons on stderr (AC-7)

These enforcement hooks exit 2 today, and each one changes:

| Hook | Block paths | Current output on block |
|------|-------------|-------------------------|
| `planifest-framework/hooks/enforcement/gate-write.mjs` | no sentinel for `plan/current/**`, no `design.md`, path outside the component paths | plain text on stdout |
| `planifest-framework/hooks/enforcement/ratchet-check.mjs` | weakening with no approval, approval present but marker uncommitted | `permissionDecision: "deny"` JSON on stdout |
| `planifest-framework/hooks/enforcement/em-dash-guard.mjs` | em dash in a scoped path | plain text on stdout |

- On every block path in the table, the hook writes a plain-text reason to stderr before it exits 2.
- `gate-write.mjs` and `em-dash-guard.mjs` write the same reason text to stderr that they write to stdout.
- `ratchet-check.mjs` writes its `reason` string to stderr as plain text, not JSON.
- Each hook keeps its stdout output unchanged, byte for byte. The Windsurf, Copilot, and Codex adapters read the reason from stdout, and they keep working with no change.
- `check-orchestrator-presence.mjs`, `check-design.mjs`, and `auto-trigger-orchestrator.mjs` never exit 2, so AC-7 doesn't change them. The adapters under `hooks/adapters/` relay a hook's exit 2 and aren't enforcement hooks, so AC-7 doesn't change them either.
- The new shell-write guard from req-004 also exits 2. Req-004 holds it to the same stderr rule.

### Fail-open and latency (NFRs)

- `gate-write.mjs` exits 0 with no stdout on each of these inputs:
  - stdin that isn't valid JSON
  - JSON with no `file_path` and no `path`
  - JSON whose `file_path` isn't a string
  - a `cwd` that doesn't exist
- Each changed hook finishes in under 200 ms per call on the CI runners. The git call in `resolveRoot` counts towards that limit.

### Tests

- A new Bash suite, `planifest-framework/tests/test-0000032-req-003-write-gate-scope.sh`, runs each hook with JSON on stdin and checks the exit code, stdout, and stderr. `run-tests.sh` finds it by its `test-*.sh` name.
- The suite builds its fixtures under `mktemp -d`. For git-root cases it runs `git init` inside the fixture, so the result never depends on the host repository.
- The existing suites for `gate-write.mjs`, `ratchet-check.mjs`, and `em-dash-guard.mjs` still pass. That includes `test-gate-write-windows.sh` and `test-0000028-req-006-em-dash-guard.sh`.

## Acceptance Criteria

- [ ] In a git fixture with no `design.md`, a **Write** to an absolute path outside the fixture exits 0 with empty stdout and stderr.
- [ ] In the same fixture with a `design.md` whose component paths don't cover the target, a **Write** outside the fixture exits 0.
- [ ] In a fixture that isn't a git repository, the root falls back to `cwd`. A **Write** outside `cwd` exits 0, and a **Write** to `cwd/src/a.js` with no `design.md` exits 2.
- [ ] In a git fixture, with `cwd` set to a subfolder, a **Write** to `{root}/src/a.js` with no `design.md` exits 2. This shows that the root is the git top-level, not `cwd`.
- [ ] With `cwd` at the git root, a `..` path that leaves the root, such as `../outside/a.js` or `src/../../outside/a.js`, exits 0.
- [ ] A `..` path that stays inside the root, such as `docs/../src/a.js`, is gated like `src/a.js`.
- [ ] A sibling folder whose name starts with the root's name, such as `{root}-other/a.js`, exits 0.
- [ ] With `cwd` set to a symbolic link that points at the git root, a **Write** to `{link}/src/a.js` with no `design.md` exits 2.
- [ ] Each of the three `gate-write.mjs` block paths exits 2 with a non-empty stderr. Its stdout matches the text from before this feature.
- [ ] Each of the two `ratchet-check.mjs` block paths exits 2 with a non-empty, non-JSON stderr. Its stdout still parses as JSON with `permissionDecision` set to `deny`.
- [ ] The `em-dash-guard.mjs` block path exits 2 with a non-empty stderr. Its stdout matches the text from before this feature.
- [ ] Driven through `hooks/adapters/windsurf.mjs` with a `pre_write_code` event, a gated path exits 2 and the adapter's stdout holds the block reason.
- [ ] `gate-write.mjs` exits 0 with no stdout on malformed stdin, on JSON with no target path, on a non-string `file_path`, and on a `cwd` that doesn't exist.
- [ ] `gate-write.mjs` imports `path-rules.mjs`. Neither file defines the always-permitted lists twice.
- [ ] After `setup.sh claude-code`, `.claude/hooks/enforcement/path-rules.mjs` exists next to `gate-write.mjs`.
- [ ] Each changed hook completes in under 200 ms per call, timed in the suite.

## Dependencies

- None upstream in this feature. Req-004 depends on `path-rules.mjs` and on the git top-level root from this requirement.
- The 0000031 CI jobs run the new suite on Linux and Windows.
