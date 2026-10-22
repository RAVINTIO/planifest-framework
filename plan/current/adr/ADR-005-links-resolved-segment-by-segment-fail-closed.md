---
title: "ADR 005: Resolve links segment by segment and fail closed inside the root"
summary: "resolveTarget walks the target one segment at a time through symbolic links, with a 40-hop limit. A loop, an over-limit chain, or any resolution error for a path inside the root blocks with exit 2. Other errors still fail open."
status: "accepted"
version: "0.1.0"
---
# ADR-005 - Resolve links segment by segment and fail closed inside the root

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

The gates judge a write by the text of its path. A link under `plan/` that points into `src/` therefore carries a write past the gate (backlog 0000106 and 0000117). Three variants matter:

- a dangling link, whose target doesn't exist yet, so `realpathSync` fails on it
- a `..` after a link, where text collapse gives a different path from the one the operating system writes
- a link loop or a very long chain

Hooks fail open on unexpected errors (0000003 ADR 005). A link loop would then pass any write. The design draws a fail-closed line: a resolution error for a path inside the root blocks, and every other error still fails open.

## Decision

- **Function:** `path-rules.mjs` exports `resolveTarget(root, cwd, target)`, artifact `path-rules-resolveTarget-links`. It returns `inside` with `relPath`, `outside`, or `unresolvable` with a reason.
- **Walk:** It walks the absolute path from the file-system root, one segment at a time:
  - It calls `lstatSync` on each existing segment.
  - A link segment gets the link text in its place. Relative text resolves against the link's real folder.
  - A `..` moves to the real parent of the path resolved so far. It never collapses as text before the segments to its left resolve.
  - From the first `ENOENT` or `ENOTDIR`, the remaining segments append as text. A dangling link therefore resolves to its target.
- **Two placements (P5 finding G-S01):** The physical walk matches the kernel, which resolves a shell path. The **Write** and **Edit** tools collapse `..` as text first, and the system then follows the links that remain. So the two can land on different files.
  - `resolveTargetText` collapses `..` as text against `cwd`, then resolves the result through links. A target below `cwd` resolves from the real path of `cwd`, so a link in that path isn't a hop (P5 deviation, build log).
  - `resolveTargetBoth` returns both placements. `judgeWrite` and `ratchet-check` judge each one and block if either verdict blocks.
  - If both placements pass, `judgeWrite` prints the notice and the warning from each one (P5 re-review finding G-N2). The scope record's notice therefore never drops out.
  - `shell-write-guard.mjs` keeps the physical walk only.
- **Hop limit:** 40 links per call, the Linux `MAXSYMLINKS` value. A link that returns to a path in its own chain counts as a loop.
- **Fail-closed line:** A loop, a chain past 40, or an error such as `EACCES`, `EIO`, or `ELOOP` gives `unresolvable` in two cases. Either the target as text lies inside the root, or the real path reached before the error does. Both gates block `unresolvable` with exit 2 and name the cause on stderr.
- **Outside the line:** If both paths lie outside the root, the result is `outside` and the write passes. Errors outside path resolution keep exit 0 (0000003 ADR 005).
- **Callers:** `shell-write-guard.mjs` calls `resolveTarget`. `judgeWrite`, and so `gate-write.mjs`, calls `resolveTargetBoth`. `toRootRelative` keeps its signature for existing callers.
- **Existing limit first:** The `MAX_PATH_CHARS` and `MAX_PATH_SEGMENTS` check still runs first and keeps its warn-and-allow result (0000032 finding F7). Both gates check the limit before they call `resolveTarget`. If a caller passes a path too long to judge, `resolveTarget` returns `outside`, which keeps the same warn-and-allow result (P3 deviation, build log). After each link substitution, a path past either limit counts as `unresolvable` when it started inside the root.
- **Logging:** The block reason shows the first 80 characters of the target the hook received. It never prints link text.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| `realpathSync` on the whole target | One call, short code | Fails on a dangling link and on any missing segment, so the gate learns nothing about the real target | Misses the dangling-link case in 0000106 |
| `realpathSync` on the nearest existing parent, then append | Handles missing files | A missing segment after a dangling link, or a `..` after a link, still gives the wrong path | Misses the `..` case in 0000117 |
| Block every write whose path holds a link | Short rule | Blocks healthy links that projects use, such as a linked `docs/` folder | Too broad, raises R-010 |
| A higher hop limit, or none | Fewer false blocks | A loop runs until some other limit stops it. Latency grows. | 40 matches the kernel limit, so no real path needs more |
| Fail open on every resolution error | Keeps 0000003 ADR 005 as written | A planted loop or an unreadable folder passes any write into `src/` | Breaks the confirmed fail-closed line |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `path-rules.mjs` gains `resolveTarget`. Both write gates call it and block on `unresolvable`. The req-003 suite covers a dangling link, `..` after a link, a loop, 41 links, a 10-link pass, and a link out of the root. |

## Consequences

**Positive:**
- The gates judge the path the operating system writes, so a link can't carry a write into `src/`.
- A resolution failure inside the root blocks with a named cause, not a silent pass.

**Negative:**
- Each hook call adds one `lstatSync` per segment and one `readlinkSync` per link (risk R-001). The 500 ms target on a 10-hop chain bounds it.
- A healthy write can block when a permission error stops the walk inside the root (risk R-010).

**Risks:**
- The fail-closed branch catches an error outside resolution and turns a fail-open case into a block (risk R-011). The suites cover both sides of the line.
- Link behaviour differs on Windows without developer mode. The suite skips link cases there with a message, so CI on that runner proves less.

## Related ADRs

- ADR-001 - depends-on. The walk uses Node built-ins only.
- ADR-002 - related-to. The scope record matches the `relPath` this function returns.
- ADR-006 - related-to. Both apply the same fail-closed line.
- ADR-007 - related-to. `ratchet-check` consumes `resolveTarget`.
- 0000003 ADR 005 (exit zero failure mode) - related-to. This ADR narrows it for path resolution inside the root.
- 0000032 ADR 004 (shared path rules and repository root) - extends

## Supersedes

- None

## Superseded By

- None
