# Migration: re-run setup for 0.35.0

**Target:** every project with an installed Planifest setup, the framework source included. That covers its installed skills, templates, standards, and boot file.
**Scope:** files that `setup.sh` or `setup.ps1` installed. This migration never edits `plan/`, `docs/`, or application code.
**Safe to skip:** No. Without a re-run, the installed skills keep the old commit, scan, and revalidation steps that 0.35.0 replaces.

---

## Background

Framework version 0.35.0 changes setup-delivered files. A setup-delivered file reaches a project only when setup runs again. The update policy defines setup-delivered files (`planifest-framework/standards/framework-update-policy.md`).

Setup copies every template and every top-level standard when a skill's `bundle_templates` or `bundle_standards` key is absent or empty. So the list below names every changed template and standard, whether or not a manifest names it.

**0.35.0** (feature `0000037-green-ci-before-ship`) changes these files:

- `skills/planifest-codegen-agent/SKILL.md`: the requirement-ID scan before P3 closes, with the `Verified by` type check
- `skills/planifest-docs-agent/SKILL.md`: the post-P6 revalidation runs after the P6 commit and writes one `Revalidation (P6)` log line
- `skills/planifest-orchestrator/SKILL.md`: resume at P9 from the recorded PR, the held-back files step, and the P6 gate wording
- `skills/planifest-ship-agent/SKILL.md`: scan-then-commit at P7 and the P8 credential guard through the credential scan script
- `skills/planifest-spec-agent/SKILL.md`: a `Verified by` field on every new acceptance criterion
- `skills/planifest-validate-agent/SKILL.md`: a Type column in the coverage table
- `standards/autonomous-run-standards.md`: the pre-commit credential scan rule
- `templates/doc-checks.template.yml`: the revalidation runs after the P6 commit
- `templates/requirement.template.md`: the `Verified by` field in the acceptance criteria

Setup copies no `scripts/` folder. The credential scan script ships with the framework source, so a project that wants the scan needs `planifest-framework/` refreshed as well.

The orchestrator rechecks this list against the branch diff at the end of P6, before setup re-runs here.

---

## What This Migration Does

Re-run setup refreshes each tool the project uses. It refreshes these installed copies:

- the skills, with the templates and standards that setup bundles beside them
- the enforcement hooks and hook adapters
- the workflows
- the hook wiring in each settings file
- the boot file

Setup is safe to re-run. A fresh 0.35.0 install still runs this migration, and the second run gives the same result.

---

## Migrator Instructions

1. Confirm that `planifest-framework/component.yml` reports version `0.35.0` or later. If it's older, stop and ask the human on the loop to refresh `planifest-framework/` first. Setup from an older framework installs the old files.
2. Re-run setup for each tool the project uses, with the flags it normally uses. If you use `planifest-refresh-setup`, it rebuilds those flags for you.
3. Run `node planifest-framework/scripts/skill-drift-check.mjs` and expect exit 0.
4. Check that each installed `enforcement/*.mjs` file matches its source in `planifest-framework/hooks/enforcement/`. For Claude Code, the installed copies sit in `.claude/hooks/enforcement/`.
5. Check that the installed ship skill names the credential scan script. Also check that the installed requirement template holds the `Verified by` field.
6. If setup reported malformed settings JSON, report it as left for a person to fix. If setup warned that Node is missing, report that the same way.
7. Decide whether the run completed. A completed run meets every one of these conditions:
   - Setup exits 0 for each tool.
   - The drift check exits 0.
   - Every installed enforcement hook matches its source.
   - Setup reported no malformed settings file and no missing Node. Setup still exits 0 when it skips hook wiring for a malformed settings file.
8. If the run completed, record the outcome at `plan/_migrations/migrate-0.35.0-rerun-setup.md`. On any other result, the migrator records nothing, so the migration stays pending. It reports the failure to the human on the loop.

---

## Present Findings

Report to the human on the loop:
- each tool that setup ran for, and the flags it used
- the drift check's exit code
- each installed enforcement hook that still differs from its source
- whether the installed ship skill names the credential scan script and the requirement template holds the `Verified by` field
- anything left for a person to fix, such as malformed JSON or missing Node
- whether the run completed, as step 7 of the Migrator Instructions defines it

---

## Record

Once the human on the loop confirms the findings, the migrator records the outcome at `plan/_migrations/migrate-0.35.0-rerun-setup.md`. The migrator writes the record only after a completed run, as step 7 of the Migrator Instructions defines it. On any other result, the migrator records nothing, so the migration stays pending. It reports the failure to the human on the loop. This file stays where it is.
