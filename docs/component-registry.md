# Component Registry

**Last updated:** 0000032-governance-continuity-and-write-gate-scope (17 Oct 2026)
**Maintained by:** planifest-docs-agent

---

## Registry

| ID | Name | Type | Domain | Status | Summary | Docs |
|----|------|------|--------|--------|---------|------|
| `setup-hook-integration` | Setup Hook Integration | component-pack | developer-tooling | active | setup.sh/ps1, skill-sync, and hook adapters (copilot, cursor, windsurf, codex): installs and configures enforcement hooks, commit standards, and external skill management into any Planifest-managed project. Writes a `.planifest-setup-flags` marker recording the flags used at install time (0000020). Registers `shell-write-guard.mjs` on a Claude Code `Bash` PreToolUse matcher, once per install (0000032). | [purpose](../src/setup-hook-integration/docs/purpose.md) |
| `planifest-framework` | Planifest Framework | component-pack | developer-tooling | active | Core standards, skills, hooks, and setup scripts enforcing the confirmed-design pipeline. Recent changes: ship-agent PR output omits the AI-attribution footer by default and its P7 archive commit stages `plan/current/` explicitly (0000025), setup scripts track active flags in a versioned `planifest-overrides/setup-config/{tool}.md`, the Scope Lock Challenge defaults to always-drafted, batch-presented answers, a new `em-dash-guard.mjs` PreToolUse hook rejects em dashes in Planifest prose (0000028), boot files (CLAUDE.md/AGENTS.md) are regenerated from the current template on every setup run (0000029), CI runs the test suite on Linux and macOS and `test_setup.ps1` under PowerShell 7 on Windows (0000031), and the session markers are cleared in P9 before the tag, with a blocking context clear after P9 (0000032). The shared `path-rules.mjs` module now holds the gated-path rules for `gate-write.mjs` and a new Bash `shell-write-guard.mjs` hook (0000032). | [component.yml](../planifest-framework/component.yml) |

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
