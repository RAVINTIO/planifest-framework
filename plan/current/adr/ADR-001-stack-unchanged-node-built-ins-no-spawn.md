---
title: "ADR 001: Stack unchanged, gate and hook output code on Node built-ins with no spawn"
summary: "0000036 keeps the declared stack. Every stream 01 change lands in path-rules.mjs, the hooks that import it, run-tests.sh, and Bash suites. The hook code adds no process spawn and no dependency. The existing git spawn in ratchet-check.mjs stays (backlog 0000128)."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Stack unchanged, gate and hook output code on Node built-ins with no spawn

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

The design declares this stack:

- JavaScript ES modules on Node built-ins
- Bash and PowerShell setup scripts
- Markdown skills
- GitHub Actions CI and a local build target

The design states "Stack unchanged". It declares no database, ORM, IaC, cloud, or compute.

Stream 01 serves four requirements:

- req-008 adds a file-type check before the gate reads `design.md`.
- req-009 adds an enforcement-path condition to the always-permitted shortcut.
- req-010 clears `CLAUDE_PROJECT_DIR` in `run-tests.sh` and in each suite that names an enforcement hook.
- req-011 changes the `shown()` cut and routes two more hook outputs through it.

Three of them change `planifest-framework/hooks/enforcement/path-rules.mjs`. That module is the shared home for path and root rules (0000032 ADR 004). `gate-write.mjs`, `shell-write-guard.mjs`, and `ratchet-check.mjs` already import it. req-011 makes `em-dash-guard.mjs` a fourth importer.

The design lists 0000035 ADR 001 and 0000032 ADR 004 as constraints: hooks use Node built-ins only, with no process spawn. Each hook call must stay under 500 ms (NFR-001).

## Decision

- **Stack:** The stack stays as the design declares it. Stream 01 adds no language, runtime, library, or service.
- **One module:** The req-008, req-009, and req-011 rules live in `path-rules.mjs`. The hooks call it and hold no copy of the rules.
- **Node built-ins only:** The new code uses `node:fs` and `node:path`. The file-type check uses `lstatSync`, `openSync`, `fstatSync`, and `fs.constants` (ADR-002). The `shown()` cut uses plain string code (ADR-004).
- **No new spawn:** This feature adds no process spawn and no new dependency (NFR-003). The changed hooks are `path-rules.mjs`, `gate-write.mjs`, `shell-write-guard.mjs`, and `em-dash-guard.mjs`. They import only `node:` modules and `./path-rules.mjs`.
- **One kept spawn:** `ratchet-check.mjs` already imports `node:child_process` (`:53`) and spawns `git` (`:150`). This feature keeps that spawn and adds no other. It adds one import to that hook, `./path-rules.mjs`. Backlog 0000128 tracks removing the spawn.
- **Source check:** The req-008 suite checks the source of those five files. It allows the one known `git` spawn in `ratchet-check.mjs` by name and fails on any other `node:child_process` import or spawn.
- **Tests:** Each requirement gets a Bash suite under `planifest-framework/tests/`, run through `run-tests.sh` and the existing CI jobs. req-010 changes `run-tests.sh` itself with one Bash line.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Spawn `stat` or `test -f` to learn the file type of `design.md` | The shell reports the type without Node file-descriptor code | Adds a process per hook call. Breaks 0000035 ADR 001. Behaves differently on Windows. | Breaks a declared constraint and the latency budget |
| Add an npm package for grapheme or escape-aware truncation | Tested Unicode code for the `shown()` cut | Hooks install by copy with no `npm install` step (0000028 ADR 002). A dependency changes the stack. | Deviates from the declared stack, and the unit rule needs only a short loop |
| Copy `shown()` into `em-dash-guard.mjs` | No new import, so the hook keeps no link to `path-rules.mjs` | Two escape rules drift apart, which is the defect class 0000032 ADR 004 removed | Shared rules are the fix (see ADR-004) |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `path-rules.mjs` gains the file-type check, the enforcement-path condition, and the new cut. `ratchet-check.mjs` and `em-dash-guard.mjs` print through `shown()`. `run-tests.sh` and seven suites gain one `unset` line each. Four new suites. |
| setup-hook-integration | No change. Setup already copies every `*.mjs` in `hooks/enforcement/` (0000028 ADR 002). |

## Consequences

**Positive:**
- All four enforcement hooks print and judge through the same code, so their output and verdicts match.
- Hook latency stays bounded by file-system calls, with no process start.

**Negative:**
- A fault in `path-rules.mjs` now affects four hooks, not three. A syntax error there disables `em-dash-guard.mjs` too.
- Node gives no portable non-blocking open on Windows, so the FIFO guard there rests on `lstatSync` alone (ADR-002).

**Risks:**
- A future change adds a spawn to `path-rules.mjs` for convenience (risk R-010). The source check on `node:child_process` catches it.
- The kept `git` spawn in `ratchet-check.mjs` still adds process-start latency and a failure path to that hook. This feature doesn't remove it, and backlog 0000128 tracks the removal.

## Related ADRs

- ADR-002, ADR-003, ADR-004 - related-to. Each records a rule that lives in `path-rules.mjs`.
- 0000035 ADR 001 (stack unchanged, Node built-ins with no spawn) - depends-on
- 0000032 ADR 004 (shared path rules and repository root) - depends-on
- 0000028 ADR 002 (shared module placement and install topology) - depends-on

## Supersedes

- None

## Superseded By

- None
