# Cross-model verdict 1: 0000039-ravintio-rebrand

**Verdict: REJECT**

- Reviewer model id: `claude-sonnet-5-5`
- Implementer model id: `claude-opus-5-5`
- Date: 2026-10-25
- Branch: `feat/0000039-ravintio-rebrand`
- Rubric: REJECT by default. Approve only when evidence shows each requirement is met.

## Result

One acceptance criterion has no test that exercises it. The `.ps1` migration helper never runs or parses under Windows PowerShell 5.1 (req-006 AC4, finding X-001). Two failed rows in the verification report also stay open (X-002). Fix both, then re-review with a fresh reviewer instance.

Everything else holds. The full suite passes 162 of 162 on a clean run (127 feature suites, 35 regression suites) with `pwsh` installed. The old-name reads in live code match the ADR-004 list. The `.sh` and `.ps1` helpers print the same text and exit codes in the parity cases.

## Test runs

| Run | Result |
|-----|--------|
| `run-tests.sh --quiet`, first run | 161 of 162. Five `[ps1]` M-004 assertions in `test-0000039-req-006-consumer-migration.sh` failed. |
| `test-0000039-req-006-consumer-migration.sh` alone | 660 passed, 0 failed. |
| `run-tests.sh --quiet`, second run | 162 of 162. 127 feature suites and 35 regression suites passed. |

The first run overlapped with two other runs of the same suite that I started. I believe the shared fixture folder caused the five failures, but I did not prove it (finding X-006).

## Requirement-by-requirement

| Req | Verdict | Evidence | Gap |
|-----|---------|----------|-----|
| req-001 pack paths and identifiers | Met | `test-0000039-req-001-pack-paths-and-identifiers.sh` passes. AC1 to AC3 map to its path, identifier, and `R` rename checks. The verification report row that said AC1 failed was a clone artefact from held-back files. The suite passes at HEAD. | X-002: the report was never updated. |
| req-002 runtime names | Met | `setup.sh:1338-1357` and `setup.ps1:70-91` stop before any write, for the old folders and for both old marker files. Both name `migrate-0.37.0-ravintio-rename`. The req-002 suite passes. | X-004: the two stop checks differ for a non-folder or dangling link. |
| req-003 environment variables | Met | The OpenCode adapter reads `RAVINTIO_SESSION_ID` first (`hooks/adapters/opencode/index.ts:26`). The old name is the only fallback. CI sets `RAVINTIO_SHARD_INDEX` and `RAVINTIO_SHARD_COUNT` (`.github/workflows/ravintio.yml:105-106`). | The verification report marks "full suite passes" as not verifiable. My run covers it. |
| req-004 brand prose | Met | The req-004 suite passes, including the heredoc byte check. The brand guard passes with a closed allowlist. | None. |
| req-005 history and split names | Met | The req-005 suite passes. The verification report shows no change under the history paths (`git diff --diff-filter=MDR`). | None. |
| req-006 consumer migration | Not met | AC1 to AC3, AC5, and AC6 have `.sh` and `.ps1` cases in the req-006 suite (660 assertions) and pass. AC4 requires Windows PowerShell 5.1 and PowerShell 7. No test runs or parses the helper under 5.1. | X-001. |
| req-007 brand guard | Met | `test-0000039-req-007-brand-guard.sh` passes. The allowlist has reasons, uses the `<<< "$(...)"` loop form, and fails on a stale entry (probe at line 271). | None. |
| req-008 emitted names | Met | The req-008 suite passes. `.github/workflows/ravintio.yml:1` reads `RAVINTIO Strict Pipeline` and the job keeps the name `validate-branch`. | None. |
| req-009 migration order and old paths | Met | The req-009 suite passes. `Applies when:` in `migrate-0.37.0-ravintio-rename.md` names all three paths. The migrator maps old paths (`ravintio-migrator/SKILL.md:69-73`). | None. |
| req-010 version bump | Met | The req-010 suite passes. `product-version.mjs` prints 0.37.0 per the verification report. | None. |

## Findings

