---
title: "Requirement: req-001 - fast-path-scope-record"
summary: "A Fast Path change declares its target paths in plan/.fast-path-scope, and both write gates admit matching writes in place of a design."
status: "draft"
version: "0.1.0"
---
# Requirement: req-001 - fast-path-scope-record

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Source:** US-001 (backlog 0000081, 0000125, and 0000062)
**Priority:** must-have

## User Story

As the human on the loop, I see a Fast Path change written through **Write** and **Edit** against a declared scope record, so that Fast Path never needs a shell workaround or a hand copy.

## Functional Requirements

### Scope record format

- The scope record lives at `plan/.fast-path-scope`. The `plan/` prefix is always permitted, so the agent writes it with **Write**.
- The record is UTF-8 text with LF or CRLF line endings. It holds these lines, in this order:
  1. `branch: <name>`, where `<name>` is the current branch, or the literal `(detached)` when `HEAD` names no branch.
  2. `head: <commit>`, where `<commit>` is the full hexadecimal `HEAD` commit ID.
  3. `paths:`
  4. One `- <path>` line per target path, with at least one such line.
- The parser skips blank lines and lines that start with `#`. Any other line that breaks the grammar makes the whole record invalid.
- Each `<path>` is relative to the repository root. A path that ends in `/` names a folder and covers everything below it. A path without a trailing `/` covers that file, and also everything below it if it is a folder.
- Path matching uses the 0000009-ADR-005 normalisation and whole path segments, as `matchesComponentPath` does today. The record has no glob syntax.
- The format is artifact `fast-path-scope-record-format`. `workflows/fast-path.md` shows one complete example of it.

### Record life

- `path-rules.mjs` reads the current branch and `HEAD` commit without a process spawn (0000032 ADR-004). It follows these steps:
  1. Find the nearest `.git` at or above the repository root.
  2. If `.git` is a folder, it is the git folder. If `.git` is a file, read its `gitdir: <path>` line and resolve `<path>` against the folder that holds the file. This covers worktrees and submodules.
  3. Read `<gitdir>/HEAD`. A `ref: refs/heads/<name>` line gives the branch `<name>`. A bare commit ID gives the branch `(detached)` and that commit.
  4. For a ref, look up the commit in `<gitdir>/<ref>`. Next, try `<commondir>/<ref>`, where `<commondir>` comes from `<gitdir>/commondir` when that file exists. Last, scan `<commondir>/packed-refs` for a `<commit> <ref>` line, skipping `#` and `^` lines.
- If any step fails, the git state counts as unreadable. Causes include a missing file, a reftable ref store, an unborn branch, or a file over its size limit. The gate then ignores the record.
- The gate ignores a record whose `branch` differs from the current branch. Branch names compare exactly, with case kept.
- The gate ignores a record whose `head` differs from the current `HEAD` commit. Commit IDs compare in lower case.
- An ignored record admits nothing. The write then gets the same block as with no record. The reason adds one line that says why the gate ignored the record.
- The git-state reader is artifact `path-rules-readGitState`. Each hook process reads the record and the git state at most once per root.

### Gate behaviour

- `evaluateWrite` keeps its check order and adds one step. When `plan/current/design.md` is absent, it reads the scope record before it returns `NO_DESIGN_REASON`.
- A valid, current record admits a root-relative path that matches one of its listed paths.
- A valid, current record blocks every other path with exit 2. The reason names the path and `plan/.fast-path-scope`, and says to add the path to the record or take the Change Pipeline.
- When `plan/current/design.md` exists, the gate ignores the scope record and applies the design.
- The `plan/current/**` sentinel check still runs first. A scope record never admits a `plan/current/` write without the sentinel.
- `path-rules.mjs` exports a constant, `FAST_PATH_ENFORCEMENT_PATHS`, as artifact `path-rules-fast-path-enforcement-paths`. It lists these entries:
  - `planifest-framework/hooks/`
  - `planifest-framework/scripts/`
  - `planifest-framework/standards/autonomous-run-standards.md`
  - any path whose last segment is `setup.sh` or `setup.ps1`
  - any path that holds the segment pair `hooks/enforcement/`, which covers every installed hook folder such as `.claude/hooks/enforcement/`
  - `.git/` and everything below it
- A scope record never admits a path that matches `FAST_PATH_ENFORCEMENT_PATHS`, whatever it lists. The gate blocks that write with exit 2. The reason names the path and 0000033 ADR-009, and says to use the Change or Feature Pipeline.
- The shell-write guard honours the record through `evaluateWrite`, with no copy of the rules. A shell write to a listed path passes, and a shell write to an unlisted or enforcement path blocks.

### Fast Path workflow text

