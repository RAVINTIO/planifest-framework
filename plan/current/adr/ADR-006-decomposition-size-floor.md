---
title: "ADR 006: Decomposition size floor with named exemptions"
summary: "A subagent is for a unit that needs its own reads or many tool calls. Small independent units run as parallel tool calls. Nine fresh-context roles are exempt by name, and no maker-checker split or TDD step is removed."
status: "accepted"
version: "0.1.0"
---
# ADR-006 - Decomposition size floor with named exemptions

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Component:** planifest-framework (the override file sits outside it)
**Date:** 2026-10-24

## Context

`planifest-overrides/instructions/custom-002-prefer-subagent-decomposition.md` tells agents to split long or multi-unit work into parallel subagents by default. Each subagent starts a fresh context and pays for it. A small unit, such as three one-line reads, costs more as a subagent than as a parallel tool call.

Some dispatches exist to give a fresh context, and the saving must not touch them. A fresh context is how the maker-checker split and the TDD red and green steps stay independent.

`setup.sh` `append_override_instructions` re-appends every file in `planifest-overrides/instructions/` into the generated boot file. So a setup re-run refreshes the copy of custom-002 in `CLAUDE.md`.

## Decision

1. Add a size floor to custom-002 and to the Agent Dispatch Template in `agent-dispatch-standards.md`. Dispatch a subagent only when the unit needs its own reads or many tool calls. Run small independent units as parallel tool calls in the main thread.
2. Both files name nine exempt roles. The floor never applies to them, whatever the unit size:
   - design critic
   - security review
   - cross-model review
   - reversal assessor
   - test-writer
   - implementer
   - refactor
   - verify-by-execution
   - Scope Lock drafts
3. Both files state that the floor never removes a maker-checker split or a TDD step. A role that needs a fresh context runs in a subagent.
4. The parallel critics and the four Scope Lock draft dispatches stay as they are.
5. The existing escape clause stays. An agent that does not split states the reason.
6. "Needs its own reads or many tool calls" has no number. A numeric threshold would be a made-up limit with nothing to measure it against. The rule gives the test: would the main thread pay less context by doing the work in place?
7. The exempt-role list is an allowlist inside the rule. A new fresh-context role is not exempt until someone adds it, so the list needs an owner. The dispatch standard owns it, and custom-002 points to the standard for the current names.
8. Unit tests check that both files state the floor, name all nine roles, and state the no-removal rule. Existing tests that pin the critic and Scope Lock dispatches must still pass.

Decision (P2): the floor is qualitative ("needs its own reads or many tool calls") with nine named exemptions / reason: a number has no measured basis, and the named list protects every fresh-context role.

Decision (P2): both custom-002 and the dispatch template carry the floor and the exemptions in the same words / reason: the override reaches installs through the boot file, and the standard reaches skills, so one text in both prevents drift.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| A byte or file-count threshold | Checkable | Arbitrary, no data behind it | Invented limit |
| Remove the decomposition default | Biggest saving | Loses parallel critics and TDD isolation | Weakens gates |
| Put the floor in only custom-002 | One edit | Skills read the standard, not the boot file | Two homes disagree |
| Exempt by "any gate role" without names | Shorter | Vague, so agents argue over it | Names are testable |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Dispatch standard edit, tests |
| planifest-overrides (outside the component) | custom-002 edit |

## Consequences

**Positive:**
- Small units stop paying for a fresh context.
- No fresh-context gate role loses its subagent.

**Negative:**
- The agent judges "its own reads", so two agents may split the same work differently.
- The generated boot copy of custom-002 stays stale until setup re-runs.

**Risks:**
- An agent could cite the floor to skip a split that was needed. The nine names and the no-removal rule limit this.
- A new role added later is not exempt until the list changes.

## Related ADRs

- ADR-003 - related-to (both edit `agent-dispatch-standards.md`, so they run in sequence)
- ADR-007 - depends-on (the migration refreshes the boot copy)

## Supersedes

- None.

## Superseded By

- None.
