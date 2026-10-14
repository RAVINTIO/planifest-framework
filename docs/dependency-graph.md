# Dependency Graph

**Last updated:** 0000030-context-mode-and-telemetry-mcp-removal (14 Oct 2026). The two retired hook integrations and their external services are removed from the graph.
**Maintained by:** planifest-docs-agent

---

## Component Dependency Diagram

```mermaid
graph TD
    subgraph "planifest-framework (component-pack)"
        SKILLS["skills/ (orchestrator + phase agents)"]
        STANDARDS["standards/, templates/"]
        ENFORCE["hooks/enforcement/\n(gate-write, ratchet-check, check-design,\nem-dash-guard)"]
        ENFSHARED["hooks/enforcement/ shared modules\n(read-stdin.mjs, phase-enum.mjs)\nalways installed"]
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
- `planifest-refresh-setup` (0000020) -> `setup-hook-integration`: two-way relationship via the `.planifest-setup-flags` marker file. `setup.sh`/`setup.ps1` write it on every successful install (producer); the refresh skill reads it for reconstruction and writes to it again before deletion (consumer and secondary writer of the same file, ADR-002). The refresh skill also re-invokes `setup.sh`/`setup.ps1` directly once flags are confirmed, and calls `refresh-delete-boot-files.sh`/`.ps1` (its own hardcoded deletion script, not a dependency on `setup-hook-integration`).

---

## Planned Components (future pipelines)

| Planned Component | Depends On | Provides |
|-------------------|-----------|---------|
| `mcp-workspace-server` | N/A | Workspace tools for multi-repo operations |
