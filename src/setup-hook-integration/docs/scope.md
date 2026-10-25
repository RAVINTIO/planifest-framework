# Scope — setup-hook-integration

## In Scope

- `setup.sh` and `setup.ps1` — all flag processing and tool dispatch
- `setup/<tool>.sh` and `setup/<tool>.ps1` — per-tool configuration stubs
- `ravintio-framework/hooks/` — all hook scripts installed by setup
- `ravintio-framework/scripts/skill-sync.sh` and `skill-sync.ps1` — external skill lifecycle management
- `ravintio-framework/standards/commit-standards.md` — normative commit message rules
- `ravintio-framework/templates/standard-boot.md` — source template for generated boot files
- `external-skills.json` manifest — records installed external skills
- Claude Code, Cursor, Windsurf, Cline, Codex, OpenCode, Copilot, Antigravity, Roo Code tool targets
- Acceptance of the three retired integration flags as no-ops (0000030-ADR-003)
<!-- BEGIN retired-integrations (0000030) -->
- The always-on clean-up of the retired integrations, including deleting `plan/.telemetry-failures/` and `plan/.telemetry-receipts/` (0000030-ADR-004, ADR-005)
<!-- END retired-integrations (0000030) -->
- `setup/opencode.sh` registration of the plugin in `opencode.json` through Node
- `<tool-dir>/.ravintio-setup-flags` marker write on successful install, in parity between `setup.sh` and `setup.ps1` (0000020)

## Out of Scope

- The content of individual skill SKILL.md files (owned by each skill)
- MCP server configuration is the user's responsibility. Setup installs no MCP integration since 0000030
- Hook uninstall / removal logic, except the fixed retired-integration clean-up list (0000030). Setup does not remove any other hook
- Automated rollback on failed setup — not implemented
- Skill content validation beyond YAML frontmatter presence

## Deferred

- Narrower clean-up that deletes shipped file names only (backlog 0000090)
- Live PowerShell checks beyond `test_setup.ps1`, such as stale-entry clean-up and retired flags
- `setup all` stopping at roo-code (backlog 0000087) and the opencode PowerShell null skills folder (backlog 0000088)
- `setup.ps1` skill subcommand routing (TD-006) — add in next iteration
- `validate_skill_name()` security guard (TD-001/002/003) — add via change-agent
- Automated test coverage for `skill-sync.sh` operations — future iteration
- `setup/copilot.sh`/`.ps1` `TOOL_HOOK_ADAPTER_DEST` self-copy bug (crashes `setup.sh copilot` on every run), discovered during 0000020 P5, filed as backlog `0000027`, not fixed in this feature
