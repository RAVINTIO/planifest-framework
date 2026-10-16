# Recommendations - CI test and PowerShell coverage

**Skill:** [docs-agent](../../planifest-framework/skills/planifest-docs-agent/SKILL.md)
**Feature:** 0000031-ci-test-and-powershell-coverage
**Version:** 0.30.0

> These are not blockers - they are opportunities for future work.

## Recommendations

| ID | Category | Priority | Component | Recommendation | Rationale | Effort |
|----|----------|----------|-----------|---------------|-----------|--------|
| REC-001 | testing | high | repository CI | Mark `Test suite (ubuntu-latest)`, `Test suite (macos-latest)`, and `Setup under PowerShell 7 (Windows)` as required checks in branch protection. | Until then, a red check doesn't block a merge (R-006). | small |
| REC-002 | security | low | repository CI | Pin `actions/checkout` to a commit SHA in every job. | A moved tag could run changed code. All jobs share the risk today. | small |
| REC-003 | maintainability | medium | planifest-framework | Avoid fixed version strings in tests. Read the version from `component.yml` instead. | A 0000030 test hard-coded `0.29.0` and failed when this run bumped the version (P4 cycle 1). | small |
| REC-004 | testing | medium | planifest-framework | Run the full suite after the P3 component version bump, not only before it. | The P3 agents ran the suite before the bump, so the version failure surfaced only in CI. | small |

## Deferred Items

| Scope Item | Recommendation | When to Address |
|-----------|---------------|-----------------|
| Windows PowerShell 5.1 coverage | Decide on 5.1 support first. Filed as backlog 0000092. | When a user reports 5.1 use |
| Suite on Windows under Git Bash | Add a Windows bash matrix leg. Filed as backlog 0000093. | When Windows bash setup changes |

## Tech Debt

| ID | Component | Description | Impact if Ignored | Suggested Fix |
|----|-----------|-------------|-------------------|--------------|
| TD-001 | setup-hook-integration | Stale-entry clean-up and retired-flag notices have no live PowerShell test (Q-013). Filed as backlog 0000094. | A PowerShell-only clean-up defect ships unseen. | Seed stale state in `test_setup.ps1` and assert the clean-up. |
