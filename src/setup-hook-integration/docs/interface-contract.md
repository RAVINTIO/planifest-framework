# Interface Contract — setup-hook-integration

## Inputs

| Input | Type | Required | Description |
|---|---|---|---|
| `<tool>` | CLI positional arg | Yes | Target tool: `claude-code`, `cursor`, `windsurf`, `cline`, `codex`, `opencode`, `copilot`, `antigravity`, `roo-code`, `all` |
| `--strict-orchestrator` | CLI flag | No | Make the orchestrator sentinel strict |
| `--include-full-skill-library` | CLI flag | No | Install the full third-party skill library |
| The three retired integration flags (see 0000030-ADR-003) | CLI flags | No | Accepted for compatibility. Each prints a one-line notice that the flag was removed in 0.29.0 and has no effect, then setup continues with exit 0. One of them takes a value, and setup consumes that value without validating it. No retired flag is written to the install marker |
| `add-skill <name> <tool>` | Subcommand | No | Delegate to skill-sync.sh: fetch and install an external skill |
| `remove-skill <name> <tool>` | Subcommand | No | Delegate to skill-sync.sh: remove an installed skill |
| `preserve-skill <name> <tool>` | Subcommand | No | Delegate to skill-sync.sh: promote skill from plan-scoped to preserved |
| `unpreserve-skill <name> <tool>` | Subcommand | No | Delegate to skill-sync.sh: demote skill from preserved to plan-scoped |

## Outputs

| Output | Type | Description |
|---|---|---|
| `.claude/settings.json` | File (merged) | Hook wiring for PreToolUse and UserPromptSubmit. Additive merge, never full replacement. Every enforcement command string is written with a `node` interpreter prefix (0000028 P5 SEC-001); a bare `.mjs` path exits 126 against the non-executable committed file mode and fails open silently. For Claude Code, setup also registers `shell-write-guard.mjs` on a `Bash` PreToolUse matcher (0000032-ADR-006). It first removes any earlier `Bash` group whose command names `shell-write-guard`, so a re-run leaves exactly one. Other `Bash` groups stay in place. |
| `.claude/hooks/enforcement/` | Directory | Every `*.mjs` under `hooks/enforcement/`, always installed, not gated on any flag. Currently `gate-write.mjs`, `check-design.mjs`, `ratchet-check.mjs`, `em-dash-guard.mjs` (0000028), `auto-trigger-orchestrator.mjs`, `check-orchestrator-presence.mjs`, `shell-write-guard.mjs` (0000032), plus the shared modules `read-stdin.mjs` (0000028) and `path-rules.mjs` (0000032) |
| `.claude/skills/` | Directory | Skill files from `ravintio-framework/skills/` |
| `CLAUDE.md` | File | Generated from `templates/standard-boot.md` (Claude Code only). Since 0000035, the Write-or-Edit rule (boot Hard Limit 8) names the sanctioned scripts, and the Hook Enforcement section covers the Fast Path scope record and link judgement. Setup copies the template text and changed in no other way (0000035 ADR-011) |
| `git config core.hooksPath` | Git config | Points to `ravintio-framework/hooks/` for advisory commit-msg hook |
| `ravintio-framework/external-skills.json` | File | Manifest of installed external skills (created on first `add-skill`) |
| `<tool-dir>/.ravintio-setup-flags` | File | Flags-used marker (0000020): tool, flags applied, timestamp, attempt status. Written on every successful install; consumed by `ravintio-refresh-setup`. Schema: `docs/data-contract.md` |

| Clean-up output | stdout lines | Every run prints one line per removal, in the form `  - <path> (retired, removed)` for a deleted path. It prints nothing when it finds nothing |
| `<tool>` settings files and `opencode.json` | File (merged) | Every settings writer skips a file that is not valid JSON, leaves it byte-identical, and names the parse error. Every write goes to a temporary file in the same folder and is renamed into place |

<!-- BEGIN retired-integrations (0000030) -->
## Retired-integration clean-up (0000030)

Every setup run, for every tool, runs this pass before its normal wiring (0000030-ADR-004). The pass runs in this order:

1. Remove hook entries, under any event, whose command runs a file under the tool's `hooks/context-mode/` or `hooks/telemetry/` folder, or `check-telemetry-failures.mjs` or `check-telemetry-receipts.mjs`. The match is on command path, never on matcher alone, so a hand-added hook stays. A group left with no hooks is dropped.
2. Remove hook groups whose matcher is `mcp__structured-telemetry-mcp__emit_event`. This step matches the matcher alone because that server no longer exists.
3. Delete the stale hook folders and the installed `check-telemetry-*.mjs` and `phase-enum.mjs` copies. This deletes the whole folder, including any file a person added (accepted, backlog 0000090).
4. Delete `.claude/telemetry-enabled`, `plan/.telemetry-failures/`, and `plan/.telemetry-receipts/`.

