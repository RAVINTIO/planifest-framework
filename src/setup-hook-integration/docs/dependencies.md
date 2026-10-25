# Dependencies — setup-hook-integration

## What this component consumes

| Dependency | Source | Nature |
|---|---|---|
| `ravintio-framework/hooks/enforcement/` | Framework source | `gate-write.mjs`, `check-design.mjs` copied to `.claude/hooks/enforcement/`. Since 0000032, setup also registers `shell-write-guard.mjs`, which imports `path-rules.mjs` with `gate-write.mjs`. Setup copies every `*.mjs`, so both modules arrive together. Since 0000035, `ratchet-check.mjs` also imports `path-rules.mjs`, and setup needed no change for that. |
| `CLAUDE_PROJECT_DIR` (environment) | Runtime, set by Claude Code | Since 0000035, the installed `gate-write.mjs`, `shell-write-guard.mjs`, and `ratchet-check.mjs` read it first to find the root. It matters when the working folder no longer exists. Setup doesn't set it. If it is absent, the hooks walk up to the nearest existing parent (0000035 ADR-006, backlog 0000118). |
| `ravintio-framework/hooks/commit-msg` | Framework source | Registered via `git config core.hooksPath` |
| `ravintio-framework/skills/` | Framework source | Skill SKILL.md files copied to tool skills directory |
| `ravintio-framework/scripts/skill-sync.sh` | Framework source | Called for `add-skill`, `remove-skill`, `preserve-skill`, `unpreserve-skill` subcommands and on re-run sync |
| `ravintio-framework/setup/<tool>.sh` | Framework source | Per-tool configuration (TOOL_SKILLS_DIR, hook adapter paths) |
| `ravintio-framework/templates/standard-boot.md` | Framework source | Source for generated `CLAUDE.md` / `AGENTS.md` |
| `ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.sh` and `.ps1` | Framework source | Consumer helpers (0000039). A consumer runs one after copying the pack in and before setup. Setup does not call them. It stops with their name while the old pack or old overrides folder exists. |
| `RAVINTIO_SESSION_ID` and its pre-0.37.0 name (environment) | Runtime, set by OpenCode | The OpenCode adapter reads the new name first and the old name only when the new one is unset (0000039-ADR-004). |
| `node` (system) | Runtime | Required for JSON merging in `settings.json` and `opencode.json`, and for the retired-integration clean-up. `jq` is no longer used. Without Node the clean-up skips with a warning |
| `curl` (system) | Runtime | Required by `skill-sync.sh` for fetching external skills |
| `bash` ≥4 (system) | Runtime | Setup scripts are bash 4+ (associative arrays, `[[ ]]`) |

## What depends on this component

No other components in `src/` depend on `setup-hook-integration`. It is consumed directly by developers running `setup.sh`.
