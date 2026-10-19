# Recommendations - Governance continuity and write-gate scope

**Skill:** [docs-agent](../../planifest-framework/skills/planifest-docs-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Version:** 0.31.0

> These are not blockers - they are opportunities for future work.

## Recommendations

| ID | Category | Priority | Component | Recommendation | Rationale | Effort |
|----|----------|----------|-----------|---------------|-----------|--------|
| REC-001 | operations | high | repository | Re-run `setup.sh` in this repository before the PR merges. The `planifest-refresh-setup` skill can reconstruct the current flags. | This repository's live `.claude/` hooks and `CLAUDE.md` still run 0.30.0. Its own sessions get the old `gate-write.mjs` and no shell guard. | small |
| REC-002 | process | high | planifest-framework | Ask the human on the loop to reconfirm A-003 in the execution plan at P9. | P1 confirmed a walk up from `cwd` to the first marker. The F1, N-4, and N-5 fixes changed that rule twice. ADR-004 still says the human confirmed it. | small |
| REC-003 | security | high | planifest-framework | Decide the shell guard's long-term design before fixing more edge cases. Filed as backlog 0000119. | P5 took three fix rounds. Each fix to `shell-write-guard.mjs` opened new edges: F2 led to N-1, then N-1 led to G-1 and G-2. | medium |
| REC-004 | testing | high | planifest-framework | Check A-001, A-002, and the `CLAUDE_PROJECT_DIR` part of A-003 in a live Claude Code session. Filed as backlog 0000118. | Every hook suite feeds stdin JSON. None shows what Claude Code itself passes to a hook or shows from stderr. | small |
| REC-005 | testing | medium | planifest-framework | Keep the P5 bypass cases as a fixture file under `planifest-framework/tests/`, so each new finding becomes a regression case. | The final P5 check ran 103 scripted exit-code cases. They live only in the build log, so a later change can reopen a closed finding unseen. | small |
| REC-006 | process | medium | planifest-framework | Make P5 re-reviews scripted exit-code checks from the start, with open-ended search as a second pass. | A safety classifier stopped the round 2 re-review partway. The round 3 scripted check covered the gap with no interruption. | small |
| REC-007 | process | medium | planifest-framework | Have `planifest-spec-agent` apply the three-criteria limit per requirement during P1. | The P2 consistency check found all four requirements over the limit (12, 13, 16, and 21 criteria). The split to 12 requirements meant a P1 re-run. | small |
| REC-008 | maintainability | medium | setup-hook-integration | Bring `setup.ps1` to hook parity with `setup.sh`. Filed as backlog 0000102. | `setup.ps1` registers only `gate-write.mjs` on **Write** and **Edit**. A Windows install gets no ratchet check or em-dash guard. | small |
| REC-009 | maintainability | low | planifest-framework | Reconcile `risk-register.md` with what shipped before P7 archives it. | R-005 still describes a git spawn that ADR-004 removed. The register rates overall risk medium and the security report rates it Low. A-003 means different things in the register and the execution plan. | small |

## Deferred Items

The human on the loop chose these at the three P5 gates. Each is already filed.

| Scope Item | Recommendation | When to Address |
|-----------|---------------|-----------------|
| F3: writers behind wrappers such as `env`, `sudo`, and `bash -c` | Strip wrapper prefixes, or list them as limits. Filed as backlog 0000105. | With the 0000119 design decision |
| F6: a dangling symbolic link in `plan/` writes into a gated path | Follow link targets with a hop limit. Filed as backlog 0000106. | Together with 0000117 |
| F9: a deleted `cwd` disables both write gates | Resolve the root from the nearest existing parent. Filed as backlog 0000107. | Next change to `path-rules.mjs` |
| F10: ANSI-C quoted targets pass with a warning | Decode `$'…'` as a literal. Filed as backlog 0000108. | With the 0000119 design decision |
| F12: `ratchet-check.mjs` uses `process.cwd()` | Use `resolveRoot` and `toRootRelative`. Filed as backlog 0000109. | Next change to `ratchet-check.mjs` |
| S-1 and S-2: setup Bash group edge cases | Remove only the guard entry, and match any matcher holding `Bash`. Filed as backlog 0000110. | With backlog 0000102 |
| S-3: the Windows shell tool name | Confirm the tool name Claude Code uses on Windows. Filed as backlog 0000111. | With backlog 0000118 |
| K-5: the post-P9 refusal is instruction only | Accept as residual risk, or add a hook. Filed as backlog 0000112. | When a downstream run skips the refusal |
| M-1: name git writers in boot-file Hard Limit 8 | Name `git checkout`, `restore`, `apply`, and `stash`. Filed as backlog 0000113. | Next boot template change |
| N-6: a nested `.git` marker under a permitted basename | Filed as backlog 0000114. | Next change to `path-rules.mjs` |
| N-7: `cp` and `mv` target option prefixes pass | Filed as backlog 0000115. | With the 0000119 design decision |
| Older `cd` gaps: `builtin cd`, `command cd`, and `CDPATH` | Filed as backlog 0000116. | With the 0000119 design decision |
| G-3: a path through a symbolic link and `..` is judged as text | Resolve links before collapsing `..`. Filed as backlog 0000117. | Together with 0000106 |

## Tech Debt

| ID | Component | Description | Impact if Ignored | Suggested Fix |
|----|-----------|-------------|-------------------|--------------|
| TD-001 | planifest-framework | `shell-write-guard.mjs` is a heuristic shell reader of about 830 lines. Each P5 fix added code and opened new edges. Filed as backlog 0000119. | Each later review finds new bypasses, and each fix makes the reader harder to change. | Choose a smaller conservative guard or a real parser, and record it in an ADR. |
| TD-002 | planifest-framework | A-001, A-002, and the `CLAUDE_PROJECT_DIR` part of A-003 have no live Claude Code test. Filed as backlog 0000118. | If any is wrong, block reasons stay hidden or the shell guard never runs. | Run one scripted live session after setup and record the results. |
| TD-003 | setup-hook-integration | `setup.ps1` registers fewer **Write** and **Edit** hooks than `setup.sh`. Filed as backlog 0000102. | A Windows install gets no ratchet check or em-dash guard. | Match `setup.sh` and add a parity assertion to `test_setup.ps1`. |
