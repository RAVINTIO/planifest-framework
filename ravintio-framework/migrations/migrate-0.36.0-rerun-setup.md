# Migration: re-run setup for 0.36.0

**Target:** every project with an installed Planifest setup, the framework source included. That covers its installed skills, templates, standards, and boot file.
**Scope:** files that `setup.sh` or `setup.ps1` installed. This migration never edits `plan/`, `docs/`, or application code.
**Safe to skip:** No. Without a re-run, an installed orchestrator keeps the 77,635-byte `SKILL.md`, and the token saving does not reach that project.

---

## Background

Framework version 0.36.0 changes setup-delivered files. A setup-delivered file reaches a project only when setup runs again. The update policy defines setup-delivered files (`planifest-framework/standards/framework-update-policy.md`).

Setup copies every template and every top-level standard when a skill's `bundle_templates` or `bundle_standards` key is absent or empty. So the list below names every changed template and standard, whether or not a manifest names it.

**0.36.0** (feature `0000038-token-efficiency-windows-shard`) changes these files:

- `skills/planifest-orchestrator/SKILL.md`: Phase 0 and Adoption Modes move out to reference files
- `skills/planifest-orchestrator/references/phase-0-assess-and-coach.md`: new reference file that the orchestrator loads at P0
- `skills/planifest-orchestrator/references/adoption-modes.md`: new reference file that the orchestrator loads for adoption modes
- `skills/planifest-codegen-agent/SKILL.md`: quiet mode
- `skills/planifest-refactor/SKILL.md`: quiet mode
- `skills/planifest-validate-agent/SKILL.md`: quiet mode
- `skills/planifest-ship-agent/SKILL.md`: the model value
- `standards/agent-dispatch-standards.md`: the model values and the decomposition size floor
- `templates/standard-boot.md`: the partial-read directive for files over about 20 KB
- `planifest-overrides/instructions/custom-002-prefer-subagent-decomposition.md`: the size floor text, which setup delivers into the generated boot file

Setup copies `references/` folders with the skill, so the two new reference files reach a project only through a re-run. An installed orchestrator that lacks them cannot load Phase 0.

The orchestrator rechecks this list against the branch diff at the end of P6, before setup re-runs here.

---

## What This Migration Does

Re-run setup refreshes each tool the project uses. It refreshes these installed copies:

- the skills, with the templates, standards, and reference files that setup bundles beside them
- the enforcement hooks and hook adapters
- the workflows
- the hook wiring in each settings file
- the boot file, including the custom-002 text and the partial-read directive

Setup is safe to re-run. A fresh 0.36.0 install still runs this migration, and the second run gives the same result.

---

## Migrator Instructions

1. Confirm that `planifest-framework/component.yml` reports version `0.36.0` or later. If it's older, stop and ask the human on the loop to refresh `planifest-framework/` first. Setup from an older framework installs the old files.
2. Re-run setup for each tool the project uses, with the flags it normally uses. If you use `planifest-refresh-setup`, it rebuilds those flags for you.
3. Run `node planifest-framework/scripts/skill-drift-check.mjs` and expect exit 0.
4. Check that each installed `enforcement/*.mjs` file matches its source in `planifest-framework/hooks/enforcement/`. For Claude Code, the installed copies sit in `.claude/hooks/enforcement/`.
5. Check that the installed orchestrator skill holds both `references/phase-0-assess-and-coach.md` and `references/adoption-modes.md`. Also check that the generated boot file holds the partial-read directive for files over about 20 KB.
6. If setup reported malformed settings JSON, report it as left for a person to fix. If setup warned that Node is missing, report that the same way.
7. Decide whether the run completed. A completed run meets every one of these conditions:
   - Setup exits 0 for each tool.
   - The drift check exits 0.
   - Every installed enforcement hook matches its source.
   - Setup reported no malformed settings file and no missing Node. Setup still exits 0 when it skips hook wiring for a malformed settings file.
8. If the run completed, record the outcome at `plan/_migrations/migrate-0.36.0-rerun-setup.md`. On any other result, the migrator records nothing, so the migration stays pending. It reports the failure to the human on the loop.

---

## Present Findings

Report to the human on the loop:
- each tool that setup ran for, and the flags it used
- the drift check's exit code
- each installed enforcement hook that still differs from its source
- whether the installed orchestrator holds both reference files and the boot file holds the partial-read directive
- anything left for a person to fix, such as malformed JSON or missing Node
- whether the run completed, as step 7 of the Migrator Instructions defines it

---

## Record

Once the human on the loop confirms the findings, the migrator records the outcome at `plan/_migrations/migrate-0.36.0-rerun-setup.md`. The migrator writes the record only after a completed run, as step 7 of the Migrator Instructions defines it. On any other result, the migrator records nothing, so the migration stays pending. It reports the failure to the human on the loop. This file stays where it is.
