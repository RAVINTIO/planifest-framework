---
title: "ADR 007: ratchet-check uses the shared root and target rules"
summary: "ratchet-check.mjs imports resolveRoot and resolveTarget from path-rules.mjs, so it finds plan/current/ from any subfolder. It passes on an unresolvable target and leaves that block to gate-write."
status: "accepted"
version: "0.1.0"
---
# ADR-007 - ratchet-check uses the shared root and target rules

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

`ratchet-check.mjs` blocks writes that remove acceptance-criteria or in-scope lines while a loop is active. It finds `plan/current/` under `process.cwd()` and resolves `file_path` with `resolve(filePath)`. If the agent runs from a subfolder such as `src/`, the hook finds no active loop, and a weakening write passes (backlog 0000109).

The write gates already find the root through `resolveRoot` in `path-rules.mjs` (0000032 ADR 004). This feature changes that function (ADR-006, ADR-008) and adds `resolveTarget` (ADR-005).

## Decision

- **Import:** `ratchet-check.mjs` imports `resolveRoot` and `resolveTarget` from `path-rules.mjs`. It keeps no root or path logic of its own.
- **Both placements (P5 finding G-S01):** The hook takes `resolveTarget` through `resolveTargetBoth`, which adds the placement with `..` collapsed as text. It guards any placement that lands on a `plan/current/` artifact.
- **cwd:** It takes the stdin `cwd`, then `process.cwd()`, then `CLAUDE_PROJECT_DIR`, as `gate-write.mjs` does.
- **Paths:** It finds `plan/current/`, `.ratchet-approve`, and `plan/ratchet-audit-log.md` under the shared root. It reads the current file from the root plus `relPath`. Its path checks and exemptions compare the normalised `relPath` (0000009 ADR 005).
- **Pass cases:** It passes with exit 0 when the root is `null`, the target is `outside`, or the target is `unresolvable`. `gate-write.mjs` already blocks an `unresolvable` target, so a second block adds nothing.
- **Unchanged:** The weakening rules, the approval format, the audit log, and the block output stay as they are. The `git status` backstop stays (backlog 0000128).
- **Install:** Setup already copies every `*.mjs` in `hooks/enforcement/`, so the import resolves in every install (0000028 ADR 002).

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Fix the ratchet's own root walk in place | No new import, so a `path-rules.mjs` fault can't reach it | A third copy of the root rules drifts from the gates. It misses the deleted-cwd and planted-marker fixes. | The shared rules are the fix |
| Block on `unresolvable` in the ratchet too | Defence in depth | Two hooks print two block reasons for one write. The ratchet can't judge content it can't read. | `gate-write` already blocks with the cause |
| Fail closed when the ratchet can't find a root | Stricter | Blocks every write outside a Planifest project | The ratchet only governs `plan/current/` |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `ratchet-check.mjs` imports the shared rules and drops its own root logic. The req-005 suite runs from a subfolder and from the root, with and without an approval line. |

## Consequences

**Positive:**
- A weakening write is blocked from any subfolder, and from a deleted `cwd`.
- The ratchet gains the link and planted-marker fixes with no extra code.

**Negative:**
- A fault in `path-rules.mjs` now reaches the ratchet as well as the write gates (risk R-018).
- On an `unresolvable` target the ratchet itself passes. It depends on `gate-write` being wired for that block.

**Risks:**
- A tool runs the ratchet but not `gate-write`. An `unresolvable` write into `plan/current/` then passes the ratchet. Every supported tool wires both hooks, so the design accepts this.

## Related ADRs

- ADR-001 - depends-on. The rules live in one module.
- ADR-005 - depends-on. It consumes `resolveTarget`.
- ADR-006 - depends-on. It consumes the changed `resolveRoot`.
- ADR-008 - depends-on. It gains the marker rule through `resolveRoot`.
- 0000032 ADR 004 (shared path rules and repository root) - extends
- 0000028 ADR 002 (shared module placement and install topology) - depends-on

## Supersedes

- None

## Superseded By

- None
