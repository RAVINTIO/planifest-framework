---
title: "Requirement: req-009 - fast-path-enforcement-paths"
summary: "path-rules.mjs exports FAST_PATH_ENFORCEMENT_PATHS, the gate checks it before the scope record, and a scope record never admits a listed path. workflows/fast-path.md names the same entries."
status: "draft"
version: "0.1.0"
---
# Requirement: req-009 - fast-path-enforcement-paths

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Source:** US-009 (backlog 0000081, 0000125, and 0000062)
**Priority:** must-have

## User Story

> One requirement doc = one user story.

As the human on the loop, I rely on Fast Path never admitting a write to an enforcement path, so that a scope record can't unwire or change the gates.

## Functional Requirements

- This requirement constrains the scope record that [req-001](req-001-fast-path-scope-record.md) adds. Req-001 owns the record format, its limits, staleness, self-authorisation, and the workflow step that writes the record. This requirement owns the enforcement list, its matching, and its precedence over the record. ADR-004 records the decision.
- The cases for this requirement live in their own suite, `planifest-framework/tests/test-0000035-req-009-fast-path-enforcement-paths.sh`, because each requirement owns its suite. The req-001 suite keeps the record cases.

### Enforcement list

- `path-rules.mjs` exports a constant, `FAST_PATH_ENFORCEMENT_PATHS`, as artifact `path-rules-fast-path-enforcement-paths`. It lists these entries:
  - `planifest-framework/hooks/`
  - `planifest-framework/scripts/`
  - `planifest-framework/setup/`, the per-tool setup scripts such as `claude-code.sh` and `windsurf.sh`
  - `planifest-framework/standards/autonomous-run-standards.md`
  - any path whose last segment is `setup.sh` or `setup.ps1`
  - any path that holds the segment pair `hooks/enforcement/`, which covers every installed hook folder such as `.claude/hooks/enforcement/`
  - `.git/` and everything below it
  - any path that holds the segment pair `hooks/adapters/`, which covers every installed Tier 1 adapter such as `.cursor/hooks/adapters/cursor.mjs`
  - the hook wiring files that `setup.sh` and `setup.ps1` write, listed below
  - the tool-local settings files that a supported tool loads hooks from, listed below
- The hook wiring files are the tool settings and config files that register the hooks. `setup.sh` and `setup.ps1` write these:
  - `.claude/settings.json` (Claude Code)
  - `.cursor/settings.json` (Cursor)
  - `.clinerules/hooks.json` (Cline)
  - `.windsurf/hooks.json` (Windsurf)
  - `.github/hooks/` (Copilot). The whole folder is listed, because setup writes `planifest.json` there and Copilot may load every file in it.
  - `.codex/config.toml` (Codex CLI)
  - `opencode.json` and `.opencode/plugins/@planifest/opencode-hooks/` (OpenCode)
- The tool-local settings files are files that setup doesn't write but a tool still loads hooks from. They are usually git-ignored, so a PR wouldn't show a change to them. The list holds these:
  - `.claude/settings.local.json` (Claude Code). It can register hooks, and its `disableAllHooks` key turns every hook off.
  - `opencode.jsonc` (OpenCode), which OpenCode reads in place of `opencode.json`.
- The setup scripts name no other local variant. The other supported tools load hooks only from the wiring files above.
- `planifest-framework/setup/` is on the list because its scripts set the wiring file paths and write their content. A Fast Path edit there would unwire the hooks at the next setup run.
- Without these entries, a record could list a wiring file and let a Fast Path change unwire `gate-write` itself.

### Matching and precedence

- Enforcement matching is case-insensitive. The gate compares `norm(relPath)` with `norm(entry)`, using the existing `norm` export (0000009 ADR 005 normalisation). On a case-insensitive volume, `Planifest-Framework/Hooks/x.mjs` therefore matches `planifest-framework/hooks/`.
- Enforcement matching also folds compatibility lookalikes and full case (P5 finding G-S02). `isEnforcementPath` applies `normalize("NFKC")`, then `toUpperCase().toLowerCase()`, to both sides after `norm`. APFS folds the long s (U+017F) to `s`, so `planifest-framework/hookſ/x.mjs` writes into `planifest-framework/hooks/`. The wider fold makes it match.
- The scope record never admits a target whose root-relative path holds a non-ASCII character (P5 finding G-S02). The gate blocks it with exit 2, and the reason names the non-ASCII rule. Record paths are already ASCII by their grammar, so no listed path loses its admission.
- The gate checks `FAST_PATH_ENFORCEMENT_PATHS` before it matches the scope record (ADR-004).
- A scope record never admits a path that matches `FAST_PATH_ENFORCEMENT_PATHS`, whatever it lists. The gate blocks that write with exit 2. The reason names the path and 0000033 ADR 009, and says to use the Change or Feature Pipeline.

### Fast Path workflow text

- The same change updates the enforcement list in the `planifest-framework/workflows/fast-path.md` prerequisites to name every entry above. The constant and the doc stay in step, and the suite parity check enforces it.
- If a target matches an enforcement path, the workflow stops and routes the change to the Change or Feature Pipeline. The prerequisites list and `FAST_PATH_ENFORCEMENT_PATHS` name the same entries.

### Tests

- The suite builds a git fixture under `mktemp -d` with no `plan/current/design.md`, as the req-001 suite does. It writes the record from the fixture's real branch and `HEAD`.
- The suite runs `gate-write.mjs` and `shell-write-guard.mjs` on the same targets and checks the exit code and stderr of each.
- The suite covers these cases:
  - a record that lists `planifest-framework/` or `planifest-framework/hooks/`, where a write to `planifest-framework/hooks/enforcement/gate-write.mjs` exits 2
  - a record that lists `.claude/settings.json`, where the write exits 2
  - a record that lists `.claude/settings.local.json`, where the write exits 2
  - a record that lists `planifest-framework/setup/claude-code.sh`, where the write exits 2
  - a mixed-case target `Planifest-Framework/Hooks/x.mjs`, where the write exits 2
- A source check asserts set equality in both directions. Every enforcement path in the `fast-path.md` prerequisites appears in `FAST_PATH_ENFORCEMENT_PATHS`, and every entry in `FAST_PATH_ENFORCEMENT_PATHS` appears in those prerequisites.

## Acceptance Criteria

- [ ] A record that lists `planifest-framework/` or `planifest-framework/hooks/` never admits a write to `planifest-framework/hooks/enforcement/gate-write.mjs`, which exits 2. The shell-write guard gives the same result.
- [ ] A record that lists `.claude/settings.json`, `.claude/settings.local.json`, or `planifest-framework/setup/claude-code.sh` never admits a write to that path. A write to the mixed-case target `Planifest-Framework/Hooks/x.mjs` also exits 2.
- [ ] The enforcement list in the `workflows/fast-path.md` prerequisites matches `FAST_PATH_ENFORCEMENT_PATHS`.

## Dependencies

- [req-001](req-001-fast-path-scope-record.md) adds the scope record and its read in `evaluateWrite`. Stream 01 builds this requirement right after req-001, because both change `path-rules.mjs` and `fast-path.md`.
- `planifest-framework/workflows/fast-path.md` (prerequisites list edited here).
- 0000033 ADR 009 (enforcement paths) and 0000009 ADR 005 (`norm` normalisation).
- It matches the root-relative path that req-003 produces, as req-001 does. It needs no other artifact from req-003.
- No dependency on req-002 or req-004 to req-008, beyond the stream 01 build order.
