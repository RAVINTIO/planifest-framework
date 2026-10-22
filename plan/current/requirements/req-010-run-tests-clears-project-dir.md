---
title: "Requirement: req-010 - run-tests-clears-project-dir"
summary: "run-tests.sh clears CLAUDE_PROJECT_DIR before it runs any suite, and every suite that names an enforcement hook clears it for a standalone run."
status: "draft"
version: "0.1.0"
---
# Requirement: req-010 - run-tests-clears-project-dir

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Source:** US-010 (backlog 0000155)
**Priority:** should-have

## User Story

As the human on the loop, I see `run-tests.sh` clear `CLAUDE_PROJECT_DIR` before any suite, so that a suite run inside Claude Code tests its fixture and not the real repo.

## Functional Requirements

### Current behaviour (verified at `f834ab2`)

- `resolveRoot` reads `CLAUDE_PROJECT_DIR` first (`path-rules.mjs:311`), and `hookCwd` falls back to it (`path-rules.mjs:417`). A suite run inside a Claude Code session inherits the variable, so a hook under test can find the real repo as its root.
- `planifest-framework/tests/run-tests.sh` never mentions the variable. It runs each `tests/test-*.sh` through `run_suite` (`run-tests.sh:13-25`, `:31-33`) and each `tests/regression/test-*.sh` in a second loop (`:49-58`).
- 25 suite files under `planifest-framework/tests/` and `planifest-framework/tests/regression/` mention `CLAUDE_PROJECT_DIR`. Only 21 of them hold an `unset CLAUDE_PROJECT_DIR` line (checked with `grep -rl`). The other four are the 0000035 suites `test-0000035-req-002-product-yml-in-p7.sh` and `test-0000035-req-008-sanctioned-scripts.sh`, each with a regression copy. They set the variable for single hook calls and never unset it.
- These suites name an enforcement hook file and don't clear it:
  - `tests/test-0000005-framework-governance.sh`
  - `tests/test-0000009-rail-tightening.sh`
  - `tests/test-0000028-req-002-shared-module-extraction.sh`
  - `tests/test-0000028-req-006-em-dash-guard.sh`
  - `tests/test-0000030-req-004-install-clean-up-and-retired-flags.sh`
  - `tests/regression/test-0000005-framework-governance.sh`
  - `tests/regression/test-0000009-rail-tightening.sh`
- The brief counts four such suites. The rule below replaces a fixed list, so the count doesn't matter to the build.

### Runner change

- `run-tests.sh` runs `unset CLAUDE_PROJECT_DIR` once, after `set -uo pipefail` and before the first `run_suite` call.
- The unset covers the feature suites and the regression suites, because both loops run in the same shell after it.
- A suite that sets the variable on purpose for one hook call still works. Examples are the `env -u` and inline `CLAUDE_PROJECT_DIR=` forms in the 0000035 suites.

### Suite rule

- A suite "names an enforcement hook" when its text holds one of these file names:
  - `gate-write.mjs`
  - `shell-write-guard.mjs`
  - `ratchet-check.mjs`
  - `em-dash-guard.mjs`
  - `path-rules.mjs`
  - `check-design.mjs`
- Every `test-*.sh` under `tests/` and `tests/regression/` that names an enforcement hook holds an `unset CLAUDE_PROJECT_DIR` line before its first command that runs `node`. A standalone run of that suite then tests its fixture.
- The rule over-matches suites that only read hook source. An unset in such a suite has no effect, and one plain rule is easier to check than a judgement of which suites run hooks.
- Each suite added by this feature follows the rule, including those for req-008, req-009, and req-011.

### Tests

- A new suite, `planifest-framework/tests/test-0000036-req-010-run-tests-clears-project-dir.sh`, holds two checks.
- Runner check: the suite copies `run-tests.sh` into a folder under `mktemp -d` with one stub `test-probe.sh`. The stub prints `[${CLAUDE_PROJECT_DIR-unset}]`. The suite runs the copy with `CLAUDE_PROJECT_DIR` set to the fixture path and asserts the output holds `[unset]`.
- Suite-rule check: the suite scans every `test-*.sh` under `tests/` and `tests/regression/`. It fails and names each file that names an enforcement hook but holds no `unset CLAUDE_PROJECT_DIR` line before its first `node` command.
- The req-010 suite clears the variable itself, so it passes when run on its own inside Claude Code.

### Non-functional

- The runner check finishes in under 2 seconds.
- The change adds no dependency beyond Bash and the tools the suites already use.

## Acceptance Criteria

- [ ] With `CLAUDE_PROJECT_DIR` set in the calling shell, a suite that `run-tests.sh` starts sees the variable unset.
- [ ] Every `test-*.sh` under `tests/` and `tests/regression/` that names an enforcement hook clears `CLAUDE_PROJECT_DIR` before its first `node` command, so a standalone run tests its fixture.
- [ ] The req-010 suite checks both, and fails with the file name when a suite breaks the rule.

## Dependencies

- `planifest-framework/tests/run-tests.sh` (edited here).
- The seven suite files listed under current behaviour (edited here, one line each).
- Req-008, req-009, and req-011, whose new suites must follow the suite rule.
- 0000035 req-005, the source of the per-suite `unset` lines and their comment wording.
