---
title: "Orchestrator reference: Adoption Modes"
summary: "The Adoption Modes section of the orchestrator skill. The orchestrator reads it in full at the start of P0."
---
Owner: `ravintio-framework/skills/ravintio-orchestrator/SKILL.md`. Read this file in full at the start of P0.

## Adoption Modes

The coaching conversation in Phase 0 and the pipeline phases are the same regardless of mode. What differs is the starting point and the version suggestion.

### Structured Discovery Pass (all modes)

Every adoption mode performs a structured discovery pass at the start of P0, before any coaching question is asked. The findings are written to `plan/current/discovery.md` (see `templates/discovery.template.md`), a standalone artifact, deliberately separate from `build-log.md` (the Q&A audit trail) and `design.md` (the curated, human-confirmed output).

**Shared header (all four modes):** adoption-mode detection result + the signal that produced it, git pre-flight findings, skills-inbox scan result.

**Record samples (all modes):** if a design depends on existing records, discovery samples recent rows of each source, such as a log, a database table, or a config history. It states how often each value the design relies on is usable, in `## Record Samples`. The sample is read-only: discovery never writes to the records it samples. A design that reads no existing records gets `None`.

**Lifecycle:** `discovery.md` is fresh every pipeline run. It is archived to `plan/_archive/{feature-id}-{YYYY-MM-DD}/` at P7 alongside `build-log.md` and `design.md`, and a brand-new copy is created at the next P0. Prior runs' discovery is read from `plan/_archive/` and `docs/`, never from a leftover `discovery.md`.

**Partial failure:** if a discovery signal cannot be read (malformed `package.json`, corrupted archive entry, broken `external-versioning.md`, failed git pre-flight), the affected section states plainly that it could not be determined, and coaching proceeds on the rest: never a hard block. Fail-open governs whether P0 continues, not whether the human is told what happened.

**Cross-session:** on resume within a still-in-progress pipeline run, the existing `discovery.md` is trusted as-is; do not re-run the pass. If the file is missing or incomplete (expected sections for the mode absent), regenerate it fresh rather than patching; discovery is a read-only scan with no human dialogue to preserve.

### Mode Taxonomy

Each mode's discovery-pass field shape is defined in `discovery.template.md` (one subsection per mode): this taxonomy states only the detection signal and the version/coaching logic specific to the orchestrator.

**Greenfield**: No prior codebase, no archive, no overrides. Starting from zero. Writes to `discovery.md`: the `0.1.0` version baseline; "nothing found yet" is itself the defined content, not an error.
- Version starts at `0.1.0`
- Coach from the Feature Brief directly

**Standard Iterative**: This system has been through at least one RAVINTIO Framework pipeline run. `plan/_archive/` or `docs/about.md` exists. Writes to `discovery.md` per its own template subsection.
- Read `docs/about.md` for current version; suggest minor bump for Feature Pipeline, patch for Change Pipeline
- Prior decisions are constraints unless an ADR supersedes them

**Retrofit**: Source code exists but has never been through a RAVINTIO pipeline run. No archive, no `docs/about.md`. Read other markers (version strings in `package.json`, `go.mod`, git tags, README) and suggest a version reflecting the project's current maturity; human confirms. The structured codebase scan that populates `discovery.md` is defined in `workflows/retrofit.md`; run it now.

**External Anchor**: An external system or organisation dictates the version. `ravintio-overrides/instructions/external-versioning.md` exists and describes the constraint. Writes to `discovery.md`: the full constraint, plus whichever underlying mode's content applies to what else is present (per its own template subsection).
- Read `external-versioning.md` and merge its instructions into the coaching workflow as additional constraints
- Do not suggest a version based on pipeline track alone; present the constraint and ask the human for the version
- External Anchor takes priority over all other signals. If `external-versioning.md` exists, the mode is External Anchor regardless of what else is present.

### Conflict Warnings

When the human's stated intent conflicts with the detected signal, warn before proceeding. One warning per conflict:

```
P0: ⚠ Conflict, you selected {human's stated mode}, but {signal} indicates {detected mode}.
{Consequence of proceeding with the wrong mode, one sentence.}
Confirm you want to proceed as {human's stated mode}? (yes / use detected mode)
```

Do not block if the human explicitly confirms their intent after a warning. Record the confirmed mode in the build log even if it differs from the detected signal.

---

