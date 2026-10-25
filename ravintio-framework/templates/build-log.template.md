---
title: "Build Log - {{feature-id}}"
summary: "Working log file maintained by the orchestrator throughout the pipeline run."
---
# Build Log - {{feature-id}}

> Created at P0. Appended by the orchestrator at each phase boundary. Survives session changes.

## Header

| Field | Value |
|-------|-------|
| Feature ID | `{{feature-id}}` |
| Pipeline start | `{{start-timestamp}}` |
| Tool | `{{tool-name}}` |
| Primary model | `{{primary-model-name}}` |
| Cheaper model | `{{cheaper-model-name}}` |
| Run mode | `interactive` / `continuous` / `autonomous` (P0 writes it at the pick and updates it if the mode changes. Later readers call `node ravintio-framework/scripts/run-mode.mjs` to read the mode.) |
| Parallel streams | `on` / `off` (`{{source}}`, for example `on (run-mode default)`) |

---

## Phase Log

### P0: Assess & Coach

| Field | Value |
|-------|-------|
| Start | `{{timestamp}}` |
| End | `{{timestamp when the phase gate passes}}` |
| Wall-clock | `{{whole minutes from Start to End}}` |
| Streams | `{{count of active streams or "n/a"}}` |
| Model tier | primary / cheaper |
| Skills loaded | ravintio-orchestrator |
| Agents spawned | `{{count}}` |
| MCP calls | `{{count}}` |
| Parallel task batches | `{{count}}` |
| P0 questions asked | `{{count}}` |
| Brief complete | `{{yes or no}}` |
| Stack unchanged | `{{yes or no}}` |
| Notes | `{{free text or "none"}}` |

Run-mode anchor, `autonomous` only. Only the orchestrator writes the anchor line, in the commit that confirms the design. It writes the real line itself, bare at column 1, with the real UTC timestamp in place of the placeholder: `Run mode confirmed: autonomous ({ISO-8601 timestamp})`.

`run-mode.mjs` counts only a whole line with a real timestamp, such as `2026-10-23T09:30:00Z`. This template holds no such line, so a copied build log holds no anchor until the orchestrator writes one.

---

<!-- Copy and fill in this block at each phase boundary:

### Px: {Phase Name}

| Field | Value |
|-------|-------|
| Start | `{{timestamp}}` |
| End | `{{timestamp when the phase gate passes}}` |
| Wall-clock | `{{whole minutes from Start to End}}` |
| Streams | `{{count of active streams or "n/a"}}` |
| Model tier | primary / cheaper |
| Skills loaded | `{{skill names}}` |
| Agents spawned | `{{count of subagents dispatched in the phase, across all streams}}` |
| MCP calls | `{{count}}` |
| Parallel task batches | `{{count}}` |
| Notes | `{{free text or "none"}}` |

Progress line, every run mode, one per phase at its gate:
Progress: P{N} {done | blocked} at {End}: {one-line summary}

Touchpoint line, `autonomous` only, one per touchpoint after the P0 confirmation turn:
Human touchpoint (P{N}): {what the run asked or waited for} [{exception: item | outside list}]

-->

---

## Summary (filled at P7)

| Metric | Value |
|--------|-------|
| Total phases completed | `{{count}}` |
| Total agents spawned | `{{count}}` |
| Total MCP calls | `{{count}}` |
| Phases using parallelism | `{{count}}` |
| Phases using streams | `{{count}}` |
| Total wall-clock | `{{whole minutes from the P0 Start to the P7 End}}` |
| Primary tier agent calls | `{{count}}` |
| Cheaper tier agent calls | `{{count}}` |
| Self-corrections | `{{count}}` |
| Phases skipped | `{{list or "none"}}` |
