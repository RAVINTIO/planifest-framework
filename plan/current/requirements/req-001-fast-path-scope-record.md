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
- Path matching uses the 0000009 ADR 005 normalisation and whole path segments, as `matchesComponentPath` does today. The record has no glob syntax.
- The gate matches each record path against the target's resolved `relPath` from `resolveTarget` (req-003). It never matches the link path the hook received.
- The format is artifact `fast-path-scope-record-format`. `workflows/fast-path.md` shows one complete example of it.

### Record life

- `path-rules.mjs` reads the current branch and `HEAD` commit without a process spawn (0000032 ADR 004). It follows these steps:
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
- A scope record never admits an enforcement path. [Req-009](req-009-fast-path-enforcement-paths.md) owns `FAST_PATH_ENFORCEMENT_PATHS`, its matching, and the rule that the gate checks it before the record.

### Self-authorisation and visibility

- The scope record is self-authorisation. The agent that makes the change also writes the record, and no human step sits between the two.
- The human on the loop accepted this residual risk at P0, when they chose the scope record over a wider allowlist (design.md, "Decisions confirmed at P0", Fast Path authorisation).
- The branch and `HEAD` binding bounds staleness only. It is not a security control, because the agent that writes the record also reads both values.
- Each write the gate admits through the record writes one line to stderr and still exits 0. The line names `plan/.fast-path-scope` and the root-relative path. Both hooks share one text, `[Planifest] Fast Path: admitted '<relPath>' through plan/.fast-path-scope.` (P3 deviation, build log).
- `gate-write.mjs` and `shell-write-guard.mjs` both write this notice for every admitted Fast Path write.
- The notice reaches the agent and the session transcript. Claude Code keeps exit-0 hook output out of the main view, so the human on the loop doesn't see it there.
- The notice stays the control for the agent and the transcript. The human on the loop sees the admitted paths in the Fast Path changelog entry, which lists the record's paths.
- Fast Path step 5 (Log the change) writes a changelog entry that lists every path from the scope record. The `fast-path.md` changelog template gains a field for those paths.
- The notice prints the resolved `relPath`, cut to its first 200 characters. It never prints raw record text.
- Every reason and notice that prints a target path passes it through `shown` in `path-rules.mjs` (P5 finding G-S11). `shown` escapes each control character as `\n`, `\r`, `\t`, or `\xNN`, so a target that holds a newline can't forge a second line of hook output.
- `shown` also escapes each Unicode format character and the line and paragraph separators U+2028 and U+2029 (P5 re-review finding G-N3). Format characters include the bidirectional controls U+202A to U+202E and U+2066 to U+2069. A character above U+00FF prints as `\u{XXXX}`, so it can't reorder or hide text on display.
- The "not listed in the Fast Path scope record" and "not covered by the confirmed design" reasons cut the escaped path to 80 characters, as the resolution reasons do.
- The shell-write guard's own lines pass each target and shell word through `shown` too, cut to 80 characters (P5 re-review finding G-N1). That covers these lines:
  - the "Shell write blocked" line
  - the "no literal prefix" warning
  - the "too many to judge" block
  - the "after a cd it can't follow" warning
- The shell-write guard honours the record through `evaluateWrite`, with no copy of the rules. A shell write to a listed path passes, and a shell write to an unlisted or enforcement path blocks.

### Fast Path workflow text

- `planifest-framework/workflows/fast-path.md` adds a named sub-step, **Write the scope record**, at the end of step 1, before "Implement the fix directly". In that sub-step, the agent writes `plan/.fast-path-scope` with **Write**. Steps 5 and 6 keep their numbers (P3 deviation, build log).
- The agent fills `branch` from `git rev-parse --abbrev-ref HEAD`, writing `(detached)` when that prints `HEAD`. It fills `head` from `git rev-parse HEAD`.
- The agent lists every path the change writes. That includes the `component.yml` that step 4 bumps, when one covers the change. `plan/changelog/` needs no entry, because `plan/` is always permitted.
- The agent writes a new record over any record already there. A stale record from an interrupted Fast Path therefore never carries into a new change.
- If the agent commits or switches branch mid-change, it rewrites the record before its next write.
- Req-009 owns the workflow's enforcement-path stop and its prerequisites list.
- Step 6 removes the record with `rm -f plan/.fast-path-scope` before `git commit`, as the ship agent removes `plan/.orchestrator-active`. No commit holds the record.
- The "What is NOT touched" list stays as it is. Fast Path still admits changes with no `src/` target (0000033 ADR 009 and 0000062).
- The root `.gitignore` gains a `plan/.fast-path-scope` line, so a mid-change `git add -A` can't commit the record. `.gitignore` is always permitted.
- Step 6 uses `rm -f` on the marker, as the ship agent skill does for `plan/.orchestrator-active` (`planifest-framework/skills/planifest-ship-agent/SKILL.md`, "Clear session markers"). Hard Limit 8 covers code and project files and gives no rule for a git-ignored session marker. The shell-write guard passes the `rm`, because the gates always permit `plan/`.

### Tests

- A new suite, `planifest-framework/tests/test-0000035-req-001-fast-path-scope-record.sh`, builds a git fixture under `mktemp -d` with no `plan/current/design.md`. It writes the record from the fixture's real branch and `HEAD`.
- The suite runs `gate-write.mjs` and `shell-write-guard.mjs` on the same targets and checks the exit code and stderr of each.
- The suite covers these cases:
  - a stale branch
  - a stale `HEAD`
  - a worktree whose `.git` is a file
  - a ref held only in `packed-refs`
  - each invalid-record case in the Input Validation section
  - an admitted write, where stderr holds the notice that names the record and the path
- The enforcement-path cases and the `fast-path.md` parity check live in the req-009 suite.
- A source check asserts that the root `.gitignore` holds a `plan/.fast-path-scope` line.
- A source check asserts that the `fast-path.md` step 5 changelog template holds the field for the record's paths.

### Non-functional

- Each hook call stays under 500 ms with a valid record and a `packed-refs` file of 10,000 lines.
- `path-rules.mjs` and the new code in this requirement use Node built-in modules only and spawn no process. A suite source check asserts that `path-rules.mjs` imports no `node:child_process`.
- The existing `git status` spawn in `ratchet-check.mjs` predates this feature and stays out of this rule. Backlog 0000128 tracks it.

## Acceptance Criteria

- [ ] With a current scope record listing `planifest-overrides/instructions/x.md` and no design, a **Write** to that path exits 0. A **Write** to `planifest-overrides/instructions/y.md` exits 2, and the shell-write guard gives the same two results.
- [ ] A record whose `branch` or `head` no longer matches admits nothing.
- [ ] `workflows/fast-path.md` writes the record, with branch and `HEAD`, before the first change and removes it in step 6 before `git commit`.

## Dependencies

- All six requirements in this stream change `planifest-framework/hooks/enforcement/path-rules.mjs`. One agent builds them in sequence, so no two edit the file at once.
- [Req-009](req-009-fast-path-enforcement-paths.md) adds the enforcement check that runs before this record. Stream 01 builds it right after this requirement.
- req-001 extends `evaluateWrite`. It works on the root-relative path that req-003 produces, so its link cases follow req-003's rules. It needs no other artifact from req-003.
- req-001 reads the root from `resolveRoot`, which req-004 and req-006 change. Its tests use a fixture with a normal cwd, so they don't depend on those changes.
- `planifest-framework/workflows/fast-path.md` (edited here).
- 0000033 ADR 009 (no `src/` target) and 0000003 ADR 005 (fail-open on unexpected errors).
- The root `.gitignore` (one line added).

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
