---
title: "ADR 002: Autonomous as a third run-mode value"
summary: "plan/.run-mode gains a third value, autonomous, which sets both continuous_run and autonomous_run. Unknown values still read as interactive. P0 also writes the mode to a build-log Run mode row, which every reader after P0 uses. This amends 0000012-ADR-005."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - Autonomous as a third run-mode value

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Component:** planifest-framework
**Date:** 2026-10-19

## Context

0000012-ADR-005 persists the P0 run-mode choice in `plan/.run-mode`. The file holds `continuous` or `interactive`. Any other value reads as `interactive`.

Even `continuous` stops for the human on the loop at about ten points. These include P0 questions, P7 to P9 prompts, and loop escalations. Products that want hands-off runs fight the framework text with overrides. `ovelunor`'s `autonomous-after-p0.md` is one example.

req-001 asks for a mode that runs from the confirmed design to a raised PR. It stops only on exception-list items (ADR-003).

Since 0000032-ADR-002, the P9 marker step deletes `plan/.run-mode` before the tag. The ship agent and the P8 report run around that step and still need the mode. That gap is execution-plan D-009.

## Decision

- **Third value:** `plan/.run-mode` accepts `interactive`, `continuous`, or `autonomous`.
- **Session flags:** `autonomous` sets both `continuous_run: true` and `autonomous_run: true`. Every rule that names `continuous_run` therefore also holds in `autonomous`. Behaviour that only `autonomous` has checks `autonomous_run`.
- **Unknown values:** Any other value, an absent file, or an unreadable file reads as `interactive`. An older framework reads `autonomous` the same way.
- **Who sets it:** Only the human on the loop's answer to the P0 run-mode prompt writes `autonomous`. An override that describes hands-off running never counts as that choice. If an override conflicts with the `autonomous` text, the override wins.
- **Prompt:** The P0 prompt offers three options, and each names who acts (req-007).
- **Resume:** Resume Detection step 6 restores all three values without asking. Restoring `autonomous` sets both flags.
- **Build-log row (D-009):** The build-log `## Header` table gains a `Run mode` row. P0 writes it for every mode, and updates it if the mode changes. Every reader after P0 uses the row. That includes the ship agent at P7 to P9 and the P8 report. No reader uses `plan/.run-mode` after the P9 marker step deletes it.
- **Rule text:** The run-mode table lives in `standards/autonomous-run-standards.md` under `## Run modes` (ADR-001).

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| A separate `plan/.autonomous` flag file next to `plan/.run-mode` | `plan/.run-mode` keeps its two values | Two files can disagree. The P9 marker step must delete a fourth marker. | One value in one file can't contradict itself |
| A loop-toggles key, such as `autonomous: on` | Uses the existing override file | Makes the mode a standing project setting, not a per-run choice. The framework never writes `planifest-overrides/`. | The mode is a per-run choice at P0 |
| Let a hands-off override set `autonomous` | Products with overrides need no P0 answer | An agent could read override prose as consent. It removes the human on the loop's explicit choice. | The human on the loop must choose the mode |
| Have later phases read `plan/.run-mode` until P9 ends | No new build-log row | The P9 marker step deletes the file before the tag and the final report | Readers after the marker step would read `interactive` |
| Carry the mode in session memory only after P0 | No file change | Lost on context clear or resume. This is the failure 0000012-ADR-005 fixed. | Breaks resume |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | The orchestrator's run-mode prompt, recording text, and Resume Detection step 6 change. The build-log template gains a `Run mode` row. The ship and build assessment skills read that row. A new `## Run modes` section lands in `autonomous-run-standards.md`. |

## Consequences

**Positive:**
- A product can run hands-off from the confirmed design to a raised PR without overrides that fight the framework.
- Every `continuous_run` rule applies in `autonomous` with no edit, so the existing P1 to P6 exceptions carry over.
- The build log records the run mode for the whole run, including after the marker step.

**Negative:**
- Run mode now sits in two places: `plan/.run-mode` until P9 and the build-log row for the whole run. A hand edit to one can leave them out of step.
- Every new `autonomous` behaviour must check `autonomous_run`, not `continuous_run`, or it leaks into `continuous`.

**Risks:**
- A run that resumes under an older framework reads `autonomous` as `interactive` with no warning (R-008). The 0.32.0 release note tells products to refresh the framework before they pick `autonomous`.
- A downstream override conflicts with the new text and a fresh session resolves it the wrong way (R-009). The standards file states that the override wins.

## Related ADRs

- 0000012-ADR-005 (run-mode sentinel file) - amended by this ADR
- 0000023-ADR-001 (continuous_run exception for P1 to P3) - depends-on. `autonomous` inherits it through `continuous_run`.
- 0000032-ADR-002 (session markers cleared in P9) - related-to. Its marker step deletes the file, which is why the build-log row exists.
- ADR-003 - depends-on. It defines what `autonomous` still stops for.
- ADR-004 - related-to. It reads the mode for its toggle defaults.
- ADR-006 - related-to. The ship agent reads the build-log row.

## Supersedes

- Amends 0000012-ADR-005. The file and its default stay. The value set grows to three, and later phases read the mode from the build-log row.

## Superseded By

- None
