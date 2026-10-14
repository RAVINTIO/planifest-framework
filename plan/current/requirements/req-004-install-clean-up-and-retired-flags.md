---
title: "Requirement: req-004 - Install clean-up and retired flags"
summary: "Setup accepts the three retired flags and removes stale Context Mode and Telemetry state on every run."
status: "active"
version: "0.1.0"
---
# Requirement: req-004 - Install clean-up and retired flags

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Source:** US-003
**Priority:** must-have

## User Story

As the human on the loop of a project that already installed either integration, I re-run setup and the stale hooks and settings entries disappear, so that no tool call runs a hook whose file no longer exists.

## Functional Requirements
- **Retired flags.** `setup.sh` and `setup.ps1` accept `--context-mode-mcp`, `--structured-telemetry-mcp`, and `--backend-url <value>`. Each prints one line naming the flag as removed in 0.29.0, then carries on. Setup does not validate the `--backend-url` value. No retired flag reaches the install marker or `planifest-overrides/setup-config/`.
- **Always-on clean-up.** Every setup run, for each tool it installs, removes stale state in this order:
  1. hook entries under any hook event whose command runs a file under the tool's `hooks/context-mode/` or `hooks/telemetry/` folder, or `hooks/enforcement/check-telemetry-failures.mjs` or `check-telemetry-receipts.mjs`
  2. hook groups whose matcher is `mcp__structured-telemetry-mcp__emit_event`
  3. the `hooks/context-mode/` and `hooks/telemetry/` folders, and `hooks/enforcement/check-telemetry-*.mjs` and `phase-enum.mjs` copies
  4. `.claude/telemetry-enabled`, `plan/.telemetry-failures/`, and `plan/.telemetry-receipts/`
- The clean-up never removes an entry that matches none of the rules above. It prints one line for each entry or path it removes. When it finds nothing, it prints nothing.
- Setup writes each settings file through a temporary file in the same folder, then renames it into place.
- If a settings file is not valid JSON, setup leaves it untouched. It names the file and the parse error, skips only the clean-up for that file, finishes the rest of the install, and exits 0.
- If Node is not available, setup skips the clean-up, warns that stale entries may remain, and exits 0.
- `setup.sh` and `setup.ps1` behave the same.

## Acceptance Criteria
- [ ] A fixture with both integrations and one hand-added hook installed ends with zero stale entries, folders, or files after one re-run. The hand-added hook and every enforcement hook stay.
- [ ] Each retired flag prints its notice, setup exits 0, and the install marker holds no retired flag. A second run changes no file.
- [ ] A fixture with a malformed `settings.json` keeps the file byte-identical, and setup prints the parse error and exits 0.

## Dependencies
- None. REQ-001 and REQ-002 depend on this requirement.

## Input Validation

- [ ] Input source: the existing settings file for each tool (filesystem path)
- [ ] Allowed character pattern: not applicable. The file is parsed as JSON, and entries are compared by exact path match, never executed.
- [ ] maximum length: not applicable, the file is read whole as today
- [ ] Failure behaviour: if JSON parsing fails, leave the file untouched, name the parse error, skip the clean-up for that file, and exit 0
- [ ] Logging policy: removed entries are logged by command path only
