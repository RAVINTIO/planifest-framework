---
title: "Requirement: req-006 - consumer-migration"
summary: "One migration and two helper scripts move a consumer repo from the Planifest names to the RAVINTIO names, and keep the old pack as a backup."
status: "draft"
version: "0.1.0"
---
# Requirement: req-006 - consumer-migration

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Source:** US-002
**Priority:** must-have

## User Story

As a human on the loop with a consumer repo on 0.36.0, I run one migration that moves it to the RAVINTIO pack and keeps a backup of the old pack, so that I upgrade without losing files.

## Functional Requirements
- Add the migration `ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.md` and the helpers `migrate-0.37.0-ravintio-rename.sh` and `migrate-0.37.0-ravintio-rename.ps1` beside it. The shape follows `migrate-archive-dirname.sh` and `migrate-archive-dirname.ps1`.
- The consumer copies `ravintio-framework/` in, runs the helper from the project root, then runs `ravintio-framework/setup.sh` or `setup.ps1`. The project root may sit below the git top level.
- The helper runs these steps in order:
  1. If `ravintio-framework/` is absent, print why and stop. Move nothing.
  2. Check every stop condition before the first move. A stop condition is any of these:
     - `planifest-overrides/` and `ravintio-overrides/` both exist.
     - `.github/workflows/ravintio.yml` exists while `planifest.yml` also exists.
     - `.ravintio-backup/planifest-framework` exists while `planifest-framework/` (the old pack) also still exists in place. If the old pack is already gone and the backup exists, the move is complete. The rerun skips step 6 and exits 0.
     - git holds a staged edit under `planifest-framework/` that differs from both `HEAD` and the working file. Run `git diff --cached --quiet --diff-filter=ACMRT -- planifest-framework` and print a clear message. Staged deletions don't count, because step 6 stages them with `git rm --cached`, so a rerun after step 6 passes this check.
     - `planifest-framework`, `planifest-overrides`, `ravintio-overrides`, `.ravintio-backup`, or either workflow file is a symbolic link or a junction, dangling or not.
  3. Move `planifest-overrides/` to `ravintio-overrides/`. Use `git mv` when git tracks the folder.
  4. Rename `.github/workflows/planifest.yml` to `ravintio.yml`. Rewrite `planifest-framework/` to `ravintio-framework/` inside it. Rewrite only the pack-owned `PLANIFEST_` variable names it holds, as whole names. Leave every other `PLANIFEST_` name, such as a consumer secret. Write to a temporary file in the same folder, then rename it over the target.
  5. Remove `.claude/.planifest-setup-flags`, `.claude/skills/.planifest-manifest`, and any `.planifest-session` marker.
  6. Stop git tracking of the old pack with `git rm -r -q --cached -- planifest-framework`. Then move the folder to `.ravintio-backup/planifest-framework/` with a plain rename. Never delete it. Add `.ravintio-backup/` to `.git/info/exclude` once. Skip that write with a warning when `.git/info` or `info/exclude` is a link.
  7. Print the next step: run `ravintio-framework/setup.sh claude-code`, or the tool the project uses, before the next commit. Name `.ravintio-backup/` and tell the human on the loop to delete it after checking it.
  8. Print a branch protection warning. A rule that requires the old check name must now require `RAVINTIO Strict Pipeline`.
- If a parent folder is a symbolic link, skip only the step that writes through it, print a warning, and carry on. A link at `.github` or `.github/workflows` skips step 4. A link at `.claude` or `.claude/skills` skips the marker under it.
- Make each step skip work that is already done, so a rerun is safe. The helper reports each step it takes and each step it skips.
- Use a plain rename for the pack. That is `mv` in Bash and `System.IO.Directory.Move` in PowerShell. A rename moves a nested link as a link and follows none. The helper deletes no file.
- Make the `.sh` and `.ps1` helpers behave the same, including output text and exit codes.
- PowerShell rules, which hold on Windows PowerShell 5.1 and PowerShell 7:
  - Write `${Var}:` in any double-quoted string where a colon follows a variable. A bare `$Var:` parses as a scope-qualified variable and breaks the script.
  - Detect a link or junction with `Get-Item -Force` and the `ReparsePoint` attribute, not with a command that PowerShell 5.1 lacks.
  - Use only syntax that both versions parse. CI parses the file on both.
- The migration file declares `**Applies when:**` `planifest-framework/` or `planifest-overrides/` exists at the project root. This source repo holds neither folder after the rename, so it skips the migration. How the migrator reads that field belongs to req-009.
- The migration body lists every renamed variable, using the req-003 inventory. Step 4 rewrites only the names on that list.
- A helper stopped after any single step resumes on rerun. It skips the done steps, completes the rest, and ends in the same state as an uninterrupted run.
- Split step: keep, at five criteria. The one concern is a single helper's run on a consumer repo: the clean run, its reruns and resumes, its link refusals, and the same behaviour in its second shell. PowerShell parity can't ship on its own, because the migration ships both helpers as one pair. The migrator ordering concern already went to req-009.
- On any stop, the helper names the step it stopped at and the files it already moved. The resume test for the fifth criterion asserts that message. It includes a run stopped right after step 6, with the pack deletions still staged.
- Ship one test per helper. Each covers the clean run and a rerun, each stop condition, each link refusal, each parent-link skip, a project below its git top level, and a consumer secret that keeps its `PLANIFEST_` name.

## Acceptance Criteria
- [ ] In a scratch consumer repo, the helper moves the overrides, renames the workflow and rewrites only pack-owned names, removes the markers, moves the old pack to `.ravintio-backup/planifest-framework/`, and prints the setup command and the branch protection warning, in both `.sh` and `.ps1`. Verified by: integration
- [ ] A rerun changes nothing and exits 0. Each stop condition (no `ravintio-framework/`, both override folders, an existing `ravintio.yml` beside `planifest.yml`, an existing backup while the old pack also still exists, a staged pack edit other than a deletion) exits non-zero before any move. Verified by: integration
- [ ] A link or junction at `planifest-framework`, `planifest-overrides`, `ravintio-overrides`, or `.ravintio-backup`, or at either workflow file, makes the helper refuse and leave the link and its target untouched. Verified by: integration
- [ ] The `.ps1` helper parses and gives the same output and exit codes as the `.sh` helper on Windows PowerShell 5.1 and PowerShell 7. Verified by: integration
- [ ] A helper stopped after any single step, then rerun, completes the remaining steps and ends in the same state as an uninterrupted run. Verified by: integration

## Dependencies
- req-001 (pack-paths-and-identifiers) provides the `ravintio-framework/` folder and the renamed `ravintio-migrator` skill.
- req-002 (runtime-names) makes setup stop while `planifest-framework/` or `planifest-overrides/` exists, and name this migration.
- req-009 (migration-ordering-and-old-paths) covers how the migrator finds, orders, and records this migration.
- RAVINTIO Zero 0000160 ADR 003 is the prior art. Its security findings S-001 to S-018 shaped the rename design, the link refusals, and the staged-edit and exclude-link checks.
- Existing pattern: `migrate-archive-dirname.sh`, `migrate-archive-dirname.ps1`, and `migrate-0.36.0-rerun-setup.md`.
