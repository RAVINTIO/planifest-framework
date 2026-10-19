---
title: "Requirement: req-007 - choice-prompts-name-the-actor"
summary: "Every choice prompt in the phase skills names who acts in each option, in every run mode. The P9 push prompt is the first case."
status: "draft"
version: "0.1.0"
---
# Requirement: req-007 - choice-prompts-name-the-actor

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-009
**Priority:** should-have

## User Story

As the human on the loop, I read choice prompts that name who acts in each option, so that I never have to track a shifting "I".

## Functional Requirements

This is a wording fix. It applies in every run mode and isn't gated on `autonomous`.

### Formatting standards (`planifest-framework/standards/formatting-standards.md`)

- **New `## 5. Choice Prompts` section:** An option that describes an action names who acts, as "Agent ..." or "Human ...". Options never use "I", "me", or "my". The question line names the actor too, such as "Who pushes the branch and raises the PR?"

### Ship skill (`planifest-framework/skills/planifest-ship-agent/SKILL.md`)

- **`### Step 10: Push/PR decision`:** The question line becomes `Who pushes the branch and raises the PR?`. The two options become:
  - `[1] Agent pushes and creates the PR (git push + gh pr create)`
  - `[2] Human pushes and creates the PR: the agent gives the PR title and description`
- The `**Option [1] (Agent pushes):**` and `**Option [2] (Human pushes):**` headings stay, so the 0000025 footer suite still finds them.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`## Context Hygiene`, dynamic compaction prompt:** The question names the agent, such as "Should the agent compact this session's context before continuing?"
- **`### Scope Lock Challenge`, partial-failure fallback:** The suggested-answer offer names the agent, such as "Should the agent suggest an answer first? (agent suggests / human answers)". The line that records the removed default offer keeps its quoted text, because it quotes history.
- **Run-mode prompt:** req-001 rewrites it with options that name the actor. This requirement's suite checks it.

### Sweep

- Check every `SKILL.md` under `planifest-framework/skills/` and every file under `planifest-framework/workflows/` for choice prompts.
- Rewrite any option that uses "I", "me", or "my" for the agent or the human.
- Record the sweep's result in the P3 build log, naming each file changed or "no change".
- The prompts found at P1 are the four above. The sweep confirms there are no others.

### Tests

- Add `planifest-framework/tests/test-0000033-req-007-choice-prompts-name-the-actor.sh`. `run-tests.sh` picks it up.
- `planifest-framework/tests/test-0000032-req-001-marker-clear-before-tag.sh` asserts `[2] I'll do it` in Step 10. Update that assertion to the new option [2] text.
- `planifest-framework/tests/test-0000025-req-001-ship-agent-pr-footer.sh` must pass unchanged.

### Verified by

- `formatting-standards.md` has a `## 5. Choice Prompts` heading, and the section bans "I", "me", and "my" in options.
- Step 10 contains `Who pushes the branch and raises the PR?`, and doesn't contain `Should I push`.
- Step 10's option lines start `[1] Agent` and `[2] Human`, and neither contains "I'll" or "me".
- The orchestrator's compaction prompt doesn't contain `Want me to`.
- The Scope Lock fallback offer doesn't contain `Want me to`, apart from the quoted history line.
- The run-mode prompt's option lines contain no "I" or "me".
- No option line in any `SKILL.md` under `planifest-framework/skills/` matches `^\s*\[[0-9]\].*\b(I|I'll|me|my)\b`.

## Acceptance Criteria

- [ ] The P9 Step 10 prompt names the agent or the human in its question and in each option, in every run mode.
- [ ] The sweep leaves no choice prompt in the phase skills or workflows whose options use "I", "me", or "my", and `formatting-standards.md` states the rule.
- [ ] The new suite, the updated 0000032 req-001 suite, and the 0000025 req-001 suite pass under `run-tests.sh`.

## Dependencies

- req-001 rewrites the run-mode prompt and follows this rule.
- req-005 adds `autonomous` text to Step 10. Both requirements edit Step 10, so they land in the same P3 stream.
