---
title: "ADR 006: Setup-delivered files follow what setup copies"
summary: "A setup-delivered file is any framework file that setup.sh or setup.ps1 copies into a tool folder or writes into a boot file or settings file. The definition follows setup's copy-all fallback, not the bundle_templates or bundle_standards lists. The update policy says that a release that changes a setup-delivered file ships a re-run-setup migration, and one migration may cover several releases."
status: "accepted"
version: "0.1.0"
---
# ADR-006 - Setup-delivered files follow what setup copies

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

The 0.33.0 release changed four enforcement hooks, both boot templates, and three skills. It shipped no re-run-setup migration, so downstream projects kept the old copies (backlog 0000158). No rule told a release when it owes such a migration.

The rule needs a definition of a setup-delivered file. The skill manifests look like the obvious source, but they don't match what setup does. In `copy_skills()`, setup copies every file in `templates/` when a skill's `bundle_templates` key is absent or empty. The same fallback applies to `bundle_standards` and the top-level standards. Six skills omit `bundle_templates`, and three set it to `[]`, so every install carries every template. The orchestrator's byte order mark also hides its frontmatter from the `awk` parse in `setup.sh` (backlog 0000170).

0000029 ADR 001 makes boot files build outputs that each setup run rewrites. So a boot template change reaches a project only through a setup run.

0.33.0 and 0.34.0 both change setup-delivered files. 0.33.0 shipped no migration for its changes.

## Decision

1. A setup-delivered file is a framework file that `setup.sh` or `setup.ps1` copies into a tool folder, or writes into a boot file or a settings file. The set is the one req-001 FR-001.1 lists:
   - each skill's `SKILL.md`, with the `scripts/`, `assets/`, and `references/` folders that setup copies beside it
   - every file in `templates/` and `schemas/`, and every top-level file in `standards/`
   - each file below `standards/` that a `bundle_standards` entry names by sub-path
   - each enforcement hook, hook adapter, and workflow file
   - the hook wiring that setup writes into a settings file
2. The definition follows setup's behaviour, copy-all fallback included. A `bundle_templates` or `bundle_standards` list never narrows it.
3. Git hooks in `hooks/` aren't setup-delivered. Git runs them in place through `core.hooksPath`.
4. `standards/framework-update-policy.md` gains a section with this definition and this sentence: "A release that changes a setup-delivered file ships a re-run-setup migration."
5. One re-run-setup migration may cover several releases when an earlier release shipped none. `migrate-0.34.0-rerun-setup.md` covers 0.33.0 and 0.34.0.
6. The migration's file list comes from the git diff of each release, filtered by this definition. Before P3 closes, the agent checks the 0.34.0 list against `git diff --name-only main`.
7. The agent repeats that diff check at the end of P6, after the last change to any setup-delivered file. It adds any file that P4, P5, or P6 changed to the Background list. This repo's setup re-run and `applied` record follow that check (ADR-007).
8. If P7, P8, or P9 changes a setup-delivered file, the agent repeats the diff check and the setup run before the P9 push.

The re-run comes at the end of P6, not in P3, because P4 to P6 can still change setup-delivered files. A P5 security fix to `path-rules.mjs` is one example. A P3 run would leave this repo's installed copies stale under an `applied` record, and the Background list incomplete.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Define the set from the `bundle_templates` and `bundle_standards` lists | Each skill's manifest states it | The copy-all fallback copies files that no list names, such as `build-log.template.md`. A release would skip a migration it owes. | It describes intent, not what setup does. |
| Fix the fallback first so the manifests become true, then use them | One source of truth | It changes what setup copies, which scope rules out. Every install would lose files it carries today. | Out of scope for 0.34.0. Backlog 0000170 tracks the related parse defect. |
| One migration per release, including a late one for 0.33.0 | Each migration maps to one release | Two migrations re-run the same setup twice in a row. Projects at 0.32.0 pay for two runs with the same result. | A setup run is idempotent and covers every change at once. |
| Every release ships a re-run-setup migration | No judgement about which files count | Releases that change only `scripts/`, tests, or docs make every project re-run setup for nothing. | The definition gives a clear test, so a blanket rule costs more than it gains. |
| No policy rule, and authors decide each time | No new text | 0.33.0 shows that authors miss it. | The gap that caused backlog 0000158 stays open. |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `framework-update-policy.md` gains the definition and the rule. `migrations/` gains one migration that covers two releases. |

## Consequences

**Positive:**
- A release author has a clear test for when a re-run-setup migration is due.
- The definition can't miss a file that setup copies through the fallback.
- A project that skipped 0.33.0 gets one setup run for both releases.

**Negative:**
- Almost every release changes a template, a standard, or a skill. So almost every release now ships a migration, and each project re-runs setup more often.
- The definition copies setup's behaviour into prose. If setup's copy rules change, the policy text is wrong until someone updates it.
- A migration that covers two releases has a longer Background. The human on the loop reads more to see what changed.
- The Background list can change after P3 builds the migration file. The end-of-P6 diff check may edit a file that P4 already validated.

**Risks:**
- The 0.34.0 file list misses a file that other streams change (R-017). The FR-001.3 diff check before P3 closes catches it, and the repeat at the end of P6 catches later changes.
- A future release forgets the rule anyway (R-016). The drift check in ADR-005 still warns on stale skills, but not on stale hooks or boot files.

## Related ADRs

- ADR-005 - related-to: the drift check reports stale skills that this migration fixes.
- ADR-007 - extends: decides where the 0.34.0 migration applies.
- 0000029 ADR 001 - depends-on: boot files are build outputs, so a template change needs a setup run.
- 0000035 ADR 016 - depends-on: each project records the migration run at `plan/_migrations/`.

## Supersedes

- None

## Superseded By

- None
