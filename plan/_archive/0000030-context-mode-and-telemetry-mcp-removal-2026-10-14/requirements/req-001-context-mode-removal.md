---
title: "Requirement: req-001 - Context Mode removal"
summary: "Delete every Context Mode MCP hook, flag path, component, doc, and test."
status: "active"
version: "0.1.0"
---
# Requirement: req-001 - Context Mode removal

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Source:** US-001
**Priority:** must-have

## User Story

As the human on the loop, I install Planifest without any Context Mode MCP hooks, flag, component, or docs, so that the framework carries no code for an MCP server it no longer supports.

## Functional Requirements
- Delete `planifest-framework/hooks/context-mode/` (`block-bash.mjs`, `block-grep.mjs`, `block-webfetch.mjs`).
- Delete `src/context-mode-hooks/`, including its manifest, docs, and tests.
- Remove the `context-mode-hooks` item from `product.yml` `components[]`. Rewrite the `product.yml` header comment so it names two components.
- Delete `docs/context-mode.md`.
- Remove every Context Mode install path from `setup.sh`, `setup.ps1`, `setup/claude-code.sh`, and `setup/claude-code.ps1`. That covers the hook copy, the `PreToolUse` wiring for `Grep`, `Bash`, and `WebFetch`, and the `TOOL_HOOKS_SRC` / `TOOL_HOOKS_DIR` variables. REQ-004 owns the retired-flag handling.
- Delete or rewrite every test that asserts Context Mode behaviour. Update `tests/regression/regression-manifest.json` so no entry points at a deleted test.

## Acceptance Criteria
- [ ] `planifest-framework/hooks/context-mode/`, `src/context-mode-hooks/`, and `docs/context-mode.md` do not exist.
- [ ] `product.yml` lists exactly two components, and `node planifest-framework/scripts/product-version.mjs` still prints `0.29.0` once the version bump lands.
- [ ] A fresh `setup.sh claude-code` in a fixture project creates no `context-mode` folder and no `Grep`, `Bash`, or `WebFetch` `PreToolUse` entry.

## Dependencies
- REQ-004 (retired flags) must land in the same change set, so setup never rejects `--context-mode-mcp`.
