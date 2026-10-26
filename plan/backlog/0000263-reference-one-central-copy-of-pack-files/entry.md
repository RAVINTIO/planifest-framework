---
title: "Backlog Entry: 0000263 - reference one central copy of pack files"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000263 - reference one central copy of pack files

**Source feature:** none (human request, mirrors RAVINTIO Zero roadmap 0000168 step 3, feature 0000171-faster-setup-ps1-tests)
**Source phase:** none (outside a pipeline run)
**Deferral source:** human request
**Date filed:** 2026-10-25

---

## Problem

`setup.sh` and `setup.ps1` copy pack files into each installed skill's `assets/` and `references/` folders. The `bundle_templates` and `bundle_standards` frontmatter in each `SKILL.md` drives the copy. A skill with no list gets every file. Setup always copies every schema.

The install in this repo shows the cost:

- `.claude/skills/` holds 777 installed files across 21 skills.
- 729 of those files are copies of 67 distinct files from `ravintio-framework/templates/`, `standards/`, and `schemas/`.
- 17 of the 21 source skills declare `bundle_templates` or `bundle_standards`.

Each copy can drift from its source, and every install repeats the work. Setup also rewrites relative links such as `../standards/` to point at the bundled copies.

Skills also name pack files in mixed ways. A count across `ravintio-framework/skills/` finds these forms:

- Full pack path: 63 uses, for example `ravintio-framework/standards/autonomous-run-standards.md` in `ravintio-validate-agent/SKILL.md` line 92.
- Short path: 21 uses, for example `standards/autonomous-run-standards.md` in `ravintio-validate-agent/SKILL.md` line 53.
- Relative or bare name: for example `../standards/code-quality-standards.md` in `ravintio-codegen-agent/SKILL.md` line 37, and `agent-dispatch-standards.md` in the same file at line 210.

A reader or agent can't tell from a short path or bare name which folder holds the file.

## Suggested Action

Mirror the three-part fix in RAVINTIO Zero roadmap 0000168 step 3 (feature 0000171-faster-setup-ps1-tests):

1. Stop bundling in both setup scripts and remove the `bundle_templates` and `bundle_standards` frontmatter fields. Skills then reference one central copy in the pack folder.
2. Rewrite every short path, relative path, and bare name in skills to the full pack path, such as `ravintio-framework/templates/x.md`.
3. Add a test that fails if a skill names a template, standard, or schema by anything other than a full pack path. The test also fails if that path does not exist.

**Wanted outcome:** a fresh install holds no copy of any pack file under `.claude/skills/*/assets/` or `references/`. Every pack-file reference in a skill is a full pack path that resolves to an existing file.

Check 0000232 at pickup. It concerns links to `standards/reference/` that bundling misses, and this change may close it.

## Positioning note (2026-10-26)

The 0000279 differentiation review keeps this port as it stands. It is install infrastructure and doesn't change how Framework differs from Zero.

## Why Deferred

The human asked for this to match the Zero change. It changes how setup installs skills on every tool, so it needs its own design and parity tests for both setup scripts.
