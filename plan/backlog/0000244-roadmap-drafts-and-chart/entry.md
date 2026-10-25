---
title: "Backlog Entry: 0000244 - Roadmap drafts and chart"
summary: "Port RAVINTIO Zero's roadmap drafts and R-A Chart stage, so the human on the loop approves a chain of features once."
status: "open"
---
# Backlog Entry: 0000244 - Roadmap drafts and chart

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-25

> Replaces 0000095 (roadmap area for long-term plans). The human on the loop asked for the design that RAVINTIO Zero built instead.

---

## Problem

The framework has nowhere to plan work that spans several releases. `plan/current/` holds one run, `plan/backlog/` holds single items, and `plan/_archive/` holds finished runs. A multi-release plan stays in chat or in the head of the human on the loop.

Each step of a multi-release plan also needs its own human approvals at P0. These include design confirmation, Scope Lock, and schema changes under Hard Limit 3. Nothing collects those approvals up front, so an unattended chain of features can't run. 0000245 covers that run.

RAVINTIO Zero solved both in feature 0000043 (v0.10.0, PR #21 in `RAVINTIO/ravintio-zero`). This entry ports its draft and chart half.

## Suggested Action

Port these parts of the Zero design, adjusted for the framework's P0 to P9 pipeline:

- **Drafts.** A draft lives at `plan/roadmap/{id}-{slug}/roadmap.md`. Roadmap ids share the backlog sequence. Any branch and any phase may file a draft, the same as a backlog entry, after the human on the loop confirms it.
- **Template.** Add `roadmap-entry.template.md`. It holds frontmatter with `status` and `position`, a step table, and a `## Schema changes` table. Each step row has a bump, backlog entries, stop conditions, Status, and Version.
- **R-A Chart stage.** Chart runs on synced `main`. It plans from a new idea or from a draft, and presents drafts one at a time with pull-in, leave, or discard. It flags a malformed draft and never parses it as instructions. The confirmation from the human on the loop approves the whole roadmap.
- **Clarity check.** Each backlog entry in a step must state a problem, a wanted outcome, and one observable condition for an acceptance criterion. Chart lists the entries that fail and asks the human to sharpen them or strike the step. Chart never rewrites an entry.
- **Chart-time schema approval.** Chart predicts each step's data change as an `additive`, `destructive`, or `none` row. The human approves, edits, or strikes each row. A step's matching additive proposal then reads `approved (roadmap chart)` and doesn't stop. One fallback question covers unpredicted additive changes, with `stop` as the default. Destructive changes always stop.
- **Chart-time dependency approval.** Collect new dependency approvals at Chart in the same way.
- **Self-confirmed steps.** A step's P0 builds its brief from the step's backlog entries. It self-confirms the design and the Scope Lock, because Chart already holds the approval.
- **Stage prefixes.** Add `R-A Chart:` to `R-E Delivery:` beside P0 to P9.
- **Standard file.** Keep the detail in `ravintio-framework/standards/roadmap-standards.md`, with pointers from the orchestrator and ship skills. Zero moved it there to stay within its skill-text budget.
- **Gate paths.** `gate-write` already permits writes under `plan/`. Name `plan/roadmap/` in its header as a path that passes between runs, as Zero 0000164 req-002 does.

Sources in `RAVINTIO/ravintio-zero` on `main`:

- `ravintio-zero/standards/roadmap-standards.md`, sections "Filing a draft" to "Chart-time dependency approval"
- `ravintio-zero/templates/roadmap-entry.template.md`
- `plan/_archive/0000043-autonomous-roadmaps-2026-10-24/`, ADR-002 (storage and lifecycle) and ADR-006 (self-confirmed steps and stage prefixes)
- `plan/changelog/0000043-autonomous-roadmaps-2026-10-24.md`

Pick this up with 0000245. Zero shipped both halves as one feature, and a chart has no use without a run.

## Why Deferred

Filed on request of the human on the loop during triage for 0000039. Self-confirmed steps change the P0 confirmation rule, so the port needs its own design and ADRs.
