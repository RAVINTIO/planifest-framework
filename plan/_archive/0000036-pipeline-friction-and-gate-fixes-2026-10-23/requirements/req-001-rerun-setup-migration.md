---
title: "Requirement: req-001 - rerun-setup-migration"
summary: "One 0.34.0 migration re-runs setup for the setup-delivered changes in 0.33.0 and 0.34.0, and the update policy requires such a migration."
status: "draft"
version: "0.1.0"
---
# Requirement: req-001 - rerun-setup-migration

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Source:** US-001 (backlog 0000158)
**Priority:** must-have

## User Story

As the human on the loop in a downstream project, I get a migration that re-runs setup after I update the framework, so that my installed hooks and boot file match the framework version.

## Functional Requirements

### FR-001.1 Setup-delivered files

- A setup-delivered file is a framework file that `setup.sh` or `setup.ps1` copies into a tool folder or writes into a boot file. These count:
  - each `skills/*/SKILL.md`, with the `scripts/`, `assets/`, and `references/` folders that setup copies beside it
  - every file in `templates/`
  - every top-level file in `standards/`, but not `standards/reference/`
  - each file below `standards/` that a `bundle_standards` entry names by sub-path, today only `standards/library-standards/_version-policy.md`
  - every file in `schemas/`
  - each `hooks/enforcement/*.mjs` file and each `hooks/adapters/` file
  - each `workflows/*.md` file
  - the hook wiring that setup writes into a tool's settings file
- The template and standard rules follow what setup does, not what the manifests name. `copy_skills()` in `setup.sh` (lines 111-148) works like this:
  - If a skill's `bundle_templates` key is absent or empty, setup copies every file in `templates/` into that skill's `assets/templates/`. The same fallback applies to `bundle_standards` and the top-level standards.
  - Six skills omit `bundle_templates`, and three set it to `[]`. So each install carries every template.
  - Four skills omit `bundle_standards`: the implementer, refactor, refresh-setup, and test-writer skills. Five set it to `[]`: the build-assessment agent, design critic, loop runner, reversal assessor, and scope-lock agent. Both cases trigger the fallback, so each install carries every top-level standard.
  - A selective `bundle_standards` list copies each named path from `standards/` into `references/`, sub-paths included. The codegen and validate agents name `library-standards/_version-policy.md`, so setup copies that file too. `setup.ps1` reads the orchestrator's list, which names the same file.
  - The orchestrator's `SKILL.md` starts with a UTF-8 byte order mark. The `awk '/^---$/'` parse never finds its frontmatter, so `setup.sh` ignores its `bundle_templates` key and copies every template. `setup.ps1` reads the key. Backlog 0000170 covers that defect.
- A `bundle_templates` or `bundle_standards` list never narrows the set. The copy-all fallback reaches every file, so a change to any of them needs a re-run.
- Git hooks in `hooks/` don't count. Git runs them in place through `core.hooksPath`, so they need no re-run.

### FR-001.2 What 0.33.0 changed

The 0000035 merge (`5c7859a`) changed these setup-delivered files against `2253e80`. The 0.33.0 release shipped no re-run-setup migration for them. The list comes from `git diff --name-only 2253e80 5c7859a`, filtered by the FR-001.1 definition. That diff changes no file in `standards/`, `schemas/`, or `hooks/adapters/`.

| File | Change |
|------|--------|
| `hooks/enforcement/path-rules.mjs` | Fast Path scope record, links judged by their real target, shared root finding |
| `hooks/enforcement/gate-write.mjs` | uses the new path rules |
| `hooks/enforcement/shell-write-guard.mjs` | honours the Fast Path scope record |
| `hooks/enforcement/ratchet-check.mjs` | finds the root with the gate's rules |
| `templates/standard-boot.md` | sanctioned-scripts sentence in Hard Limit 8, new hook descriptions |
| `templates/cursor-boot.md` | sanctioned-scripts sentence in Hard Limit 8 |
| `skills/planifest-migrator/SKILL.md` | Record step and target check |
| `skills/planifest-orchestrator/SKILL.md` | migration run state in Resume Detection |
| `skills/planifest-ship-agent/SKILL.md` | P7 product release step |
| `templates/feature-brief.template.md` | template change, copied into skill `assets/templates/` folders |
| `templates/product.template.yml` | template change, copied by the copy-all fallback |
| `workflows/fast-path.md` | Fast Path scope record |

