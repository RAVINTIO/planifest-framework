---
title: "ADR 007: The 0.34.0 migration targets the framework source too"
summary: "The 0.34.0 re-run-setup migration's Target line names every project with an installed Planifest setup, the framework source included. The migrator's target check therefore runs it in this repo. P3 builds the migration file but doesn't run it here. At the end of P6, after the last change to a setup-delivered file, the agent re-runs setup here with the recorded flags and only then writes an applied record."
status: "accepted"
version: "0.1.0"
---
# ADR-007 - The 0.34.0 migration targets the framework source too

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

The 0.31.0 re-run-setup migration names "a downstream project" in its `**Target:**` line. Under 0000035 ADR 019, the migrator's target check (Step 1b) records such a migration `not applicable` in this repo, with no run.

That reasoning fits a migration that fixes downstream-only state. A re-run-setup migration is different. This repo also carries an install. `.claude/skills/`, `.claude/hooks/`, the settings file, and `CLAUDE.md` all come from setup, and the session reads them. On 2026-10-22, `.claude/hooks/enforcement/` still differs from source in the four hooks that 0.33.0 changed.

The 0.34.0 hooks close two write-gate bypasses. If this repo keeps the old hooks, the framework's own sessions run without those fixes.

ADR-006 decides that one migration covers 0.33.0 and 0.34.0. This ADR decides where it applies.

## Decision

1. The `**Target:**` line of `migrate-0.34.0-rerun-setup.md` names every project with an installed Planifest setup, the framework source included. It never names only a downstream project.
2. The migrator's target check therefore passes in this repo, and the Migrator Instructions run here.
3. P3 builds `migrate-0.34.0-rerun-setup.md` but doesn't run it in this repo.
4. At the end of P6, after the last change to any setup-delivered file, the agent first repeats the ADR-006 diff check. It then re-runs `planifest-framework/setup.sh claude-code --strict-orchestrator` with the flags in `.claude/.planifest-setup-flags`.
5. Only after setup completes does the agent write `plan/_migrations/migrate-0.34.0-rerun-setup.md` through **Write**. The record holds `outcome: "applied"` and `framework-version: "0.34.0"`.
6. The agent commits the record with the tracked `planifest-overrides/setup-config/claude-code.md` change that setup writes.
7. If P7, P8, or P9 changes a setup-delivered file, the agent repeats the diff check and the setup run before the P9 push. The record stays as written, because it still describes a completed run.

The run waits until the end of P6 because P4 to P6 can still change setup-delivered files. A P5 security fix to `path-rules.mjs` is one example. A P3 run would leave this repo's installed hooks stale under an `applied` record. A run after the last change makes the record match the install that ships.
8. The migration still applies on a fresh 0.34.0 install. Setup is safe to re-run.
9. Future re-run-setup migrations follow this rule. The 0.31.0 migration keeps its downstream-only Target, because its record here already exists.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Follow the 0.31.0 precedent and target only downstream projects | Matches the existing migration | This repo records `not applicable` and keeps stale hooks. Its own sessions miss the 0.34.0 gate fixes. | The record would state something false about this repo's install. |
| Target downstream only, and re-run setup here by hand | Keeps the migration text narrow | The record says `not applicable` while setup did run. Run state and reality disagree. | A record must come from a scan run in the project (0000035 ADR 019). |
| Re-run setup and write the record in P3 | The install and the hooks it holds update earliest | P4, P5, or P6 can still change a setup-delivered file. The `applied` record would then describe an install that no longer matches source. | The record must match the install that ships, so the run follows the last change. |
| Seed an `applied` record here without re-running setup | No setup run during the feature | The record claims a run that never happened (R-019). The drift check would still report stale skills. | A record must reflect a completed run. |
| Skip the migration on a fresh 0.34.0 install | Saves one setup run | The migrator would need to tell a fresh install from an update. That logic adds risk for little gain. | Setup is idempotent, so the extra run costs seconds (R-018). |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | The migration's Target line names the framework source. P3 builds the migration. The end of P6 re-runs setup in this repo and writes its record. |

## Consequences

**Positive:**
- This repo's sessions run the 0.34.0 hooks and skills once the end-of-P6 run completes.
- The record in this repo describes a real setup run, so run state matches the install.
- The run follows P5, so the installed hooks are the reviewed code.
- The req-002 drift check has a real install to exit 0 against after the run.

**Negative:**
- P4 to P6 run on this repo's old installed hooks. The 0.34.0 gate fixes don't protect this feature's own later phases.
- The feature must run setup inside a feature run. Setup rewrites `CLAUDE.md`, the settings file, and the installed hooks mid-session. P7 to P9 in the same session load the new hooks.
- P4 runs the req-001 suite before the record exists. The suite's record check skips while the record is absent (req-001 FR-001.8). The end-of-P6 run must see that check run and pass.
- The setup run changes a tracked file, `planifest-overrides/setup-config/claude-code.md`. That adds churn to the feature diff.
- Two re-run-setup migrations now treat this repo differently. A reader must check each Target line to know why.

**Risks:**
- The agent writes the record before setup finishes (R-019). The decision orders the steps, and the suite checks the record only after the run.
- A phase after P6 changes a setup-delivered file and the install goes stale again. Decision 7 repeats the run before the P9 push.
- The recorded flags in `.claude/.planifest-setup-flags` are wrong or missing. Setup then installs a different wiring. `planifest-refresh-setup` rebuilds the flags from the installed hooks.

## Related ADRs

- ADR-006 - depends-on: defines the migration whose target this ADR sets.
- ADR-005 - related-to: the drift check runs again after this setup run and should exit 0.
- 0000035 ADR 016 - depends-on: the record format and location.
- 0000035 ADR 019 - related-to: the target check that ruled downstream-only migrations out of this repo.

## Supersedes

- None

## Superseded By

- None
