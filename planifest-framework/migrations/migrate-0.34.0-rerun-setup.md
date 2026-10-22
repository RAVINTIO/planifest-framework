# Migration: re-run setup for 0.33.0 and 0.34.0

**Target:** every project with an installed Planifest setup, the framework source included. That covers its installed skills, enforcement hooks, workflows, settings files, and boot file.
**Scope:** files that `setup.sh` or `setup.ps1` installed. This migration never edits `plan/`, `docs/`, or application code.
**Safe to skip:** No. Without a re-run, the installed hooks keep the write-gate bypasses that 0.34.0 closes.

---

## Background

Framework versions 0.33.0 and 0.34.0 both change setup-delivered files. A setup-delivered file reaches a project only when setup runs again. The 0.33.0 release shipped no re-run-setup migration, so this one migration covers both releases. The update policy defines setup-delivered files (`planifest-framework/standards/framework-update-policy.md`).

Setup copies every template and every top-level standard when a skill's `bundle_templates` or `bundle_standards` key is absent or empty. So the lists below name every changed template and standard, whether or not a manifest names it.

**0.33.0** (feature `0000035-write-gate-scope-and-path-hardening`) changed these files:

- `hooks/enforcement/path-rules.mjs`: the Fast Path scope record, links judged by their real target, and shared root finding
- `hooks/enforcement/gate-write.mjs`: uses the new path rules
- `hooks/enforcement/shell-write-guard.mjs`: honours the Fast Path scope record
- `hooks/enforcement/ratchet-check.mjs`: finds the root with the gate's rules
- `templates/standard-boot.md`: the sanctioned-scripts sentence in the Write-or-Edit rule (boot Hard Limit 8), and new hook descriptions
- `templates/cursor-boot.md`: the sanctioned-scripts sentence in the Write-or-Edit rule (boot Hard Limit 8)
- `skills/planifest-migrator/SKILL.md`: the Record step and the target check
- `skills/planifest-orchestrator/SKILL.md`: migration run state in Resume Detection
- `skills/planifest-ship-agent/SKILL.md`: the P7 product release step
- `templates/feature-brief.template.md`: a template change
- `templates/product.template.yml`: a template change
- `workflows/fast-path.md`: the Fast Path scope record

0.32.0 changed no setup-delivered file.

**0.34.0** (feature `0000036-pipeline-friction-and-gate-fixes`) changes these files:

- `hooks/enforcement/path-rules.mjs`: a non-regular `design.md` reads as no design, permitted names skip enforcement paths, and hook output is escaped
- `hooks/enforcement/ratchet-check.mjs`: escaped hook output
- `hooks/enforcement/em-dash-guard.mjs`: escaped hook output
- `templates/standard-boot.md`: hard limits cited by name and source
- `templates/loop-toggles.template.yml`: the design critic default
- `templates/build-log.template.md`: the run-mode anchor format
- `skills/planifest-orchestrator/SKILL.md`: the drift check in Resume Detection, the anchor code block, the critic default, and hard-limit citations
- `skills/planifest-ship-agent/SKILL.md`: commit subjects without placeholders, and hard-limit citations
- `skills/planifest-loop-runner/SKILL.md`: the critic default and the split step
- `skills/planifest-spec-agent/SKILL.md`: the split step and hard-limit citations
- `skills/planifest-design-critic/SKILL.md`: the split-step rubric row
- `skills/planifest-migrator/SKILL.md`: hard-limit citations
- `skills/planifest-adr-agent/SKILL.md`, `skills/planifest-codegen-agent/SKILL.md`, `skills/planifest-docs-agent/SKILL.md`, `skills/planifest-security-agent/SKILL.md`, and `skills/planifest-validate-agent/SKILL.md`: the commit-cadence heading cites its rule by name
- `standards/framework-update-policy.md`: the setup-delivered definition and the re-run-setup rule
- `standards/autonomous-run-standards.md` and `standards/agent-dispatch-standards.md`: hard-limit citations, the critic default, and the Write-or-Edit rule in the dispatch template
- `workflows/fast-path.md`: hard limits cited by name and source

The orchestrator rechecks this list against the branch diff at the end of P6, before setup re-runs here.

---

## What This Migration Does

Re-run setup refreshes each tool the project uses. It refreshes these installed copies:

- the skills, with the templates and standards that setup bundles beside them
- the enforcement hooks and hook adapters
- the workflows
- the hook wiring in each settings file
- the boot file

Setup is safe to re-run. A fresh 0.34.0 install still runs this migration, and the second run gives the same result.

---

## Migrator Instructions

1. Confirm that `planifest-framework/component.yml` reports version `0.34.0` or later. If it's older, stop and ask the human on the loop to refresh `planifest-framework/` first. Setup from an older framework installs the old files.
2. Re-run setup for each tool the project uses, with the flags it normally uses. If you use `planifest-refresh-setup`, it rebuilds those flags for you.
3. Run `node planifest-framework/scripts/skill-drift-check.mjs` and expect exit 0.
4. Check that each installed `enforcement/*.mjs` file matches its source in `planifest-framework/hooks/enforcement/`. For Claude Code, the installed copies sit in `.claude/hooks/enforcement/`.
5. Check that the boot file holds the sanctioned-scripts sentence. Also check that it names the Write-or-Edit rule.
6. If setup reported malformed settings JSON, report it as left for a person to fix. If setup warned that Node is missing, report that the same way.
7. Record the outcome at `plan/_migrations/migrate-0.34.0-rerun-setup.md`, and only once the run completes.

---

## Present Findings

Report to the human on the loop:
- each tool that setup ran for, and the flags it used
- the drift check's exit code
- each installed enforcement hook that still differs from its source
- whether the boot file holds the sanctioned-scripts sentence and names the Write-or-Edit rule
- anything left for a person to fix, such as malformed JSON or missing Node

---

## Record

Once the human on the loop confirms the findings, the migrator records the outcome at `plan/_migrations/migrate-0.34.0-rerun-setup.md`. The migrator writes the record only when the run completes. This file stays where it is.
