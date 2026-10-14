# Architecture Overview

> Living document. Reflects current system state. Updated after every pipeline run.
> Do not archive this file; update it in place.

Last updated: 0000030-context-mode-and-telemetry-mcp-removal

---

## System Summary

Planifest is a CLI tooling framework that enforces a structured design pipeline for agentic coding agents. It installs enforcement hooks into agentic IDEs (Claude Code, Cursor, Windsurf, GitHub Copilot, Codex) that gate writes to `src/` behind a confirmed design document, and provides a suite of pipeline skills (spec, ADR, codegen, validate, security, docs, ship) that guide development from brief to merged PR.

---

## Components

| Component | Type | Purpose | Status |
|-----------|------|---------|--------|
| `setup-hook-integration` | component-pack | setup.sh/ps1 and skill-sync: installs enforcement hooks, commit standards, external skill management, and (0000020) a per-tool flags-used marker into any Planifest-managed project | active |
| `planifest-refresh-setup` | skill (standalone, not a src/ component) | Detects a Planifest install's target tool, reconstructs the setup flags in effect from the flags-used marker or hook wiring, confirms with the human on the loop, and safely re-invokes setup.sh/setup.ps1; see `planifest-framework/skills/planifest-refresh-setup/SKILL.md` | active |

---

## Communication Patterns

```mermaid
flowchart TD
    subgraph IDE["Agentic IDE (Claude Code / Cursor / Windsurf / Copilot / Codex)"]
        Agent["Agent"]
        HookRunner["Hook Runner\n(PreToolUse / UserPromptSubmit)"]
    end

    subgraph Adapters["Hook Adapters (planifest-framework/hooks/adapters/)"]
        CUR["cursor.mjs"]
        CPL["copilot.mjs"]
        WS["windsurf.mjs"]
        CDX["codex.mjs"]
    end

    subgraph Enforcement["Enforcement Scripts (hooks/enforcement/)"]
        GW["gate-write.mjs\n(path allowlist + sentinel check)"]
        CD["check-design.mjs\n(scope injection)"]
        RC["ratchet-check.mjs\n(criteria/scope weakening block,\narmed while a loop is active)"]
        ED["em-dash-guard.mjs\n(U+2014 rejected in Planifest prose,\nsentinel bypass, 0000028)"]
        SHE["read-stdin.mjs\n(shared module, always installed)"]
    end

    subgraph Setup["Setup (planifest-framework/)"]
        SH["setup.sh / setup.ps1"]
        SS["skill-sync.sh / skill-sync.ps1"]
    end

    subgraph Skills["Pipeline Skills (P0–P9)"]
        ORCH["planifest-orchestrator\n(P0)"]
        SPEC["planifest-spec-agent\n(P1)"]
        ADR["planifest-adr-agent\n(P2)"]
        CG["planifest-codegen-agent\n(P3)"]
        VAL["planifest-validate-agent\n(P4)"]
        SEC["planifest-security-agent\n(P5)"]
        DOCS["planifest-docs-agent\n(P6)"]
        SHIP["planifest-ship-agent\n(P7–P9)"]
        BA["planifest-build-assessment-agent\n(P8, sub-agent of ship-agent)"]
    end

    Agent -->|"plans Write/Edit"| HookRunner
    Agent -->|"submits prompt"| HookRunner
    HookRunner -->|"stdin JSON"| CUR
    HookRunner -->|"stdin JSON"| CPL
    HookRunner -->|"stdin JSON"| WS
    HookRunner -->|"stdin JSON"| CDX
    CUR -->|"common envelope"| GW
    CUR -->|"common envelope"| CD
    CPL -->|"common envelope"| GW
    CPL -->|"common envelope"| CD
    WS -->|"common envelope"| GW
    WS -->|"common envelope"| CD
    CDX -->|"common envelope"| GW
    CDX -->|"common envelope"| CD
    GW -->|"exit 0 (pass) / exit 2 (block)"| HookRunner
    CD -->|"additionalContext JSON"| HookRunner
    HookRunner -->|"stdin JSON (Write/Edit)"| ED
    ED -->|"exit 0 (pass) / exit 2 (block)"| HookRunner
    GW -.->|"imports"| SHE
    CD -.->|"imports"| SHE
    RC -.->|"imports"| SHE
    ED -.->|"imports"| SHE

    SH -->|"copies skills + writes hook configs"| IDE
    SS -->|"syncs on re-run"| IDE

    ORCH --> SPEC --> ADR --> CG --> VAL --> SEC --> DOCS --> SHIP
```

---

## Governance Loops (0000016)

The pipeline has an optional loop layer, entirely toggle-gated via `planifest-overrides/loop-toggles.yml` (absent = all off; zero-config behaviour identical to pre-0000016):

| Loop | Seam | Verifier | Deterministic guard |
|------|------|----------|--------------------|
| P0 completeness | P0 exit | Gate checklist re-evaluated per coaching round | 2-rounds-per-gap escalation |
| Design critic | End of P1/P2 | Fresh-context `planifest-design-critic` (REJECT-default) + `scripts/consistency-check.mjs` | Cap 3, no-progress halt |
| Governed reversal | P3–P6 blocked by upstream P0–P6 artifact | Fresh-context `planifest-reversal-assessor` (DENY-default) | Budget 2/feature, cascade >3 human gate, ratchet-check.mjs on writes |
| Verify-by-execution | P4 after CI | `planifest-verify-by-execution` (runs the software) | Feeds existing P4 cap-5 loop |
| Cross-model review | End of P6, strictly pre-P7-archive | Fresh-context reviewer on a different model id (REJECT-default) | Cap 3; blocks P7 on cap-without-approval |

