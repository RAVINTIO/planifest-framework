# Migration: rename a consumer repo to RAVINTIO for 0.37.0

**Target:** every consumer project that still holds the 0.36.0 pack, its overrides folder, or the backup this helper leaves.
**Applies when:** `planifest-framework/`, `planifest-overrides/`, or `.ravintio-backup/planifest-framework/` exists at the project root.
**Scope:** the old pack folder, the old overrides folder, the installed CI workflow, the session marker, the setup flags file and skills manifest in each tool folder, the skill folders a manifest lists, and `.git/info/exclude`. This migration never edits `plan/`, `docs/`, or application code.
**Safe to skip:** No. Setup stops while the old pack or the old overrides folder exists, so the project can't take 0.37.0 until this migration runs.

---

## Background

Framework version 0.37.0 (feature `0000039-ravintio-rebrand`) renames the pack to RAVINTIO. The pack folder, the overrides folder, the skills, the workflow, and the environment variables all take the new name. Setup handles the skills and the installed files. Setup doesn't move the old folders, so this migration does.

The helper backs up and never deletes (ADR-005). It moves the old pack to `.ravintio-backup/` with a plain rename. The only file it removes is the session marker.

This source repo and a fresh consumer hold none of the three folders on the **Applies when** line. The migrator records `not applicable` for them. A consumer that ran the helper by hand still holds the backup, so the condition stays true. The migrator then runs a helper rerun as a check pass and records `applied`.

---

## Run order

1. Copy the new `ravintio-framework/` folder into the project.
2. From the project root, run the helper:
   - Bash: `bash ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.sh`
   - PowerShell: `pwsh -File ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.ps1`
3. Run `ravintio-framework/setup.sh` or `setup.ps1` for each tool the project uses, before the next commit.

The project root may sit below the git top level. Run the helper from the folder that holds `ravintio-framework/`.

---

## What the helper does

The helper runs these steps in order. Each step skips work that is already done, so a rerun is safe. A run stopped after any step completes the rest on its next run.

1. Stops if `ravintio-framework/` is absent. It moves nothing.
2. Checks every stop condition before the first move. It stops with exit 1 for any of these:
   - Both the old and the new overrides folder exist.
   - Both the old workflow and `.github/workflows/ravintio.yml` exist.
   - The backup of the old pack exists while the old pack is still in place.
   - git holds a staged edit, other than a deletion, under the old pack.
   - The old pack, either overrides folder, `.ravintio-backup`, or either workflow file is a symbolic link or a junction.
   - git holds the old pack as a submodule. Run `git submodule deinit` and `git rm` on it first.
   - A tool folder holds both `.planifest-setup-flags` and `.ravintio-setup-flags`.
   - A skills folder holds both `.planifest-manifest` and `.ravintio-manifest`.
   - A manifest lists a `planifest-X` skill folder, and both it and `ravintio-X` exist.

   Just before each move, the helper checks again that the target is absent. If the target appeared after step 2, the helper stops at that step with exit 1.
3. Moves the old overrides folder to `ravintio-overrides/`. It uses `git mv` when git tracks the folder.
4. Renames the workflow to `.github/workflows/ravintio.yml`. It rewrites these parts:
   - the line `name: Planifest Strict Pipeline` to `name: RAVINTIO Strict Pipeline`, when it is the whole line. Setup skips a workflow that already exists, so only the helper changes this line.
   - the old pack path to `ravintio-framework/`.
   - each pack-owned variable name in the list below, as a whole name.

   A name that follows `secrets.` or `vars.` keeps its old prefix, even when it matches a pack-owned name. It names a consumer secret or variable. A name that is not on the list also keeps its old prefix.
5. Removes the `.claude/` session marker. Then it renames the markers in each tool folder: `.claude`, `.cursor`, `.windsurf`, `.clinerules`, `.agents`, `.github`, `.gemini`, and `.opencode`.
   - It renames `.planifest-setup-flags` to `.ravintio-setup-flags`. The content stays the same.
   - It renames `skills/.planifest-manifest` to `skills/.ravintio-manifest`.
   - It renames each `planifest-X` skill folder the manifest lists to `ravintio-X`.
   - It rewrites the manifest through a temporary file in the same folder. Each kept entry becomes the real skills folder joined with its name.
   - It drops an entry whose parent is not the real skills folder. It also drops one whose last part doesn't match `^[A-Za-z0-9][A-Za-z0-9._-]*$` or ends in `.`. It prints a `WARNING:` line for each dropped entry and never touches its target.
   - It removes its temporary manifest when a write fails. Before it reads each manifest, it removes any regular file left by a stopped run whose name matches `^\.ravintio-manifest\.[A-Za-z0-9]{6}$`. It leaves every other name.

   It uses `git mv` when git tracks a marker or a skill folder. If the tool folder, its `skills` folder, or a marker file is a symbolic link, it skips that tool folder with a warning.
