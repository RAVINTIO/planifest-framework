---
title: "Requirement: req-007 - stderr-block-reasons"
summary: "Every enforcement hook that blocks writes a plain-text reason to stderr and keeps its stdout unchanged."
status: "draft"
version: "0.1.0"
---
# Requirement: req-007 - stderr-block-reasons

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Source:** US-003
**Priority:** must-have

## User Story

As an agent, I want every enforcement hook that blocks to show its reason, so that I can act on a block without reading the hook's source.

## Functional Requirements

### Block reasons on stderr (AC-7)

These enforcement hooks exit 2 today, and each one changes:

| Hook | Block paths | Current output on block |
|------|-------------|-------------------------|
| `planifest-framework/hooks/enforcement/gate-write.mjs` | no sentinel for `plan/current/**`, no `design.md`, path outside the component paths | plain text on stdout |
| `planifest-framework/hooks/enforcement/ratchet-check.mjs` | weakening with no approval, approval present but marker uncommitted | `permissionDecision: "deny"` JSON on stdout |
| `planifest-framework/hooks/enforcement/em-dash-guard.mjs` | em dash in a scoped path | plain text on stdout |

- On every block path in the table, the hook writes a plain-text reason to stderr before it exits 2 (ADR-005).
- `gate-write.mjs` and `em-dash-guard.mjs` write the same reason text to stderr that they write to stdout.
- `ratchet-check.mjs` writes its `reason` string to stderr as plain text, not JSON.
- Each hook keeps its stdout output unchanged, byte for byte. The Windsurf, Copilot, and Codex adapters read the reason from stdout, and they keep working with no change.
- `check-orchestrator-presence.mjs`, `check-design.mjs`, and `auto-trigger-orchestrator.mjs` never exit 2, so AC-7 doesn't change them. The adapters under `hooks/adapters/` relay a hook's exit 2 and aren't enforcement hooks, so AC-7 doesn't change them either.
- The new shell-write guard from req-008 also exits 2. Req-008 holds it to the same stderr rule.

### Latency (NFR)

- Each changed hook finishes in under 200 ms per call on the CI runners.

### Tests

- A new Bash suite, `planifest-framework/tests/test-0000032-req-007-stderr-block-reasons.sh`, runs each hook with JSON on stdin and checks the exit code, stdout, and stderr. `run-tests.sh` finds it by its `test-*.sh` name.
- The suite builds its fixtures under `mktemp -d` and runs `git init` inside them, so the walk-up from req-006 finds the fixture root.
- The existing suites for `gate-write.mjs`, `ratchet-check.mjs`, and `em-dash-guard.mjs` still pass. That includes `test-gate-write-windows.sh` and `test-0000028-req-006-em-dash-guard.sh`.

### Verified by

- Each of the three `gate-write.mjs` block paths exits 2 with a non-empty stderr. Its stdout matches the text from before this feature.
- Each of the two `ratchet-check.mjs` block paths exits 2 with a non-empty, non-JSON stderr. Its stdout still parses as JSON with `permissionDecision` set to `deny`.
- The `em-dash-guard.mjs` block path exits 2 with a non-empty stderr. Its stdout matches the text from before this feature.
- Driven through `hooks/adapters/windsurf.mjs` with a `pre_write_code` event, a gated path exits 2 and the adapter's stdout holds the block reason.
- Each changed hook completes in under 200 ms per call, timed in the suite.

## Acceptance Criteria

- [ ] Every block path in `gate-write.mjs`, `ratchet-check.mjs`, and `em-dash-guard.mjs` exits 2 with a non-empty, plain-text stderr. Tests assert this for each block path.
- [ ] Each hook's stdout stays as it was, so `ratchet-check.mjs` still emits its deny JSON and the Windsurf adapter still relays the reason.
- [ ] Each changed hook completes in under 200 ms per call, timed in the suite.

## Dependencies

- Req-006: `gate-write.mjs` runs on `path-rules.mjs` and the repository root rule.
- ADR-005 records the stderr rule and the byte-for-byte stdout rule.
- The 0000031 CI jobs run the new suite on Linux and Windows.
