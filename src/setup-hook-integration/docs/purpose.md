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

7. **Accepts the three retired integration flags** (see 0000030-ADR-003). Each prints a one-line notice and changes nothing, so a refresh from an old marker still succeeds.
8. **Cleans up the retired integrations** (0000030). Every run, for every tool, removes stale settings entries, hook folders, and state files before it wires anything. See 0000030-ADR-004 and 0000030-ADR-005.
9. **Registers the shell-write guard** (0000032). For Claude Code, setup wires `shell-write-guard.mjs` on a `Bash` PreToolUse matcher. A re-run replaces the earlier entry, so the install holds exactly one. See 0000032-ADR-006.

It is designed to be re-run safely (idempotent) and is the single entry point for all tool-specific configuration.
