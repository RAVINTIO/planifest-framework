# Recommendations - Human-on-the-loop run mode

**Skill:** [docs-agent](../../planifest-framework/skills/planifest-docs-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Version:** 0.32.0

> These are not blockers - they are opportunities for future work.

## Recommendations

| ID | Category | Priority | Component | Recommendation | Rationale | Effort |
|----|----------|----------|-----------|---------------|-----------|--------|
| REC-001 | testing | high | planifest-framework | Run one `autonomous` pipeline end to end on a test product before relying on it. Check that every stop is on the exception list. | The 78 feature suites assert skill text and script behaviour. None runs a whole pipeline in `autonomous`. The security report lists this as its first action before production. | medium |
| REC-002 | maintainability | high | planifest-framework | Decompose `planifest-orchestrator/SKILL.md` (backlog 0000020). Move phase detail into standards files and keep the skill as a router. | The skill grew from 9,276 to 10,314 words (11 percent) in this run. A fresh session reads all of it before acting. Risk R-001 stays open. | large |
| REC-003 | operations | high | repository | Re-run setup here so the installed `.claude/skills/` copies match the source skills. The `planifest-refresh-setup` skill can reconstruct the current flags. | This session ran the old installed copies. The installed docs-agent predates req-014, so P6 used the source copy by hand. | small |
| REC-004 | process | high | planifest-framework | Turn `design_critic` on by default for P1 and P2. | The P1 review found 1 blocker and 6 major findings the drafting agents missed. The P5 reviews found High findings the P3 agents missed. Both ran outside the toggle. | small |
| REC-005 | process | medium | planifest-framework | Add file-ownership batching to `agent-dispatch-standards`. Assign each shared file to one work package per wave. Other packages send their edits to that owner or wait for the next wave. | Parallel work packages shared `planifest-orchestrator/SKILL.md`, the build-log template, and the build-assessment skill. WP4 rewrote the orchestrator once with `sed -i` during wave 1. No edit was lost, but nothing prevented it. | small |
| REC-006 | testing | medium | planifest-framework | Keep the textconv and replace-ref attack fixtures as named regression cases under `planifest-framework/tests/`. Add each new P5 finding as a case. | These two attacks forged `autonomous` in P5 cycle 2. A later change to `scripts/run-mode.mjs` could reopen them unseen. | small |
| REC-007 | process | medium | planifest-framework | Have `planifest-test-writer` check that each criterion asserts the stated behaviour, not only that a term is present. | P4 cycle 1 found req-010 AC-2 and AC-3 with no assertion. The suites asserted term presence. | small |
| REC-008 | security | low | planifest-framework | Read `autonomous` run-mode trust as an integrity check, not a security boundary, in the next governance review. | `scripts/run-mode.mjs` stops file-write spoofing. Backlog 0000121 documents the git-config paths that remain. | small |

## Deferred Items

| Scope Item | Recommendation | When to Address |
|-----------|---------------|-----------------|
| S6 residual: a join can claim another stream's changed file in the same range | Already filed as backlog 0000120. Limit a join to its own changed files. | Next change to `stream-reconcile.mjs` |
| User and repo git config, alternates, grafts, and shallow files can forge the run-mode anchor | Already filed as backlog 0000121. Harden `run-mode.mjs` against these paths. | Next change to `run-mode.mjs` |
| Quality gates for agent workflow evaluation (0000097) | Already filed as backlog 0000097. Build on the touchpoint count from req-006. | After the first `autonomous` runs give real counts |
| Orchestrator skill decomposition | Already filed as backlog 0000020. See REC-002. | Next run |
| `design_critic` on by default (REC-004) | Not yet filed. Needs a new backlog entry. | Before the next run |
| File-ownership batching in `agent-dispatch-standards` (REC-005) | Not yet filed. Needs a new backlog entry. | Before the next parallel run |

## Tech Debt

| ID | Component | Description | Impact if Ignored | Suggested Fix |
|----|-----------|-------------|-------------------|--------------|
| TD-001 | planifest-framework | The join check in `stream-reconcile.mjs` accepts a file another stream changed. Already filed as backlog 0000120. | A join can pass with a false consumer claim. | Limit each join to its own changed files. |
| TD-002 | planifest-framework | `scripts/run-mode.mjs` trusts user and repo git config paths. Already filed as backlog 0000121. | A deliberate multi-step tamper can forge `autonomous`. | Set the config paths explicitly in each git call. |
| TD-003 | planifest-framework | The orchestrator skill holds 10,314 words. Already filed as backlog 0000020. | Each feature adds text and makes the skill harder for a fresh session to follow. | Move phase detail into standards files. |
| TD-004 | planifest-framework | Installed `.claude/skills/` copies in this repository predate the 0.32.0 source skills. Not filed. See REC-003. | Local sessions run old rules and skip new checks. | Re-run setup with the current flags. |
