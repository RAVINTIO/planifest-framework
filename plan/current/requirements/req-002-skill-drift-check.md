---
title: "Requirement: req-002 - skill-drift-check"
summary: "A Node script compares each source SKILL.md with the active tool's installed copy, and the orchestrator runs it at session start."
status: "draft"
version: "0.1.0"
---
# Requirement: req-002 - skill-drift-check

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Source:** US-002 (backlog 0000154)
**Priority:** must-have

## User Story

As the human on the loop, I see which installed skills differ from source when a session starts, so that no phase runs on a stale skill copy.

## Functional Requirements

### FR-002.1 The script

- The script sits at `planifest-framework/scripts/skill-drift-check.mjs`. It uses Node built-ins only and starts no process.
- It reads files and never writes, moves, or deletes one.
- The project root defaults to the folder that holds `planifest-framework/`, found from the script's own path. A `--root <dir>` argument overrides it, so suites can point it at a fixture.
- It finishes in under 1 s on this repo (NFR-002). A timed case in FR-002.6 checks this against a full fixture install of every source skill.

### FR-002.2 Finding the active tool

- The script holds a map from tool name to skills folder. The map matches `TOOL_SKILLS_DIR` in each `planifest-framework/setup/{tool}.sh`:

  | Tool | Skills folder | Marker |
  |------|---------------|--------|
  | `claude-code` | `.claude/skills` | `.claude/.planifest-setup-flags` |
  | `cursor` | `.cursor/skills` | `.cursor/.planifest-setup-flags` |
  | `codex` | `.agents/skills` | `.agents/.planifest-setup-flags` |
  | `antigravity` | `.gemini/skills` | `.gemini/.planifest-setup-flags` |
  | `copilot` | `.github/skills` | `.github/.planifest-setup-flags` |
  | `windsurf` | `.windsurf/skills` | `.windsurf/.planifest-setup-flags` |
  | `cline` | `.clinerules/skills` | `.clinerules/.planifest-setup-flags` |
  | `opencode` | none | `.opencode/.planifest-setup-flags` |

- Setup writes each marker as JSON next to the tool's skills folder. A marker is valid when it parses and its `tool` value is a key in the map.
- The active tools are those with a valid marker. If two or more markers are valid, the script checks each of those tools.
- If no marker is valid, the active tool is unknown. The script then checks every skills folder from the map that exists.
- `opencode` installs no skills. If it is the only active tool, the script reports that the tool installs no skills and exits 0.

### FR-002.3 Comparing copies

- The source skills are the folders in `planifest-framework/skills/` that hold a `SKILL.md`.
- For each active tool and each source skill, the script compares `{skills folder}/{skill}/SKILL.md` with the source `SKILL.md`.
- Setup doesn't copy `SKILL.md` byte for byte. It rewrites four relative paths. Before it compares, the script applies the same rewrites to the source text, in `setup.sh` order:
  1. `../templates/` becomes `./assets/templates/`
  2. `../standards/` becomes `./references/`
  3. `../standards/reference/` becomes `./references/reference/`
  4. `../schemas/` becomes `./assets/schemas/`
- The script strips one leading UTF-8 byte order mark (`ef bb bf`) from the source text and one from the installed copy. It strips each one independently, and only when present.
  - The source `planifest-orchestrator/SKILL.md` starts with a byte order mark. `setup.sh` copies it with `cp`, so the installed copy keeps it. Backlog 0000170 covers that defect.
  - `setup.ps1` on Windows PowerShell 5 writes a byte order mark into the installed copy, whether or not the source holds one.
  - The script strips one mark only. A second mark is content, so a difference there is drift.
- After those two steps, the copy matches when its bytes equal the rewritten source bytes. Any other difference is drift.
- The script compares `SKILL.md` only. It ignores `assets/`, `references/`, `scripts/`, and every other file that setup adds beside it.
- It ignores an installed skill folder with no source skill, such as an external skill or a capability skill. It also ignores `.planifest-manifest`.

### FR-002.4 Outcomes and output

| Case | Exit | Output |
|------|------|--------|
| Every installed copy matches | 0 | one line on stdout naming each tool checked and the skill count |
| A copy differs from source | 1 | `stale: {tool}: {skill}` on stderr for each one |
| A source skill has no installed `SKILL.md` | 1 | `missing: {tool}: {skill}` on stderr for each one |
| No active tool has a skills folder, or the fallback finds none | 1 | `not installed` on stderr, with a recommendation to run `setup.sh` or `setup.ps1` |
| The script can't compare | 2 | the reason on stderr |

- On exit 1 with stale or missing copies, the last stderr line recommends `planifest-refresh-setup`.
- The script can't compare when `planifest-framework/skills/` is missing or unreadable. It also can't compare when a read fails with any error other than "no such file".
- The script checks each installed `SKILL.md`, each marker, and each skills folder with `lstat` before it reads (P5 S-3, S-4). It never follows a link and never opens a FIFO, a device, or any other non-regular file. It reads at most 1 MiB from any file.
  - Setup copies and never links. So a link at an installed copy, its skill folder, or the tool's skills folder makes that copy stale.
  - A FIFO, a device, or any other non-regular file at an installed copy is stale. So is a copy over 1 MiB.
  - A marker that is a link, a non-regular file, or over 1 MiB isn't valid.
  - The source side follows the same rules. A linked source skill folder, or a source `SKILL.md` that is a link, a non-regular file, or over 1 MiB, can't compare. The script exits 2.
- Each skill name and path in the output passes through the same escaping as hook output, so a crafted folder name can't forge a line.

### FR-002.5 Orchestrator resume detection

