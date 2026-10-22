---
title: "Domain Glossary - write gate scope and path hardening"
summary: "Definitions of domain terms used within feature 0000035."
status: "active"
version: "0.1.0"
---
# Domain Glossary - write gate scope and path hardening

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md) (updated by any agent that introduces a new domain term)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Version:** 0.33.0

> Terms come from `design.md`, `feature-brief.md`, `discovery.md`, `path-rules.mjs`, and the migrator skill. Concepts without a clear name are listed after the table.

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| Scope record | The file `plan/.fast-path-scope`. It lists the target paths of one Fast Path change. The gate accepts it in place of `design.md`. It also stores the branch and `HEAD` commit it was written at, which bound staleness only. The record is self-authorisation, and each admitted write prints a stderr notice. Fast Path removes it before the commit. | Fast Path scope record | planifest-framework |
| Fast Path | The route for a trivial change with no feature brief, execution plan, or ADR. Since 0000033 ADR 009 it admits changes with no `src/` target and never an enforcement path. | | planifest-framework |
| Enforcement path | A path the framework gates whatever the scope record lists, such as `planifest-framework/hooks/`. `FAST_PATH_ENFORCEMENT_PATHS` lists them, including hook wiring files and `.git/`. Matching is case-insensitive through `norm`. Fast Path never admits one (req-009). | gated path | planifest-framework |
| Always-permitted path | A path the gate never blocks for lack of a design. It is a prefix in `ALWAYS_PERMITTED_PREFIXES` (`plan/`, `docs/`) or a file in `ALWAYS_PERMITTED_FILES`, such as `claude.md`. | always-permitted prefix, always-permitted file | planifest-framework |
| Root marker | A folder whose presence marks a repository root. The markers are `planifest-framework` and `.git`, checked in that order. | `ROOT_MARKERS` | planifest-framework |
| Sanctioned script | A fixed framework script that a skill step runs to write files. Hard Limit 8 allows it, because the agent passes it arguments and never content. The `Sanctioned scripts:` sentence in both boot templates names all seven (req-008). | | planifest-framework |
| Planted marker | A root marker created under an always-permitted name, for example `plan/w/.git`. Moving the folder could turn it into a false root. The gates ignore it (US-006). | planted root, planted `.git` | planifest-framework |
| Root | The repository root that `resolveRoot` returns. All path judgements are relative to it. | repo root | planifest-framework |
| `CLAUDE_PROJECT_DIR` | The environment variable that names the project root. The gates read it when the working directory no longer exists. 0000118 has not checked it live. | | planifest-framework |
| Real target | The path a write lands on after every symbolic link in it resolves. The gates judge this path, not the text of the path given. | real path, resolved path | planifest-framework |
| Dangling link | A symbolic link whose target does not exist. A write through it creates the target, so the gates judge the target. | | planifest-framework |
| Hop limit | The most links the gates follow in one chain. A chain past it blocks with exit 2. The limit is 40, the Linux `MAXSYMLINKS` value. The latency target uses a 10-hop chain. | | planifest-framework |
| Link loop | A chain of links that returns to a link already followed. It blocks with exit 2. | | planifest-framework |
| Fail open | A hook outcome that allows the write because it hit an error it can't judge. It exits 0 (0000003 ADR 005). | | planifest-framework |
| Fail closed | A hook outcome that blocks the write because it can't judge the path. It exits 2 with a reason on stderr. This feature applies it to path resolution errors inside the repo root. | | planifest-framework |
| Fail-closed line | The boundary between errors that fail closed and errors that fail open. Resolution errors for a path inside the root fail closed. All other errors fail open. | | planifest-framework |
| `gate-write` | The PreToolUse hook on **Write** and **Edit**. It blocks writes to `src/` without a confirmed design or a matching scope record. | write gate | planifest-framework |
| Shell-write guard | The PreToolUse hook on Bash. It is a heuristic that blocks shell writers when `gate-write` would block a **Write** to the same path. | `shell-write-guard` | planifest-framework |
| `ratchet-check` | The PreToolUse hook that blocks writes removing acceptance-criteria or in-scope lines while a loop is active. | ratchet | planifest-framework |
| Active loop | A `plan/current/loop-state-*.md` file with `status: active`. | | planifest-framework |
| Migration | A file in `planifest-framework/migrations/` that brings a project in line with a framework change. It never moves after this feature. | | planifest-framework |
| Migration record | The file in `plan/_migrations/` that shows a migration ran in this project. There is one record per migration. | run record | planifest-framework |
| `not applicable` record | A migration record that states the migration does not apply here. It counts as a record. | | planifest-framework |
| Pending migration | A migration with no readable record in `plan/_migrations/`. An unreadable record also counts as pending. | | planifest-framework |
| Downstream-only migration | A migration that applies to projects that consume the framework and not to this repo. Two exist. This repo records them as `not applicable` (req-010). | | planifest-framework |
| Migrator | The `planifest-migrator` skill. It runs one pending migration with the human on the loop and writes the record. | | planifest-framework |
| Scan | The check a migration runs to find what needs changing. A compliant project gets a clean result and a record. | | planifest-framework |
| Resume detection | The orchestrator step that lists pending migrations at session start. | | planifest-framework |
| Close-out | The P7 to P9 sequence that archives the run, writes the report, tags, and ends with a clean working tree. | | planifest-framework |
| `product.yml` update | The ship agent step that sets `version` and `feature` in P7, before Step 6 archives `design.md`. | | planifest-framework |
| Anchor | The recorded run-mode confirmation in the P0 build log, which commit `c7f5a66` re-recorded. Backlog 0000127 covers its format. | run-mode anchor | planifest-framework |
| Three-story rule | The release size limit of three stories when no `release-budget.yml` exists. This run exceeds it by choice. | | planifest-framework |
| Human on the loop | The person who sets intent at P0, reviews the result after P9, and merges. | | planifest-framework |
| Run mode | The value in `plan/.run-mode`. It is `interactive`, `continuous`, or `autonomous`. This run is `autonomous`. | | planifest-framework |
| `setup-hook-integration` | The component that owns the setup integration docs and tests. | | setup-hook-integration |

## Concepts without a clear name

- **Stale scope record.** The design says the gate "ignores" a record once the branch or `HEAD` changes, and "stale" appears in the brief. No agreed term exists for this state. This glossary uses "stale scope record" until the human on the loop names it.
- **Resolution error.** Req-003 and req-004 define it. A link loop, a chain past 40 hops, and an error such as `EACCES`, `EIO`, or `ELOOP` count when the target or the real path reached lies inside the root. Each blocks with exit 2.
- **Migration count.** There are eight migrations, which are the top-level `*.md` files once `_done/` returns. Two helper scripts, `migrate-archive-dirname.sh` and `migrate-archive-dirname.ps1`, belong to `0003-archive-dirname.md` and are not migrations.
- **Anchor.** The build log uses "anchor" for the run-mode confirmation record. Backlog 0000127 notes the format is not settled.
