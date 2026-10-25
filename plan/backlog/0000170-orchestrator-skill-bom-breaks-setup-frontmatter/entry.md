---
title: "Backlog Entry: 0000170 - Orchestrator skill BOM breaks setup frontmatter"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000170 - Orchestrator skill BOM breaks setup frontmatter

**Source feature:** 0000036-pipeline-friction-and-gate-fixes
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

`ravintio-framework/skills/ravintio-orchestrator/SKILL.md` starts with a UTF-8 byte order mark (`ef bb bf`). `copy_skills()` in `ravintio-framework/setup.sh` parses each skill's frontmatter to read `bundle_templates`. The byte order mark stops that parse from finding the opening `---`, so setup ignores the orchestrator's `bundle_templates` list. Setup then copies every template into the orchestrator's `assets/` folder, as it does for a skill with no list.

The 0000036 P1 design critic found this. Other framework files may carry a byte order mark too.

## Suggested Action

Remove the byte order mark from the orchestrator skill, and make the setup frontmatter parse strip one leading byte order mark. Add a suite check that no source skill starts with one, or that setup handles it.

## Why Deferred

The defect predates 0000036 and changes setup behaviour, which this feature keeps out of scope. 0000036 req-002 strips a byte order mark from both copies before it compares, so the drift check works either way.
