# Recommendations - Green CI before ship

**Skill:** [docs-agent](../../planifest-framework/skills/planifest-docs-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Version:** 0.35.0

> These are not blockers. They are opportunities for future work.

## Recommendations

Items already in the backlog appear by ID. Pick them up at a future P0.

| ID | Category | Priority | Component | Recommendation | Rationale | Effort |
|----|----------|----------|-----------|---------------|-----------|--------|
| REC-001 | process | high | all | Stop relying on rule text to prevent shell writes. Add a report-only mode to `planifest-framework/hooks/shell-write-guard.mjs` that warns on `sed -i`, `perl -pi`, `>>`, `tee`, and `git stash` against any tracked file, including files under `plan/` and `planifest-framework/tests/`. Add a RED-proof method to `planifest-test-writer` that uses a copy in a temporary folder. Filed as backlog 0000225, beside 0000105 and 0000189. | The run broke the Write-or-Edit rule (boot Hard Limit 8) five times: `sed -i` at P2 (orchestrator), `printf >>` at P5, `git stash push` and `pop` at P5, `sed -i` at P5, and a `python3` heredoc at P3 that the permission check stopped. The dispatch template already states the rule, so more text will not help. The guard passes `plan/` and suite paths because `gate-write` always permits them. | medium |
| REC-002 | process | high | all | Add an adversarial-input checklist to `planifest-design-critic` and `planifest-adr-agent`. Any requirement that stages, commits, or scans paths must name fixtures for glob names, bracket names, `:`-led names, a tracked and modified file, an empty list, and a file that moves between steps. Require a short git probe in the ADR for each git behaviour it relies on. Filed as backlog 0000226. | P5 needed six re-reviews and two approaches (`plan/current/security-report.md`, re-review history). Approach 1 patched prose unstage rules and hit its cap at N-09. Approach 2 moved the decision into `credential-scan.mjs --safe-paths`. Three findings were visible in a one-minute probe: `git commit -- {paths}` commits working-tree content (N-09), `--pathspec-from-file` reads patterns (N-12), and an empty pathspec file commits the whole index. The stream 01 ADRs and req-003 could have named them at P1 or P2. | medium |
| REC-003 | process | medium | all | Make "who owns the held-back file across P7 to P9" a named design question at P1. The held-back rule had no owner, so N-01, N-07, and N-08 each found another step that bypassed it. Start from the `### Scan-then-commit` procedure in `planifest-framework/standards/autonomous-run-standards.md`, and require any new commit step to cite it. | A cross-cutting rule that lives in step-level prose fails at the next step. The fix that held was one procedure cited by name from every step. | small |
| REC-004 | process | medium | all | Pick up backlog 0000227. Make the orchestrator paste `date -u` output into each loop-state iteration, and check the timestamp against the commit time of the iteration artifact at loop close. | `plan/current/loop-state-design_critic-p1.md` holds estimated timestamps (`00:40:00Z` and `00:55:00Z`) for iterations 2 and 3. A correction note and a build-log line record this. Nothing prevented it, and nothing could detect it. | small |
| REC-005 | performance | high | planifest-framework | Pick up backlog 0000213 with 0000221. Assign Windows shards by measured duration from a committed weights file, and check the shard list against the real suites. Until then, review the shard layout whenever a suite is added. | The Windows leg now runs seven shards, which raised the jobs per PR from 10 to 13. The shards ran 2 to 13 minutes in run 40053917957 (2m07s, 4m00s, 13m07s, 4m08s, 3m05s, 2m05s, 3m27s), so shard 3 sets the wall-clock time while the rest idle. Four setup-heavy suites (`test-0000030-req-004` alone takes about 600 seconds) landed in one shard under four-way positional sharding and hit the 20-minute cap on PR #64. A new suite shifts every later position and can regroup them. | medium |
| REC-006 | performance | low | planifest-framework | Measure the total Windows minutes per PR after the first merge, and add the figure to `docs/architecture-overview.md`. Decide whether the seven shards stay once 0000213 lands. | The R-013 cost estimate predates the shard split. The figure is the input for the 0000213 design. | small |
| REC-007 | maintainability | high | planifest-framework | Pick up backlog 0000193 and 0000199 together. Read the head that the Step 11 push of `final-report.md` creates, and fetch `v*` tags in the CI checkout. | Until 0000193 lands, the P9 check covers only the head P9 reads. Until 0000199 lands, the req-008 tag check prints `SKIP: no v* tags fetched` in CI. | small |
| REC-008 | security | medium | planifest-framework | Pick up backlog 0000204. Make the enforcement hooks read Git Bash style paths such as `/c/proj/src/a.js` as repository paths. | It is the one pre-existing finding that holds the P5 rating at Medium. The Windows Git Bash leg now exists, so the gap is testable. | medium |
| REC-009 | security | medium | planifest-framework | Pick up backlog 0000216, 0000217, and 0000209. Cover split, encoded, and homoglyph secrets in `credential-scan.mjs`, run `gitleaks` once, and close the `O_NOFOLLOW` gap in `path-rules.mjs` on Windows. | These are the P5 findings left open at Low or Medium. 0000216 matters most while `autonomous` runs without `gitleaks` (regex-only mode). | medium |
| REC-010 | security | medium | planifest-framework | Pick up backlog 0000218 and 0000219. Pin `actions/checkout` to a commit SHA, add `permissions:` to the two older jobs in `.github/workflows/planifest.yml`, and stop the `setup.ps1` allowed-tools merge from dropping user settings. | Both came from the P5 CI and setup review. | small |
| REC-011 | testing | medium | planifest-framework | Pick up backlog 0000208, 0000210, 0000211, and 0000212 as one pass. Each lists Windows checks skipped under `SKIP (windows)`. Review the skip table in `planifest-framework/tests/README.md` at each release. | The Windows leg is green partly because of narrow skips. The table is the only record of what Windows does not check. | medium |
| REC-012 | testing | low | planifest-framework | Pick up backlog 0000200, 0000203, 0000222, and 0000223 only if they recur or a release touches the same files. | 0000200 did not reproduce in 22 runs. 0000222 and 0000223 are Low edge cases of `### Scan-then-commit`. 0000203 is a Low byte order mark defect. | small |

## Deferred Items

| Scope Item | Recommendation | When to Address |
|-----------|---------------|-----------------|
| Read the head that the Step 11 push of `final-report.md` creates (existing backlog 0000193, listed in `scope.md`). | Cited, not refiled. Extend Step 10c to reread checks after the Step 11 push. | Next feature that edits the ship skill. |
| Fetch `v*` tags in the CI checkout (existing backlog 0000199, listed in `scope.md`). | Cited, not refiled. Add `fetch-depth: 0` or a tag fetch to the checkout step. | With the first migration that ships after 0.35.0. |
| Enforcement hooks read Git Bash paths as outside the repository (existing backlog 0000204). | Cited, not refiled. See REC-008. | Before the next Windows-facing release. |
| Adversarial-input checklist for the P1 and P2 critics (backlog 0000226). | Add the checklist to `planifest-design-critic` and `planifest-adr-agent`. See REC-002. | Next feature that edits the critic skills. |
| Script for the P9 CI poll (backlog 0000229). | Move the poll to a testable script, and keep the fix-and-push loop in skill text. See ADR-001. | After 0000193 lands, because both edit Step 10c. |

## Tech Debt

Items already in the backlog appear in the recommendations above. This table lists only debt that this run filed as a new entry.

| ID | Component | Description | Impact if Ignored | Suggested Fix |
|----|-----------|-------------|-------------------|--------------|
| TD-001 | planifest-framework | `shell-write-guard.mjs` passes shell writes to always-permitted paths and passes `git stash` (backlog 0000225). | Subagents keep breaking the Write-or-Edit rule, and only a human reading the build log notices. | Add a report-only warning mode, then decide on blocking after one feature. |
| TD-002 | planifest-framework | Loop-state timestamps can be estimates, and nothing detects it (backlog 0000227). | The audit trail can hold invented times, as it did in the P1 loop-state file. | Paste `date -u` output per iteration, and compare with commit times at loop close. |
| TD-003 | planifest-framework | The ship skill and docs-agent skill keep superseded commit lines and the old skip phrase, because older suites assert them (backlog 0000228). | A reader can run a reference line by mistake, and two forms of one rule can drift. | Move the older assertions to the new commands, then delete the reference lines. |

## Process notes for the next run

- Five Write-or-Edit breaches happened in one run, three of them at P5. They came from fix agents under time pressure. Name the rule in the first lines of each fix-agent prompt, and give the allowed way to append to a file.
- A fresh-context re-reviewer found defects the author's tests missed in all six rounds. Keep the re-review loop, and aim to move its cheapest probes to P2.
- The draft PR at P3 (the "CI before P4" step in `design.md`) caught 25 failing Windows suites and the `ConvertFrom-Json -AsHashtable` defect before P4. Keep it for any release that touches CI or Windows paths.
- Verify by execution found the `gh pr checks` empty-output defect (backlog 0000215), which the stub-based suite could not. Keep it on.
- The P1 design critic needed two approaches. The cross-file draft-PR rule had no owner under approach 1. When a finding spans files, assign one owner for the fix.

## Backlog filed or closed in this run

Pulled in at P0: 0000191, 0000192, 0000086, 0000186, 0000100, 0000071, 0000089, 0000093, 0000092, 0000094.

| ID | Status | Phase | Title |
|----|--------|-------|-------|
| 0000193 | open | P1 | Final report push leaves the last head unchecked |
| 0000199 | open | P1 | CI checkout fetches no release tags |
| 0000200 | open | P3 | Fast-path scope suite fails intermittently |
| 0000203 | open | P3 | `setup.ps1` writes a byte order mark under Windows PowerShell 5.1 |
| 0000204 | open | P3 | Enforcement hooks treat Git Bash style paths as outside the repository |
| 0000208 | open | P3 | Windows hook suite checks skipped for cwd, link, mode, and name limits |
| 0000209 | open | P3 | `design.md` gate follows a link swapped in after `lstat` on Windows |
| 0000210 | open | P3 | Windows symlink fixture checks skipped |
| 0000211 | open | P3 | Windows NTFS permission, shim, and name checks skipped |
| 0000212 | open | P3 | Windows gitleaks stand-in and bare `.mjs` checks skipped |
| 0000213 | open | P3 | Duration-weighted Windows shards |
| 0000215 | closed (P4) | P4 | `gh pr checks` prints no JSON before checks register |
| 0000216 | open | P5 | Credential scan misses split, encoded, and homoglyph secrets |
| 0000217 | open | P5 | Credential scan runs `gitleaks` once per source and can leave a temp copy |
| 0000218 | open | P5 | Workflow jobs lack permissions, tag-pinned actions, and inline `base_ref` |
| 0000219 | open | P5 | `setup.ps1` allowed-tools merge can drop user settings |
| 0000220 | closed (P5) | P5 | P8 guard keeps refused files staged |
| 0000221 | open | P5 | Shard list not checked against real suites |
| 0000222 | open | P5 | Scan output path glob characters stall unstage |
| 0000223 | open | P5 | Empty-list guard leaves a block's exit code at 1 |
| 0000225 | open | P6 | Shell guard passes shell writes to `plan/` and `git stash` |
| 0000226 | open | P6 | Adversarial-input checklist for the P1 and P2 critics |
| 0000227 | open | P6 | Loop-state timestamps can be estimated |
| 0000228 | open | P6 | Legacy reference lines kept in the ship and docs skills |
| 0000229 | open | P6 | P9 CI poll has no script, so it cannot be tested |

The stream agents reserved IDs 0000194, 0000195, 0000196 to 0000198, 0000201, 0000202, 0000205 to 0000207, and 0000214. They filed nothing under them.
