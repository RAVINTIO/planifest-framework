# Recommendations - token efficiency and Windows shard fix

**Skill:** [docs-agent](../skills/planifest-docs-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Version:** 0.36.0

> These are not blockers. They are opportunities for future work.

## Recommendations

| ID | Category | Priority | Component | Recommendation | Rationale | Effort |
|----|----------|----------|-----------|---------------|-----------|--------|
| REC-001 | testing | medium | planifest-framework | Add `HUP` to the `trap` in `tests/run-tests.sh` quiet mode. | A stopped run leaks its capture file after SIGHUP. Backlog 0000233 holds this. | small |
| REC-002 | maintainability | medium | setup-hook-integration | Make the reference-link rewrite in `setup.sh` and `setup.ps1` report a failure. | A failed `sed` leaves a link unrewritten with no warning. Backlog 0000233 holds this. | small |
| REC-003 | cost | low | planifest-framework | Split `skills/planifest-ship-agent/SKILL.md` by phase, using the pattern of ADR-002. | The file is 42,318 bytes and a session loads all of it. Backlog 0000231 holds this. | medium |

## Deferred Items

| Scope Item | Recommendation | When to Address |
|-----------|---------------|-----------------|
| One-week usage re-run | Repeat the 0000230 measurement and compare it with the estimate. Filed as backlog 0000234. | One week after the 0.36.0 release |
| Ship-agent skill split | Pick up backlog 0000231 if the re-run shows a remaining context cost. | After backlog 0000234 reports |

## Tech Debt

| ID | Component | Description | Impact if Ignored | Suggested Fix |
|----|-----------|-------------|-------------------|--------------|
| TD-001 | planifest-framework | The quiet-mode `trap` covers `INT` and `TERM` only, and the setup rewrite fails silently (security findings L1 and L5). | A capture file stays in the temp folder, and an install holds a broken link with no warning. | Backlog 0000233. |
| TD-002 | planifest-framework | Installed stack-evaluation links dangle. | An installed skill points to a file setup does not copy. | Backlog 0000232. |
