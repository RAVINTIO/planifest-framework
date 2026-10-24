---
title: "ADR 007: A re-run-setup migration for release 0.36.0"
summary: "Release 0.36.0 ships migrate-0.36.0-rerun-setup.md. It lists every setup-delivered file the feature changes or adds and tells projects to re-run setup. The orchestrator rechecks the list at the end of P6."
status: "accepted"
version: "0.1.0"
---
# ADR-007 - A re-run-setup migration for release 0.36.0

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Component:** planifest-framework
**Date:** 2026-10-24

## Context

A setup-delivered file reaches a downstream project only when setup runs again. This feature changes skills, a standard, the boot template, and the override instructions. It also adds files to the orchestrator `references/` folder. Without a re-run, an installed orchestrator would keep the old `SKILL.md` and could never load the new reference files, or would load pointers to files that do not exist.

Earlier releases set the pattern: `migrate-0.34.0-rerun-setup.md` and `migrate-0.35.0-rerun-setup.md`. 0000037 ADR-010 checks the list against the branch diff in both directions. The list must therefore be exact.

## Decision

1. Add `planifest-framework/migrations/migrate-0.36.0-rerun-setup.md`, in the format of the 0.35.0 migration.
2. The list names these setup-delivered files, subject to the P6 recheck:
   - `skills/planifest-orchestrator/SKILL.md`, with the new reference files `skills/planifest-orchestrator/references/phase-0-assess-and-coach.md` and `skills/planifest-orchestrator/references/adoption-modes.md`
   - `skills/planifest-refactor/SKILL.md`, `skills/planifest-validate-agent/SKILL.md`, and `skills/planifest-codegen-agent/SKILL.md` (quiet mode)
   - `skills/planifest-ship-agent/SKILL.md` (model value)
   - `standards/agent-dispatch-standards.md` (model values and the size floor)
   - `pipeline-reference.md`, if setup delivers it. The P6 recheck settles that.
   - `templates/standard-boot.md` (partial reads)
   - `planifest-overrides/instructions/custom-002-prefer-subagent-decomposition.md`, delivered into the generated boot file
3. The migration says a re-run also refreshes the generated boot file, so the new custom-002 text and the partial-read directive reach `CLAUDE.md` or its equivalent.
4. The migration is safe to skip: no. Without a re-run, an installed orchestrator keeps the 77,635-byte `SKILL.md`, and the saving does not reach that project.
5. The migrator instructions match 0.35.0: check the framework version is 0.36.0 or later, then re-run setup for each tool with the usual flags.
6. The file name sorts after 0.35.0, so the migrator applies it in order.
7. The orchestrator rechecks the list against the branch diff at the end of P6, before the version bump at P7. Tests and `run-tests.sh` are not setup-delivered and stay off the list.
8. The migration is written at P3 or P6 with the rest of the code. This ADR fixes only its shape.

Decision (P2): ship `migrate-0.36.0-rerun-setup.md` in the 0.35.0 format and recheck its list at the end of P6 / reason: installs need setup to receive the skills, references, standard, and boot text, and the diff check needs an exact list.

Decision (P2): the migration names the two new reference files explicitly / reason: setup copies `references/` with `cp -r`, but a list that omits new files fails the two-way diff check.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| No migration | Less work | Installs keep old files silently | Stale installs |
| Fold into the 0.35.0 migration | One file | That release is tagged, so its migration is frozen | Breaks the frozen rule |
| A migration that edits installed files directly | No setup run | Bypasses setup and risks drift | Setup is the supported path |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | One new migration file. Version bump to 0.36.0 at P7 |

## Consequences

**Positive:**
- Downstream projects get an instruction to refresh, in the same pattern as before.
- The two-way diff check can pass.

**Negative:**
- Each project runs setup again.
- The list needs a manual recheck at P6.

**Risks:**
- A missed file leaves a project half-updated. The diff check catches it.
- A project that skips the migration keeps the old, larger orchestrator and the Opus subagents.

## Related ADRs

- ADR-002 - depends-on (new reference files)
- ADR-003 - depends-on (installed standard copies)
- ADR-006 - depends-on (boot copy of custom-002)
- 0000037 ADR-010 - depends-on (the two-way diff check)

## Supersedes

- None.

## Superseded By

- None.
