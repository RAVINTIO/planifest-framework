---
title: "Domain Glossary - pipeline friction and gate fixes"
summary: "Definitions of domain terms used within feature 0000036."
status: "active"
version: "0.1.0"
---
# Domain Glossary - pipeline friction and gate fixes

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md) (updated by any agent that introduces a new domain term)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Version:** 0.34.0

> Terms come from `design.md`, `feature-brief.md`, `discovery.md`, and the framework files. Concepts without a clear name are listed after the table.

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| Drift check | The script `scripts/skill-drift-check.mjs`. It compares each source `SKILL.md` with its installed copy by bytes. It warns and never blocks. It exits 0 on a match, 1 on drift or a missing copy, and 2 when it can't compare (US-002). | skill drift check | planifest-framework |
| Drift | An installed `SKILL.md` that differs from its source copy. | stale copy | planifest-framework |
| Installed copy | The copy of a framework file that a setup script writes into a tool folder, such as `.claude/skills/`. The drift check reads it and setup owns it. | | planifest-framework |
| Source copy | The canonical file under `planifest-framework/`, such as `planifest-framework/skills/{name}/SKILL.md`. | source | planifest-framework |
| Tool folder | The folder a tool loads framework files from, such as `.claude/`. The drift check covers every one it finds when the active tool is unknown. | | planifest-framework |
| Install marker | The file that records the setup flags in effect, `.claude/.planifest-setup-flags` or the tool's equivalent. The drift check reads it to find the active tool. | flags-used marker | planifest-framework |
| Re-run-setup migration | A migration that tells the human on the loop to re-run setup so installed hooks and the boot file match the framework version. This release ships `migrate-0.34.0-rerun-setup.md`. | | planifest-framework |
| Setup-delivered file | A file that `setup.sh` or `setup.ps1` copies or writes into a project, such as a hook or a boot file. A release that changes one ships a re-run-setup migration. | | planifest-framework |
| Migration | A file in `planifest-framework/migrations/` that brings a project in line with a framework change. | | planifest-framework |
| Migration record | The file in `plan/_migrations/` that shows a migration ran in this project. | run record | planifest-framework |
| Migrator | The `planifest-migrator` skill. It runs one pending migration with the human on the loop and writes the record. | | planifest-framework |
| Resume detection | The orchestrator step at session start. It lists pending migrations and, in this release, runs the drift check. | | planifest-framework |
| `planifest-refresh-setup` | The skill that detects the target tool, rebuilds the setup flags in effect, confirms with the human on the loop, and re-runs setup. The orchestrator recommends it on drift. | refresh setup | planifest-framework |
| Run-mode anchor | The recorded run-mode confirmation line in the build log. `run-mode.mjs` reads it. It is a bare line or one leading `- ` list item, and the bare line in a code block is the preferred form (US-004). | anchor | planifest-framework |
| Run mode | The value in `plan/.run-mode`. It is `interactive`, `continuous`, or `autonomous`. This run is `autonomous`. | | planifest-framework |
| One-commit rule | The rule that `run-mode.mjs` trusts the anchor only when one commit added it. A line added in a later commit reads as `interactive`. | | planifest-framework |
| Hard limit | A numbered rule in a boot file or the orchestrator skill. Two rules share the number 8, so citations name the rule and the source. | Hard Limit | planifest-framework |
| Build-log rule | Orchestrator Hard Limit 8, which covers the build log. | | planifest-framework |
| Write-or-Edit rule | Boot Hard Limit 8, which requires every change to code and project files through **Write** or **Edit**. | | planifest-framework |
| Bare citation | A hard-limit citation that gives a number and no rule name, such as "Hard Limit 8". A suite fails on one (US-005). | | planifest-framework |
| Design critic | The `planifest-design-critic` skill. It gives a fresh-context, REJECT-default critique of P1 and P2 artifacts. | | planifest-framework |
| `design_critic` | The key in `loop-toggles.yml` that sets the critic mode. An absent key now reads as `report-only` outside `autonomous` and as `on` in `autonomous`. | | planifest-framework |
| Report-only | A critic mode where the verdict goes to the build log and blocks nothing. | `report-only` | planifest-framework |
| Toggle file | `loop-toggles.yml`. A missing file reads the same as a missing key. | `loop-toggles.yml` | planifest-framework |
| Split step | A step in the spec agent, the design critic rubric, and the loop runner fix dispatch. It fires when a requirement would reach a fourth criterion and asks whether it holds two concerns (US-007). | | planifest-framework |
| Three-story rule | The release size limit of three stories when no `release-budget.yml` exists. This run exceeds it by choice. | | planifest-framework |
| Wave | A group of features that ships together. This release has one wave of eleven stories. | | planifest-framework |
| Non-regular file | Anything at a path that is not a regular file, such as a folder or a FIFO. A non-regular `plan/current/design.md` counts as no design (US-008). | | planifest-framework |
| FIFO | A named pipe. Opening one waits for a writer, so the hook never opens a non-regular `design.md`. | named pipe | planifest-framework |
| `lstat` | The call that reads a path's type without following links. It runs before any read of `design.md`. If it throws, the hook fails open. | | planifest-framework |
| Fail open | A hook outcome that allows the write because it hit an error it can't judge. It exits 0 (0000003 ADR-005). | | planifest-framework |
| Always-permitted name | A path the gate never blocks for lack of a design, such as `plan/`, `docs/`, or a file like `claude.md`. Inside an enforcement path it gets no shortcut (US-009). | always-permitted path, permitted name | planifest-framework |
| Enforcement path | A path the framework gates whatever a scope record lists, such as `planifest-framework/hooks/`. Fast Path never admits one (0000033 ADR-009). | enforcement list, gated path | planifest-framework |
| Normal route | How the gate judges a path with no shortcut: through the design scope, or the Fast Path scope verdict. | | planifest-framework |
| Fast Path | The route for a trivial change with no feature brief, execution plan, or ADR. | | planifest-framework |
| Scope record | The file `plan/.fast-path-scope`. It lists the target paths of one Fast Path change. | Fast Path scope record | planifest-framework |
| `path-rules.mjs` | The shared module that holds `evaluateWrite`, `isAlwaysPermitted`, `isEnforcementPath`, and `shown`. `gate-write.mjs`, `ratchet-check.mjs`, and `em-dash-guard.mjs` import it. | | planifest-framework |
| `shown()` | The function in `path-rules.mjs` that escapes quoted text for hook output and caps its length. It must not cut an escape sequence in half (US-011). | | planifest-framework |
| `gate-write` | The PreToolUse hook on **Write** and **Edit**. It blocks writes to `src/` without a confirmed design or a matching scope record. | write gate | planifest-framework |
| `ratchet-check` | The PreToolUse hook that blocks writes removing acceptance-criteria or in-scope lines while a loop is active. | ratchet | planifest-framework |
| `em-dash-guard` | The hook that checks written text for em dashes and prints a message that quotes it. | | planifest-framework |
| `CLAUDE_PROJECT_DIR` | The environment variable that names the project root. `run-tests.sh` clears it before any suite so a suite tests its fixture (US-010). | | planifest-framework |
| Sanctioned script | A fixed framework script that a skill step runs to write files. | | planifest-framework |
| Human on the loop | The person who sets intent at P0, reviews the result after P9, and merges. | | planifest-framework |
| `setup-hook-integration` | The component that owns the setup integration docs and tests. | | setup-hook-integration |

## Concepts without a clear name

- **Forged anchor.** The design says a forged, uncommitted, or missing anchor reads as `interactive`. No agreed term separates a forged anchor from a missing one. This glossary uses "forged anchor" for a line that fails the one-commit rule or the design Confirmation check, until the human on the loop names it.
- **Enforcement folder.** US-009 and its backlog entry say "enforcement folder" and the design says "enforcement list". This glossary treats both as the enforcement path list.
- **Setup-delivered change.** The brief uses the phrase for a change to a file that setup writes. It has no separate definition beyond the setup-delivered file above.
