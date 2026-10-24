---
title: "ADR 009: The wired-command test runs the installed command verbatim"
summary: "The test runs the exact command strings that setup.sh writes for gate-write, shell-write-guard, and auto-trigger-orchestrator through bash -c in a fixture workspace. A bare-path negative fixture proves the test detects broken wiring. A missing entry fails and never skips."
status: "accepted"
version: "0.1.0"
---
# ADR-009 - The wired-command test runs the installed command verbatim

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Component:** planifest-framework
**Date:** 2026-10-24

## Context

Existing hook suites call each `.mjs` file directly with `node`. They never run the `command` string that `setup.sh` writes into `.claude/settings.json`. A broken string can pass every suite and still fail in a real install. Backlog 0000071 records this gap. A bare `.mjs` path with no `node` prefix is one example, and a wrong directory is another.

The test needs a fixture workspace. `setup.sh` builds the strings from the `gate_cmd`, `shell_guard_cmd`, and `trigger_cmd` variables. A test that rebuilds those strings would test its own copy and not the installer.

The `auto-trigger-orchestrator` hook exits 0 on every internal error. Exit code 0 alone proves nothing for that hook. It also prints plain text and no JSON, and only when the workspace holds `planifest-framework/` and no `plan/.orchestrator-active` sentinel.

Missing entries are a second hazard. If a hook has no entry in the settings file, a lenient test would skip it and report green.

## Decision

1. The test runs `setup.sh` for Claude Code into a temporary workspace. It parses `.claude/settings.json` with `node`, so it needs no `jq`.
2. For each entry under test, the test takes the `command` value verbatim. It runs the string through `bash -c` with the workspace as the working directory. It never rebuilds the string.
3. The entries under test are `gate-write` (matcher `Write`), `shell-write-guard` (matcher `Bash`), and `auto-trigger-orchestrator` (`UserPromptSubmit`).
4. Each enforcement entry gets one violating payload and one clean payload on stdin. Violating payloads expect exit 2. Clean payloads expect exit 0.
5. The `auto-trigger-orchestrator` run uses a workspace with `planifest-framework/` and no sentinel. The test asserts that stdout contains `Load the planifest-orchestrator skill`. The stdout check is the proof, because the exit code is always 0.
6. A negative fixture rewrites the `auto-trigger-orchestrator` entry to a bare `.mjs` path with no `node` prefix. A second variant uses a wrong directory. Both runs must exit non-zero. This proves the test detects broken wiring.
7. If the settings file has no entry for a named hook, the test fails and names the hook. A missing entry never reads as a skip.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Rebuild the command string in the test from the same variables | Short test code | Tests the test's own copy, so a wrong string in `setup.sh` still passes | It misses the defect that backlog 0000071 describes. |
| Parse the settings file and match each `command` against a regex | No process runs | Checks the shape, not the behaviour. A regex that accepts a bare path hides the defect. | Shape does not prove the string runs. |
| Skip an entry when it is absent | Tolerates a tool without that hook | A removed hook reads as green | The test targets Claude Code, where all three entries must exist. |
| Rely on exit code alone for the trigger hook | No stdout check | The hook exits 0 on every internal error | A broken string would pass. |
| Use `jq` to read the settings file | Familiar tool | Adds a dependency that CI and Git Bash may lack | `node` is already required by the hooks. |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Gains `tests/test-0000037-req-007-wired-command.sh`. `setup.sh` changes only if the test finds a real wiring defect. |

## Consequences

**Positive:**
- A wrong prefix, path, or directory in an installed command fails the suite before release.
- The negative fixture shows the test can fail, so a green run carries meaning.
- The test needs no `jq`, so it runs on every CI leg.

**Negative:**
- The test depends on the exact shape of the `settings.json` hook entries. A change to that shape means a test change.
- The test runs `setup.sh` once per suite run, which adds a few seconds.

**Risks:**
- The test passes on macOS and fails on Windows because of path separators or the working directory (R-016). Mitigation: run the string as written and keep the suite portable under ADR-011.
- The first run on the Git Bash leg may expose a real wiring defect. P3 fixes it in `setup.sh` and records a Deviation.

## Governs

- req-007 (FR-007.1 to FR-007.6, AC-007.1 to AC-007.3)

## Related ADRs

- ADR-011 - related-to: the lint keeps this suite portable.
- 0000031 ADR 001 - related-to: the Windows legs run this suite.

## Supersedes

- None.

## Superseded By

- None.
