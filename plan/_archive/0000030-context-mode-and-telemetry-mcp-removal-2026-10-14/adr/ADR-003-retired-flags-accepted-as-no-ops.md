---
title: "ADR 003: Retired flags stay accepted as no-ops"
summary: "Setup keeps accepting --context-mode-mcp, --structured-telemetry-mcp, and --backend-url, prints a one-line notice, and never records them."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - Retired flags stay accepted as no-ops

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Component:** setup-hook-integration
**Date:** 2026-10-14

## Context

`planifest-refresh-setup` rebuilds setup flags from the install marker and replays them. Old markers in downstream projects hold `--context-mode-mcp`, `--structured-telemetry-mcp`, and `--backend-url <url>`. Today `setup.sh` exits 1 on an unknown flag, and it also exits 1 on a `--backend-url` value that isn't a plain http(s) URL. Once ADR-002 removes the integrations, a refresh in those projects would fail.

## Decision

`setup.sh` and `setup.ps1` keep parsing all three flags. Each one prints a single line saying the flag was removed in 0.29.0 and has no effect, and setup carries on. Setup consumes the `--backend-url` value without validating it. No retired flag is written to the install marker, so the notice appears at most once per project. The flag-parsing block carries a marker comment, so the NFR-001 check can allow its text.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Remove the flags, so setup rejects them as unknown | Cleanest code | Every refresh from an old marker fails, and a person has to edit the marker by hand | Breaks the brief's constraint that setup never fails on old flags |
| Accept the flags silently | No output noise | A person who passes the flag on purpose gets no sign it did nothing | Silent no-ops hide a behaviour change |
| Accept with a notice, and keep validating `--backend-url` | Catches typos | It validates a value that is then thrown away, and can still fail a refresh | No value in validating input that is ignored |

## Affected Components

| Component | Impact |
|-----------|--------|
| `setup-hook-integration` | The flag parser gains a retired-flag branch, and the marker writer drops retired flags |

## Consequences

**Positive:**
- A refresh from an old marker succeeds, and rewrites the marker without the retired flags.

**Negative:**
- The setup scripts carry flag names for features that no longer exist.

**Risks:**
- A later feature reuses one of these flag names for something new. The marker comment makes that collision visible in review.

## Related ADRs

- ADR-002 - depends-on
- ADR-004 - related-to (both run in the same setup pass)

## Supersedes

- None

## Superseded By

- None
