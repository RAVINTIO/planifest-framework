---
title: "ADR 001: Stack unchanged"
summary: "0000038 keeps the declared stack. Every change is Bash, PowerShell, Node ES module, Markdown, or workflow text. No dependency or package manifest is added."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Stack unchanged

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Component:** planifest-framework
**Date:** 2026-10-24

## Context

The design declares the stack as Bash, PowerShell, Node ES module hooks and scripts, Markdown, and GitHub Actions. Build target is local. All seven requirements edit text or shell. None needs a new tool.

Two pieces of work could tempt a new dependency. Quiet-mode test output could use a TAP library. The model-value test could use a YAML parser.

## Decision

Keep the stack unchanged.

- Quiet mode is plain Bash in `run-tests.sh`.
- The model-value test is a Bash suite that greps the files.
- The reference files are Markdown.
- The migration is Markdown.

Decision (P2): keep the stack unchanged for all seven requirements / reason: no requirement needs a capability that Bash, Node built-ins, or Markdown lack.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Add a TAP or test library | Structured output | New install step on every machine and CI leg | Plain Bash meets the need |
| Add a YAML parser for the model test | Exact column parsing | New dependency | The table and skeleton are greppable text |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | No new dependency or manifest |

## Consequences

**Positive:**
- Installs and CI legs need no new setup.
- Windows Git Bash and PowerShell behave as they do today.

**Negative:**
- The tests parse Markdown tables with grep, which is brittle if the table layout changes.

**Risks:**
- A layout change to the tier table breaks the model-value test. The test fails loudly, so the risk is a red check and no silent pass.

## Related ADRs

- ADR-003 - related-to (the model-value test uses grep)
- ADR-004 - related-to (quiet mode uses Bash only)

## Supersedes

- None.

## Superseded By

- None.