0000034 (0.32.0) changed no setup-delivered file, so the migration doesn't name 0.32.0.

### FR-001.3 What 0.34.0 changes

The migration names the setup-delivered files that this release changes. The expected set is:

- `hooks/enforcement/path-rules.mjs` (req-008, req-009, and req-011)
- `hooks/enforcement/ratchet-check.mjs` and `hooks/enforcement/em-dash-guard.mjs` (req-011)
- `hooks/enforcement/gate-write.mjs`, if req-008 changes it
- `templates/standard-boot.md` and `templates/cursor-boot.md`, which cite hard limits by name (req-005)
- the skills that the other requirements change, including the ship agent, orchestrator, loop runner, spec agent, and design critic
- each template that changes, including `loop-toggles.template.yml` (req-006) and `build-log.template.md` (req-004)
- each top-level standard that changes, such as `framework-update-policy.md` (FR-001.6)

No skill names `build-log.template.md` in its `bundle_templates` list. It is setup-delivered because the copy-all fallback in FR-001.1 copies it. The same reasoning covers every other template and top-level standard.

Before P3 closes, the agent compares this list with `git diff --name-only main` and adds any setup-delivered file it missed. It repeats the comparison at the end of P6, after the last change to any setup-delivered file, and before the FR-001.7 setup run. It applies the FR-001.1 rules to each path in that diff. It never filters the diff by the `bundle_templates` or `bundle_standards` lists. New scripts in `planifest-framework/scripts/`, such as `skill-drift-check.mjs` (req-002), stay in place and aren't setup-delivered.

### FR-001.4 The migration file

- The migration sits at `planifest-framework/migrations/migrate-0.34.0-rerun-setup.md`. One file covers both 0.33.0 and 0.34.0.
- It follows the 0.31.0 migration's layout. The header holds a `# Migration:` title, a `**Target:**` line, a `**Scope:**` line, and a `**Safe to skip:**` line.
- It holds these sections in order:
  1. `## Background` names both versions and lists the files from FR-001.2 and FR-001.3.
  2. `## What This Migration Does` says that a re-run refreshes installed skills, hooks, workflows, settings wiring, and the boot file.
  3. `## Migrator Instructions` holds the steps in FR-001.5.
  4. `## Present Findings` lists what the migrator reports to the human on the loop.
  5. `## Record` says that the migrator records the outcome at `plan/_migrations/migrate-0.34.0-rerun-setup.md`.
- `**Safe to skip:**` reads No. Without a re-run, the installed hooks keep the write-gate bypasses that 0.34.0 closes.
- The `**Target:**` line names every project with an installed Planifest setup, the framework source included. It doesn't name only a downstream project, so the migrator's target check (Step 1b) runs it in this repo.

### FR-001.5 Migrator instructions

1. Confirm that `planifest-framework/component.yml` reports `0.34.0` or later. If it's older, stop and ask the human on the loop to refresh `planifest-framework/` first.
2. Re-run setup for each tool the project uses, with the flags it normally uses. `planifest-refresh-setup` rebuilds those flags.
3. Run `node planifest-framework/scripts/skill-drift-check.mjs` and expect exit 0 (req-002).
4. Check that each installed `enforcement/*.mjs` file matches its source in `planifest-framework/hooks/enforcement/`.
5. Check that the boot file holds the sanctioned-scripts sentence and names the Write-or-Edit rule.
6. If setup reported malformed settings JSON or missing Node, report it as left for a person to fix.
7. Decide whether the run completed. A completed run meets every one of these conditions:
   - Setup exits 0 for each tool.
   - The drift check exits 0.
   - Every installed enforcement hook matches its source.
   - Setup reported no malformed settings file and no missing Node. Setup still exits 0 when it skips hook wiring for a malformed settings file (P5 re-review N-2).
8. If the run completed, record the outcome. On any other result, the migrator records nothing, so the migration stays pending. It reports the failure to the human on the loop (P5 S-6).

