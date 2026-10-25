---
title: "Backlog Entry: 0000064 - Playwright MCP as a setup flag, used comprehensively when configured"
summary: "RAVINTIO Framework has no first-class browser-automation integration. Add a --playwright-mcp setup flag alongside the existing --structured-telemetry-mcp gate, and when it is configured, route every Playwright-shaped requirement through the MCP rather than leaving each run to improvise with whatever browser tooling the host happens to expose."
status: "open"
---
# Backlog Entry: 0000064 - Playwright MCP as a setup flag, used comprehensively when configured

**Source feature:** 0000028-telemetry-hardening-and-enforcement-fixes
**Source phase:** P0 (backlog exploration, raised directly by the human on the loop)
**Deferral source:** discovered mid-flight
**Date filed:** 2026-08-08

---

## Problem

RAVINTIO has no first-class integration with browser automation, and no declared position on how a feature
whose acceptance criteria are browser-shaped should be verified.

Three things are true today and pull against each other:

1. **`ravintio-verify-by-execution` demands real execution.** The P4 skill explicitly requires acceptance
   criteria to be verified by running the software, naming "browser click-throughs" first among its methods,
   and forbids verification by reading test output alone. It does not say what drives the browser.

2. **The framework already knows how to gate an MCP integration.** `--structured-telemetry-mcp` is passed to
   `setup.sh` / `setup.ps1`, and `0000018 ADR-001` makes that single flag the unified signal governing whether
   telemetry emission is mandatory or genuinely absent. That is a working, precedented pattern for exactly
   this shape of optional external capability, owned by the `setup-hook-integration` component.

3. **Nothing connects the two.** There is no `--playwright-mcp` flag, no equivalent unified signal, and no
   guidance in any phase skill about which browser surface to use. A run needing browser verification is left
   to improvise against whatever the host tool happens to expose that session, which differs between Claude
   Code, Cursor, Windsurf and the rest. The `webapp-testing` capability skill named in the orchestrator's
   Capability Skills section is the closest existing answer, but capability skills encode craft knowledge and
   are installed ad hoc per plan; they are not a declared, detectable project capability the way a setup flag is.

**Availability, checked at filing time rather than assumed.** Playwright MCP was not available in the session
that filed this entry. It is absent from the session's tool set, and `search_mcp_registry` returned zero
results for `playwright`, `browser automation`, `e2e testing` and `web testing`. What was available was the
in-app Browser (`mcp__Claude_Browser__*`, offering navigate, read_page, computer, console and network reads)
and Claude in Chrome (`mcp__claude-in-chrome__*`). So this entry is not blocked on a missing feature in
RAVINTIO alone; at pickup someone must first establish how the target Playwright MCP is obtained and
registered, because it was not installable from the registry on the machine where this was filed.

## Suggested Action

Add a `--playwright-mcp` flag to `setup.sh` and `setup.ps1` mirroring the `--structured-telemetry-mcp`
pattern: recorded in the flags-used marker, detectable by the orchestrator at P0, surfaced in `discovery.md`
alongside the other capability signals, and reconstructable by `ravintio-refresh-setup`.

When the flag is configured, make its use comprehensive rather than optional. That means at minimum: the P0
discovery pass records it as an available capability; the spec-agent may write browser-driven acceptance
criteria knowing a deterministic driver exists; `ravintio-verify-by-execution` prefers the MCP over ad hoc
browser tooling for any criterion needing a click-through; and the codegen-agent generates Playwright specs
rather than hand-rolled browser scripts. When the flag is absent, behaviour is exactly as today, with no
prompt and no degradation, matching how the telemetry signal behaves when genuinely absent.

Decisions worth making at pickup rather than inheriting: whether a browser-shaped acceptance criterion should
hard-block when the flag is absent or degrade to manual verification; whether this generalises to a
capability-flag mechanism rather than a second bespoke flag, given a third such integration is now plausible;
and how the flag interacts with the existing `webapp-testing` capability skill, which overlaps in intent and
should not end up as a competing answer to the same question.

## Why Deferred

Raised during `0000028`'s P0 backlog exploration, after that feature's scope was already confirmed and locked
with the human on the loop. `0000028` is a telemetry-hardening and enforcement-fix release touching
`hooks/telemetry/*.mjs`, `block-bash.mjs` and a style-guard hook; a new setup flag with cross-phase skill
changes shares none of that surface and would push an already-oversized batch further past the framework's
own three-story heuristic.

It also needs a design decision before it can be specified, which is the more binding reason. The
absent-flag behaviour, the block-or-degrade question, and whether to build a general capability-flag
mechanism instead of a second bespoke one are all genuine architectural choices, not implementation detail.
Filing them as open questions here is more honest than pre-deciding them in a run that cannot give them room.

Practical prerequisite: Playwright MCP could not be located from the filing machine, so pickup should begin
by establishing how it is obtained and registered before any framework work is specified against it.
