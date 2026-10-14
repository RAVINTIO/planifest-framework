# Purpose — setup-hook-integration

## What this component exists to do

`setup-hook-integration` is the installation layer of the Planifest framework. It bridges the framework source (in `planifest-framework/`) and the tool-specific configuration directories that AI coding agents read at startup.

When a developer runs `setup.sh <tool>`, this component:

1. **Installs enforcement hooks** — copies `gate-write.mjs` and `check-design.mjs` into `.claude/hooks/enforcement/` and wires `PreToolUse` (Write/Edit) and `UserPromptSubmit` entries in `settings.json`.
2. **Installs the advisory commit-msg hook** — registers `planifest-framework/hooks/commit-msg` via `git config core.hooksPath`.
3. **Syncs external skills** — calls `skill-sync.sh sync <tool>` to re-install any skills registered in `external-skills.json`.
4. **Copies skills to the tool's skills directory** — SKILL.md files from `planifest-framework/skills/` copied to `.claude/skills/`, `.cursor/rules/`, etc.
5. **Writes the boot template** — generates `CLAUDE.md`, `AGENTS.md`, etc. from `templates/standard-boot.md`.
6. **Records the flags used** (0000020), writes `<tool-dir>/.planifest-setup-flags` on successful completion, so the `planifest-refresh-setup` skill can reconstruct and re-apply the same flags later without the human on the loop having to remember or reverse-engineer them.

It is designed to be re-run safely (idempotent) and is the single entry point for all tool-specific configuration.
