---
title: "ADR 004: Old name reads"
summary: "Through 0.x, one environment variable, the old boot-file markers and ignore-file headers, and two setup marker files stay readable. Every other variable renames with no fallback."
status: "accepted"
version: "0.1.0"
---
# ADR-004 - Old name reads

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Component:** ravintio-framework, setup-hook-integration
**Date:** 2026-10-25

## Context

The rename moves 31 `PLANIFEST_*` variables to `RAVINTIO_*`. Most are internal. The pack's own scripts, hooks, tests, and CI set them, so no consumer depends on the old names.

Three kinds of old name reach the pack from outside.

- `PLANIFEST_SESSION_ID` is set by the OpenCode runtime, which the pack does not control.
- A consumer repo on 0.36.0 holds boot files and ignore files with the old block markers and headers. Setup must replace them, or each block appears twice after a re-run.
- The same repo holds `.planifest-setup-flags` and `.planifest-manifest`. Setup and refresh-setup need their contents once to carry flags forward and to prune old skill copies.

Two test suites for 0000030 check that retired telemetry text is absent. They simulate a consumer who still holds `PLANIFEST_TELEMETRY*`. Renaming those names would stop the checks testing that case.

ADR-003 sets the 0.x window and the 1.0.0 removal. This ADR lists what the window covers.

## Decision

Exactly these old names stay readable through every 0.x release. Version 1.0.0 removes them.

- `PLANIFEST_SESSION_ID` (req-003). The OpenCode adapter reads `RAVINTIO_SESSION_ID` first. It reads the old name only when the new one is unset. It prints no warning.
- The old boot-file markers and ignore-file headers (req-002). Setup recognises them and replaces each block with the RAVINTIO form, so no block appears twice.
- `.planifest-setup-flags` and `.planifest-manifest` (req-002). Setup and refresh-setup read each once, write the new `.ravintio-*` marker, and remove the old file. The migration helper leaves both in place for setup to read (req-006 step 5).
- `.planifest-session` is not read. The helper removes it, and `archive-current.mjs` still deletes it as well as the new marker (req-005).
- Added at P3: the em-dash guard still accepts the old `<!-- planifest-em-dash-allow -->` sentinel beside the new one, so consumer files that carry it keep their bypass.
- Added at P5 (finding S-02): `FAST_PATH_ENFORCEMENT_PATHS` in `path-rules.mjs` still lists the old OpenCode plugin path and the old workflow file, so a Fast Path record can't admit writes to them.

Every other variable renames with no fallback, because only the pack sets it.

The two test-0000030 telemetry-absence suites keep checking the old `PLANIFEST_TELEMETRY*` names. The brand guard allowlists them (req-007).

This mirrors RAVINTIO Zero 0000160 ADR 002. That ADR kept three consumer-facing aliases and renamed the rest.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Fallback for every variable | Maximum compatibility | Adds about 30 reads of names no consumer sets, each with a test | Dead code with no reader |
| Warn when an old name is read | Pushes the human on the loop to move | Adds noise to unattended OpenCode runs and setup re-runs | The consumer migration already tells them |
| No fallback at all | Cleanest code, no allowlist entries | An OpenCode session loses its ID. A re-run of setup duplicates blocks | The pack does not control the runtime variable or the files already in the consumer repo |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | The OpenCode adapter carries one fallback. Every other variable uses the new name only. |
| setup-hook-integration | Setup and refresh-setup read the old markers, headers, and two marker files once, then replace or remove them. |

## Consequences

**Positive:**
- An existing OpenCode session keeps its ID across the upgrade.
- A re-run of setup on a 0.36.0 repo leaves one block per boot file and ignore file.
- The read list is short and each entry has the same removal version.

**Negative:**
- Old-name code and brand guard allowlist entries stay in the pack until 1.0.0.
- Tests must cover both names, and the case where both are set.
- A reviewer who sees `PLANIFEST_` in live code must check this list to tell a planned read from a missed rename.

**Risks:**
- Nobody removes the reads at 1.0.0. The allowlist entries name the removal version, so the guard test flags them.
- A consumer skips the 0.x window and upgrades from 0.36.0 to 1.0.0. Setup then sees old markers it no longer recognises. The 1.0.0 release notes must name this.

## Related ADRs

- ADR-003 - depends-on (sets the 0.x window and the 1.0.0 removal)
- ADR-002 - related-to (the rename map lists these names)
- ADR-007 - related-to (the guard allowlist holds the retained names)
- ADR-010 - related-to (the pack owns the consumer marker files)
- RAVINTIO Zero 0000160 ADR 002 - mirrors (same pattern with different names)

## Supersedes

- None.

## Superseded By

- None.
