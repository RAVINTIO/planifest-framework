---
title: "ADR 004: Setup clean-up is always on, path-matched, and fails open"
summary: "Every setup run removes stale Context Mode and Telemetry state by exact path match, writes atomically, and never blocks the install."
status: "accepted"
version: "0.1.0"
---
# ADR-004 - Setup clean-up is always on, path-matched, and fails open

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Component:** setup-hook-integration
**Date:** 2026-10-14

## Context

Downstream projects installed with either integration have settings entries and hook folders that ADR-002 makes stale. Once the hook files are gone, each entry runs `node` against a missing file on every matching tool call. People also add their own hooks to the same settings files. Today setup's existing wiring drops any `PreToolUse` entry with a `Grep`, `Bash`, or `WebFetch` matcher, whoever added it. Setup also writes settings with no backup, and calls `JSON.parse` with no error handling.

## Decision

Every setup run, for every tool it installs, runs one clean-up pass before its normal wiring:

1. Remove hook entries, under any event, whose command runs a file under the tool's `hooks/context-mode/` or `hooks/telemetry/` folder. The same applies to `hooks/enforcement/check-telemetry-failures.mjs` and `check-telemetry-receipts.mjs`.
2. Remove hook groups whose matcher is `mcp__structured-telemetry-mcp__emit_event`.
3. Delete the stale hook folders and installed copies.
4. Delete `.claude/telemetry-enabled`, `plan/.telemetry-failures/`, and `plan/.telemetry-receipts/`.

The pass matches on command path, never on matcher alone, so a hand-added hook stays. It prints one line per removal, and nothing when it finds nothing. It writes each settings file to a temporary file in the same folder, then renames it into place.

If a settings file doesn't parse, the pass leaves it byte-identical. It names the parse error and skips only that file. If Node is missing, the pass is skipped with a warning. In every case setup exits 0.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Clean up only when a retired flag is passed | Clean-up never runs unless asked | A project that ran setup with the flag once but not since keeps its stale entries | Misses the projects that most need it |
| Match on matcher (`Grep`, `Bash`, `WebFetch`) as today | Already written | Removes hand-added hooks with the same matcher | Destroys work a person wrote |
| Leave the clean-up to the migration file, done by hand | No setup code | Every downstream project does manual JSON surgery | Error-prone, and the human on the loop chose automatic clean-up |
| Fail setup on a malformed settings file | Forces a fix | Blocks the rest of the install, against 0000003-ADR-005 | The framework fails open |

## Affected Components

| Component | Impact |
|-----------|--------|
| `setup-hook-integration` | New clean-up pass in `setup.sh` and `setup.ps1`, plus atomic settings writes |

## Consequences

**Positive:**
- One re-run fixes any downstream install, whatever state an earlier run left.
- Settings writes can no longer truncate the file on a crash.

**Negative:**
- Setup carries the removed paths in its clean-up code for as long as the pass exists.
- A malformed settings file keeps its stale entries until a person fixes it.

**Risks:**
- A person stored their own hook under `hooks/telemetry/` and it gets removed. The per-removal output makes that visible (R-003).

## Implementation Notes

Added at P5 on 2026-10-14:
- Step 2 removes groups by matcher alone. That departs from the path-match rule above. It is accepted because the `structured-telemetry-mcp` server no longer exists, so no live hook can depend on that matcher.
- Step 3 deletes the whole stale folder, including any file a person added there. Backlog 0000090 records the narrower design: delete shipped file names only, and remove an empty folder.
- P5 hardening: deletes resolve the parent directory and refuse to act outside the project. PowerShell uses `-LiteralPath` and removes a link without following it. A failed delete or rename warns and continues. Temporary files keep the original file mode and are created exclusively.

## Related ADRs

- 0000003-ADR-005 - extends (exit-zero failure mode)
- ADR-002 - depends-on
- ADR-005 - depends-on (who owns the deleted state)

## Supersedes

- None

## Superseded By

- None