Shared mechanics (state file, append-only run log, stop rules, escalation format) live in `planifest-loop-runner`. P7 remains the lock line: no loop or reversal touches archived state (`plan/backlog/` is the governed home for deferred work instead).

---

## Shared hook modules (0000028)

Hook files import their shared helper by relative path instead of carrying their own copy. `read-stdin.mjs` lives in `hooks/enforcement/`, which installs unconditionally, so every hook that imports it finds it on every install. A helper with an always-installed caller belongs in that tree. The reverse placement would leave an always-installed hook importing an absent module, which fails at ESM module-load time before the hook's own `try/catch` runs and so defeats the exit-zero invariant.

Self-modification sequencing (ADR-004) governs how such a change is applied to hooks that are executing the build doing the editing. Rewire one caller, commit, re-run `setup.sh` for that edit alone, then assert a real side effect. Exit 0 proves nothing here by design.

---

## Data Ownership

No components own persistent data. Planifest operates on local filesystem artifacts (plan/ files, skill SKILL.md files) written and read during pipeline execution. No databases. New in 0000016 (all plain markdown/YAML, git-tracked): `plan/backlog/` entries (orchestrator-owned, filed by any phase agent), `product.yml` (ship-agent writes, orchestrator reads), and `plan/current/` loop-state/run-log/defect-report/revision-log artifacts (orchestrator-owned). New in 0000020 (local, gitignored, not version-tracked): `<tool-dir>/.planifest-setup-flags`, owned by `setup-hook-integration`, written on every successful install and read/updated by `planifest-refresh-setup`. New in 0000025 (git-tracked, additive to the 0000020 marker, not a replacement): `planifest-overrides/setup-config/{tool}.md`, one file per AI tool, written by `setup.sh`/`setup.ps1` alongside the existing gitignored marker so the flags in effect at install time are versioned and reviewable, not only locally cached.

---

## External Dependencies

| Dependency | Type | Components That Use It |
|-----------|------|----------------------|
| Node.js (built-ins only: fs, path, child_process, os, url) | Runtime | All hook adapters and enforcement scripts |
| Bash | Runtime | setup.sh, test scripts, hook install scripts |
| PowerShell 7+ | Runtime | setup.ps1, test_setup.ps1, PowerShell hook scripts |
| git (core.hooksPath) | CLI | setup.sh/ps1 (commit-msg hook installation) |

---

## Key Architectural Decisions

Reference `docs/decisions-index.md` for the full ADR list.

- **ADR-001 (0000003):** Three-tier enforcement model: Claude Code (Tier 1a), other IDEs (Tier 1b), instructions-only (Tier 2)
- **ADR-002 (0000003):** Common envelope shape: all adapters normalise to `{ session_id, cwd, tool_input, event }` before delegating
- **ADR-005 (0000003):** Exit-zero failure mode: hooks never block on unexpected errors (NFR-003)
- **ADR-003 (0000011):** Hook adapter architecture: delegating pattern; adapters translate envelopes, enforcement logic lives only in shared scripts
- **ADR-003 (0000018):** discovery.md elevated to Hard Limit status: matches build-log.md's Hard Limit 8 enforcement pattern
- **ADR-001 (0000020):** Hardcoded, non-extensible deletion allowlist for the refresh skill, enforced in a dedicated script, not prose alone (P5 security finding)
- **ADR-002 (0000020):** Single marker file (`.planifest-setup-flags`) serves as both install-time record and refresh retry cache, not two separate files
- **ADR-003 (0000020):** Mandatory human confirmation gate before any refresh action, regardless of flag-reconstruction confidence
- **ADR-004 (0000020):** Tool selection is explicit input to the refresh skill, never silently auto-resolved when multiple installs are present
- **ADR-005 (0000020):** No automatic retry on a failed setup re-invocation; retry is always human-initiated
- **ADR-001 (0000024):** `product.yml` extended to single-component projects as the declared product id home (stable name for versioning and for attributing archived runs): extends, not supersedes, 0000016 ADR-002's versioning-only scope
- **ADR-001 (0000025):** Ship-agent PR footer defaults off; restorable only via a `planifest-overrides/instructions/` opt-in file
- **ADR-002 (0000025):** `planifest-overrides/setup-config/{tool}.md` (tracked) is source of truth over the gitignored `.planifest-setup-flags` marker; reconciled on setup/refresh; `.orchestrator-strict` explicitly out of scope
- **ADR-003 (0000025):** Scope Lock Challenge defaults to always-drafted, batch-presented answers: supersedes **ADR-003 (0000017)**, scoped narrowly against `0000014-ADR-008`'s one-question-at-a-time convention (unchanged everywhere else)
- **ADR-002 (0000028):** Shared hook modules live inside the existing `hooks/enforcement/` tree, which installs unconditionally, never in a new top-level `shared/` directory
- **ADR-003 (0000028):** The em dash guard attaches as a `PreToolUse(Write, Edit)` sibling of `gate-write.mjs`, not a git hook, with a reusable in-content sentinel as the bypass so the exemption is visible in the artifact's own diff
- **ADR-004 (0000028):** Self-modification sequencing: when editing the hooks running the build, rewire one caller at a time and verify a real side effect, because exit 0 cannot distinguish a working hook from a silently broken one
- **ADR-002 (0000030):** The retired hook and MCP integrations are removed from the framework. Setup ignores their flags and a re-run cleans up the old install.

---

*Template: architecture-overview.template.md*
