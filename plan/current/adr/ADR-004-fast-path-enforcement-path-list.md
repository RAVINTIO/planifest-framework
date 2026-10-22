---
title: "ADR 004: A concrete Fast Path enforcement list that covers hook wiring"
summary: "path-rules.mjs exports FAST_PATH_ENFORCEMENT_PATHS. It extends the fast-path.md list with hook wiring files, tool-local settings files, the setup scripts folder, installed hook and adapter folders, and .git/. A scope record never admits a match."
status: "accepted"
version: "0.1.0"
---
# ADR-004 - A concrete Fast Path enforcement list that covers hook wiring

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

0000033 ADR 009 says Fast Path never admits an enforcement path. Until now that list lived only as prose in `planifest-framework/workflows/fast-path.md`, and no hook enforced it. The scope record (ADR-002) makes Fast Path writes a gate decision, so the gate needs the list as code.

The prose list named the hook and script folders. It missed the files that turn hooks on:

- the hook wiring files that `setup.sh` and `setup.ps1` write, such as `.claude/settings.json`
- tool-local settings files that a tool also loads hooks from, such as `.claude/settings.local.json`. Its `disableAllHooks` key turns every hook off, and it is usually git-ignored, so a PR shows no change.
- `planifest-framework/setup/`, whose scripts write the wiring files at the next setup run
- `.git/`, which holds git hooks and config

Without these entries, a self-written record could unwire `gate-write` itself. The scope keeps every existing entry, so no path leaves the list.

## Decision

- **Constant:** `path-rules.mjs` exports `FAST_PATH_ENFORCEMENT_PATHS`, artifact `path-rules-fast-path-enforcement-paths`. req-009 lists every entry. The groups are:
  - framework enforcement folders: `planifest-framework/hooks/`, `planifest-framework/scripts/`, `planifest-framework/setup/`, and `planifest-framework/standards/autonomous-run-standards.md`
  - any path whose last segment is `setup.sh` or `setup.ps1`
  - any path that holds the segment pair `hooks/enforcement/` or `hooks/adapters/`, which covers every installed copy
  - `.git/` and everything below it
  - the hook wiring files per tool, with the whole `.github/hooks/` folder for Copilot
  - the tool-local settings files `.claude/settings.local.json` and `opencode.jsonc`
- **Matching:** Matching is case-insensitive. The gate compares `norm(relPath)` with `norm(entry)` (0000009 ADR 005), so a mixed-case path on a case-insensitive volume still matches.
- **Precedence:** The enforcement check runs before the record match. A match blocks with exit 2 whatever the record lists. The reason names the path and 0000033 ADR 009, and points to the Change or Feature Pipeline.
- **One list in two places:** `fast-path.md` names every entry in its prerequisites. A suite source check asserts that each doc entry appears in the constant. The workflow stops and reroutes when a target matches.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep the prose list as it was | No change to `fast-path.md` | A record could list `.claude/settings.json` and turn the gates off | A scope record must never unwire enforcement |
| Read the wiring file paths from setup at run time | One source of truth | The gate would parse shell and PowerShell scripts, or spawn them | Too fragile and breaks ADR-001 |
| Allowlist the paths a record may name | Smaller attack surface | Fast Path covers any trivial change, so no fixed allowlist fits. The scope puts a wider allowlist out of scope. | Rejected at P0 |
| Case-sensitive matching | Matches the stored text exactly | On macOS and Windows `Planifest-Framework/Hooks/x.mjs` writes the real hook file but slips past the list | Fails open on case-insensitive volumes |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `path-rules.mjs` gains the constant and the precedence check. `workflows/fast-path.md` lists the same entries. The req-009 suite covers wiring files, a tool-local settings file, a setup script, and a mixed-case hook path. |
| setup-hook-integration | No change. Its docs name the wiring files the list now covers. |

## Consequences

**Positive:**
- A Fast Path change can't unwire, edit, or reinstall any hook, by any route the setup scripts know.
- The doc and the code can't drift without a suite failure.

**Negative:**
- A trivial typo fix in a setup script or a hook now needs the Change Pipeline.
- A new supported tool needs its wiring file added in three places: setup, the constant, and `fast-path.md`.

**Risks:**
- A future setup change adds a wiring file and misses the constant. No suite checks setup against the constant. Backlog 0000130 tracks that check.
- A tool starts loading hooks from a new local file. The list then misses it until a later feature adds it.

## Related ADRs

- ADR-002 - related-to. The scope record can never admit a path on this list.
- 0000033 ADR 009 (Fast Path admits no `src/` changes) - extends. This ADR makes its enforcement path rule concrete.
- 0000009 ADR 005 (path normalisation) - depends-on

## Supersedes

- None

## Superseded By

- None
