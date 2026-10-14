# Changelog (0000030-context-mode-and-telemetry-mcp-removal, 14 Oct 2026)

**Feature:** Context Mode and Telemetry MCP removal
**Pipeline run:** P0 to P9 completed in continuous mode. No phases skipped.
**PR:** https://github.com/planifest/planifest-framework/pull/57

## What Was Built

- **Context Mode MCP removed.** Its hooks, setup flag path, the `context-mode-hooks` component, its docs, and its tests are gone. `product.yml` now lists two components.
- **Telemetry MCP removed.** Its hooks, the two backstops, `phase-enum.mjs`, the helper scripts, the setup flag path, the CI schema job, and the telemetry standard are gone. Every skill instruction about telemetry is removed, along with the build-log `Telemetry` field.
- **Existing installs clean up on re-run.** Every setup run removes stale entries, hook folders, and state files for each tool. It matches on command path, writes settings atomically, and never fails the install. The three retired flags still work as no-ops that print a one-line notice.
- **Downstream migration.** `planifest-framework/migrations/migrate-remove-context-mode-and-telemetry.md` tells downstream projects to refresh and re-run setup.
- **Security hardening.** P5 fixes stop a malformed `opencode.json` from being truncated. Deletes no longer follow links or wildcards. A failed delete or rename warns and carries on. Settings temporary files are exclusive and keep the file mode.

Version: `0.28.1` → `0.29.0`. `setup-hook-integration` moves to `0.6.0`.

## Artifacts Produced

- `feature-brief.md`, `discovery.md`, `design.md`, `build-log.md`
- `execution-plan.md`, `scope.md`, `risk-register.md`, `domain-glossary.md`
- `requirements/req-001` to `req-005`
- `adr/ADR-001` to `ADR-007`
- `security-report.md`, `iteration-log.md`, `recommendations.md`
- Backlog entries 0000087 to 0000091

## Decisions

- ADR-001: The stack stays as declared. No new dependency is added.
- ADR-002: Both integrations are removed completely. It supersedes 11 earlier ADRs in full and 3 in part.
- ADR-003: The three retired flags stay accepted as no-ops with a notice, so a refresh from an old marker works.
- ADR-004: The setup clean-up is always on, matches on path, and fails open.
- ADR-005: Setup owns retiring the leftover telemetry state folders.
- ADR-006: This repo removed its own wiring last, entries before files. The migration file was the last code commit.
- ADR-007: The P0 `product.yml` `id` hard-stop stays, now justified by versioning and archive attribution.

## Skipped Phases

None
