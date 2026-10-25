---
title: "Backlog Entry: 0000061 - Component manifest path is inconsistent with the framework's own self-manifest"
summary: "spec-agent and docs-agent state src/{component-id}/ as the only location for a component manifest and per-component docs, while ship-agent and codegen-agent both read and write ravintio-framework/component.yml — a schema-conformant component manifest outside src/. Downstream projects whose only component is not application code have no documented path."
status: "open"
---
# Backlog Entry: 0000061 - Component manifest path is inconsistent with the framework's own self-manifest

**Source feature:** filed from downstream repo `rapid-prototypes`, feature `0000002-backlog-reframe`
**Source phase:** P0 (routing analysis, after the same gap blocked `0000001-prototype-folder-selection`)
**Deferral source:** discovered mid-flight
**Date filed:** 2026-08-08

---

## Problem

Two framework skills treat `ravintio-framework/component.yml` as a first-class component manifest living outside `src/`:

- `skills/ravintio-ship-agent/SKILL.md:159` — *"No `product.yml` and the project has exactly one component (exit 4) — read the `version` field from the single `component.yml` (**for this repo: `ravintio-framework/component.yml`**)."*
- `skills/ravintio-codegen-agent/SKILL.md:163,166` — instructs P3 to bump `ravintio-framework/component.yml` and include it in the commit so the ship-agent reads the right version at tag time.

That file is schema-conformant against `templates/component.template.yml` — every top-level key matches (`id, name, feature, version, status, type, domain, summary, systemContext, responsibilities, exceptions, stack, contract, data, scope, risk, quality, pipeline, metadata`), with `type: "component-pack"`, one of the template's three enumerated values. It carries `feature: 0000025-…`, so it is maintained by this repo's own pipeline runs.

Five lines in two other skills state the opposite:

| File | Line | Text |
|------|------|------|
| `skills/ravintio-spec-agent/SKILL.md` | 24 | "Write the component manifest to `src/{component-id}/component.yml`" |
| `skills/ravintio-spec-agent/SKILL.md` | 31 | Component Manifest → `src/{component-id}/component.yml` |
| `skills/ravintio-spec-agent/SKILL.md` | 73 | "Write the draft manifest to `src/{component-id}/component.yml`. Create the component folder if it doesn't exist." |
| `skills/ravintio-docs-agent/SKILL.md` | 83 | Input: "The implementation at `src/{component-id}/`" |
| `skills/ravintio-docs-agent/SKILL.md` | 90 | "For each component in the feature, write to `src/{component-id}/docs/`" |

**What the inconsistency costs downstream.** In `rapid-prototypes`, two consecutive features have produced a component that is not application code — a governance instruction under `ravintio-overrides/instructions/`. Both times P1 and P6 demanded artifacts at `src/{component-id}/`, and both times producing them would have been actively wrong:

1. `gate-write` blocks the write, because `src/{component-id}/` is not in the confirmed design's `## Component Paths`; and
2. more importantly, it would have created an unprefixed component directly in `src/` — which in that repo is precisely the outcome its own governance instruction exists to prevent.

Both features omitted the artifacts and recorded the reason. That is a workaround repeated per-run, not a documented path.

**Intent is genuinely unclear, and this entry does not assume it.** `src/{component-id}/` may be a deliberate rule for *product* components with the framework's self-manifest a consciously-carved exception, rather than an oversight. Either reading is consistent with the evidence. What is not defensible is that the exception exists, is relied on by two skills, and is documented nowhere — so a downstream project cannot tell whether it is permitted to do the same thing.

## Suggested Action

Decide which of these is true, then make the skills say it:

- **The rule is `src/` for product components, and the framework's self-manifest is a named exception.** Then say so in `spec-agent` and `docs-agent`, and state what a downstream project should do when its only component is not application code — most likely "declare no component; omit the manifest and per-component docs, and record why."
- **A component may declare a path outside `src/`.** Then generalise the five hardcoded lines to read from the design's `## Component Paths` rather than assuming `src/{component-id}/`, which is what `gate-write` already does.
- **A distinct component type exists for non-code artifacts** — governance, configuration, documentation packs — exempt from data-contract, test-coverage and per-component-docs requirements. `type: "component-pack"` may already be close to this.

Whichever is chosen, the pair of skills and the two that read the self-manifest should agree, and `component-guide.md` should state where a manifest may live.

## Why Deferred

Filed from a downstream repo that does not maintain this framework. The fix belongs to `spec-agent`, `docs-agent`, and probably `component-guide.md`, none of which the filing project modifies.

The downstream project is not blocked: `rapid-prototypes` is resolving its own half with a repo-level override that declares no `src/` component for governance-only runs. This entry exists so the inconsistency is recorded upstream, not because anything is waiting on it.

Related, filed from the same downstream analysis: the P7 cross-reference check string-matches `plan/current/` rather than resolving relative links, and shipped ten broken links in a downstream archive while reporting success. Recorded downstream as `rapid-prototypes` backlog `0000004`; worth raising here separately if that repo's finding is judged to generalise.