- `planifest-framework/workflows/fast-path.md` adds a step before "Implement the fix directly". In that step, the agent writes `plan/.fast-path-scope` with **Write**.
- The agent fills `branch` from `git rev-parse --abbrev-ref HEAD`, writing `(detached)` when that prints `HEAD`. It fills `head` from `git rev-parse HEAD`.
- The agent lists every path the change writes. That includes the `component.yml` that step 4 bumps, when one covers the change. `plan/changelog/` needs no entry, because `plan/` is always permitted.
- The agent writes a new record over any record already there. A stale record from an interrupted Fast Path therefore never carries into a new change.
- If the agent commits or switches branch mid-change, it rewrites the record before its next write.
- If a target matches an enforcement path, the workflow stops and routes the change to the Change or Feature Pipeline. The prerequisites list and `FAST_PATH_ENFORCEMENT_PATHS` name the same entries.
- Step 6 removes the record with `rm -f plan/.fast-path-scope` before `git commit`, as the ship agent removes `plan/.orchestrator-active`. No commit holds the record.
- The "What is NOT touched" list stays as it is. Fast Path still admits changes with no `src/` target (0000033 ADR-009 and 0000062).

### Tests

- A new suite, `planifest-framework/tests/test-0000035-req-001-fast-path-scope-record.sh`, builds a git fixture under `mktemp -d` with no `plan/current/design.md`. It writes the record from the fixture's real branch and `HEAD`.
- The suite runs `gate-write.mjs` and `shell-write-guard.mjs` on the same targets and checks the exit code and stderr of each.
- The suite covers these cases:
  - a stale branch
  - a stale `HEAD`
  - a worktree whose `.git` is a file
  - a ref held only in `packed-refs`
  - each invalid-record case in the Input Validation section
- A source check asserts that every enforcement path in the `fast-path.md` prerequisites appears in `FAST_PATH_ENFORCEMENT_PATHS`.

### Non-functional

- Each hook call stays under 500 ms with a valid record and a `packed-refs` file of 10,000 lines.
- `path-rules.mjs` uses Node built-in modules only and spawns no process. A suite source check asserts that it imports no `node:child_process`.

## Acceptance Criteria

- [ ] With a current scope record listing `planifest-overrides/instructions/x.md` and no design, a **Write** to that path exits 0. A **Write** to `planifest-overrides/instructions/y.md` exits 2, and the shell-write guard gives the same two results.
- [ ] A record that lists `planifest-framework/` or `planifest-framework/hooks/` never admits a write to `planifest-framework/hooks/enforcement/gate-write.mjs`, which exits 2. A record whose `branch` or `head` no longer matches admits nothing.
- [ ] `workflows/fast-path.md` writes the record, with branch and `HEAD`, before the first change and removes it in step 6 before `git commit`. Its enforcement list matches `FAST_PATH_ENFORCEMENT_PATHS`.

## Dependencies

- All five requirements in this stream change `planifest-framework/hooks/enforcement/path-rules.mjs`. One agent builds them in sequence, so no two edit the file at once.
- req-001 extends `evaluateWrite`. It works on the root-relative path that req-003 produces, so its link cases follow req-003's rules. It needs no other artifact from req-003.
- req-001 reads the root from `resolveRoot`, which req-004 and req-006 change. Its tests use a fixture with a normal cwd, so they don't depend on those changes.
- `planifest-framework/workflows/fast-path.md` (edited here).
- 0000033 ADR-009 (enforcement paths) and 0000003-ADR-005 (fail-open on unexpected errors).

## Input Validation

The scope record and the git files are file content that any agent can write, so the gate treats them as untrusted.

- [ ] Input source: `plan/.fast-path-scope` under the repository root.
- [ ] Input source: the git files `.git` (as a file), `HEAD`, `commondir`, loose ref files, and `packed-refs`.
- [ ] maximum length: the record is at most 16 KiB. A larger record counts as invalid, and the gate checks the size with `statSync` before it reads.
- [ ] maximum length: each git file except `packed-refs` is at most 4 KiB. `packed-refs` is at most 4 MiB. A larger file makes the git state unreadable.
- [ ] Allowed character pattern for `branch`: `[A-Za-z0-9._/-]`, 1 to 255 characters, with no `..` and no leading `-`. The literal `(detached)` is the only other value.
- [ ] Allowed character pattern for `head`: `[0-9a-fA-F]`, exactly 40 or 64 characters.
- [ ] Allowed character pattern for each path: `[A-Za-z0-9._@+ /-]`, 1 to 512 characters. A path can't start with `/` or a drive letter, and can't hold a backslash. It can't hold an empty, `.`, or `..` segment, and can't name the root itself.
- [ ] The record lists at most 64 paths.
- [ ] Failure behaviour: any rule break makes the whole record invalid. The gate never strips characters to repair a record. An invalid record admits nothing, and the write gets the no-record block with exit 2.
- [ ] Logging policy: the block reason names the line number and the broken rule. It never echoes a raw value from the record or the git files.
