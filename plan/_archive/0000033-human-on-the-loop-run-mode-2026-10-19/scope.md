---
title: "Scope - Human-on-the-loop run mode"
summary: "Defines explicit boundaries of what is in scope and out of scope."
status: "active"
version: "0.1.0"
---
# Scope - Human-on-the-loop run mode

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Version:** 0.32.0

## In Scope

Each item maps to a requirement and to the backlog entry it came from.

- req-001 autonomous-run-mode (0000078). `autonomous` becomes a third `plan/.run-mode` value. 0000012-ADR-005 changes so the value is recognised. Unknown values still read as `interactive`, and an older framework reads `autonomous` as `interactive`.
- req-002 exception-list (0000078). Only these items wait for the human: schema and destructive changes, a gross deviation, human review of the running result, promotion beyond the candidate environment, a human-only input, and an exhausted budget. A product can add items in an override.
- req-003 gates-as-loops (0000078). In `autonomous`, every phase gate runs as a loop under `planifest-loop-runner` with a fresh-context checker. Existing caps stay.
- req-004 escalation-changes-approach (0000078). At a cap, the run tries a different approach, up to 3 approaches per loop instance. The fourth becomes an exception. The reversal budget stays at 2.
- req-005 ship-without-asking-and-final-report (0000078). P9 pushes and raises the PR without asking. One report at the end of P9 lists what shipped, every decision and deviation, the version, the PR and its CI result, and every exception waiting.
- req-006 on-the-loop-visibility (0000078). The build log gets a one-line progress entry per phase and a human-touchpoint count. The P8 report flags the count.
- req-007 choice-prompts-name-the-actor (0000059). Every two-option prompt names the actor in each option. The P9 push prompt is the first case, and a sweep covers the other phase skills.
- req-008 p0-real-forks-only (0000076). P0 asks only real forks. Derivable items go into the design draft for one confirmation. The design, the Scope Lock batch, and the run mode confirm in one turn. The P0 build-log block records the question count.
- req-009 sample-existing-records (0000101). If a design depends on existing records, discovery samples recent rows and states how often each value it relies on is usable. The design names that rate as an assumption.
- req-010 release-budget (0000103). A new `planifest-overrides/release-budget.yml` holds a target and a ceiling in size points. P0 sizes each requirement as small (1), medium (2), or large (3) and fills the release up to the target. If the file is absent, the three-story rule stays.
- req-011 lightweight-track-for-no-src (0000062). Fast Path's prerequisite relaxes to admit a change with no `src/` target. Its four criteria stay. The orchestrator's track table says so.
- req-012 archive-script-without-glob-delete (0000075). A new `scripts/archive-current.mjs` moves each tracked item with `git mv`, removes markers by explicit path, and prints what it moved. Each step is a separate command, so a resumed run repeats only unfinished steps.
- req-013 clean-close-out (0000073). The P8 build report goes into the archive commit. P8 and P9 end with a scoped `git status --porcelain` check. In `autonomous`, the run commits any leftover file. In other modes, it lists the file for the human.
- req-014 revalidate-after-p6 (0000086). The docs agent reruns the P4 check set after its edits. A product can declare a smaller doc-check command in `planifest-overrides/`.
- req-015 parallel-streams-toggle-and-state (0000104). Independent requirements move through P1 to P4 as separate streams. Each stream has a state file under `plan/current/streams/`. A new loop toggle, `parallel_streams`, defaults to `on` in `autonomous` and `off` otherwise.
- req-016 always-parallel-work-units (0000104). Parallel dispatch is the default in every phase. Each phase skill lists the work units that always run in parallel.
- req-017 join-owner-and-reconciliation (0000082). The orchestrator owns every join between streams or batches. After each join, a reconciliation step checks that a stream or a requirement consumes every artifact another stream declares.
- req-018 subagent-count-and-wall-clock (0000104). The P8 report records subagent count and wall-clock time per phase.
- Text-level tests for each change, run by `run-tests.sh`, plus new tests for each run mode.
- A 0.32.0 version bump (minor) and the migration or release note the bump needs.

## Out of Scope

- Decomposing the orchestrator skill (0000020). It restructures the same file and goes in the next run.
- Quality gates for agent workflow evaluation (0000097), beyond the human-touchpoint count in req-006.
- Shell-guard, setup, and Windows backlog entries.
- Push notifications. The framework can't send one on every tool, so visibility uses the build log.
- Merging a PR in any mode. Merging stays human-only.
- Changing the schema and destructive-operation hard limits. They stay human-gated in every mode.
- Any change to `interactive` or `continuous` behaviour.
- Edits to downstream products' overrides. `ovelunor` can retire its own overrides after it upgrades.

## Deferred

Nothing deferred.
