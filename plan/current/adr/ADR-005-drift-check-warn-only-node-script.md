---
title: "ADR 005: Drift check is a warn-only Node script"
summary: "A new scripts/skill-drift-check.mjs compares each source SKILL.md with the active tool's installed copy. It reproduces setup's four path rewrites and strips one leading byte order mark from both copies. It exits 0, 1, or 2, never blocks, and never runs setup. The orchestrator runs it at Resume Detection and again after any setup run in the session."
status: "accepted"
version: "0.1.0"
---
# ADR-005 - Drift check is a warn-only Node script

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

Setup copies each source `SKILL.md` into a tool folder such as `.claude/skills/`. A framework update changes the source, but the installed copy stays old until someone re-runs setup. An agent then runs a phase on a stale skill (backlog 0000154).

Setup doesn't copy `SKILL.md` byte for byte. `copy_skills()` in `setup.sh` rewrites four relative paths with `sed`. `setup.ps1` does the same, and Windows PowerShell 5 adds a byte order mark. The source orchestrator skill also starts with a byte order mark, which `cp` keeps (backlog 0000170). P1 corrected the P0 assumption of a byte copy (R-012, A-001).

0000006 ADR 003 keeps dispatch and behaviour in skill text. Scripts verify and report. 0000035 ADR 001 keeps framework scripts on Node built-ins with no child process.

The check needs these properties:

- It runs at every session start, so it must be fast and must not fail the session.
- It must work for every tool, not only tools with hook support.
- It must not report false drift on a correct install.

## Decision

1. A new script at `planifest-framework/scripts/skill-drift-check.mjs` compares `SKILL.md` text only. It uses Node built-ins, reads files, and never writes.
2. Before it compares, the script applies setup's four path rewrites to the source text, in `setup.sh` order. It then strips one leading UTF-8 byte order mark from the source and one from the installed copy, each only when present.
3. The script finds the active tool from each tool's `.planifest-setup-flags` marker. If no marker is valid, it checks every installed skills folder it finds.
4. The exit codes are fixed:
   - `0`: every installed copy matches.
   - `1`: a copy is stale or missing, or nothing is installed. Each finding goes to stderr.
   - `2`: the script can't compare, for example when the source skills folder is missing.
5. The check warns and never blocks. It never runs setup, and no agent runs setup because of it without the human on the loop.
6. The orchestrator runs the script in Resume Detection, after step 1a. On drift it names each skill, loads the source copy for the rest of the session, and recommends `planifest-refresh-setup`.
7. After any setup run in the same session, the orchestrator runs the script again. A `planifest-refresh-setup` run or a re-run-setup migration counts.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| A `SessionStart` or `UserPromptSubmit` hook | Runs without the orchestrator's help | Only some tools run hooks. Cursor, Cline, and others would get no check. A hook that fails can disrupt the session. | 0000006 ADR 003 keeps behaviour in skill text so every tool gets it. The orchestrator runs on every tool. |
| A plain byte compare | Shortest code | Every installed copy differs from source by setup's path rewrites. The check would flag every skill on a correct install. | False drift on every run makes the warning useless (R-012). |
| A manifest of hashes that setup writes at install time | Fast, and exact for what setup wrote | It changes what setup writes, which scope rules out. It proves only that the install is unchanged since setup ran. It can't see a newer source. | The question is whether the copy matches the current source. Only a compare against source answers it. |
| Setup re-runs itself when it finds drift | Fixes drift with no human step | Setup rewrites settings files and the boot file. An agent would change tool wiring without the human on the loop (R-014). | A warning plus a recommendation keeps the human on the loop in control of setup. |
| Compare every file in the skill folder | Catches stale `assets/` and `references/` | Setup adds bundled templates and standards there, and their selection depends on manifest fallbacks. The compare would need to reproduce all of `copy_skills()`. | `SKILL.md` is the file an agent loads. Req-001 covers the other files through a re-run-setup migration. |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Gains `scripts/skill-drift-check.mjs`, a new suite, and a Resume Detection step in the orchestrator skill. Setup scripts don't change. |

## Consequences

**Positive:**
- Every tool gets the check, because the orchestrator runs it from skill text.
- A correct install reports no drift, whether setup ran from `setup.sh` or `setup.ps1`.
- A stale skill no longer drives a phase. The orchestrator loads the source copy instead.
- The human on the loop keeps control of every setup run.

**Negative:**
- The script holds a second copy of setup's rewrite list. If setup gains a fifth rewrite and the script doesn't, every skill that holds that path reports false drift until someone fixes the script.
- The check can't detect a stale `assets/`, `references/`, or `scripts/` file. A skill can pass the check and still bundle an old template.
- A tool that doesn't run the orchestrator at session start gets no warning.

**Risks:**
- The rewrite list drifts from setup. The req-002 suite asserts that the script's list matches the `sed` expressions in `setup.sh` (R-012).
- An agent ignores the warning and loads the installed copy anyway (R-014). The Resume Detection text names the source path to load.
- The skill count grows and the check passes 1 s (R-015). The suite times a full fixture install.

## Related ADRs

- ADR-006 - related-to: a re-run-setup migration fixes the drift that this check reports.
- 0000006 ADR 003 - depends-on: behaviour stays in skill text, and scripts verify.
- 0000035 ADR 001 - depends-on: Node built-ins only, with no child process.

## Supersedes

- None

## Superseded By

- None
