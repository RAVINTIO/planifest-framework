---
title: "Risk Register - Human-on-the-loop run mode"
summary: "Technical, operational, and security risks with their mitigations."
status: "active"
version: "0.1.0"
---
# Risk Register - Human-on-the-loop run mode

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Version:** 0.32.0
**Overall Risk Level:** high

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | The orchestrator skill grows further, at 9,276 words already. New `autonomous` text makes it harder for a fresh session to read and follow. | high | medium | Put new detail in standards files and link to them. 0000020 decomposes the skill in the next run. | open |
| R-002 | technical | Parallel streams break the order the gates rely on. A later phase starts on a requirement before an earlier gate clears it. | medium | high | Streams join at every review gate. The orchestrator owns each join (req-017). Each stream keeps its own state file. | open |
| R-003 | technical | A change to `autonomous` text regresses `interactive` or `continuous` behaviour. | medium | high | Every existing suite must pass unchanged. New tests cover each of the three modes. | open |
| R-004 | operational | This run holds 10 stories, against today's three-story rule. The run overruns its context or its time. | medium | medium | Four parallel streams. P4 runs the full suite. The P8 report records subagent count and wall-clock time (req-018). | open |
| R-005 | security | An `autonomous` run skips a human-only item. Examples are a schema change, a destructive operation, or a merge. | low | high | Tests over skill text and the run-mode contract assert each exception-list item. Merging stays human-only in every mode. Hard limits 2 and 3 apply in every mode. | open |
| R-006 | technical | A fresh-context checker approves a defect, because it shares the writer's blind spots or reads a thin summary. | medium | high | The checker is REJECT-default under 0000016-ADR-006. The human reviews the final report and the PR before merging. | open |
| R-007 | technical | Parallel streams race on shared files. The orchestrator skill, `build-log.md`, and `plan/.run-mode` are the likely cases. | medium | medium | Streams write only their own state file. The orchestrator owns the build log and every shared artifact. Reconciliation runs after each join. | open |
| R-008 | operational | An older framework version reads `autonomous` in `plan/.run-mode` as `interactive`. A run resumed across versions changes mode without warning. | medium | medium | The back-compat read is by design. The 0.32.0 note tells downstream products to refresh the framework before they choose `autonomous`. | open |
| R-009 | operational | A downstream override, such as `autonomous-after-p0.md`, conflicts with the new `autonomous` text. A fresh session resolves the conflict the wrong way. | medium | medium | The first-run path states that an override wins. An override never counts as choosing `autonomous`. The release note names the retirable overrides. | open |
| R-010 | technical | Test suites assert the old skill text. Rewording a skill breaks an unrelated suite. | high | low | Search the suites for each changed phrase before editing. Update only the assertions the new text changes, and record each in the build log. | open |
| R-011 | technical | The new `archive-current.mjs` moves the wrong file, or a resumed run repeats a finished step and loses work. | low | high | Each step is a separate command with an explicit path. The script prints what it moved. TDD tests cover a resume after each step. | open |
| R-012 | operational | The first `autonomous` run has no loop-state history. A gate loops through 3 approaches and then ends in an exception without progress. | medium | low | Attempt counts persist in loop state files. The P8 report shows how often a gate reaches the fourth approach. | open |

## Assumptions Logged as Risks

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | A fresh-context checker can stand in for the human at a phase gate. Likelihood: medium. | Autonomous runs ship defects a human would have caught. The human still reviews before merging. | open |
| A-002 | Three approaches per loop instance is enough for most failures. Likelihood: medium. | More runs end with an exception. The P8 report shows how often. | open |
| A-003 | Downstream overrides like `ovelunor`'s keep working. Likelihood: medium. | A product's hands-off runs change behaviour on upgrade. The first-run path says overrides win. | open |
