# Dependency Graph

**Last updated:** 0000032-governance-continuity-and-write-gate-scope (17 Oct 2026). `gate-write.mjs` and the new `shell-write-guard.mjs` import the shared `path-rules.mjs` module. No component dependency changed.
**Maintained by:** planifest-docs-agent

---

## Component Dependency Diagram

```mermaid
graph TD
    subgraph "planifest-framework (component-pack)"
        SKILLS["skills/ (orchestrator + phase agents)"]
        STANDARDS["standards/, templates/"]
        ENFORCE["hooks/enforcement/\n(gate-write, ratchet-check, check-design,\nem-dash-guard)"]
        SWG["hooks/enforcement/shell-write-guard.mjs\n(Bash PreToolUse, Claude Code only, 0000032)"]
        ENFSHARED["hooks/enforcement/ shared modules\n(read-stdin.mjs)\nalways installed"]
        PATHRULES["hooks/enforcement/path-rules.mjs\n(gated-path rules and repository root,\nshared module, always installed, 0000032)"]
    end

    subgraph "Claude Code Runtime"
        CC[Claude Code Agent]
        HookRunner["PreToolUse Hook Runner\n(Claude Code internal)"]
    end

    subgraph "setup-hook-integration (component-pack)"
        SH["setup.sh / setup.ps1"]
        SKS["skill-sync.sh"]
        MARKER[".planifest-setup-flags\n(per tool dir)"]
    end

    subgraph "planifest-refresh-setup (skill, 0000020)"
        RS["planifest-refresh-setup/SKILL.md"]
        DEL["refresh-delete-boot-files.sh/.ps1"]
    end

    subgraph "System Tools (runtime deps)"
        NODE["node (required, sole runtime)"]
    end

    CC -->|"plans Write/Edit call"| HookRunner
    SH -->|"reads hooks/skills/templates from"| ENFORCE
    SH -->|"copies skills into IDE-discovered dir"| SKILLS
    SKS -->|"syncs external skills for"| SKILLS
    ENFORCE -->|"wired via"| HookRunner
    HookRunner -->|"PreToolUse Write/Edit"| ENFORCE
    ENFORCE -->|"reads Component Paths from"| STANDARDS

    ENFORCE --- NODE
    ENFORCE -.->|"imports"| ENFSHARED
    ENFORCE -.->|"gate-write imports"| PATHRULES
    SWG -.->|"imports"| PATHRULES
    SWG -.->|"imports"| ENFSHARED
    HookRunner -->|"PreToolUse Bash"| SWG
    SWG --- NODE
    SH -->|"registers on Bash matcher, idempotent"| SWG
    SH -->|"copies *.mjs unconditionally"| ENFSHARED

    SH -->|"writes on successful install"| MARKER
    RS -->|"reads (reconstruction) and writes (pre-deletion cache)"| MARKER
    RS -->|"invokes"| DEL
    RS -->|"re-invokes with confirmed flags"| SH
```

---

## Dependency Direction Notes

- `setup-hook-integration` → `planifest-framework`: `setup.sh`/`setup.ps1` are the sole distribution mechanism: they copy `skills/`, `hooks/enforcement/`, `templates/`, and `standards/` into whichever directory the target agentic tool auto-discovers. One-way; `planifest-framework` has no dependency back on `setup-hook-integration`.
- `planifest-framework`'s `hooks/enforcement/` → Claude Code's PreToolUse hook runner: `gate-write.mjs` and `ratchet-check.mjs` are invoked on every Write/Edit; `ratchet-check.mjs` additionally reads `plan/current/loop-state-*.md` (not shown, not a component, a runtime artifact) to decide whether it is armed.
- `gate-write.mjs` and `shell-write-guard.mjs` → `path-rules.mjs` (0000032-ADR-004): both import the same module and keep no copy of the rules. `path-rules.mjs` imports Node built-ins only. It reads `plan/.orchestrator-active` and `plan/current/design.md` from the repository root it resolves. A broken import fails both hooks at module load, before their own `try`, so both stop enforcing at once (0000028-ADR-004).
- `planifest-framework`'s `hooks/enforcement/shell-write-guard.mjs` → Claude Code's Bash PreToolUse hook runner (0000032-ADR-006): `setup.sh` and `setup.ps1` register it for Claude Code only. Other tools don't run it.
- `planifest-refresh-setup` (0000020) -> `setup-hook-integration`: two-way relationship via the `.planifest-setup-flags` marker file. `setup.sh`/`setup.ps1` write it on every successful install (producer); the refresh skill reads it for reconstruction and writes to it again before deletion (consumer and secondary writer of the same file, ADR-002). The refresh skill also re-invokes `setup.sh`/`setup.ps1` directly once flags are confirmed, and calls `refresh-delete-boot-files.sh`/`.ps1` (its own hardcoded deletion script, not a dependency on `setup-hook-integration`).

---

## Planned Components (future pipelines)

| Planned Component | Depends On | Provides |
|-------------------|-----------|---------|
| `mcp-workspace-server` | N/A | Workspace tools for multi-repo operations |