A fresh 0.34.0 install still runs the migration. Setup is safe to re-run, and the migrator writes the record only after a completed run. The `## Record` section repeats the completed-run rule. The req-001 suite asserts the rule's sentences in both sections.

### FR-001.6 Update policy

- `planifest-framework/standards/framework-update-policy.md` gains a section on setup-delivered files. It defines them as FR-001.1 does:
  - each skill's `SKILL.md`, with its `scripts/`, `assets/`, and `references/` folders
  - every file in `templates/` and `schemas/`, and every top-level file in `standards/`
  - each file below `standards/` that a `bundle_standards` entry names, such as `standards/library-standards/_version-policy.md`
  - each enforcement hook, hook adapter, and workflow file
  - the hook wiring that setup writes into a settings file
- The section says that setup copies every template and top-level standard when a skill's `bundle_templates` or `bundle_standards` key is absent or empty. So a release can't treat a template or standard as safe because no manifest names it.
- The section states this sentence: "A release that changes a setup-delivered file ships a re-run-setup migration."
- The section also says that one migration may cover several releases when an earlier release shipped none.

### FR-001.7 Record in this repo

- This repo is the framework source. The migrator decides that from the root `product.yml` `id: "planifest-framework"`.
- The Target line from FR-001.4 lets the migration apply here. P3 builds the migration file but doesn't run it in this repo.
- The run happens at the end of P6, after the last change to any setup-delivered file. P4 to P6 can still change such a file, so a P3 run would leave stale installed copies under an `applied` record (ADR-007).
- At the end of P6, the agent repeats the FR-001.3 diff check. It then re-runs `planifest-framework/setup.sh claude-code --strict-orchestrator`, with the flags from `.claude/.planifest-setup-flags`.
- The agent then writes `plan/_migrations/migrate-0.34.0-rerun-setup.md` through **Write**. The record holds `outcome: "applied"` and `framework-version: "0.34.0"`, with the record fields from 0000035 req-007.
- The setup run rewrites the tracked `planifest-overrides/setup-config/claude-code.md`. The agent commits that change with the record.
- If P7, P8, or P9 changes a setup-delivered file, the agent repeats the diff check and the setup run before the P9 push.

### FR-001.8 Tests

- A new suite `planifest-framework/tests/test-0000036-req-001-rerun-setup-migration.sh` checks:
  - the migration file exists at the top level of `migrations/`
  - the header lines and the five sections from FR-001.4
  - the text names `0.33.0`, `0.34.0`, `Re-run setup`, `planifest-refresh-setup`, and `plan/_migrations/`
  - the Background names `path-rules.mjs` and `standard-boot.md`
  - the Target line names the framework source
  - the policy file holds the sentence from FR-001.6
  - this repo's record exists and holds `outcome: "applied"`
- The record check prints a `SKIP` line and passes while the record is absent, because P4 runs the suite before the end-of-P6 setup run. Once the record exists, the check must find `outcome: "applied"`. The end-of-P6 step runs the suite again and confirms that the record check ran with no `SKIP` line.
- `test-0000035-req-007-migration-run-state.sh` and `test-0000035-req-010-migration-records-for-this-repo.sh` expect eight migrations. Each changes its count to nine.

## Acceptance Criteria

- [ ] AC-001.1: `planifest-framework/migrations/migrate-0.34.0-rerun-setup.md` exists with the 0.31.0 migration's header lines and sections. It names the setup-delivered files that 0.33.0 and 0.34.0 change, and this repo holds an `applied` record for it.
- [ ] AC-001.2: `planifest-framework/standards/framework-update-policy.md` defines setup-delivered files and says that a release that changes one ships a re-run-setup migration.
- [ ] AC-001.3: `test-0000036-req-001-rerun-setup-migration.sh` passes and fails when a section, a version, or the policy sentence is removed. The 0000035 req-007 and req-010 suites pass with nine migrations.

## Dependencies

- [Req-002](req-002-skill-drift-check.md) supplies `skill-drift-check.mjs`, which step 3 of the Migrator Instructions runs.
- The 0.34.0 file list depends on what stream-01 and stream-03 change. FR-001.3 checks it against the diff before P3 closes and again at the end of P6.
- 0000035 req-007 record format and the migrator's target check (Step 1b).
