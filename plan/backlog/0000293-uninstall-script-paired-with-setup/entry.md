---
title: "Backlog Entry: 0000293 - an uninstall script that pairs with setup"
summary: "Add uninstall.sh and uninstall.ps1 that remove everything setup installed and nothing else, so a pack only needs to know about itself and another pack can install cleanly."
status: "open"
---
# Backlog Entry: 0000293 - an uninstall script that pairs with setup

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-28

---

## Problem

Framework has `setup.sh` and `setup.ps1` but no way to remove an install. Setup writes to many places outside `ravintio-framework/`:

- skill folders under the tool's skills folder, plus `.ravintio-manifest`
- hook files under `.claude/hooks/enforcement/` and the other tools' hook folders
- hook entries in `.claude/settings.json` and the other tools' wiring files
- the boot file, such as `CLAUDE.md`
- `.gitattributes`, `.gitignore`, and the tool ignore files (0000278 lists them)
- `git config core.hooksPath ravintio-framework/hooks`
- `.github/workflows/ravintio.yml`, when it is absent
- the opencode plugin and its `opencode.json` registration
- the flags-used marker

0000292 looks at keeping RAVINTIO Zero and Framework in one repository and switching with setup. Without an uninstall, each setup must know the other pack's hooks and files to clear them. The human on the loop wants each pack to know only about itself. Each pack's uninstall clears its own install, then the other pack's setup runs on a clean tree.

Related entries show the same gap from other sides:

- 0000090: setup clean-up removes a person's own files in stale hook folders.
- 0000255 and 0000259: the skill prune trusts the paths the manifest lists.
- 0000258: the old opencode plugin stays registered after an upgrade.
- 0000272: the manifest lists folders setup didn't install.

The RAVINTIO strategy (section 11) asks each repository for upgrade and removal instructions, and a dry-run or inspect mode.

## Suggested Action

1. **Install record.** Make setup write one install record of everything it changed:
   - each file it created or replaced, with a content hash
   - each settings entry it added, by event, matcher, and command
   - each line block it added to `.gitignore` or `.gitattributes`
   - each git config value it set, with the value before
   - whether it created `.github/workflows/ravintio.yml` or skipped it

   This replaces `.ravintio-manifest` and fixes 0000272 on the way.
2. **Uninstall scripts.** Add `ravintio-framework/uninstall.sh` and `uninstall.ps1`. They take the same tool names as setup, including `all`. They remove only what the install record lists:
   - Delete a file only if its hash still matches. Report a changed file and leave it.
   - Remove only the settings commands setup added. Keep every user command, with the per-command filter setup already uses.
   - Remove only the line blocks setup added.
   - Unset `core.hooksPath` only if it still points at `ravintio-framework/hooks`. Restore the value before, if there was one.
   - Leave `.github/workflows/ravintio.yml` by default, because the project's CI may depend on it. Report it.
3. **Durable state stays.** Never touch `plan/`, `docs/`, `src/`, `ravintio-overrides/`, `product.yml`, or the pack folder. Those hold the project's work, not the install.
4. **Refuse during a run.** Stop if `plan/current/` holds artefacts or any run sentinel exists, such as `plan/.orchestrator-active`.
5. **Dry run.** Default to listing what would change. Change files only with `--apply`.
6. **Sanction the scripts.** Add `uninstall.sh` and `uninstall.ps1` to the sanctioned scripts in boot Hard Limit 8 and to `FAST_PATH_ENFORCEMENT_PATHS`.
7. **Tests.** A round trip of setup then uninstall leaves the tree as it was before setup. A user hook, a user skill, and a user `.gitignore` line survive. A changed hook file survives with a report. Both shells give the same result.
8. **Zero.** File the matching entry in the Zero repository, so Zero gets its own uninstall with the same contract.

Switching packs then becomes two commands, for example:

```sh
ravintio-framework/uninstall.sh claude-code --apply
ravintio-zero/setup.sh claude-code
```

## Wanted outcome

After setup then uninstall, `git status` shows no change from before setup, apart from files a person changed. The other pack's setup then runs with no leftover hooks, skills, or git config from the first.

## Why Deferred

The human on the loop asked for it while weighing 0000292. It changes setup and adds enforcement-adjacent scripts, so it needs the Feature Pipeline. It should land before any trial of 0000292.
