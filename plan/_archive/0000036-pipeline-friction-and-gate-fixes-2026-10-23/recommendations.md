# Recommendations - Pipeline friction and gate fixes

**Skill:** [docs-agent](../../planifest-framework/skills/planifest-docs-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Version:** 0.34.0

> These are not blockers. They are opportunities for future work.

## Recommendations

Items already in the backlog appear by ID. Pick them up at a future P0.

| ID | Category | Priority | Component | Recommendation | Rationale | Effort |
|----|----------|----------|-----------|---------------|-----------|--------|
| REC-001 | security | medium | all | Pick up backlog 0000182. Treat any `!` warning line from setup as an incomplete run in `planifest-framework/migrations/migrate-0.34.0-rerun-setup.md`, and give the gate a separate reason line for an open error on a regular `design.md`. | The second P5 re-review left M-1 and M-2 open. Today an unwritable settings file still records `applied` with no hooks wired. | small |
| REC-002 | maintainability | medium | all | Pick up backlog 0000181. Make step 1a of Resume Detection in the orchestrator skill detect file-level changes, not only version strings. | Step 1b of the same skill rests on step 1a. An unversioned change to a source `SKILL.md` reads as no update. | medium |
| REC-003 | security | medium | all | Pick up backlog 0000162 with 0000179 and 0000180. Decide whether `chmod 000` on `design.md` should block, whether `.gitattributes` can stay in the always-permitted names, and where the provenance gate sits in a re-run-setup migration. | P5 accepted all three as Low. Each is a pre-existing pattern that this feature narrowed but did not remove. | medium |
| REC-004 | maintainability | medium | all | Pick up backlog 0000161. Stop `check-design.mjs` and `ratchet-check.mjs` from reading a FIFO. | Req-008 closed this for `path-rules.mjs` only. The two hooks still open a FIFO at their own read sites. | small |
| REC-005 | maintainability | medium | all | Pick up backlog 0000164. Fix the double encoding of 14 skills by `setup.ps1` on Windows PowerShell 5.1. | The drift check from req-002 strips a byte order mark but cannot repair a double-encoded copy. Windows installs report stale skills until setup is fixed. | medium |
| REC-006 | maintainability | low | all | Pick up backlog 0000170. Remove the byte order mark from the source `planifest-orchestrator/SKILL.md`. | The drift check strips a byte order mark from both copies as a workaround. The source file should not hold one. | small |
| REC-007 | maintainability | low | all | Pick up backlog 0000167. Reconcile the two rules about who may write `.ratchet-approve`. | The P1 decision on a split under an active loop relies on the agents-never-write rule. The conflict leaves the rule ambiguous. | small |
| REC-008 | maintainability | low | all | Pick up backlog 0000177. Make `em-dash-guard.mjs` print the target path with its original case. | The block message lowercases the path, which makes a mixed-case path hard to find. | small |
| REC-009 | testing | medium | all | Run `node planifest-framework/scripts/skill-drift-check.mjs` at the start of the next feature, and record how often it reports stale skills. | Req-002 shipped the check. Real usage will show whether the warning at session start changes behaviour. | small |
| REC-010 | testing | low | all | Review the `design_critic` false-positive rate across the next three features that run it under `report-only`. | The data decides backlog 0000185. | small |

## Deferred Items

| Scope Item | Recommendation | When to Address |
|-----------|---------------|-----------------|
| Move the `design_critic` default to `on` outside `autonomous` (backlog 0000185). | Collect the critic's false-positive rate, then change the default in the five locations that state it. | After three more features have run the critic under `report-only`. |

The scope file lists the shell-guard parser entries (0000105, 0000108, 0000115, 0000116) and the remaining 0000035 hardening entries as out of scope. They already have backlog entries, so this table does not repeat them.

## Tech Debt

Items already in the backlog appear in the recommendations above. This table lists only debt that this run filed as a new entry.

| ID | Component | Description | Impact if Ignored | Suggested Fix |
|----|-----------|-------------|-------------------|--------------|
| TD-001 | planifest-framework | `test-0000036-req-001-rerun-setup-migration.sh` does not compare the migration's 0.34.0 file list with the release diff (backlog 0000186). | A later release can ship a migration that misses changed setup-delivered files, as this one did before P4 fixed it in `16df927`. | Compare the list with `git diff --name-only` against the previous release tag, and skip the check when the tag is absent. |
| TD-002 | planifest-framework | A linked `plan/` or `plan/current/` folder serves a `design.md` from outside the repository (backlog 0000187). | The gate reads a design the repository does not hold. Pre-existing and rated Low. | Resolve the path with `realpathSync` and require the result inside the root. |
| TD-003 | planifest-framework | `shown()` leaves a literal backslash and a lone surrogate ambiguous in `ratchet-check.mjs` and `em-dash-guard.mjs` output (backlog 0000188). | A path with the text `\n` reads like a path with a newline. No line can be forged. | Escape a backslash as `\\` and print a lone surrogate as `\uXXXX`. |
| TD-004 | planifest-framework | The dispatch-template sentence cites "(the Write-or-Edit rule, boot Hard Limit 8)", a bracketed form beside the ADR-010 form (backlog 0000189). | Two citation shapes for one rule, and the req-005 suite accepts both. | Rewrite the sentence to the ADR-010 form and tighten the suite. |

## Process notes for the next run

- The orchestrator moved the three stream files at P2 with a shell `perl -pi` command. That broke the Write-or-Edit rule (boot Hard Limit 8). The content was right, so the files stayed. Use **Write** or **Edit** for stream moves.
- Verify by execution caught the one defect that the suite missed (AC-001.1). Keep it on for any release that ships a migration.
- P5 ran two fix rounds, and each fresh-context re-review found smaller Low cases. The stop rule in the build log (no Critical, High, or Medium finding remains) worked. Keep it.
