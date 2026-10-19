---
title: "Scope - Governance continuity and write-gate scope"
summary: "Defines explicit boundaries of what is in scope and out of scope."
status: "active"
version: "0.1.0"
---
# Scope - Governance continuity and write-gate scope

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Version:** 0.31.0

## In Scope

- Ship skill marker timing. The ship skill deletes `.orchestrator-active`, `.orchestrator-ack`, and `.run-mode` after P8 and before the Step 9 tag, and commits the deletions. The P7 Step 7 commit and the Step 9b check no longer refer to the markers (AC-1).
- Orchestrator Resume Detection step 2a. It reads the feature ID from the sentinel and picks the latest matching archive. It resumes at P8 or at the P9 marker deletion, based on `build-report.md`. It stops and asks when no archive matches (AC-2).
- The `auto-trigger-orchestrator.mjs` message. It says no Planifest run is active and tells the agent to triage the request first. It keeps the instruction to load the skill (AC-3).
- A ship skill rule that routes each next step in a P9 handover note through a track (AC-4).
- A blocking ship Step 12 that asks the human on the loop to run `/clear` or start a new session. The orchestrator refuses new work in the same session, and its Context Hygiene section matches (AC-5).
- `gate-write.mjs` passes any target outside the repository root, with or without `design.md` (AC-6).
- A plain-text stderr block reason in every enforcement hook that exits 2. Existing stdout output stays (AC-7).
- A new Bash PreToolUse shell-write guard that blocks AC-8 writer forms aimed at gated paths. It fails open with a stderr warning when it can't parse a command (AC-8).
- One path-rules module shared by the shell-write guard and `gate-write.mjs` (AC-9).
- Idempotent Claude Code registration of the shell-write guard in `setup.sh` and `setup.ps1`, with setup tests (AC-10).
- A 0.31.0 migration in `planifest-framework/migrations/` that tells downstream projects to re-run setup (AC-11).
- A boot-file statement that code changes go through **Write** or **Edit**.
- Two ADRs superseding 0000015 ADR-001 (interrupted-run signal) and ADR-002 (advisory post-P9 message).
- Tests for each change, run by `run-tests.sh` and the 0000031 CI jobs. These include the NFR latency, fail-open, false-positive, and detection checks.

## Out of Scope

- Registering the shell-write guard for tools other than Claude Code. Cursor, Windsurf, and the other adapters keep their current hook wiring.
- Extending `ratchet-check.mjs` to shell writes. It stays on **Write** and **Edit**.
- Shell writes made by git commands, scripts, or variables the guard can't parse. These are documented limits, covered by the boot-file rule.
- Fast Path writes through `gate-write` (backlog 0000081).
- Downstream product runbooks that push to `main`. Those belong to each downstream project.
- Gitignored session markers. The markers stay committed (0000023 req-002).

## Deferred

- Nothing deferred.
