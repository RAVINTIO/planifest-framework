---
title: "ADR 015: Data ownership of run state and overrides"
summary: "planifest-framework owns the run state this feature adds or changes: plan/.run-mode, plan/current/ with its streams/ folder, and plan/current/.archive-target. The product's human on the loop owns the planifest-overrides/ files the feature reads. The framework only reads them, and setup never writes or overwrites them."
status: "accepted"
version: "0.1.0"
---
# ADR-015 - Data ownership of run state and overrides

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Component:** planifest-framework
**Date:** 2026-10-19

## Context

Hard Limit 5 says one component owns each piece of data. Every data ownership mapping needs an ADR.

This feature adds run state and reads new override files:

- `plan/.run-mode` gains a third value, `autonomous` (ADR-002).
- `plan/current/streams/` holds stream state files and join records (ADR-013, ADR-014).
- `plan/current/.archive-target` records the archive folder for a resumed P7 (ADR-010).
- `planifest-overrides/exception-list.yml` adds exception items (ADR-003).
- `planifest-overrides/release-budget.yml` sets a release budget (ADR-008).
- `planifest-overrides/doc-checks.yml` declares a doc-check command (ADR-012).
- `planifest-overrides/loop-toggles.yml` gains a `parallel_streams` key (ADR-013).

0000005-ADR-002 places project overrides in `planifest-overrides/`, beside the framework. 0000016-ADR-003 keeps loop toggles there so agents can't enable loops for themselves. 0000032-ADR-002 gives `planifest-framework` ownership of the session markers.

The override files decide what an `autonomous` run may do without the human on the loop. An agent that could write them could add or drop its own exceptions, budgets, or checks.

## Decision

- **Framework-owned run state:** `planifest-framework` owns these paths:
  - `plan/.run-mode`
  - `plan/current/` and everything under it, including `streams/`
  - `plan/current/.archive-target`

  Framework skills, scripts, and hooks are the only writers.
- **Writers by path:**

  | Path | Writer | Readers |
  |------|--------|---------|
  | `plan/.run-mode` | The orchestrator at P0. The P9 marker step deletes it (0000032-ADR-002). | The orchestrator at resume. Later phases read the build-log `Run mode` row instead (D-009). |
  | `plan/current/streams/*.md` | The orchestrator only. Stream subagents report back and never write these files. | Resume Detection step 6b, `stream-reconcile.mjs`, and P8. |
  | `plan/current/.archive-target` | `archive-current.mjs` only. | `archive-current.mjs` and Resume Detection step 2a. |

- **Human-owned overrides:** The product's human on the loop owns these files:
  - `planifest-overrides/exception-list.yml`
  - `planifest-overrides/release-budget.yml`
  - `planifest-overrides/doc-checks.yml`
  - `planifest-overrides/loop-toggles.yml`

  The framework ships a template for each one under `planifest-framework/templates/`. The human copies a template to set a value.
- **Read only:** Framework skills, agents, scripts, and hooks only read these four files. No phase writes, edits, or deletes them, in any run mode.
- **Setup:** `setup.sh` and `setup.ps1` never create, write, or overwrite these four files. Setup's existing write to `planifest-overrides/setup-config/{tool}.md` (0000025-ADR-002) stays as it is, and it is the only override path setup writes.
- **Absent or invalid files:** An absent file means the framework default. An invalid file falls back to the default with a logged reason. The framework never repairs the file.
- **Archive:** P7 moves `plan/current/`, `streams/` included, into the archive. Archived copies stay framework-owned and read-only.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Framework settings in `planifest-framework/` | One place for all framework files | Setup refreshes overwrite the folder, so product values are lost | 0000005-ADR-002 keeps overrides outside the framework |
| Setup installs default override files | The human sees every option at once | A refresh could overwrite a human's values. A shipped `on` would self-enable a loop. | Breaks 0000016-ADR-003's rule that agents can't self-enable |
| Agents may write overrides on instruction | Faster for the human on the loop | An autonomous run could widen its own limits | The exception list and budgets limit the agent, so the agent can't own them |
| Stream subagents write their own state files | Less orchestrator work | Concurrent writers, and a subagent can't see the join | The join owner (ADR-014) must hold the record |
| Run state under `planifest-overrides/` | Survives archive | Mixes per-run state with durable product settings | Run state belongs to one run and archives with it |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Owns and writes the run-state paths. Ships four override templates and reads the copied files. Setup scripts stay unchanged for these files. |

## Consequences

**Positive:**
- An `autonomous` run can't change its own exception list, budget, doc check, or toggles.
- Each run-state file has one writer, so concurrent streams don't race on it.
- A setup refresh never loses a product's settings.

**Negative:**
- The human on the loop must copy each template by hand to set a value.
- A typo in an override falls back to the default, which the human may not notice until they read the build log.

**Risks:**
- A future skill could write an override by mistake. Text-level tests should assert that no skill or script names an override path as a write target.
- A human could commit a hostile `doc-checks.yml` command. The trust level matches the repo's own scripts, since the same human owns both.

## Related ADRs

- 0000005-ADR-002 (planifest-overrides sibling directory) - depends-on.
- 0000016-ADR-003 (loop toggles in `planifest-overrides/`) - extends. The same ownership rule now covers three more files.
- 0000025-ADR-002 (setup-config overrides precedence) - related-to. Setup keeps its one override write, `setup-config/{tool}.md`.
- 0000032-ADR-002 (session markers owned by the framework) - extends. Framework ownership now covers `streams/` and `.archive-target`.
- ADR-002, ADR-003, ADR-008, ADR-010, ADR-012, ADR-013, and ADR-014 - related-to. Each adds a path this ADR assigns.

## Supersedes

- None

## Superseded By

- None
