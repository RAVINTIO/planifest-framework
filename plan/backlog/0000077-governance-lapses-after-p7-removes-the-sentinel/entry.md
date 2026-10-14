---
title: "Backlog Entry: 0000077 - Governance lapses after P7 removes the sentinel"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000077 - Governance lapses after P7 removes the sentinel

**Source feature:** reported by the human after the `ovelunor` product's `0000036-nav-popular-categories` run (a downstream consumer of this framework)
**Source phase:** P7 to P9, and the same session after P9
**Deferral source:** process defect
**Date filed:** 2026-10-10

---

## Problem

The `ovelunor` product's 0000036 run went from P0 to P9 under the orchestrator. Planifest then stopped governing the session at P7, not after P9. Two framework gaps let that happen, and two agent errors followed from them.

### 1. The ship skill removes the sentinel before P8 and P9 run

`planifest-framework/skills/planifest-ship-agent/SKILL.md`, P7 Step 6 item 5, deletes `plan/.orchestrator-active` as part of the archive. P8 and P9 still have to run. From that point, nothing marks a run as active.

### 2. The auto-trigger hook's message is false once the skill is loaded

`planifest-framework/hooks/enforcement/auto-trigger-orchestrator.mjs` fires on every prompt while the sentinel is missing. It says "the orchestrator has not been loaded yet for this session." Through P8, P9, and every prompt after them, the skill was loaded, so the message was wrong. The agent learned to ignore it.

The hook should have prompted a triage of each new request. In this session, nothing did.

### 3. Requests after P9 skipped the routing directive

The human asked to "plan go-live release" in the same session. The orchestrator's Routing Directive says to triage every request into a track before acting:

- Fast Path
- Change Pipeline
- Feature Pipeline

The agent skipped triage. It cut `feat/0000037-go-live` and committed two plan changes with no P0, no sentinel, no `discovery.md`, and no build log.

Context Hygiene says to clear context after P9. The agent only advised a fresh session. It then took on new work in the same one.

### 4. A P9 resume note put the next change outside the pipeline

The previous run's P9 wrote `plan/resume.md`, a product-level handover note. It said go-live "isn't a feature pipeline run, so no P0 is needed". It also followed the product runbook in pushing a code change straight to `main`.

That change edits `src/site-deploy/check_access_posture.py`, so it needs at least the Change Pipeline. The agent repeated both claims until the human corrected them. The human's rule is that nothing is ever pushed straight to `main`.

### 5. Enforcement hooks don't see shell writes

`setup.sh` registers `gate-write.mjs` and `ratchet-check.mjs` on the **Write** and **Edit** tools only. In auto mode the agent wrote nearly every file through Bash (heredocs and short Python scripts), which neither hook sees.

During 0000036 this changed nothing, because `design.md` existed. With no design, the gate wouldn't stop a shell write under `src/`.

`gate-write.mjs` also blocked a **Write** to the agent's memory folder, which sits outside the repository. That path isn't project code, so the block was a false positive.

## Suggested Action

1. **Sentinel timing.** In the ship skill, move the sentinel, `.orchestrator-ack`, and `.run-mode` deletions from P7 Step 6 to the end of P9, after the Step 11 confirmation. Update the Step 7 commit and the Step 9b check to match, and the orchestrator's interrupted-P9 detection (Resume Detection step 2a).
2. **Hook message.** Change the auto-trigger message to name the real state, for example: "No Planifest run is active. Triage this request as Fast Path, Change Pipeline, or Feature Pipeline before acting." Keep the instruction to load the skill if it isn't loaded.
3. **Shell writes.** Add a Bash PreToolUse hook that refuses writes under `src/` when no `plan/current/design.md` exists. It should catch redirects, `tee`, `sed -i`, and scripted writes. If that's too broad, state in the generated boot file that `src/` changes go through **Write** or **Edit** only.
4. **gate-write scope.** Limit `gate-write.mjs` to paths inside the repository root.
5. **Handover notes.** Any P9 handover note must route each next step through a track. It must never say a step that changes code needs no P0.
6. **Post-P9 context.** After P9, the orchestrator waits for the human to clear context before it takes on new work. If the host can't clear context itself, the orchestrator asks the human to, and doesn't continue in the same session.

## Why Deferred

Filed from a downstream product's session. The fixes belong in this framework's ship skill, orchestrator skill, hooks, and `setup.sh`.
