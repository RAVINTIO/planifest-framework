---
title: "Requirement: req-006 - no-planted-root-marker"
summary: "The root walk ignores a .git or planifest-framework marker that sits below an always-permitted basename of a higher marked folder."
status: "draft"
version: "0.1.0"
---
# Requirement: req-006 - no-planted-root-marker

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Source:** US-006 (backlog 0000114)
**Priority:** must-have

## User Story

As the human on the loop, I rely on the gates to ignore a `.git` marker planted under an always-permitted name, so that a moved folder can't become a new root.

## Functional Requirements

### Trust rule

- `markedRoot` keeps the rule that distrusts a marked folder whose first segment below a higher marked folder is `plan` or `docs`.
- `markedRoot` also distrusts a marked folder when any segment of its path below a higher marked folder matches an entry in `ALWAYS_PERMITTED_FILES`. The check includes the candidate folder's own name.
- The comparison uses the 0000009 ADR 005 normalisation, so `CLAUDE.md` and `claude.md` both match.
- The rule applies to both marker kinds, `planifest-framework/` and `.git` (folder or file).
- The rule applies to the walk from `CLAUDE_PROJECT_DIR` and to the walk from `cwd`, because both call `markedRoot`.
- A distrusted marker never ends the walk. The walk goes on to the next trusted marked folder above it.
- A nested marker under any other name stays a root, as today. A git submodule at `vendor/lib/` therefore still counts as its own root.
- The changed rule is artifact `path-rules-markedRoot-basename-distrust`.

### Tests

- A new suite, `planifest-framework/tests/test-0000035-req-006-no-planted-root-marker.sh`, builds a fixture under `mktemp -d`. The fixture has a `.git` folder, no `planifest-framework/`, and no design. The suite unsets `CLAUDE_PROJECT_DIR`.
- The suite runs `mkdir -p plan/w/.git && mv plan/w src/claude.md` in the fixture. It then runs `gate-write.mjs` and `shell-write-guard.mjs` with `cwd` set to `src/claude.md` and the target `../other/x.js`.
- The suite repeats the case for a second permitted basename, `pause.md`, and for a planted `planifest-framework/` folder in place of `.git`.
- The suite checks that a marker at `vendor/lib/.git` still makes `vendor/lib` the root.
- The existing 0000032 req-006 marker cases still pass.

### Non-functional

- Each hook call stays under 500 ms with a `cwd` 20 segments deep.
- `path-rules.mjs` and the new code in this requirement use Node built-in modules only and spawn no process.
- The existing `git status` spawn in `ratchet-check.mjs` predates this feature and stays out of this rule. Backlog 0000128 tracks it.

## Acceptance Criteria

- [ ] The fixture has `.git` and no `planifest-framework/`. After `mkdir -p plan/w/.git && mv plan/w src/claude.md`, a write from `src/claude.md` to `../other/x.js` exits 2 in both gates.
- [ ] A `planifest-framework/` marker planted below an always-permitted basename doesn't move the root either.
- [ ] A marker at `vendor/lib/.git` still makes `vendor/lib` the root, as it does today.

## Dependencies

- All five requirements in this stream change `planifest-framework/hooks/enforcement/path-rules.mjs`. One agent builds them in sequence.
- req-004 changes `resolveRoot`, which calls `markedRoot`. The two changes touch different functions and can land in either order.
- req-005 gains this rule through `resolveRoot` with no extra work.
- `ALWAYS_PERMITTED_FILES` in `path-rules.mjs` defines the basenames. A later change to that list changes this rule too.
