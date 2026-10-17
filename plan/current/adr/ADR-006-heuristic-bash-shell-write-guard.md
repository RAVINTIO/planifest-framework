---
title: "ADR 006: Heuristic Bash shell-write guard"
summary: "A Bash PreToolUse hook, shell-write-guard.mjs, finds common shell writers, judges their targets with the shared path rules, and fails open on anything it can't parse. A boot-file Hard Limit covers the documented gaps. It's registered for Claude Code only."
status: "accepted"
version: "0.1.0"
---
# ADR-006 - Heuristic Bash shell-write guard

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Component:** planifest-framework
**Date:** 2026-10-17

## Context

`gate-write.mjs` runs on **Write** and **Edit** only. In auto mode, an agent can write `src/` through Bash with `cat >`, `sed -i`, or `cp`. No hook sees that write, so the design gate has a gap (backlog 0000084).

This is a security trade-off. A Bash command is a full shell program. A complete answer would need a shell parser and would still miss writes made inside scripts. A guard that blocks too much would stop read-only commands that agents run all the time. Hooks must also stay dependency-free and fail open (0000003-ADR-005), and finish in under 200 ms.

A-002 records that Claude Code passes the command as `tool_input.command`. A-006 records the glob, variable, and `cd` rules, and A-008 records the boot-file rule. The human on the loop accepted all three.

## Decision

- A new hook, `planifest-framework/hooks/enforcement/shell-write-guard.mjs`, runs on Claude Code's Bash PreToolUse event.
- It splits the command at shell operators and respects quotes and escapes. It skips leading assignments and here-document bodies.
- It finds write targets in these forms:
  - redirects, including `>>`, `&>`, and file-descriptor forms such as `2>`
  - `tee`
  - `sed -i` and `perl -i`
  - the destination of `cp`, `mv`, `install`, and `ln`
  - every argument of `rm`, `touch`, and `mkdir`
- It judges each target with `toRootRelative` and `evaluateWrite` from `path-rules.mjs` (ADR-004). It therefore blocks exactly when `gate-write.mjs` would block a **Write** to the same path.
- A target holding a glob or variable is judged by its literal prefix, so `src/*.js` is judged as `src/`.
- A target with no literal prefix passes with a one-line warning on stderr. An unbalanced quote does the same.
- A `cd` with one literal argument moves a tracked base for the commands after it. A relative target is judged against both the starting folder (the hook's `cwd`) and the tracked base. It blocks if either judgement blocks, so a `cd` that never runs can't move a write out of the gate (security finding F2).
  - The tracked base returns to its outer value at `)`.
  - A `cd` doesn't carry across `|`, `||`, or `&`.
  - `cd /tmp && echo hi > x.txt` therefore blocks when `{root}/x.txt` is gated. It passes only when both bases pass, such as `cd /tmp && echo hi > plan/x.md`. No command in the false-positive corpus changes.
- Short-option clusters are read one letter at a time, so `cp -vt src/ a`, `perl -lpi -e …`, and `sed -Ei '' …` find their targets (security finding F4).
- `((…))`, `$((…))`, and `$[…]` are read as one unit, so an arithmetic `<<` never opens a here-document. A here-document body with no closing delimiter line is read as commands (security finding F5).
- A target over 4096 characters or 256 segments warns and passes before any file-system walk (ADR-004, security finding F7).
- More than 64 levels of nested quotes, substitutions, or arithmetic make a command unjudgeable. It warns and passes, and a stack overflow does the same (security finding F8).
- Stderr holds each distinct reason once, at most 20 reasons and 20 warnings, then one line that counts the rest (security finding F11).
- The hook ignores commands named `git`. It can't see writes made inside scripts, interpreter one-liners, build tools, or package managers. Its header comment lists each limit.
- On a block, it exits 2 with a plain-text reason on stderr (ADR-005). The reason names the writer, the root-relative target, and the rule, and points the agent to **Write** or **Edit**.
- `standard-boot.md` and `cursor-boot.md` gain a Hard Limit: code changes go through **Write** or **Edit**, never through Bash. The rule covers the guard's limits and the tools that don't run the guard.
- `setup.sh` and `setup.ps1` register the hook for Claude Code only. Each removes any earlier `shell-write-guard` group before it adds one, so repeated runs leave exactly one. Bash groups the human on the loop added stay in place.
- A 0.31.0 migration tells downstream projects to re-run setup.
- Two fixed corpora measure the guard. The detection corpus in the req-008 suite must block every command. The false-positive corpus in the req-009 suite must produce zero blocks.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Boot-file rule only | No code, no false positives | Relies on the agent obeying text in auto mode, which is the failure this feature fixes | It gives no enforcement. It stays as the backstop for the guard's limits. |
| Block every Bash write inside the repository | Closes more of the gap | Needs to know every write, which no parser can, and blocks builds and test runs that write output | The false-positive cost would push the human on the loop to remove the hook. |
| Use a full shell parser dependency | Parses quoting, expansion, and nesting correctly | Breaks the dependency-free hook rule and adds load time. Still misses writes inside scripts. | The gain over the heuristic is small, and the cost breaks a design constraint. |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Gains `shell-write-guard.mjs`, setup registration in both scripts, a 0.31.0 migration, a boot-template Hard Limit, and a test suite with two corpora. |

## Consequences

**Positive:**
- The common ways an agent writes code through Bash now meet the same design gate as **Write** and **Edit**.
- Parse failures and unknown targets pass with a warning, so the guard never stops a session it can't understand.
- A `cd` that may not run can't hide a write, because the starting folder is always judged too.
- The corpora give a fixed, repeatable measure of both false positives and misses.

**Negative:**
- The guard misses writes through git, scripts, interpreters, variables with no literal prefix, and anything it can't parse. The boot-file rule is text only for those cases.
- Only Claude Code runs the guard. Other tools rely on the boot-file rule alone.
- A relative write after a `cd` out of the repository blocks when the same path inside the repository is gated. The agent can use an absolute path instead.
- A command nested past 64 levels, or a path past the length limits, passes with a warning.
- Downstream projects gain the hook only after they re-run setup.

**Risks:**
- A read-only command outside the corpus could match a writer pattern and block. The corpus and the stderr reason make such a case quick to spot and fix.
- A Claude Code change to the Bash `tool_input` shape would make the guard pass every command in silence (A-002).

## Related ADRs

- ADR-004 - depends-on (shared path rules and repository root)
- ADR-005 - depends-on (block reason on stderr)
- 0000003-ADR-005 - depends-on (fail open on unexpected errors)
- 0000028-ADR-003 - related-to (a sibling PreToolUse hook rather than a change to `gate-write.mjs`)
- 0000029-ADR-001 - depends-on (setup regenerates boot files, so the Hard Limit reaches installs)

## Supersedes

- None

## Superseded By

- None
