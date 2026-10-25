---
title: "ADR 001: Stack unchanged"
summary: "0000039 keeps the declared stack. The rename adds no language, library, or tool. The brand guard is a Bash suite and the migration helpers are .sh and .ps1."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Stack unchanged

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Component:** ravintio-framework (renamed from planifest-framework), setup-hook-integration
**Date:** 2026-10-25

## Context

The design declares the stack as Bash, PowerShell 5.1 and 7, Node `.mjs` scripts, Bash test suites, and GitHub Actions CI. Build target is local.

The rename touches paths, identifiers, variables, markers, and prose. It also adds a brand guard suite and a consumer migration with two helpers. Each new piece could tempt a new tool.

The existing suites already run on Bash 3.2, Bash 5, and both PowerShell versions in CI. The helpers must run on the same legs.

## Decision

Keep the stack unchanged.

- The brand guard is a Bash suite that reads `git ls-files`.
- The migration helpers are `migrate-0.37.0-ravintio-rename.sh` and `.ps1`.
- The bulk rename is one throwaway script in the scratchpad. It is not a repo file and adds no dependency.
- The migration record is Markdown.
- Line loops use `done <<< "$(...)"`, never `done < <(...)`.

Decision (P2): keep the stack unchanged for all ten requirements / reason: no requirement needs a capability that Bash, PowerShell, Node built-ins, or Markdown lack.

This decision governs req-001 to req-010.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Write the guard and helpers in Node for one portable implementation | One code path for all platforms | Consumers need Node to run the migration, and the two shell helpers are the pattern every earlier migration uses | The migration must run in a consumer repo that may have no Node install |
| Add a dedicated rename tool such as a codemod or a refactoring CLI | Handles path and content renames with less custom code | New install step on every machine and CI leg, and it can't read the protected-name list or the history exclusions | The one-pass script already needs the protected list, so a tool adds a dependency without removing work |
| Write the brand guard as a Node test with a test library | Structured failure output and richer regex handling | New dependency, and the other 43 suites are Bash, so the guard would break the test runner pattern | Plain Bash with `grep` meets the need and runs in the existing runner |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | No new dependency or manifest. New files are Bash, PowerShell, and Markdown. |
| setup-hook-integration | Hook wiring tests change path references only. |

## Consequences

**Positive:**
- Installs and CI legs need no new setup.
- A consumer runs the migration with the shell they already have.
- The guard runs in the existing test runner and fails in the same way as the other suites.

**Negative:**
- The same migration logic exists twice, in `.sh` and `.ps1`. A fix to one helper must reach the other, or the two platforms drift.
- The guard parses file lists and lines with `grep`. A line regex mistake in the allowlist can hide a real old-name hit.

**Risks:**
- The PowerShell helper fails to parse on 5.1 or acts on a junction. CI runs both PowerShell legs, and the helper never deletes, so the risk is a red check and no data loss.
- Bash 3.2 hides lines in a guard loop. The safe loop form removes that cause.

## Related ADRs

- ADR-007 - related-to (the guard is a Bash suite with an allowlist)
- ADR-008 - related-to (the scripted pass uses no new tool)
- ADR-005 - related-to (the helpers are shell scripts that back up and never delete)

## Supersedes

- None.

## Superseded By

- None.
