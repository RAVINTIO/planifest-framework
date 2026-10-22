---
title: "ADR 003: The always-permitted file-name shortcut skips enforcement paths"
summary: "evaluateWrite admits an always-permitted file name at step 1 only when isEnforcementPath is false. Such a name inside an enforcement path takes the design or scope route. The plan/ and docs/ prefix shortcut stays as it is."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - The always-permitted file-name shortcut skips enforcement paths

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

Step 1 of `evaluateWrite` returns `{ allowed: true }` when `isAlwaysPermitted(relPath)` holds. That function holds in two cases:

- the last segment is in `ALWAYS_PERMITTED_FILES`, such as `CLAUDE.md` or `AGENTS.md`
- the path starts with `plan/` or `docs/`

`isEnforcementPath` runs only inside `scopeVerdict`, which runs only after step 1. A write to `planifest-framework/hooks/enforcement/CLAUDE.md` therefore passes with or without a design and never meets the enforcement list (backlog 0000159).

0000033 ADR 009 says Fast Path never admits an enforcement path, and 0000035 ADR 004 made that list concrete. A file under `hooks/enforcement/` may not run as code, but a tool can load a `CLAUDE.md` or `AGENTS.md` there as instructions. An agent could then write guidance that steers later sessions around the gate.

req-009 serves US-009. Risk R-007 records that the change blocks writes that pass today, and R-008 records that it must not weaken an existing check.

## Decision

- **Condition:** The file-name shortcut at step 1 applies only when `isEnforcementPath(relPath)` is false.
- **Normal route:** An always-permitted name inside an enforcement path goes on to the `design.md` step:
  - With a regular `design.md`, the component-path check judges it.
  - With no design, `scopeVerdict` judges it. The enforcement-path block then applies whenever a scope record exists (0000035 ADR 004).
- **Prefix shortcut unchanged:** The `plan/` and `docs/` prefix shortcut keeps its current behaviour. US-009 and backlog 0000159 name only the file-name shortcut. The planning paths must stay writable before P0 completes.
- **Sentinel check unchanged:** The sentinel step keeps its file-name exemption. A path below `plan/current/` still meets the `plan/` prefix shortcut, so its verdict stays as before.
- **One list:** Matching uses `isEnforcementPath` as it stands, with its case and compatibility folding. The gate keeps no second copy of the list.
- **Both gates:** `shell-write-guard.mjs` calls `evaluateWrite`, so it gains the rule with no change of its own.
- **Comment:** The comment block above `evaluateWrite` states the new condition on step 1.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Skip the whole of `isAlwaysPermitted`, prefix shortcut included, for enforcement paths | One rule for both shortcuts | A `**/hooks/enforcement/` entry can match below `plan/` or `docs/`. Blocking those would stop plan writes before P0 completes, which the sentinel design relies on. | Widens the change past US-009 with no threat named for the prefix case |
| Block every always-permitted name inside an enforcement path outright | Shortest code, no design lookup | A confirmed design that covers `planifest-framework/` could no longer admit `hooks/enforcement/CLAUDE.md`. Framework work on those docs would need a gate bypass. | The normal route already gives the right answer, including the admit case the suite checks |
| Remove `CLAUDE.md` and `AGENTS.md` from `ALWAYS_PERMITTED_FILES` | Closes the gap everywhere | Boot-file edits in every component folder would need a design entry. That breaks P0, where agents write these files before any design exists. | Changes behaviour for paths outside the enforcement list, which req-009 keeps |
| Keep a separate list of protected folders for the shortcut | No dependency on the Fast Path list | Two lists drift. 0000035 ADR 004 already guards set equality for one list. | A second copy is the defect class this feature avoids |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Step 1 of `evaluateWrite` gains the `isEnforcementPath` condition. Both write gates inherit it. The req-009 suite covers three enforcement targets, a case variant, and one path outside the list, in four fixture states. |

## Consequences

**Positive:**
- A permitted file name can no longer carry a write into an enforcement folder past the gate.
- Every path outside the enforcement list gets the same verdict as before, so no other project write changes.

**Negative:**
- Editing `planifest-framework/hooks/enforcement/CLAUDE.md` or an installed `AGENTS.md` under `**/hooks/enforcement/` now needs a design that covers the path. A Fast Path typo fix there can no longer land (risk R-007).
- Every write to an always-permitted name now runs `isEnforcementPath`, with its fold and list scan, before it passes.

**Risks:**
- A future entry in `FAST_PATH_ENFORCEMENT_PATHS` that matches a common folder could block boot-file writes across a project. The suite for that list catches doc drift, not breadth.
- An enforcement path below `plan/` or `docs/` still passes through the prefix shortcut. This gap exists today. The entries `**/hooks/enforcement/` and `**/hooks/adapters/` already match below `plan/` and `docs/`, so a write to such a path passes at step 1. This feature leaves it open.

## Related ADRs

- ADR-001 - depends-on. The condition uses Node built-ins only.
- ADR-002 - related-to. Both change `evaluateWrite`, and stream 01 builds them in sequence.
- 0000035 ADR 004 (Fast Path enforcement path list) - depends-on. This ADR applies that list one step earlier.
- 0000033 ADR 009 (Fast Path admits no `src/` changes) - extends. A permitted file name no longer slips past its enforcement path rule.

## Supersedes

- None

## Superseded By

- None
