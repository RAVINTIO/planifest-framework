---
title: "ADR 001: Stack and enforcement approach"
summary: "Hooks stay dependency-free Node ES modules that read stdin through read-stdin.mjs. Setup stays in Bash and PowerShell, skills in Markdown, and tests in Bash suites run by run-tests.sh and the 0000031 CI jobs. Every hook fails open."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Stack and enforcement approach

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Component:** planifest-framework
**Date:** 2026-10-17

## Context

This feature changes two skills and two existing hooks. It also adds a Bash PreToolUse shell-write guard and a shared path-rules module. `plan/current/design.md` fixes the stack in its Engineering Layer and lists the hooks constraint under Constraints.

The existing hooks share a known shape. Each is a Node ES module in `planifest-framework/hooks/enforcement/` with no npm dependencies. Each reads its envelope through `read-stdin.mjs`, which 0000028 ADR-002 extracted. 0000003 ADR-005 requires every hook to exit 0 on an unexpected error. `setup.sh` and `setup.ps1` copy the hooks into downstream projects and register them.

The new shell guard parses arbitrary command strings. It is a heuristic, so it will meet input it can't read. The design names a 200 ms latency target per hook call on the CI runners.

## Decision

- Hooks are JavaScript Node ES modules with no dependencies beyond Node built-ins. Each reads stdin through `read-stdin.mjs`.
- The shell guard and `gate-write.mjs` import one path-rules module from `hooks/enforcement/`. Neither keeps its own copy of the rules.
- `setup.sh` and `setup.ps1` register the shell guard for Claude Code. A repeated run leaves exactly one registration.
- Skill changes stay in Markdown under `planifest-framework/skills/`.
- Tests are Bash suites under `planifest-framework/tests/`. `run-tests.sh` runs them locally, and the 0000031 CI jobs run them on each PR.
- Every changed or new hook fails open. On malformed stdin, a missing `command`, or any unexpected error, it exits 0. If the shell guard can't parse a command, it writes a warning to stderr and allows it.
- A hook that exits 2 writes a plain-text reason to stderr. It keeps any stdout output its adapters already read.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Write the shell guard as a Bash script | Bash already parses shell syntax | Needs Git Bash or WSL on Windows, which 0000017 ADR-002 removed | Reverses the move to Node-only hooks |
| Add an npm shell parser such as `shell-quote` | Fewer parse misses | Adds a dependency and an install step to every downstream project | The design requires dependency-free hooks |
| Copy the path rules into the shell guard | No change to `gate-write.mjs` | The two copies drift, so the gates stop matching | AC-9 requires the gated paths to match exactly |
| Fail closed when the shell guard can't parse a command | Catches more real writes | A parse miss blocks read-only commands and can stall a session | Breaks 0000003 ADR-005 |
| Test with a JavaScript framework | Richer assertions | Adds a dependency, and the existing suites are Bash | `run-tests.sh` and the 0000031 CI jobs already run Bash suites |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Gains a shell-guard hook, a shared path-rules module, setup registration, and new Bash suites. `gate-write.mjs` imports the shared module. |
| repository CI | Runs the new and changed suites through the 0000031 jobs. |

## Consequences

**Positive:**
- Downstream projects need only Node, as they do today.
- One module defines the gated paths, so a rule change reaches both gates at once.
- A hook defect never blocks a session.

**Negative:**
- The shell guard can't see writes made inside scripts, through variables, or by git. The boot files must also state that code changes go through **Write** or **Edit**.
- Without a parser library, the guard needs a corpus test to hold its detection and false-positive rates.

**Risks:**
- A fail-open path hides a real defect. The stderr warning on parse failure is the only signal.
- If Claude Code reads block reasons from a stream other than stderr, AC-7 fixes nothing for Claude Code.

## Related ADRs

- 0000003 ADR-005 (exit-zero failure mode) - depends-on
- 0000017 ADR-002 (Node-only hook runtime) - depends-on
- 0000028 ADR-002 (shared module placement) - depends-on
- ADR-002 - related-to
- ADR-003 - related-to

## Supersedes

- None

## Superseded By

- None