Failure behaviour, in every case with exit 0:

- If a settings file does not parse, the pass leaves it byte-identical, names the parse error, and skips only that file.
- If Node is missing, the pass skips with a warning.
- Before each delete, `setup.sh` resolves the parent folder with `cd -P` and refuses a path outside the physical project root. `setup.ps1` refuses any reparse point between the path and the root.
- `setup.ps1` uses `-LiteralPath`, removes a reparse point with `.Delete()` so it never follows the link, and finds dangling links with `Get-Item -Force`.
- A failed delete or rename prints a warning and setup continues. A failed rename removes the temporary file and leaves the original untouched.
- Settings temporary files get a random name, are created exclusively (`wx` in Node, `CreateNew` in PowerShell), and copy the target file's mode.

<!-- END retired-integrations (0000030) -->

## Windows PowerShell 5.1 (0000037)

`setup.ps1` runs under PowerShell 7 and Windows PowerShell 5.1 with the same inputs and outputs (0000037-ADR-012). Two behaviours matter to a caller:

- `Merge-AllowedTools` parses `settings.json` through `ConvertTo-RavintioHashtable`, since 5.1 has no `ConvertFrom-Json -AsHashtable`.
- `Invoke-RavintioGuardrails` checks the exit code of `git config core.hooksPath`. If the call fails, for example outside a git repository, setup prints a warning, continues, and does not print the guardrails-activated line. `setup.sh` behaves the same way.

## OpenCode setup

`setup/opencode.sh` now parses and writes `opencode.json` with Node and the shared settings helpers, not `jq`. A malformed `opencode.json` stays byte-identical and setup warns (F1). If you run `setup/opencode.sh` on its own, it leaves an existing `opencode.json` unchanged and prints a warning, because the helpers come from `setup.sh`.

## Wiring files and the Fast Path enforcement list (0000035)

A Fast Path scope record never admits a write to a file that wires the hooks (0000035 ADR-004). `FAST_PATH_ENFORCEMENT_PATHS` in `hooks/enforcement/path-rules.mjs` lists these setup outputs and sources:

- every hook wiring file that `setup.sh` and `setup.ps1` write, such as `.claude/settings.json` and `.github/hooks/`
- the installed `hooks/enforcement/` and `hooks/adapters/` folders
- `ravintio-framework/setup/`, `setup.sh`, `setup.ps1`, and the installed `.github/workflows/ravintio.yml`

If setup gains a new wiring file, add it to that constant and to the `workflows/fast-path.md` prerequisites in the same change. The req-009 suite checks that the two lists match.

## Rename to RAVINTIO and old-name reads (0000039)

Version 0.37.0 renames the pack to `ravintio-framework/`, the overrides folder to `ravintio-overrides/`, and every skill to `ravintio-*`. Setup and hook output use the `[RAVINTIO]` prefix. Setup changes in these ways:

- Setup stops with exit 1 while the old pack folder or the old overrides folder exists. The message names `migrate-0.37.0-ravintio-rename`.
- Setup replaces the old boot-file instruction markers and the old ignore-file headers with the RAVINTIO forms.
- Setup reads the old setup flags file and the old manifest file once, then removes them. It prunes the old skill folders from the skills folder.
- The OpenCode adapter reads `RAVINTIO_SESSION_ID` first and the old session ID variable only when the new one is unset.

Each of these reads is removed at 1.0.0. The helpers `migrate-0.37.0-ravintio-rename.sh` and `.ps1` behave the same, move the old pack into `.ravintio-backup/`, and delete no pack file (0000039-ADR-005).

## Breaking Change Policy

Changes to `setup.sh` inputs or outputs require a version bump in `component.yml` and a migration note. Consumers: any developer running setup.sh on a RAVINTIO-managed project.

## Consumers

No downstream components consume the outputs programmatically. Outputs are consumed by:
- The AI coding agent at session start (reads `settings.json`, skills, boot file)
- Git at commit time (reads `core.hooksPath`)
- `skill-sync.sh` (reads `external-skills.json`)
- `ravintio-refresh-setup` skill (reads and updates `.ravintio-setup-flags`, 0000020)