- `planifest-framework/skills/planifest-orchestrator/SKILL.md` Resume Detection gains a step after step 1a. The step runs `node planifest-framework/scripts/skill-drift-check.mjs` at session start.
- On exit 0, the step reports nothing and the session goes on.
- On exit 1 with stale or missing copies, the orchestrator:
  1. names each stale or missing skill to the human on the loop
  2. loads the source copy from `planifest-framework/skills/{skill}/SKILL.md` in place of the installed copy for the rest of the session
  3. recommends a `planifest-refresh-setup` run
- If step 1a found a framework update that the human on the loop rejected or hasn't confirmed, the orchestrator loads no source copy. It only reports the drift (P5 S-5). An unconfirmed update is untrusted, so its source skills never replace the installed ones.
- On `not installed`, the orchestrator recommends a run of `setup.sh` or `setup.ps1`.
- On exit 2, the orchestrator reports that the check couldn't compare, with its reason, and goes on.
- The check warns and never blocks. The orchestrator never runs setup itself.
- After any setup run in the same session, the orchestrator runs the check again. Such a run comes from `planifest-refresh-setup` or a migration such as `migrate-0.34.0-rerun-setup.md`.

### FR-002.6 Tests

A new suite `planifest-framework/tests/test-0000036-req-002-skill-drift-check.sh` builds fixtures in a temporary folder and runs the script with `--root`. It covers:

- a match, where the installed copy carries the rewritten paths, a BOM, and extra `assets/` and `references/` files: exit 0
- a match, where the source `SKILL.md` starts with a BOM and the installed copy keeps it, as `setup.sh` leaves it: exit 0
- a match, where the source `SKILL.md` starts with a BOM and the installed copy has none: exit 0
- a match built from this repo's real `planifest-orchestrator/SKILL.md`, which holds a BOM. The suite copies it with `cp` and applies the `setup.sh` `sed` rewrites: exit 0
- a timed case for NFR-002, built as a full fixture install:
  1. The suite copies every source skill's `SKILL.md` from `planifest-framework/skills/` into `{fixture}/.claude/skills/{skill}/SKILL.md`.
  2. It applies setup's four path rewrites to each copy with the `setup.sh` `sed` expressions.
  3. It writes a valid `claude-code` marker at `{fixture}/.claude/.planifest-setup-flags`.
  4. It copies `planifest-framework/skills/` into the fixture as the source.
  5. It runs the script with `--root {fixture}` and asserts exit 0 and a run time under 1 s.

  The fixture holds every source skill, 21 today, so the timed case measures a full comparison on CI. `.claude/` is git-ignored, so a run against this repo on CI would compare nothing.
- a run against this repo with no `--root`: exit 0 or 1, never 2. A fresh clone has no install and exits 1 with `not installed`. This case checks only the default root, and it isn't the NFR-002 measurement. Step 3 of req-001 FR-001.5 checks for exit 0 after setup runs in this repo
- a stale copy: exit 1, and stderr names the skill
- a missing copy: exit 1, and stderr names the skill
- no installed copies: exit 1 with `not installed`
- no valid marker: the script checks every skills folder it finds
- a missing source skills folder: exit 2
- a rewrite-list check: the suite reads the four path rewrites from the `sed` expressions in `setup.sh` `copy_skills()` and from the `-replace` calls in `setup.ps1` `Copy-PlanifestSkills`. It compares the from-and-to pairs as a set and asserts that the script's set matches each script's set (R-012). The two scripts apply the two `standards` rewrites in opposite orders, so an ordered compare can't match both.
- the tool map: each entry matches `TOOL_SKILLS_DIR` in its `setup/{tool}.sh`
- the orchestrator Resume Detection text names the script and `planifest-refresh-setup`
- the Resume Detection text holds the sentence that loads no source copy after a rejected or unconfirmed framework update
- unsafe files, each run under a 5-second limit:
  - a FIFO at an installed `SKILL.md`: exit 1, stale
  - a FIFO marker: the marker isn't valid, and the fallback check exits 0
  - an installed `SKILL.md` linked to `/dev/zero`: exit 1, stale
  - an installed copy, a skill folder, or a skills folder linked out of `--root`, with matching text: exit 1, stale
  - a linked source skill folder, or a FIFO source `SKILL.md`: exit 2
  - an installed copy over 1 MiB: exit 1, stale
  - a source `SKILL.md` over 1 MiB: exit 2
  - a `SKILL.md` of exactly 1 MiB on both sides: exit 0

## Acceptance Criteria

- [ ] AC-002.1: `skill-drift-check.mjs` compares each source `SKILL.md`, after setup's path rewrites, with the active tool's installed copy. It lists each stale or missing copy on stderr and exits 1, exits 0 when all match, and exits 2 when it can't compare. It ignores the folders that setup adds.
- [ ] AC-002.2: Orchestrator Resume Detection runs the script at session start and again after any setup run. On drift it names the stale skills, loads their source copies, and recommends `planifest-refresh-setup`. It never blocks and never runs setup itself.
- [ ] AC-002.3: `test-0000036-req-002-skill-drift-check.sh` passes, covering a match, a stale copy, a missing copy, no installed copies, an unknown tool, and the exit-2 case.

## Dependencies

- `planifest-framework/setup.sh` `copy_skills()` and `setup.ps1` `Copy-PlanifestSkills` define the copy and the path rewrites. This requirement doesn't change them.
- `planifest-framework/setup/{tool}.sh` define each tool's skills folder.
- Req-011 changes `shown()` in `path-rules.mjs`. If the script reuses `shown()`, it imports it from there. Otherwise it applies the same escaping rule.
- [Req-001](req-001-rerun-setup-migration.md) runs this script in its Migrator Instructions.
- Stream-03 edits other parts of `planifest-orchestrator/SKILL.md`. This requirement edits only Resume Detection.
