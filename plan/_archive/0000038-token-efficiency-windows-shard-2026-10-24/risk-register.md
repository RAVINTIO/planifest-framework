---
title: "Risk Register - token efficiency and Windows shard fix"
summary: "Risks for feature 0000038 with likelihood, impact, and mitigation."
status: "active"
version: "0.1.0"
---
# Risk Register - token efficiency and Windows shard fix

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Version:** 0.36.0
**Overall Risk Level:** medium

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | Moving Phase 0 and Adoption Modes out of `SKILL.md` breaks test greps on the moved text (req-004) | high | medium | P3 moves each assertion with its text and runs the full suite. A new absence test stops a grep passing on the wrong file | open |
| R-002 | technical | Quiet mode hides a failed suite (req-003) | low | high | A test feeds a failing suite and a crashing suite through quiet mode and checks the `FAIL` line, the failed-suite list, the totals, and the non-zero exit | open |
| R-003 | operational | Seven stories overrun one session | medium | medium | req-005 reset prompts and `pause.md`. Work in the pairs set in the execution plan build order | open |
| R-004 | technical | The warm-up hides cold-start cost that real sessions pay (req-001) | medium | low | The hook still runs as a fresh Node process on every timed call. Only disk caches warm | open |
| R-005 | operational | A subagent can't be proved to run on its tier inside the run (req-002) | medium | medium | P4 dispatches one `haiku` subagent and checks the model it reports. The one-week re-run confirms the cost shift | open |
| R-006 | technical | The orchestrator edits for req-004 and req-005 collide in `SKILL.md` | medium | medium | Build them in sequence. Commit the move first | open |
| R-007 | technical | Existing installs keep old skills and boot text until `setup.sh` or `setup.ps1` re-runs | high | low | The re-run-setup migration, which the orchestrator runs at the next session start | open |
| R-008 | technical | The req-009 best-of-three loop removal makes the check stricter and exposes a hook that is slow when warm | low | medium | P4 measures warm calls. If one passes 200 ms, speed up the hook and keep the limit | open |
| R-009 | operational | The size floor in req-006 reduces decomposition so far that a long unit grows main-thread context | low | medium | The floor keeps subagents for units that need their own reads or many tool calls. The one-week re-run checks cost per request | open |
| R-010 | compliance | A change weakens a quality gate by accident | low | high | NFR-004. The P4 diff review checks that no gate, critic, review, or assertion text is removed. The design critic reviews the specs | open |

## Assumptions Logged as Risks

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | The Claude Code Agent tool honours `model: "sonnet"` and `model: "haiku"` | req-002 saves nothing | open |
| A-002 | The PR #64 failure came from a cold call (1 sample of 1) | The check stays red and the hook needs a speed fix | open |
| A-003 | The 0000230 profile is accurate and can't be re-read here | The savings estimate moves | open |
| A-004 | Primary maps to `sonnet` and cheaper maps to `haiku` in the Claude Code column | A task type needs a different tier and the design changes | open |
