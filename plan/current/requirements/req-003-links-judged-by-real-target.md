---
title: "Requirement: req-003 - links-judged-by-real-target"
summary: "The write gates resolve a target through symbolic links one segment at a time, so a link under plan/ can't carry a write into src/."
status: "draft"
version: "0.1.0"
---
# Requirement: req-003 - links-judged-by-real-target

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Source:** US-003 (backlog 0000106 and 0000117)
**Priority:** must-have

## User Story

As the human on the loop, I rely on the gates to judge where a write lands after symbolic links resolve, so that a link under `plan/` can't carry a write into `src/`.

## Functional Requirements

### Segment-by-segment resolution

- `path-rules.mjs` exports `resolveTarget(root, cwd, target)` as artifact `path-rules-resolveTarget-links`. It returns one of three results:
  - `{ status: "inside", relPath }` for a target inside the root, with `relPath` in forward slashes and its original case
  - `{ status: "outside" }` for a target outside the root
  - `{ status: "unresolvable", reason }` for a path inside the root that it can't resolve
- `resolveTarget` resolves a relative target against `cwd`, and `cwd` itself goes through the same resolution.
- It walks the absolute path one segment at a time from the file-system root. It calls `lstatSync` on each existing segment.
- If a segment is a symbolic link, it reads the link with `readlinkSync` and puts the link text in place of that segment. It resolves a relative link text against the real folder that holds the link. An absolute link text restarts the walk at its own root.
- A `..` segment moves to the real parent of the real path resolved so far. `resolveTarget` never collapses `..` as text before it resolves the segments to its left. This matches how the kernel resolves a shell redirect or a shell command's path.
- The **Write** and **Edit** tools place a target another way. They collapse `..` as text against `cwd` first, and only then does the system follow links (P5 finding G-S01). With `docs/L` a link to `../plan/x/y`, `docs/L/../../src/a.js` lands in `src/a.js`.
- `path-rules.mjs` exports `resolveTargetText(root, cwd, target)`, which collapses `..` as text first and then resolves the result through links. It returns the same three results as `resolveTarget`.
- `path-rules.mjs` exports `resolveTargetBoth(root, cwd, target)`. It returns the physical and the text placements, or one entry when both land on the same path.
- `judgeWrite`, and so `gate-write.mjs`, judges each placement. It blocks if either verdict blocks.
- `shell-write-guard.mjs` keeps the physical walk only, because the kernel resolves a shell path physically.
- If `lstatSync` reports `ENOENT` or `ENOTDIR`, the segment and every segment after it are missing. `resolveTarget` appends the missing segments to the real path so far and collapses any `..` among them as text.
- A dangling link resolves to its target path. The gate judges that target, not the link path.
- The hop limit is 40 links per call, the Linux `MAXSYMLINKS` value. A link that leads back to a path already in its own chain counts as a loop.
- `toRootRelative` keeps its signature and returns `relPath` for an `inside` result and `null` otherwise. Existing callers keep working.
- `judgeWrite`, `gate-write.mjs`, and `shell-write-guard.mjs` call `resolveTarget` in place of `toRootRelative`.
- The existing too-long check still runs first. A path over `MAX_PATH_CHARS` or `MAX_PATH_SEGMENTS` keeps its warn-and-allow result (0000032 finding F7).

### Fail-closed line

- A link loop, a chain past the hop limit, or any other resolution error gives an `unresolvable` result in two cases:
  - the target, resolved against `cwd` as text, lies inside the root
  - the real path reached before the error lies inside the root
- Other resolution errors include `EACCES`, `EIO`, and an operating-system `ELOOP`.
- An `unresolvable` result blocks with exit 2 in `gate-write.mjs` and in `shell-write-guard.mjs`. The reason names the target and the cause, such as "link loop", "more than 40 links", or the error code. It goes to stderr.
- If both paths in the two cases above lie outside the root, the result is `outside` and the write passes.
- Errors outside path resolution keep their fail-open behaviour (0000003 ADR 005). Examples are bad JSON on stdin and a throw in the hook's own code.

### Tests

- A new suite, `planifest-framework/tests/test-0000035-req-003-links-judged-by-real-target.sh`, builds a git fixture under `mktemp -d` with no design. It runs both `gate-write.mjs` and `shell-write-guard.mjs` on each case.
- The suite covers these cases:
  - a dangling link under `plan/` whose target is in `src/`
  - `plan/l/../../../src/x.js` with `plan/l` a link deeper into the repo
  - a link loop under `plan/`
  - a chain of 41 links
  - a chain of 10 links into `plan/`, which passes
  - a link under `plan/` to a file outside the root, which passes
  - `docs/L/../../src/a.js` with `docs/L` a link to `../plan/x/y`, which `gate-write.mjs` blocks with no design
  - `docs/L/../../.claude/settings.json` under a current scope record, which `gate-write.mjs` blocks as an enforcement path
- The suite skips the link cases with a clear message when the platform can't create symbolic links, such as Windows without developer mode.

### Non-functional

- Each hook call stays under 500 ms on a 10-hop link chain. The suite times one `gate-write.mjs` call and one `shell-write-guard.mjs` call on that chain.
- `path-rules.mjs` and the new code in this requirement use Node built-in modules only and spawn no process.
- The existing `git status` spawn in `ratchet-check.mjs` predates this feature and stays out of this rule. Backlog 0000128 tracks it.

## Acceptance Criteria

- [ ] With no design, a write through a dangling `plan/` link to a `src/` target exits 2. Both `gate-write.mjs` and the shell-write guard give that result.
- [ ] With `plan/l` a link deeper into the repo, both gates judge `plan/l/../../../src/x.js` as `src/x.js`, and it exits 2 with no design.
- [ ] A link loop or a 41-link chain inside the root exits 2 with its cause on stderr. A 10-link chain gets its verdict in under 500 ms per hook call.

## Dependencies

- All six requirements in this stream change `planifest-framework/hooks/enforcement/path-rules.mjs`. One agent builds them in sequence.
- req-005 consumes `path-rules-resolveTarget-links` in `ratchet-check.mjs`. Build req-003 before req-005.
- req-001 and req-009 judge the `relPath` this requirement returns. They need no other artifact from req-003.
- `shell-write-guard.mjs` `judgeOnce` changes to call `resolveTarget` and to block on `unresolvable`.

## Input Validation

- [ ] Input source: link text from `readlinkSync`, which any agent can plant under `plan/`.
- [ ] Allowed character pattern: any text the operating system accepts. `resolveTarget` treats link text as a path and never runs or prints it as code.
- [ ] maximum length: the resolved path keeps the existing `MAX_PATH_CHARS` and `MAX_PATH_SEGMENTS` limits after each substitution. A path past either limit counts as `unresolvable` when it started inside the root.
- [ ] Failure behaviour: an `unresolvable` result blocks with exit 2.
- [ ] Logging policy: the block reason shows the first 80 characters of the target the hook received. It never prints link text.
