---
title: "ADR 005: Block reasons on stderr"
summary: "Every enforcement hook that exits 2 writes a plain-text reason to stderr, because Claude Code reads a PreToolUse block reason from there. Existing stdout stays byte for byte, so the stdout adapters keep working."
status: "accepted"
version: "0.1.0"
---
# ADR-005 - Block reasons on stderr

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Component:** planifest-framework
**Date:** 2026-10-17

## Context

Three enforcement hooks exit 2 today, and all three write their reason to stdout.

| Hook | Output on block |
|------|-----------------|
| `gate-write.mjs` | plain text on stdout |
| `ratchet-check.mjs` | `permissionDecision: "deny"` JSON on stdout |
| `em-dash-guard.mjs` | plain text on stdout |

0000011-ADR-001 records that Claude Code takes "exit 2 plus a stdout message". In practice, Claude Code reads a PreToolUse block reason from stderr (A-001). An agent therefore sees a block with no reason and has to read the hook's source.

Other tools depend on the current stdout. The Windsurf, Copilot, and Codex adapters relay a hook's stdout as the block reason. Copilot and Codex parse the `ratchet-check.mjs` deny JSON. Changing stdout would break those tools, and they are outside this feature's scope.

## Decision

- On every block path, each enforcement hook writes a plain-text reason to stderr before it exits 2. This covers these hooks:
  - `gate-write.mjs`
  - `ratchet-check.mjs`
  - `em-dash-guard.mjs`
  - the new `shell-write-guard.mjs` (ADR-006)
- `gate-write.mjs` and `em-dash-guard.mjs` write the same text to stderr that they write to stdout.
- `ratchet-check.mjs` writes its `reason` string to stderr as plain text, not JSON.
- Each existing hook keeps its stdout byte for byte.
- `shell-write-guard.mjs` has no stdout consumer, so it writes to stderr only.
- Hooks that never exit 2 and the adapters under `hooks/adapters/` don't change.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Move the reason to stderr only | One copy of the reason in every tool | The Windsurf, Copilot, and Codex adapters lose the reason. Copilot and Codex lose the deny JSON. | It breaks working adapters to fix one tool. |
| Dedupe in each adapter | No doubled reason anywhere | Needs changes in Cursor, Cline, and OpenCode wiring | Those tools are out of scope, and some relay output with no Planifest adapter in between. |
| Keep stdout only | No change | Claude Code shows no reason | That leaves AC-7 unmet. |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Three hooks gain a stderr write on each block path. The new shell guard follows the same rule. The boot templates state that block reasons go to stderr. |

## Consequences

**Positive:**
- Claude Code shows the agent why a write blocked, so the agent can fix the design or the path.
- Adapters that read stdout keep working with no change.
- The rule is one line per block path, so new hooks can follow it with little effort.

**Negative:**
- Cursor, Cline, and OpenCode relay both streams, so they show the reason twice (A-007).
- Each hook now has two outputs to keep in step, and a test must check both.
- This ADR corrects the stdout claim in 0000011-ADR-001 for Claude Code without superseding the adapter rules it holds.

**Risks:**
- If A-001 is wrong, the stderr write fixes nothing for Claude Code. The hook still blocks correctly, so the cost is the lost fix, not a regression.

## Related ADRs

- 0000011-ADR-001 - extends (adds stderr for Claude Code, keeps the stdout and deny JSON contract)
- 0000011-ADR-003 - depends-on (adapters relay stdout and stay unchanged)
- 0000003-ADR-005 - related-to (unexpected errors still exit 0 with no block reason)
- ADR-004 - related-to
- ADR-006 - related-to (the shell guard follows this rule)

## Supersedes

- None

## Superseded By

- None
