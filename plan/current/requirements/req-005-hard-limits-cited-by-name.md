---
title: "Requirement: req-005 - hard-limits-cited-by-name"
summary: "Every hard-limit citation in the framework and the living docs names its rule and its source list as well as its number. The dispatch template states the Write-or-Edit rule. No hard limit is renumbered."
status: "draft"
version: "0.1.0"
---
# Requirement: req-005 - hard-limits-cited-by-name

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Source:** US-005 (backlog 0000157)
**Priority:** must-have

## User Story

> One requirement doc = one user story.

As the human on the loop, I see every hard-limit citation name its rule, so that no agent mistakes the build-log rule for the Write-or-Edit rule.

## Functional Requirements

### The problem

- Several files keep their own numbered Hard Limits list. Two lists both hold a Hard Limit 8:
  - The orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md:27`) numbers the build-log rule as Hard Limit 8.
  - The boot templates (`planifest-framework/templates/standard-boot.md:14`, `cursor-boot.md:20`) number the Write-or-Edit rule as Hard Limit 8.
- The ship agent, the migrator, and the loop runner keep their own lists too. A bare "Hard Limit 3" can point at any of them.
- `planifest-framework/standards/agent-dispatch-standards.md` doesn't state the Write-or-Edit rule. A subagent with no boot file can miss it.

### Citation form

- Every citation names the rule, then its source list and number in brackets. The form is `the {name} rule ({source} Hard Limit {N})`.
- Two limits from one list take the plural form `the {name} and {name} rules ({source} Hard Limits {N} and {M})`.
- `{source}` is one of `orchestrator`, `boot`, `ship agent`, `migrator`, or `loop runner`. A citation inside the same file still names its source.
- Headings follow the same form, for example `## Commit cadence: the commit-cadence rule (orchestrator Hard Limit 7)`.
- The form keeps the text `Hard Limit {N}`. Existing suites that assert a substring such as `Hard Limit 6` or `Hard Limit 11` keep passing.
- No list is renumbered, and no limit's text changes.

### Rule names

P3 uses these names for every limit that a file cites today:

| Source | Number | Name |
|--------|--------|------|
| orchestrator | 2 | schema rule |
| orchestrator | 3 | destructive-operation rule |
| orchestrator | 4 | data-ownership rule |
| orchestrator | 6 | credentials rule |
| orchestrator | 7 | commit-cadence rule |
| orchestrator | 8 | build-log rule |
| orchestrator | 11 | discovery rule |
| boot | 8 | Write-or-Edit rule |
| ship agent | 6 | handover-track rule |
| migrator | 3 | skip rule |
| loop runner | 3 | budget-counter rule |

If P3 finds a citation of a limit not in this table, it names that limit from its bold heading and logs the name as a deviation.

### Files to change

A search on 2026-10-22 found bare citations in these files:

- `planifest-framework/skills/`: the orchestrator (`:328`, `:363`, `:558`, `:567`), the ship agent (`:116`, `:201`, `:385`), and the migrator (`:46`).
- The `## Commit Cadence (Hard Limit 7)` heading and its line in the adr, codegen, docs, security, spec, and validate agent skills.
- `planifest-framework/templates/standard-boot.md:28`, the shell-write-guard bullet.
- `planifest-framework/standards/autonomous-run-standards.md` (`:37`, `:43`, `:79` to `:81`, `:128`) and `agent-dispatch-standards.md:94`.
- `planifest-framework/workflows/fast-path.md:103` and `planifest-framework/pipeline-reference.md:67`.
- Comments in `planifest-framework/scripts/set-product-release.mjs:24` and `promote-to-regression.sh:15`, and the `planifest-framework/component.yml:37` string.
- Living docs: `docs/architecture-overview.md` (`:299`, `:301`, `:359`, `:398`), `docs/decisions-index.md` (`:195`, `:343`), and `docs/component-registry.md:13`.

These stay as they are:

- `plan/_archive/` and `plan/changelog/`, because they are historical records.
- `planifest-framework/tests/`, because suite strings describe the text they check.
- The root `CLAUDE.md` and `AGENTS.md`, and the installed copies under `.claude/`. Setup writes them from the templates and the source skills (0000029 ADR 001). They pick up the change when setup next runs, which [req-001](req-001-rerun-setup-migration.md)'s migration triggers.

### Dispatch template

- `planifest-framework/standards/agent-dispatch-standards.md` adds one sentence to both example prompts at `:125` and `:128`. The sentence reads: "Make every file change through Write or Edit, never through the shell (the Write-or-Edit rule, boot Hard Limit 8)."
- The self-contained prompt rule at `:131` lists the same sentence among the things every prompt says.
- The existing run-mode sentence and its count check in `test-0000033-req-001-run-mode-script.sh:248` stay unchanged.

### Suite

- A new suite, `planifest-framework/tests/test-0000036-req-005-hard-limits-cited-by-name.sh`, scans `planifest-framework/` without `tests/`, and `docs/`.
- It finds each `Hard Limits? [0-9]+` match. It fails on any match that the citation form doesn't wrap, and prints the file and line.
- The numbered list items that define each limit don't hold the text `Hard Limit`, so the scan doesn't see them.
- It also asserts that both dispatch prompts and the self-contained prompt rule hold the Write-or-Edit sentence.

## Acceptance Criteria

- [ ] Every hard-limit citation in `planifest-framework/` and `docs/` names its rule and source as well as its number. No file cites a bare "Hard Limit 8", and no list is renumbered.
- [ ] `standards/agent-dispatch-standards.md` states the Write-or-Edit rule in both dispatch prompts and in the self-contained prompt rule.
- [ ] The new suite fails on a bare hard-limit citation and names the file and line.

## Dependencies

- [req-001](req-001-rerun-setup-migration.md): its migration re-runs setup, which carries the boot template change into each project's `CLAUDE.md`.
- [req-003](req-003-ship-commit-subjects.md), [req-004](req-004-run-mode-anchor-format.md), and [req-006](req-006-design-critic-default.md) edit some of the same skill and standards files. The orchestrator orders those edits.
- [req-007](req-007-story-split-step.md) edits the spec agent skill, which also holds a Commit Cadence heading.
- 0000035 req-008 added the sanctioned-scripts sentence to boot Hard Limit 8. Its suite finds that limit by its list item text, `8. **Code changes go through Write or Edit`, so this requirement leaves that suite alone.
