# Security re-review - 0000039-ravintio-rebrand (fix commit 19e485f5)

Reviewer: fresh-context security agent, 2026-10-25. The review started from REJECT and judged each claimed fix on its own.

Method:

- Read `git show 19e485f5` and both source reviews.
- Built two scratch copies of the pack in `mktemp -d`. `fixed` is the pack at 19e485f5. `pre` is the same pack with `setup.sh`, `setup.ps1`, both helpers, and `path-rules.mjs` reverted to 19e485f5^.
- Ran the new tests against both copies. Ran adversarial probes against `setup.sh` and `setup.ps1` (pwsh 7 on macOS) and both helpers.
- Nothing ran in ROOT. Windows PowerShell 5.1 and real NTFS junctions were not available.

Result: 6 findings closed, 2 partly closed, 0 open. The fixes add one new Low finding.

## Verdicts

| ID | Verdict | Evidence |
|---|---|---|
| S-01 Medium | Closed | Both scripts now act only on `{skills folder}/{leaf}`, and only when the entry's parent resolves to the skills folder. The probe ran 11 manifest entries through both scripts, with identical results. These entries survived: an absolute path outside the repo, a `..` path, a linked parent (`skills/lnk/planifest-lp`), `skills/lnk/../x`, and `out/lnk/../x`. These entries were still pruned: a legitimate entry, a relative entry, an entry with a trailing slash or `//`, and a link inside the skills folder. The link was unlinked and its target survived. An entry with trailing spaces fails safe (skipped, so the folder stays). On `pre`, the absolute, `..`, and linked-parent folders were all deleted. The new `req-002` cases fail on `pre` (3 FAIL) and pass on `fixed`. The new `test_setup.ps1` case throws on `pre` and passes on `fixed`. That case has no linked-parent check, but the probe covered it. See N-01 for a parity gap. |
| S-02 Low | Partly closed | `.opencode/plugins/@planifest/opencode-hooks/` and `.github/workflows/planifest.yml` are now enforcement paths, and `fast-path.md` lists them. Two `req-008` asserts fail on `pre` and pass on `fixed`. The review also asked `setup/opencode.sh` and `setup/opencode.ps1` to drop the old plugin from `opencode.json`. Neither script changed, and neither mentions the old path. So OpenCode still loads a leftover old plugin. It can no longer be written through a Fast Path scope record. |
| M-001 Medium | Partly closed | Both helpers now keep a name that follows `secrets.` or `vars.`, and the twins match byte for byte. The new `req-006` asserts fail on `pre` and pass on `fixed`, on both the `.sh` and `.ps1` sides. `env.PLANIFEST_NAME` is still rewritten, which is correct, because the same file's `env:` key is rewritten with it. `PLANIFEST_NAME_EXTRA` keeps its name. The original failure is still reachable in both helpers through other GitHub expression forms. See the list after this table. |
| M-002 Medium | Closed | Both helpers rewrite an exact `name: Planifest Strict Pipeline` line, with or without CR. `setup.sh` lines 810 to 814 skip an existing `ravintio.yml`, so the helper's rewrite is the only change, and the test confirms it. The shipped `hooks/ravintio.yml` job is `validate-branch` with no job-level `name:`, so `validate-branch` is the check name. The new warning in both helpers and the `.md` is now true. R-007 matches. The new asserts fail on `pre` and pass on `fixed`. |
| L-001 Low | Closed | Both helpers re-check the target just before each move: `move_path` and `Move-Entry` (steps 3 and 4), plus step 6. The git shim test plants the target after step 2. On `pre`, it fails 8 asserts on `.sh` and 4 on `.ps1`. The `.ps1` step 6 plain move was already safe. On `fixed`, all pass. A window of a few system calls remains between the check and the move. That is inherent, and the attacker already needs write access to the project. |
| L-006 Low | Closed | The `.md` Backup clean-up section and the step 7 message in both helpers now say `git clean -x` deletes the backup. The assert fails on `pre` and passes on `fixed`. |
| L-007 Low | Closed | Both helpers stop at step 2 when `git ls-files -s` shows mode `160000`, and they name `git submodule deinit`. Case (g2) fails on `pre` and passes on `fixed`, on both sides. It confirms that nothing moves. |
| L-009 Low | Closed | Check-pass step 1 in `SKILL.md` now says that if either old folder remains, the migrator follows the Migrator Instructions in the migration file instead. That removes the conflict. The change is a text change, with no test. |

The M-001 forms that the helpers still rewrite, all confirmed in scratch runs of both helpers:

- `${{ secrets['PLANIFEST_NAME'] }}` and `${{ secrets[ 'PLANIFEST_TIER' ] }}`. GitHub documents this bracket form.
- `${{ Secrets.PLANIFEST_NAME }}`. GitHub context names are case-insensitive.
- `${{ secrets . PLANIFEST_NAME }}`.
- A reusable-workflow call's `secrets:` key, `PLANIFEST_NAME: ${{ secrets.PLANIFEST_NAME }}`. The key names the called workflow's secret, which the consumer owns.
- `inputs.` and `needs.*.outputs.` references.

Each form gives the same silent empty value as the original finding. The bracket and `secrets:` key forms are the plausible ones. Residual severity: Low, because each form needs a consumer secret named with an old pack prefix and a pack suffix.

Fix for the residual: also skip a match when the text before it ends in `secrets[` or `vars[`, allowing an optional quote and spaces. Match `secrets.` and `vars.` case-insensitively. Then correct `.md` step 4 to list the forms the helper keeps. A narrower option is to stop the rewrite on any line that holds `secrets` and print the line for the human on the loop.

## New findings from the fixes

| ID | Severity | Finding |
|---|---|---|
| N-01 | Low | The two S-01 fixes differ when the skills folder, or a folder above it, is a link. `setup.ps1` walks up to the project root, skips the prune on any reparse point, and leaves the orphan folder. `setup.sh` resolves both sides with `pwd -P` and prunes inside the link target. The scratch probe used `.claude/skills` linked to `out/skills`. `setup.sh` deleted `out/skills/planifest-x`, and `setup.ps1` kept it. The deleted folder is a `planifest-*` folder inside the folder the tool uses as its skills folder, so the outcome matches intent. It is a twin parity gap, not an escape. Fix: pick one rule and use it in both scripts. |

## Out-of-scope note

`test-0000039-req-008-emitted-names.sh` line 184 reads the workflow from `$REPO`, which is the repo above the pack. The test fails `req-008 AC3: the workflow name reads RAVINTIO Strict Pipeline` whenever the pack is copied somewhere without `.github/workflows/ravintio.yml` above it. This happened in both scratch copies. The check should read `$B/.github/workflows/ravintio.yml`, the scratch repo setup just wrote. The failure predates 19e485f5, and it never touches ROOT.

## Summary

Overall re-review rating: **Low**. No Medium finding remains open. The P5 gate can pass once someone accepts or fixes the residuals:

1. M-001: the bracket, case-variant, and reusable-workflow `secrets:` forms.
2. S-02: the old OpenCode plugin registration.
3. N-01: the link parity gap between the two setup scripts.
