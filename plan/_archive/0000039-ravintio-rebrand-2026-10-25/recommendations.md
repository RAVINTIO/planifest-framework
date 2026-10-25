# Recommendations - RAVINTIO rebrand

**Skill:** [docs-agent](../../ravintio-framework/skills/ravintio-docs-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Version:** 0.37.0

> These are not blockers. They are opportunities for future work.

## Recommendations

| ID | Category | Priority | Component | Recommendation | Rationale | Effort |
|----|----------|----------|-----------|---------------|-----------|--------|
| REC-001 | maintainability | high | ravintio-framework | Make P1 require a `## Component Paths` section in `design.md`, and have the spec-agent template include it. | `gate-write` blocked the first two P3 test-writers because `design.md` had no such section. It read path-like lines from `## Scope` instead. The orchestrator added the section as a P3 deviation. | small |
| REC-002 | maintainability | high | ravintio-framework | Add a `gate-write` check at the P1 gate that names a missing or empty `## Component Paths` section. | The block surfaced only at P3, after two subagents had started. A P1 check would catch it with no wasted dispatch. | small |
| REC-003 | testing | high | ravintio-framework | Put the ban on interpreters and shell writers in the shared dispatch template, not in each prompt. Add a post-dispatch diff check for `plan/current/`. | In P1 a critic revision agent edited nine `plan/current/` files with a Python one-liner, so `ratchet-check` never ran. The shared brief said "Edit" only as advice. Backlog 0000238 holds the fix and now cites this case. | medium |
| REC-004 | maintainability | medium | ravintio-framework | Make the consistency check resolve an ADR reference that names another feature against that feature, not the current one. | The check read cross-feature ADR references, such as the RAVINTIO Zero ADRs that ADR-004 cites, as local. Backlog 0000252. | small |
| REC-005 | security | medium | ravintio-framework | Tighten the credential scan's `api-secret-key` rule so a hyphenated word ending in `sk` does not match. Add a way to record a human-cleared false positive. | The scan held back three vendored `external-skills/` files for four hits. All four were false positives, and the P4 clearance cost a human touchpoint. Backlog 0000253. | small |
| REC-006 | maintainability | high | ravintio-framework | Teach the orchestrator to check `gh pr view` for mergeability at P4 and after any PR merges to `main` mid-run. | PR #70 merged during the run, so PR #71 conflicted. GitHub runs no `pull_request` workflow on a conflicting PR, so CI reported "no checks reported" and the cause was not obvious. Cycle 1 of P4 fixed it with a merge of `origin/main`. | small |
| REC-007 | testing | high | ravintio-framework | Add a Windows pre-flight list to the test-writer brief: strip CR before comparing text, probe whether `ln -s` links before a link test, and convert Git Bash `/d/a/...` paths with `pwd -W` before passing them to node. | P4 cycles 3 and 4 hit four Windows-only failures: CRLF in the parity text, Git Bash `ln -s` copying instead of linking, node reading `/d/a/...` as `C:\d\a`, and CRLF checkouts differing from stored blobs. Each cost a CI round trip. | medium |
| REC-008 | testing | medium | ravintio-framework | Run the three lint suites (`test-0000031-no-pipe-into-grep-q.sh`, `test-0000037-req-009-portability-lint.sh`, `test-0000036-req-010-run-tests-clears-project-dir.sh`) before every push in P4, not only after a test is written. | P4 cycle 5 failed on a path literal because the orchestrator pushed cycle 4 before it ran them. | small |
| REC-009 | testing | medium | ravintio-framework | Add an adversarial-input checklist to the migration helper brief: names that look like secrets or expressions, links in parent folders, and a folder that appears between check and move. | The first P5 round found three Mediums. S-01 was an old-manifest prune that could leave the skills folder. M-001 was a helper that renamed a `secrets.` reference. M-002 was a branch protection warning that named the wrong check. All three would have shown under such a checklist. Backlog 0000226 holds the P1 and P2 critic version. | medium |
| REC-010 | maintainability | medium | ravintio-framework | Have the scripted-rename step write its protected list to a tracked fixture before the pass. | The three held-back files left a clean clone with three old-name paths, which the local run hid because they showed as deleted. P4 cycle 2 caught it only through verify-by-execution in a clean clone. | small |
| REC-011 | maintainability | low | ravintio-framework | Extend the P3 rename pass rule: tell the script to leave the three-file delete-plus-add case reviewable, and keep `0000039-rename-exceptions.txt` as the model for future renames. | Three small files fell to 34 to 46% similarity and git recorded delete plus add. The fixture lists them, but a future rename must rediscover the pattern. | small |
| REC-012 | maintainability | medium | ravintio-framework | Have the migration helper report override files that still name an old pack path, without rewriting them. | Verify-by-execution found consumer `CLAUDE.md` line 94 still naming an old path from the overrides copy. The migration doc now tells consumers to search, but the helper could list the hits. | small |

## Deferred Items

| Scope Item | Recommendation | When to Address |
|-----------|---------------|-----------------|
| Run `gh repo rename ravintio-framework` and update `origin` after the PR merges | Backlog 0000260 | Right after the human on the loop merges the PR |
| Remove the old-name reads at 1.0.0: `PLANIFEST_SESSION_ID`, the old boot-file markers and ignore-file headers, and the old em-dash sentinel. Setup no longer reads `.planifest-setup-flags` or `.planifest-manifest`, so 1.0.0 decides only whether the setup stop on them and the helper rename step stay. | Backlog 0000261 | The 1.0.0 release |

## Tech Debt

| ID | Component | Description | Impact if Ignored | Suggested Fix |
|----|-----------|-------------|-------------------|--------------|
| TD-001 | ravintio-framework | The PowerShell halves of the req-002 and req-006 suites skip locally without `pwsh`. Only CI proves them. Backlog 0000262. | A PowerShell defect, such as the `File.Replace` `$null` failure, costs a CI round trip each time. | Document `pwsh` as a local prerequisite, or add a container recipe, and print the skipped count. |
