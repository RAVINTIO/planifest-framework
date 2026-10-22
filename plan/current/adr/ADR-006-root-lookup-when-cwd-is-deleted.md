---
title: "ADR 006: Root lookup from CLAUDE_PROJECT_DIR, then the nearest existing parent"
summary: "When the working directory no longer exists, resolveRoot checks CLAUDE_PROJECT_DIR first and then walks from the nearest existing parent. A resolution error inside the CLAUDE_PROJECT_DIR root blocks. This supersedes one 0000032 req-006 fail-open case."
status: "accepted"
version: "0.1.0"
---
# ADR-006 - Root lookup from CLAUDE_PROJECT_DIR, then the nearest existing parent

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

`resolveRoot` walks up from the working directory to find a root marker (0000032 ADR 004). If the agent deletes its own working directory, the walk finds nothing. The gate then fails open on a write into `src/` (backlog 0000107).

0000032 req-006 made this fail-open case explicit. Its suite asserts that a `cwd` that doesn't exist exits 0.

Two sources can name the root instead:

- `CLAUDE_PROJECT_DIR`, which Claude Code is expected to pass to hooks. Backlog 0000118 has not checked this live (assumption A-001).
- the nearest folder above the deleted one that still exists

The nearest existing parent can sit above the repo root when the variable is unset (risk R-012).

## Decision

- **Order:** `resolveRoot(cwd)` checks `CLAUDE_PROJECT_DIR` first. If the variable names a folder and the walk from it finds a marker, that root wins.
- **Fallback:** If `cwd` is not a folder, the walk steps up with `dirname` to the nearest existing folder. It starts the marker walk from that folder's real path. If no marker turns up, that folder is the root, as 0000032 sets when no marker exists.
- **Missing versus unreadable:** The walk uses `statSync`, not `existsSync`. Only `ENOENT` and `ENOTDIR` count as missing. Any other error, such as `EACCES`, stops the walk at that path.
- **Fail-closed line:** If `realpathSync` fails where the walk stopped, the hook treats it as a resolution error. It blocks with exit 2 when the target lies inside the `CLAUDE_PROJECT_DIR` root, and names the error code. Otherwise the hook fails open, as 0000003 ADR 005 sets.
- **Hook cwd:** Each hook uses the stdin `cwd` field first. If that is absent and `process.cwd()` throws, it uses `CLAUDE_PROJECT_DIR`. If that is unset too, it passes.
- **Relative targets:** A relative target from a deleted `cwd` resolves against the `cwd` text through the same walk.
- **Superseded case:** The 0000032 req-006 assertion for a missing `cwd` changes to expect exit 2 for `src/a.js`. The P3 agent logs this as a deliberate deviation.
- **Contract:** `resolveRoot` returns `null` only for a `cwd` that is not a non-empty string, and never throws. The changed lookup is artifact `path-rules-resolveRoot-deleted-cwd`.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep the 0000032 fail-open case | No change to an existing suite | A deleted `cwd` lets any write into `src/` pass | The bug this story fixes |
| Block every write when `cwd` is gone | Simplest fail-closed rule | Blocks writes outside any repo, which 0000032 req-006 allows | Too broad, breaks the outside-repository pass |
| Nearest existing parent first, then `CLAUDE_PROJECT_DIR` | Works with no environment variable | A parent above the repo becomes the root, and the `src/` write passes (R-012) | The variable names the project exactly, so it goes first |
| Use `existsSync` in the walk | Shorter code | It returns `false` for `EACCES`, so the walk steps past an unreadable folder and may leave the root | Hides a resolution error that must block |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `resolveRoot` and the hook `cwd` fallback change. One assertion in `test-0000032-req-006-outside-repository-pass.sh` changes. The req-004 suite covers the variable set and unset, no marker above, and a `chmod 000` stop. |

## Consequences

**Positive:**
- A deleted working directory no longer opens the gate on `src/`.
- The walk tells a missing folder from an unreadable one, so a permission error can't move the root.

**Negative:**
- One 0000032 behaviour changes, and its suite assertion with it.
- With the variable unset and no marker above, the root may still sit above the repo, and a `src/` write passes there.

**Risks:**
- Claude Code doesn't pass `CLAUDE_PROJECT_DIR` to hooks (A-001). The fix then rests on the nearest-parent walk only. Backlog 0000118 tracks the live check.
- Other tools don't set the variable. They get the nearest-parent walk only.

## Related ADRs

- ADR-005 - related-to. Both apply the same fail-closed line.
- ADR-007 - related-to. `ratchet-check` consumes the changed `resolveRoot`.
- ADR-008 - related-to. Both walks call `markedRoot`, which ADR-008 changes.
- 0000032 ADR 004 (shared path rules and repository root) - extends
- 0000003 ADR 005 (exit zero failure mode) - related-to

## Supersedes

- None. It changes one 0000032 req-006 test case, not an ADR.

## Superseded By

- None
