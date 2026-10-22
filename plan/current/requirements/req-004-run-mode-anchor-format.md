---
title: "Requirement: req-004 - run-mode-anchor-format"
summary: "run-mode.mjs accepts the autonomous anchor as a bare line or as one list item that starts with a hyphen and a space. Every other anchor rule stays, and the orchestrator skill and build-log template show the exact line in a code block."
status: "draft"
version: "0.1.0"
---
# Requirement: req-004 - run-mode-anchor-format

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Source:** US-004 (backlog 0000127)
**Priority:** must-have

## User Story

> One requirement doc = one user story.

As the human on the loop, I see `autonomous` restore after P0 whether the anchor line is bare or a list item, so that a format slip never needs a repair commit.

## Functional Requirements

### The problem

- `planifest-framework/scripts/run-mode.mjs:60` sets `LINE_PREFIX` to `Run mode confirmed: autonomous`.
- The working-tree check at `:134` keeps only lines that start with that prefix. The history check at `:154-155` matches `-` or `+` followed directly by the prefix.
- An orchestrator that writes the anchor as a list item, `- Run mode confirmed: autonomous (...)`, matches neither check. The script then prints `interactive`, and the run needs a repair commit.
- The orchestrator skill at `SKILL.md:458` quotes the line inline in prose. The build-log template shows no line at all. Neither shows the exact form.

### Accepted forms

- The script accepts exactly two forms of the anchor line. A line counts only when it starts at column 1 with one of these:
  - `Run mode confirmed: autonomous`, the bare form.
  - `- Run mode confirmed: autonomous`, one hyphen and one space, then the bare form.
- Every other form counts as no anchor line. That covers leading spaces or tabs, `* `, `+ `, `> `, `1. `, `-- `, `- - `, and a hyphen followed by two spaces or a tab.
- The working-tree check counts lines of both forms together. Exactly one such line must exist, so one bare line plus one list line reads as two and fails.
- The history check reads `+` or `-` followed by either form. A removal of either form still fails the check.
- The line in the working tree must equal the line the anchor commit added, prefix included. A commit that turns a bare line into a list item removes one form and adds the other, so the removal rule rejects it.

### Rules that stay unchanged

- Exactly one commit adds the anchor line, and no commit removes or edits it.
- That same commit sets the design Confirmation line to `yes`. `CONFIRM_RE` at `:61` doesn't change.
- The merge rule, the rename rule, the symlink checks, and the 1 MB read cap stay as they are.
- A forged, uncommitted, or missing anchor prints `interactive` with one reason line on stderr, as today.
- The header comment's rule 3 names both accepted forms.

### Skill and template text

- `planifest-framework/skills/planifest-orchestrator/SKILL.md` (paragraph at `:458`) shows the anchor line in a fenced code block, in the bare form:

  ```
  Run mode confirmed: autonomous ({ISO-8601 timestamp})
  ```

- The paragraph calls the bare line the preferred form. It says the script also accepts the line as one `- ` list item.
- `planifest-framework/templates/build-log.template.md` shows the same code block in its P0 section. A note says that only the orchestrator writes it, and only for `autonomous`, in the commit that confirms the design.

### Suite

- `planifest-framework/tests/test-0000033-req-001-run-mode-script.sh` gains the new cases. Each case builds a fixture repo, as the suite does today.
- The suite already covers the bare form. The new cases cover these outcomes:
  - The list-item form, added in the design-confirm commit, prints `autonomous`.
  - An indented line prints `interactive`.
  - A line with another prefix, such as `* ` or `-- `, prints `interactive`.
  - A list-item line added in a later commit than the design-confirm commit prints `interactive`.
  - A bare line plus a list-item line prints `interactive`.
  - A commit that turns a bare line into a list item prints `interactive`.
- P3 adds the same cases to the suite's copy in `planifest-framework/tests/regression/`.

## Acceptance Criteria

- [ ] `run-mode.mjs` prints `autonomous` for an anchor written as a bare line or as one `- ` list item. It keeps the one-commit rule, the removal rule, and the design Confirmation check unchanged.
- [ ] The orchestrator skill and `templates/build-log.template.md` each show the exact bare anchor line in a fenced code block.
- [ ] The suite prints `interactive` for an indented line, a line with another prefix, and a list-item line added in a later commit.

## Dependencies

- 0000033 req-001 and its ADRs define the anchor rules that this requirement keeps.
- Stream 02 also edits `planifest-framework/skills/planifest-orchestrator/SKILL.md` for the drift check in resume detection. [req-003](req-003-ship-commit-subjects.md), [req-005](req-005-hard-limits-cited-by-name.md), and [req-006](req-006-design-critic-default.md) edit the same file. The orchestrator orders those edits.
- No dependency on req-001, req-002, or req-007 to req-011.

## Input Validation

The build log is text that any agent can write, so the script treats it as untrusted.

- [ ] Input source: `plan/current/build-log.md` in the working tree, or the archived path the ship agent passes, plus its git history.
- [ ] Allowed character pattern: a line counts as an anchor only when it matches `^(- )?Run mode confirmed: autonomous` at column 1. Every other line is ignored for the anchor.
- [ ] maximum length: the existing 1 MB read cap per file. A larger file prints `interactive`.
- [ ] Failure behaviour: any rule break prints `interactive`, writes one reason line to stderr, and exits 0.
- [ ] Logging policy: the reason line goes through the existing `clean()` filter, so it holds no control characters and at most 200 characters.
