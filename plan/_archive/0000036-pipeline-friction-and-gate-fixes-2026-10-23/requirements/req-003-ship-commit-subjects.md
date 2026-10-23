---
title: "Requirement: req-003 - ship-commit-subjects"
summary: "Every commit subject template in the framework skills drops its placeholders. Subjects name the phase and the action only, and the feature ID moves to the commit body, so no subject can pass 72 characters."
status: "draft"
version: "0.1.0"
---
# Requirement: req-003 - ship-commit-subjects

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Source:** US-003 (backlog 0000160)
**Priority:** must-have

## User Story

> One requirement doc = one user story.

As the human on the loop, I see every ship commit pass the `commit-msg` hook whatever the feature ID length, so that P7 and P9 never stop on a rejected subject.

## Functional Requirements

### The problem

- `planifest-framework/hooks/commit-msg` reads the first line of the message as the subject. A subject over 72 characters exits 1 and blocks the commit.
- Three ship-agent subjects embed `{feature-id}`. A feature ID can run to 80 characters, so the subject length depends on the feature. 0000035 hit the block at P9.
- A search of `planifest-framework/skills/`, `workflows/`, `standards/`, and `templates/` on 2026-10-22 found four subject templates that hold a placeholder:
  - `planifest-framework/skills/planifest-ship-agent/SKILL.md:157`, `plan(p7): archive {feature-id}`.
  - `planifest-framework/skills/planifest-ship-agent/SKILL.md:244`, `plan(p9): clear session markers for {feature-id}`.
  - `planifest-framework/skills/planifest-ship-agent/SKILL.md:364`, `plan(p9): add final report for {feature-id}`.
  - `planifest-framework/skills/planifest-orchestrator/SKILL.md:687`, the same P9 marker subject quoted in prose.
- The two close-out leftover commits at `SKILL.md:207` and `:354` already keep the ID out of the subject. They pass it as a second `-m`, so they set the pattern.

### New subjects

- Each subject names the phase and the action only. The feature ID goes in the body through a second `-m "{feature-id}"`, as the leftover commits do.
- The new subject templates are these:
  - P7 Step 7: `plan(p7): archive plan/current`
  - P9 marker step: `plan(p9): clear session markers`
  - P9 Step 11: `plan(p9): add final report`
- In the two P9 commands that name paths, the body `-m` sits before the `--` path list. Each command keeps its paths, its `git diff --cached --quiet` guard, and its order.
- The orchestrator's "What P9 produces" paragraph quotes the new P9 marker subject.
- No other part of the ship steps changes. The tag message `git tag v{version} -m "{feature-id}"` is a tag message, not a commit subject, and it stays.

### Suite

- A new suite, `planifest-framework/tests/test-0000036-req-003-ship-commit-subjects.sh`, scans every `SKILL.md` under `planifest-framework/skills/` and every file under `planifest-framework/workflows/`.
- It reads the first `-m` value of each `git commit` command. It also reads each backtick span in prose that has the `type(scope): description` form.
- It fails if a subject holds `{`, `}`, `<`, or `>`, or runs past 72 characters.
- It also runs `hooks/commit-msg` on each subject it found, in a temp message file, and expects exit 0.

### Existing suites

These suites assert the old subject text, so P3 updates each one to the new text:

- `planifest-framework/tests/test-0000023-req-002-marker-commit-lifecycle.sh:51`
- `planifest-framework/tests/test-0000032-req-001-marker-clear-before-tag.sh:66` and `:112`, and its copy in `tests/regression/`
- `planifest-framework/tests/test-0000033-req-005-ship-without-asking-and-final-report.sh:121`, and its copy in `tests/regression/`

Each updated assertion also checks that the command carries `-m "{feature-id}"`, so the ID stays traceable.

## Acceptance Criteria

- [ ] No commit subject template in any framework skill or workflow holds `{feature-id}` or any other placeholder. The P7 archive commit and both P9 commits carry the feature ID in the body.
- [ ] The new suite fails when a skill's commit subject template holds a placeholder or runs past 72 characters. Each subject it finds passes `hooks/commit-msg` with exit 0.

## Dependencies

- `planifest-framework/hooks/commit-msg`, read only. This requirement doesn't change the hook.
- `planifest-framework/standards/commit-standards.md` section 1 sets the 72-character limit. The new subjects follow its `type(scope): description` form.
- [req-005](req-005-hard-limits-cited-by-name.md) also edits `planifest-framework/skills/planifest-ship-agent/SKILL.md` and the orchestrator skill. The edits touch different lines, but the orchestrator orders them because both change the same files.
- No dependency on req-001, req-002, req-004, or req-006 to req-011.
