---
title: "Domain Glossary - Governance continuity and write-gate scope"
summary: "Definitions of domain terms used within this feature."
status: "active"
version: "0.1.0"
---
# Domain Glossary - Governance continuity and write-gate scope

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Version:** 0.31.0

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| Sentinel | The `plan/.orchestrator-active` file. The orchestrator writes it at P0, and its presence marks a Planifest run as active. It holds the feature ID. From this feature on, the ship skill deletes it after P8 and before the Step 9 tag. | `.orchestrator-active`, orchestrator sentinel | planifest-framework |
| Markers | The three committed run files: the sentinel, `plan/.orchestrator-ack`, and `plan/.run-mode`. The orchestrator writes them, the ship skill deletes them, and hooks read them only. | session markers | planifest-framework |
| `.orchestrator-ack` | The strict-mode marker. When `plan/.orchestrator-strict` exists, the orchestrator writes the session ID or a UTC timestamp here at P0. This silences the strict-mode banner for the session. | ack | planifest-framework |
| `.run-mode` | The marker that holds the confirmed run mode, `continuous` or `interactive`. Resume reads it so the orchestrator doesn't ask again. | run mode | planifest-framework |
| Active run | The period from the sentinel's creation at P0 to its deletion before the Step 9 tag. | run in progress | planifest-framework |
| Track | One of the three routes a request can take: Fast Path, Change Pipeline, or Feature Pipeline. | route, pipeline | planifest-framework |
| Fast Path | The track for a trivial fix that meets every Fast Path criterion. It needs no Feature Brief, Execution Plan, or ADR. | none | planifest-framework |
| Change Pipeline | The track for a targeted change to one or two existing components. The change-agent runs it. | `PC:` | planifest-framework |
| Feature Pipeline | The full P0 to P9 track for new features, new problem statements, or wider changes. | full pipeline | planifest-framework |
| Triage | Choosing a track for a request by the orchestrator's routing heuristics, before any work starts. | routing | planifest-framework |
| Resume Detection | The orchestrator skill section that decides where an interrupted run restarts. Step 2a resumes from archive evidence when the sentinel exists but `plan/current/` is empty. Step 2b finishes a P9 marker step whose marker deletion was never committed. | resume | planifest-framework |
| Context Hygiene | The orchestrator skill section that asks for `/clear` or a new session so a new run starts with no residual context. | context reset | planifest-framework |
| Handover note | The P9 note that tells the human on the loop what to do next. From this feature on, each next step in it routes through a track. | handoff note | planifest-framework |
| Repository root | The nearest folder that holds `planifest-framework/`, then the nearest that holds `.git`, or `cwd` when none does. The walk starts at `CLAUDE_PROJECT_DIR` when it names a folder and finds a marker, and at `cwd` otherwise. A marker inside `plan/` or `docs/` never counts. Paths outside the root are never gated. | repo root | planifest-framework |
| Always-permitted path | A path that `gate-write.mjs` never blocks, such as `plan/`, `docs/`, `CLAUDE.md`, and `AGENTS.md`. The shared path-rules module holds the full list. | permitted path | planifest-framework |
| Gated path | Any path inside the repository root that isn't an always-permitted path. With no `design.md`, every write to one is blocked. With a design, only writes outside a component path are blocked. | protected path | planifest-framework |
| Component path | A path prefix listed under `## Component Paths` in `plan/current/design.md`. A gated path under one passes once a design exists. | declared path | planifest-framework |
| Shell-write guard | The new Bash PreToolUse hook. It blocks AC-8 writer forms aimed at gated paths, using the same path rules as `gate-write.mjs`. | Bash hook, shell guard | planifest-framework |
| Folder set | The folders a command in a shell line may run in, as the shell guard tracks them through `cd`, `pushd`, and `popd`. The guard judges a relative target against every folder in the set. After a certain `cd dir &&`, the set holds `dir` alone. | tracked base, cd base | planifest-framework |
| P9 marker step | The ship skill step, headed "Clear session markers", that deletes and commits the markers after P8 and before the Step 9 tag. | P9 marker deletion | planifest-framework |
| Path-rules module | `planifest-framework/hooks/enforcement/path-rules.mjs`. It holds the root rule and the always-permitted list, and both write gates import it. | shared path rules | planifest-framework |
| Detection corpus | The AC-8 writer commands in the req-008 suite that the guard must block. | none | planifest-framework |
| False-positive corpus | The read-only commands in the req-009 suite that the guard must pass. | none | planifest-framework |
| Writer | A shell form that writes a file: a redirect, `tee`, an in-place edit, or a file command such as `cp` or `rm`. | writer form | planifest-framework |
| Unjudgeable path | A target over 4096 characters or 256 segments. Both write gates warn and pass it rather than walk the file system. | long path | planifest-framework |
| Block reason | The plain-text message an enforcement hook writes to stderr when it exits 2. It tells the agent why the hook blocked and what to do. | block message | planifest-framework |
| Fail open | A hook exits 0 on any unexpected error, so a hook fault never blocks the session. | none | planifest-framework |
| Human on the loop | The person who confirms gates, reviews and merges pull requests, and answers escalations. | none (never "user" or "developer") | all |

## Flagged concepts without a clear name

None. P3 named all four concepts that P1 flagged. See path-rules module, detection corpus, false-positive corpus, P9 marker step, and writer.