6. Stops git tracking of the old pack, then moves it to `.ravintio-backup/planifest-framework/`. It adds `.ravintio-backup/` to `.git/info/exclude` once.
7. Prints the setup command to run next. It prints one command for each `.ravintio-setup-flags` whose `tool` value is a tool setup accepts. That command carries the `--include-full-skill-library` and `--strict-orchestrator` flags the file holds, and no other flag. If no flags file names such a tool, it prints the generic command.
8. Prints the branch protection warning.

On any stop, the helper names the step and lists what it already moved. If a parent folder such as `.github` or `.claude` is a symbolic link, the helper skips only the step that writes through it. It prints a `WARNING:` line and carries on.

Both helpers print the same text and exit with the same codes:

| Exit code | Meaning |
|-----------|---------|
| `0` | The run completed, or there was nothing to do |
| `1` | A stop condition held, or a move failed |
| `3` | The test hook `RAVINTIO_MIGRATE_STOP_AFTER=N` stopped the run after step N |

---

## Renamed variables

Step 4 rewrites each of these names from the old `PLANIFEST_` prefix to the `RAVINTIO_` prefix, as whole names only. The list is the req-003 inventory. The retired telemetry names aren't on it.

- `RAVINTIO_ADAPTER_CMD`
- `RAVINTIO_BASENAME`
- `RAVINTIO_BOOT`
- `RAVINTIO_DESIGN`
- `RAVINTIO_EM_DASH`
- `RAVINTIO_FILE_PATH`
- `RAVINTIO_GATE`
- `RAVINTIO_GITLEAKS`
- `RAVINTIO_HOOKS_BASE`
- `RAVINTIO_NAME`
- `RAVINTIO_OPENCODE_JSON`
- `RAVINTIO_PLUGIN_REF`
- `RAVINTIO_PRESENCE`
- `RAVINTIO_PROMOTED_BY`
- `RAVINTIO_PROMOTION_DATE`
- `RAVINTIO_RATCHET`
- `RAVINTIO_REGRESSION_DIR`
- `RAVINTIO_SESSION_ID`
- `RAVINTIO_SETTINGS`
- `RAVINTIO_SETTINGS_JS_HELPERS`
- `RAVINTIO_SETTINGS_REL`
- `RAVINTIO_SHARD_COUNT`
- `RAVINTIO_SHARD_INDEX`
- `RAVINTIO_SHELL_GUARD`
- `RAVINTIO_SOURCE_FEATURE`
- `RAVINTIO_TIER`
- `RAVINTIO_TMP`
- `RAVINTIO_TRIGGER`

---

## Your own override files

The helper moves `ravintio-overrides/` but doesn't rewrite the text inside it. Those files are yours. If an instruction or setup config there names a `planifest-framework/` path, change it to `ravintio-framework/`. Search with `grep -rn 'planifest-framework/' ravintio-overrides/`.

## Branch protection

The workflow name is now `RAVINTIO Strict Pipeline`. GitHub matches a required status check by its job name, and the job is still `validate-branch`. So a branch protection rule that requires `validate-branch` needs no change. Don't require `RAVINTIO Strict Pipeline`: that is a workflow name, and no check reports under it.

---

## Backup clean-up

The old pack stays in `.ravintio-backup/planifest-framework/`, and git ignores it through `.git/info/exclude`. Check it for any custom file of yours, and move that file somewhere you keep. Then delete `.ravintio-backup/` yourself. The helper never deletes it. `git clean -x` deletes it, because git ignores it, so check the backup before you run that command.

---

## Migrator Instructions

1. Read the **Applies when** line. If none of the three folders exists, report `Skipped:` with the reason and record `not applicable`.
2. Confirm that `ravintio-framework/` exists at the project root. If it doesn't, stop and ask the human on the loop to copy it in.
3. Run the helper for the project's shell from the project root. If the human on the loop already ran it, this run is a check pass and prints `Nothing to do`.
4. If the helper exits 1, report its `ERROR:` line and the step it names. Record nothing, so the migration stays pending.
5. If the helper exits 0, run setup for each tool the project uses, with the flags it normally uses.
6. Decide whether the run completed. A completed run meets every one of these conditions:
   - The helper exits 0.
   - Setup exits 0 for each tool.
   - The project root holds neither the old pack nor the old overrides folder.
7. If the run completed, record the outcome at `plan/_migrations/migrate-0.37.0-ravintio-rename.md`. On any other result, record nothing and report the failure to the human on the loop.

---

## Present Findings

Report to the human on the loop:
- each step the helper took and each step it skipped
- each `WARNING:` line, such as a linked parent folder or a linked exclude file
- the setup command it ran, and its exit code
- the branch protection warning
- the backup folder, with the reminder to check it and delete it

---

## Record

Once the human on the loop confirms the findings, the migrator records the outcome at `plan/_migrations/migrate-0.37.0-ravintio-rename.md`. The migrator writes the record only after a completed run, as step 6 of the Migrator Instructions defines it. On any other result, the migrator records nothing, so the migration stays pending. This file stays where it is.
