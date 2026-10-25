---
title: "Requirement: req-001 - pack-paths-and-identifiers"
summary: "Rename every pack path and identifier from Planifest to RAVINTIO in one scripted pass."
status: "draft"
version: "0.1.0"
---
# Requirement: req-001 - pack-paths-and-identifiers

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Source:** US-001
**Priority:** must-have

## User Story

As a human on the loop, I see `ravintio` in every pack path and identifier, so that the file layout matches the RAVINTIO org.

## Functional Requirements
- The P3 scripted pass renames these paths with `git mv`:
  - `planifest-framework/` to `ravintio-framework/`
  - `planifest-overrides/` to `ravintio-overrides/`
  - the 21 skill folders `planifest-*` under `ravintio-framework/skills/` to `ravintio-*`
  - `.github/workflows/planifest.yml` to `.github/workflows/ravintio.yml`
  - `ravintio-framework/hooks/planifest.yml` to `ravintio-framework/hooks/ravintio.yml`
  - `refresh-planifest-framework-dir.ps1` to `refresh-ravintio-framework-dir.ps1`
- The same pass rewrites these identifiers:
  - the `name:` field in the frontmatter of each of the 21 `SKILL.md` files
  - `id` and `name` in `product.yml`, and the matching pointer in its `components[]` list
  - `id` and `name` in `ravintio-framework/component.yml`
  - `name` in `ravintio-framework/hooks/adapters/opencode/package.json`, from `@planifest/opencode-hooks` to `@ravintio/opencode-hooks`
- `src/setup-hook-integration/component.yml` has an `id` and `name` that carry no brand. The pass leaves both values unchanged. Only a Planifest reference in its other fields changes.
- The pass has two steps. It runs `git mv` for every path first. It then runs a content replace that skips the protected list defined in req-005.
- The script lives in the scratchpad and never in the repo. It runs once. Its output, the `setup.sh claude-code` re-run, and the build-log update land in one commit.
- Git history must record the moves as renames. The commit must not read as delete plus add. Content rewrites inside a moved file must leave it above git's default 50% similarity threshold, so `git log --follow` and `git diff -M` pair the old and new paths.
- The rename check runs `git diff -M --name-status` between the pass's parent and the pass commit. Before the pass, the test-writer dry-runs it in a scratch clone and confirms every listed path reports `R`. A file that falls below the threshold gets `D` plus `A`, is logged in the build log, and is the only exception to AC3. The third criterion's "no `D` plus `A` pair" reads as "none outside that build-log list".
- Follow-up fixes after the pass use **Edit**, never a second script.
- Split step: keep. Paths and identifiers move together in one pass, so one concern covers all three criteria.

## Acceptance Criteria
- [ ] After the pass, `git ls-files` lists no path containing `planifest` outside the protected list from req-005, and every path in the rename list above exists under its new name. Verified by: execution
- [ ] Each of the 21 `ravintio-*/SKILL.md` files has a `name:` equal to its folder name. `product.yml`, `ravintio-framework/component.yml`, and the OpenCode `package.json` carry the new `id`, `name`, and `@ravintio` scope, and `product.yml` points at `ravintio-framework/component.yml`. Verified by: integration
- [ ] The pass commit shows the moved paths as renames. `git show -M --name-status` reports `R` entries for the folders, the workflow, the hook file, and the PowerShell script, with no `D` plus `A` pair for any of them. Verified by: execution

## Dependencies
- req-005 supplies the protected list that the content replace skips.
- req-002 covers the names inside the workflow and hook files. This requirement covers only their file names.
- req-007 enforces the result after the pass.
