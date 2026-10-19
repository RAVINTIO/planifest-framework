# Changelog (0000032-governance-continuity-and-write-gate-scope, 17 Oct 2026)

**Feature:** Governance continuity and write-gate scope
**Pipeline run:** P0 to P9 in continuous mode. No phases skipped.
**PR:** https://github.com/planifest/planifest-framework/pull/58 (draft, shared with 0000031 on the same branch, body updated at P9 on 2026-10-19)

## What Was Built

- **The run stays active through P9.** The ship skill now deletes the session markers after P8 and before the Step 9 tag. It commits them with this feature's archive only. Push and PR stay optional.
- **An interrupted close-out resumes.** Resume Detection step 2a checks the sentinel's feature ID and finds the latest matching archive. It resumes at P8 or at the P9 marker step, and stops and asks when nothing matches.
- **Requests after a run get triaged.** With no sentinel, `auto-trigger-orchestrator.mjs` says no run is active. It asks the agent to triage the request as Fast Path, Change Pipeline, or Feature Pipeline.
- **P9 ends with a context clear.** Ship Step 12 asks the human on the loop for `/clear` or a new session. The orchestrator refuses new work in the same session. Each next step in a handover note goes through a track.
- **`gate-write` ignores paths outside the repository.** A new `path-rules.mjs` module finds the repository root and holds the gated-path rules. A marker inside `plan/` or `docs/` can't move the root.
- **Block reasons reach the agent.** Every enforcement hook that exits 2 now writes its reason to stderr. Existing stdout output is unchanged.
- **Shell writes meet the design gate.** A new Bash PreToolUse hook, `shell-write-guard.mjs`, blocks common shell writers aimed at gated paths. It uses the same rules as `gate-write` and fails open on commands it can't parse.
- **Setup registers the guard once.** `setup.sh` and `setup.ps1` register the shell guard for Claude Code, and a re-run leaves one entry.
- **Downstream projects get a migration.** A 0.31.0 migration tells them to re-run setup.
- **Boot files send code through Write or Edit.** `standard-boot.md` and `cursor-boot.md` gain a Hard Limit for code changes.

## Artifacts Produced

- `feature-brief.md`, `design.md`, `discovery.md`, and `build-log.md`
- `execution-plan.md`, `scope.md`, `risk-register.md`, and `domain-glossary.md`
- `requirements/` (req-001 to req-012) and `adr/` (ADR-001 to ADR-006)
- `security-report.md`, `recommendations.md`, and `iteration-log.md`
- Backlog 0000102 to 0000119. 0000103 and 0000104 were copied from another product at the human's request.

## Decisions

- ADR-001: Hooks stay dependency-free Node ES modules that fail open. Setup stays in Bash and PowerShell, and skills in Markdown.
- ADR-002: The ship skill clears the session markers in P9 before the tag. It supersedes 0000015 ADR-001 and amends 0000015 ADR-004.
- ADR-003: P9 ends with a blocking context clear. It supersedes 0000015 ADR-002.
- ADR-004: `gate-write` and the shell guard share one path-rules module and one repository root rule.
- ADR-005: Enforcement hooks write block reasons to stderr and keep their stdout.
- ADR-006: The Bash shell-write guard is a heuristic. It fails open, and a boot-file Hard Limit covers its gaps.

## Security

P5 took three fix rounds. Overall risk went from Medium to Low. Every Medium finding is fixed and verified. The Low findings are in backlog 0000105 to 0000117.

## Skipped Phases

None
