---
title: "ADR 008: Distrust root markers under always-permitted names"
summary: "markedRoot ignores a .git or planifest-framework marker when any segment below a higher marked folder matches an always-permitted file name. The walk then goes on to the next trusted marker. Nested repos under other names stay roots."
status: "accepted"
version: "0.1.0"
---
# ADR-008 - Distrust root markers under always-permitted names

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

`markedRoot` already distrusts a marked folder whose first segment below a higher marked folder is `plan` or `docs` (0000032 ADR 004). An agent can still plant a marker and move it:

1. `mkdir -p plan/w/.git` passes, because `plan/` is always permitted.
2. `mv plan/w src/claude.md` gives `src/claude.md/.git`.
3. With `cwd` at `src/claude.md`, the walk takes that folder as the root. A write to `../other/x.js` now lies outside the root and passes (backlog 0000114).

The name `claude.md` matters. Its basename is in `ALWAYS_PERMITTED_FILES`, so the folder's own path text looks permitted.

A real nested repo, such as a git submodule at `vendor/lib/`, must stay its own root (risk R-009).

## Decision

- **Rule:** `markedRoot` distrusts a marked folder when any segment of its path below a higher marked folder matches an entry in `ALWAYS_PERMITTED_FILES`. The check includes the candidate folder's own name.
- **Existing rule kept:** The `plan` and `docs` first-segment rule stays.
- **Normalisation:** The comparison uses the 0000009 ADR 005 form, so `CLAUDE.md` and `claude.md` both match.
- **Both markers, both walks:** The rule covers `planifest-framework/` and `.git` as a folder or a file. It applies to the walk from `CLAUDE_PROJECT_DIR` and the walk from `cwd`.
- **Walk continues:** A distrusted marker never ends the walk. The walk goes on to the next trusted marked folder above.
- **Coupling:** The rule reads `ALWAYS_PERMITTED_FILES` directly. A later change to that list changes this rule too.
- **Artifact:** `path-rules-markedRoot-basename-distrust`.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Distrust every nested marker | Closes all planted-root tricks | A submodule at `vendor/lib/` stops being its own root, which breaks 0000032 behaviour | Fails R-009 |
| Take the outermost marker as the root | One rule, no name list | Same submodule break. A workspace that holds several repos gets one root for all. | Changes root semantics for every project |
| Block `mv` and `mkdir .git` in the shell guard | Stops the plant at its source | The shell guard is a heuristic, and parser work waits on backlog 0000119. **Write** can't create a folder, so the hole is in the shell only. | Out of scope, and a parser rule is easier to evade |
| Check only the candidate folder's own name | Smaller check | A marker at `src/claude.md/inner/.git` passes | Misses deeper plants |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `markedRoot` in `path-rules.mjs` gains the name check. The req-006 suite covers `claude.md`, `pause.md`, a planted `planifest-framework/`, and a genuine `vendor/lib/.git`. |

## Consequences

**Positive:**
- A marker planted under `plan/` and moved under an always-permitted name can't move the root.
- Real nested repos under ordinary names keep working.

**Negative:**
- A genuine repo whose path holds a segment such as `agents.md` or `pause.md` loses root status inside a parent repo. That naming is rare.
- The marker rule now depends on the always-permitted list, so editing that list has a second effect.

**Risks:**
- An agent plants a marker and moves it under an ordinary name, such as `src/lib/.git`. That folder then becomes a root. The plant still needs a shell move, which the shell guard parser work (0000119) addresses later.

## Related ADRs

- ADR-001 - depends-on. The rule lives in `path-rules.mjs`.
- ADR-006 - related-to. Both walks in the changed `resolveRoot` call `markedRoot`.
- ADR-007 - related-to. The ratchet gains this rule through `resolveRoot`.
- 0000032 ADR 004 (shared path rules and repository root) - extends
- 0000009 ADR 005 (path normalisation) - depends-on

## Supersedes

- None

## Superseded By

- None
