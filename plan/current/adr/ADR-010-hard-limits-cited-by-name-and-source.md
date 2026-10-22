---
title: "ADR 010: Hard limits cited by name and source"
summary: "Every hard-limit citation names the rule and its source list as well as its number, in the form 'the {name} rule ({source} Hard Limit {N})'. No list is renumbered. The dispatch template states the Write-or-Edit rule, and a suite fails on any bare citation."
status: "accepted"
version: "0.1.0"
---
# ADR-010 - Hard limits cited by name and source

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

This ADR serves [req-005](../requirements/req-005-hard-limits-cited-by-name.md) (US-005, backlog 0000157).

Five files keep their own numbered Hard Limits list:

- the orchestrator skill
- the boot templates
- the ship agent
- the migrator
- the loop runner

Two lists both hold a Hard Limit 8. The orchestrator's is the build-log rule. The boot template's is the Write-or-Edit rule. A bare "Hard Limit 8" can point at either, and agents have mistaken one for the other.

`standards/agent-dispatch-standards.md` doesn't state the Write-or-Edit rule. A subagent with no boot file can miss it.

Many files and suites cite limits by number. 0000035 req-008's suite finds boot Hard Limit 8 by its list item text. Other suites assert substrings such as `Hard Limit 6`.

## Decision

- **Citation form:** Every citation reads `the {name} rule ({source} Hard Limit {N})`. Two limits from one list read `the {name} and {name} rules ({source} Hard Limits {N} and {M})`.
- **Sources:** `{source}` is one of `orchestrator`, `boot`, `ship agent`, `migrator`, or `loop runner`. A citation inside the same file still names its source.
- **Names:** req-005's table fixes the name of each limit that a file cites today. A limit outside that table takes its name from its bold heading, and P3 logs it as a deviation.
- **Headings:** Headings use the same form, for example `## Commit cadence: the commit-cadence rule (orchestrator Hard Limit 7)`.
- **No renumbering:** No list changes its numbers, and no limit changes its text.
- **Number kept in the text:** The form keeps `Hard Limit {N}`, so suites that match that substring keep passing.
- **Dispatch template:** Both example prompts and the self-contained prompt rule in `agent-dispatch-standards.md` carry one sentence. The sentence states the Write-or-Edit rule and cites boot Hard Limit 8.
- **Out of scope:** `plan/_archive/`, `plan/changelog/`, and `planifest-framework/tests/` stay as they are. The root `CLAUDE.md`, `AGENTS.md`, and installed copies pick up the change when setup next runs.
- **Suite:** A new suite scans `planifest-framework/` without `tests/`, `docs/`, and `src/*/docs/`. It fails on any `Hard Limits? [0-9]+` match that the citation form doesn't wrap, and prints the file and line.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Renumber into one global list | One number per rule. No source needed in a citation. | Every installed `CLAUDE.md`, every archived ADR, and many suites cite the current numbers. Old citations would point at the wrong rule with no error. | It breaks every existing reference silently, and the design puts renumbering out of scope |
| Cite by name only and drop the number | Shortest citations. Names don't collide. | Suites that assert `Hard Limit {N}` fail. A reader can't find the rule in its numbered list quickly. | It costs suite churn and loses the link to the list |
| Prefix the number with the source only, as in "boot HL8" | Short and unambiguous | A reader still has to look the rule up to know what it says. The confusion in backlog 0000157 came from not knowing what the rule says. | The name is what stops the mix-up |
| Fix only the two Hard Limit 8 citations | Smallest change | The ship agent, migrator, and loop runner lists can collide the same way. No suite would stop a new bare citation. | It fixes today's collision and leaves the next one |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Skills, standards, templates, workflows, `pipeline-reference.md`, two script comments, and `component.yml` rewrite each bare citation. `agent-dispatch-standards.md` gains the Write-or-Edit sentence. A new suite, `test-0000036-req-005-hard-limits-cited-by-name.sh`, scans for bare citations. |
| setup-hook-integration | `docs/test-coverage.md` and `docs/interface-contract.md` rewrite their boot Hard Limit 8 citation. |
| docs | `architecture-overview.md`, `decisions-index.md`, and `component-registry.md` rewrite their citations. |

## Consequences

**Positive:**
- Every citation says which rule it means, so an agent can't apply the build-log rule where the Write-or-Edit rule applies.
- No list changes, so archived ADRs and older installed copies still point at the right limit by number.
- The suite stops a new bare citation from landing.

**Negative:**
- Citations get longer in every file that uses them. Short sentences in skills grow by several words, which costs context in every session.
- Each rule now has a name that must stay in step with its text. If a limit's meaning changes and its name doesn't, the name misleads more than a bare number would.
- Downstream projects keep the old bare citations in `CLAUDE.md` until they re-run setup. The two Hard Limit 8 entries still collide there until then.

**Risks:**
- An author writes a new limit into a list and cites it with a name not in the table. The suite checks the form, not the name, so two names for one rule can drift apart.
- The suite's pattern misses a citation written another way, such as "limit 8". Such a citation would pass unchecked.

## Related ADRs

- 0000035 ADR 011 (sanctioned scripts in boot Hard Limit 8) - related-to. Its suite finds the limit by list item text, which this ADR doesn't touch.
- 0000029 ADR 001 (boot files are disposable build outputs) - related-to. Setup writes `CLAUDE.md` and `AGENTS.md` from the templates, so those files change only on the next setup run.

## Supersedes

- None

## Superseded By

- None
