---
title: "ADR 005: Consumer migration backs up, never deletes"
summary: "Migration migrate-0.37.0-ravintio-rename ships a Bash and a PowerShell helper. The helpers move the old pack to .ravintio-backup/ with a plain rename and delete nothing."
status: "accepted"
version: "0.1.0"
---
# ADR-005 - Consumer migration backs up, never deletes

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Component:** ravintio-framework, setup-hook-integration
**Date:** 2026-10-25

## Context

Consumers copy the pack folder into their repo and run setup. The rename leaves four things in a consumer repo that setup does not handle:

- the old `planifest-framework/` folder
- the content of `planifest-overrides/`
- the installed `.github/workflows/planifest.yml`
- the old marker files, of which the helper removes `.planifest-session` and setup removes the other two

A consumer who runs the new setup first risks a half-moved install. The pack already has a pattern for one-off changes. A migration file lives in `migrations/`, with a Bash and a PowerShell helper beside it. The migrator skill runs it. `migrate-archive-dirname.sh` and `migrate-archive-dirname.ps1` are the model.

RAVINTIO Zero 0000160 ADR 003 faced the same problem. Its first design deleted the old pack behind guards. Windows PowerShell 5.1 `Remove-Item -Recurse` followed a nested junction and deleted the files behind it. That drew a High security finding. Six fix cycles followed, and each guard either missed a case or blocked a normal upgrade. The final design replaced deletion with a rename into a backup folder.

This feature governs req-006.

## Decision

Ship the migration `migrate-0.37.0-ravintio-rename.md` with the helpers `migrate-0.37.0-ravintio-rename.sh` and `migrate-0.37.0-ravintio-rename.ps1`. The helpers behave the same, including output text and exit codes.

The consumer works in this order:

1. Copy `ravintio-framework/` into the repo.
2. Run the helper from the project root.
3. Run `ravintio-framework/setup.sh` or `setup.ps1`.

The helper runs these steps:

1. Stop if `ravintio-framework/` is absent. Move nothing.
2. Check every stop condition before the first move.
3. Move `planifest-overrides/` to `ravintio-overrides/`.
4. Rename the workflow to `ravintio.yml`. Rewrite only the pack-owned names in it. A consumer secret keeps its `PLANIFEST_` name.
5. Remove the old marker files.
   - Of the old markers, the helper removes only `.planifest-session`. It leaves `.planifest-setup-flags` and `.planifest-manifest` for setup, which reads each once and then removes it (ADR-004, req-006 step 5).
6. Stop git tracking of the old pack. Move it to `.ravintio-backup/planifest-framework/` with a plain rename.
7. Print the setup command and tell the human on the loop to delete the backup after checking it.
8. Print a branch protection warning. A rule that requires the old check name must now require `RAVINTIO Strict Pipeline`.

The safety rules are:

- The helper never deletes the pack or any folder. Its one removal is the old `.planifest-session` marker file, a regular file it checks is not a link first (`rm -f` in Bash, `File.Delete` in PowerShell). The pack moves with `mv` in Bash and `System.IO.Directory.Move` in PowerShell. A rename moves a nested link as a link and follows none.
- The helper refuses a symbolic link or junction, dangling or not, at the old pack, either overrides folder, `.ravintio-backup`, or either workflow file. It leaves the link and its target untouched.
- A link at a parent folder skips only the step that writes through it, with a warning.
- Every step skips work that is already done, so a rerun is safe. A run stopped after any single step resumes and ends in the same state as an uninterrupted run.
- A clash stops the helper before the first move. Examples are both overrides folders, or a backup that exists beside an old pack still in place.
- A staged edit under the old pack stops the helper. Staged deletions do not. Step 6 stages its own deletions with `git rm --cached`, so a rerun after step 6 passes the check.
- On any stop, the helper names the step and the files it already moved.
- The workflow rewrite goes to a temporary file in the same folder, which then replaces the target.

Setup stops while `planifest-framework/` or `planifest-overrides/` exists. It names this migration (req-002).

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Delete the old pack, guarded by dirty, junction, and top-level checks | Leaves no backup on disk. The repo ends clean | Each guard missed a case or blocked a normal upgrade. RAVINTIO Zero 0000160 ADR 003 hit a High finding on PowerShell 5.1 junctions and needed six fix cycles | A rename deletes nothing, so no guard can fail into data loss |
| Setup does the migration itself | One step for the consumer | Setup would carry rename logic for good. A mistake in it moves consumer content on every run | Migrations exist for one-off changes. The migrator already records the outcome |
| One cross-platform Node helper | One script to test and maintain | Consumers need Node on the path. The pack ships Bash and PowerShell helpers for every earlier migration | The helper must run before setup, and setup is what makes the tool available |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | Adds the migration file and two helpers, and their tests. Migrations run in this pack's migrator |
| setup-hook-integration | Setup gains a stop while the old pack or overrides folder exists, and names this migration |

## Consequences

**Positive:**
- The upgrade deletes no file. A custom or ignored file in the old pack stays in `.ravintio-backup/`.
- A stopped run leaves the repo in its starting state, or resumes cleanly, because the checks run before the first move.
- The helpers need no junction-aware tree walk, which removes the PowerShell 5.1 failure class.

**Negative:**
- The backup stays on disk until the human on the loop deletes it. A consumer who forgets keeps a second copy of the old pack.
- Two helpers on two shells double the test work, and CI must parse the PowerShell file on 5.1 and 7.
- Consumers must run the migration before setup, and setup blocks until they do.
- The helper only warns about branch protection. A consumer who skips the warning finds the old required check never reports, and PRs stay blocked.

**Risks:**
- A consumer keeps a custom file inside `planifest-framework/`. It lands in the backup, and the migration text tells the consumer to check the backup before deleting it.
- A PowerShell parse difference between 5.1 and 7 breaks the `.ps1` helper. The requirement lists the known cases, and CI runs both legs.

## Related ADRs

- ADR-002 - depends-on: the rename map defines the target names
- ADR-006 - related-to: the migrator order, old-path mapping, and Applies when check
- ADR-010 - related-to: the pack owns the marker files that step 5 removes
- RAVINTIO Zero 0000160 ADR 003 - extends: the same backup-instead-of-delete design

## Supersedes

- None.

## Superseded By

- None.