| ID | Severity | File:line or criterion | Issue | Suggested fix |
|----|----------|------------------------|-------|---------------|
| X-001 | High | req-006 AC4. `ravintio-framework/tests/test-0000039-req-006-consumer-migration.sh:1019`. `.github/workflows/ravintio.yml:135-157` | AC4 requires the `.ps1` helper to parse and match the `.sh` helper on Windows PowerShell 5.1 and PowerShell 7. The suite skips AC4 when `pwsh` is missing. On the Windows legs it runs `pwsh`, which is PowerShell 7. The 5.1 CI job (`setup-powershell-51`) runs only `test_setup.ps1`, which never mentions the helper (`grep migrate-0.37` finds no hit in any `.ps1` test). Nothing runs or parses `migrate-0.37.0-ravintio-rename.ps1` under 5.1. The requirement also says "CI parses the file on both". The build log at line 189 leaves this to CI, and CI does not do it. | Add a step to the `setup-powershell-51` job that parses the helper with `[System.Management.Automation.Language.Parser]::ParseFile`. Better, run the clean-run and rerun scenarios from the req-006 suite under `powershell.exe` and compare with the `.sh` output. Add a test that asserts the step exists. |
| X-002 | Medium | `plan/current/verification-report.md:17`, `:58`, `:20`, `:28`, `:74` | The report ends with two rows marked failed (req-001 AC1 and D-1) and one not-verifiable row (req-003 full suite). The D-1 fix (72ac382d) and the P5 rerun changes (dae0eaf5, 00691244, 1e950fc4) came after the last execution run at 7b182157. No row records that D-1 or the strict name rules were re-run against the built software. The verify-by-execution gate cannot pass with an open failed row. | Re-run the step 5 helper rerun on a linked project path and the crafted-manifest cases against HEAD. Append a re-verification section with the new outcome and update the counts. |
| X-003 | Low | `plan/current/adr/ADR-004-old-name-reads.md:59` and `plan/current/design.md:51` | After the P6 change, setup reads neither old marker file. ADR-004 line 59 still says setup and refresh-setup read "two marker files once, then replace or remove them". Design line 51 still says setup and refresh-setup read `.planifest-setup-flags` once and then remove it. The P6 sub-bullets that follow (ADR-004 line 35, design line 52) contradict them. Hard Limit 7 needs the documents to match what was built. | Edit ADR-004 line 59 to say setup stops while either file exists. Edit design line 51 to mark the item as replaced, or add the P6 note inline. |
| X-004 | Low | `ravintio-framework/setup.sh:1341-1347` and `ravintio-framework/setup.ps1:72-78` | The two shells test different things. `.sh` uses `[ -d ]`, so a regular file or a dangling link named `planifest-framework` does not stop it. `.ps1` uses `Test-Path`, which stops on a regular file. The marker checks use link-aware tests in both shells, so only the folder check differs. I read this from the code and did not run it. | Use `[ -e ] \|\| [ -L ]` in `.sh` and `Get-Item -Force -ErrorAction SilentlyContinue` in `.ps1`, as the marker checks already do. Add a case for a file and a dangling link. |
| X-005 | Low | `plan/current/requirements/req-006-consumer-migration.md`, step 8 | The step 8 body still says a rule that requires the old check name must now require `RAVINTIO Strict Pipeline`. The P5 correction sub-bullet and the helper say the opposite. The sub-bullet resolves it, but a reader of the body alone gets the wrong rule. | Strike or rewrite the step 8 body line so it matches the correction. |
| X-006 | Low | `ravintio-framework/tests/test-0000039-req-006-consumer-migration.sh` (fixture folder `$WS`) | My first full run failed five `[ps1]` M-004 assertions while two other copies of the suite ran at the same time. The same suite passed alone and on a clean full run. I did not prove a shared-folder collision. If two runs share a fixture folder, a developer who starts two runs gets false failures. | Confirm that `$WS` is unique per process (for example `mktemp -d`). If it is not, make it so. |

## Checks that found nothing

- Old-name reads in live code: `grep -i planifest` outside tests, migrations, and vendored text lists only the entries ADR-004 names. Those are `PLANIFEST_SESSION_ID`, the old boot-file markers and ignore-file headers, the old em-dash sentinel, the two old enforcement paths, the `.planifest-session` delete, the old-marker stop checks, and the migrator mapping.
- Brand guard allowlist: each entry carries a reason and a path regex. The whole-file entries (`.` as the line regex) cover only the guard, the 0.37.0 migration, the 0000039 suites, `_reference/`, and `external-skills/`. All match the req-007 list.
- Docs against code: `docs/architecture-overview.md:475`, `docs/decisions-index.md:414`, and the setup-hook-integration `interface-contract.md:79` and `data-contract.md:36` match the built behaviour (setup stops while an old marker exists).
- Migration guide against helper: step 4 and step 5 text matches the helper logic for the temporary-file clean-up, the name allowlist, and the probe file. The `.sh` and `.ps1` parity cases pass.
- Deviation review: rows 1 to 15 are classified, and the destructive rows are on the exception list with a recorded basis.

## Exit condition

Approval needs X-001 closed with a test that runs or parses the `.ps1` helper under Windows PowerShell 5.1, and X-002 closed with a re-verification at HEAD. X-003 to X-006 are not blocking, but fix X-003 under Hard Limit 7 in the same pass.
