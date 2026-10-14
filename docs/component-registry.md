# Component Registry

**Last updated:** 0000030-context-mode-and-telemetry-mcp-removal (14 Oct 2026)
**Maintained by:** planifest-docs-agent

---

## Registry

| ID | Name | Type | Domain | Status | Summary | Docs |
|----|------|------|--------|--------|---------|------|
| `setup-hook-integration` | Setup Hook Integration | component-pack | developer-tooling | active | setup.sh/ps1, skill-sync, and hook adapters (copilot, cursor, windsurf, codex): installs and configures enforcement hooks, commit standards, and external skill management into any Planifest-managed project. Writes a `.planifest-setup-flags` marker recording the flags used at install time (0000020). | [purpose](../src/setup-hook-integration/docs/purpose.md) |
| `planifest-framework` | Planifest Framework | component-pack | developer-tooling | active | Core standards, skills, hooks, and setup scripts enforcing the confirmed-design pipeline. Recent changes: ship-agent PR output omits the AI-attribution footer by default and its P7 archive commit stages `plan/current/` explicitly (0000025), setup scripts track active flags in a versioned `planifest-overrides/setup-config/{tool}.md`, the Scope Lock Challenge defaults to always-drafted, batch-presented answers, a new `em-dash-guard.mjs` PreToolUse hook rejects em dashes in Planifest prose (0000028), and boot files (CLAUDE.md/AGENTS.md) are regenerated from the current template on every setup run (0000029). | [component.yml](../planifest-framework/component.yml) |

---

## Status Key

| Status | Meaning |
|--------|---------|
| `active` | In production / installed in target environments |
| `in-progress` | Pipeline in flight |
| `deprecated` | Superseded; pending removal |
| `planned` | On roadmap; not yet in a pipeline |

---

## Notes

- This registry is updated by the docs-agent at the end of each feature pipeline.
- Each `ID` corresponds to a directory under `src/` containing a `component.yml` manifest.
- Add new components here when a new feature pipeline completes Phase 6.
