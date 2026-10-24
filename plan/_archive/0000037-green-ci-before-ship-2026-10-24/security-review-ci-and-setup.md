# Security review: CI workflow, test runner, and Windows setup

**Feature:** 0000037-green-ci-before-ship
**Phase:** P5
**Reviewer:** fresh-context security reviewer
**Diff reviewed:** `git diff c8b1036..HEAD -- . ':!plan'`
**Overall risk rating:** Medium

The surface holds no Critical or High finding. Four Medium findings need a decision before ship. Neither 0000204 nor 0000209 blocks this release.

## Counts

| Severity | Count |
|----------|-------|
| Critical | 0 |
| High | 0 |
| Medium | 4 |
| Low | 6 |

## Method

I read the workflow, `run-tests.sh`, the `setup.ps1` diff, every `SKIP (windows)` guard, the skip table, the credential test diff, the credential script, and PR #64. I ran the shard parser against a copy of `run-tests.sh` in the scratchpad with dummy suites. I did not run anything on Windows. Where a finding about Windows rests on reading code, it says so.

## STRIDE table

| Threat | Category | Severity | Mitigation | Finding |
|--------|----------|----------|------------|---------|
| A fork PR runs the workflow and reads secrets or writes to the repository | Elevation | Low | The trigger is `pull_request`, not `pull_request_target`. Fork runs get a read-only token and no secrets. No job uses `secrets.*`. Two older jobs set no `permissions:` block. | F-05 |
| Branch name or PR title injects shell through `${{ }}` | Tampering | Low | Matrix values are static literals. `github.base_ref` is the only user-influenced context, and the trigger limits it to `main` or `master`. | F-05 |
| A moved `actions/checkout@v4` tag runs altered code | Tampering | Low | Not mitigated. All five checkouts use the tag. | F-05 |
| A Windows shard passes having run zero suites | Tampering | Medium | The matrix is static and the dummy-suite test covers valid values. The runner does not fail on zero suites or on `08` and `09`. | F-01 |
| A shard count drifts from the shard list and drops suites | Tampering | Low | A text test counts seven shard entries and the literal `7`. No check proves the shards cover every real suite. | F-01 |
| A Windows leg times out and reads as pass | Repudiation | Low | `timeout-minutes` is set per job. A timeout gives `cancelled`, which R-006 maps to unknown. | none |
| `setup.ps1` reports guardrails active when `core.hooksPath` is unset | Repudiation | Medium | Not mitigated. | F-02 |
| A crafted `settings.json` breaks the converter | DoS | Low | `Test-SettingsFileReadable` rejects invalid JSON and over-deep input first. A very large array makes the converter slow. | F-09 |
| Credential rule regresses and the guard test still passes | Info disclosure | Medium | Four patterns run against fixtures. Six rules have no runtime fixture. | F-03 |
| A credential reaches the draft PR title or body | Info disclosure | Low | Orchestrator scans both files before `gh pr create`. Regex only, because `gitleaks` was absent. | F-08 |
| Git Bash style absolute path in a Bash command passes the shell guard | Elevation | Medium | Not mitigated. Filed as 0000204. | F-04 |
| Link swapped in after `lstatSync` on Windows is followed | Elevation | Low | Not mitigated. Filed as 0000209. | F-06 |
| Windows skips hide untested link handling in enforcement code | Elevation | Low | Each skip has a table row and a backlog entry. | F-07 |
| Windows runs cost up to 7 x 20 minutes per PR | DoS | Low | `fail-fast: false` and per-job caps. First-time fork contributors need approval. | F-10 |

## Findings

### F-01 (Medium): shard parser fails open and a zero-suite shard passes

**Where:** `planifest-framework/tests/run-tests.sh:26-33` (validation) and `:44` (`in_shard`).

**Evidence:** I ran the parser with dummy suites.

- `PLANIFEST_SHARD_INDEX=08 PLANIFEST_SHARD_COUNT=09` prints `value too great for base`, runs no suite, and exits 0 with `0 passed, 0 failed`. Bash reads a leading zero as octal, so `08` and `09` fail the arithmetic at line 44. The `-lt` and `-gt` tests at line 30 accept them as decimal, so validation passes.
- `PLANIFEST_SHARD_INDEX=9 PLANIFEST_SHARD_COUNT=9` against three suites also exits 0 with no suite run.
- `PLANIFEST_SHARD_COUNT=99999999999999999999` makes the `[` test print `integer expression expected`. It returns status 2, which the `if` reads as false, so validation passes. The modulo then wraps.

The workflow sets static values 1 to 7, so no attacker reaches this today. The risk is drift. A future edit such as a `shard: 08` entry turns a Windows shard green while it tests nothing. This feature exists to make green CI mean something.

**Fix:** Strip leading zeros, or force base 10 with `10#$SHARD_INDEX` and `10#$SHARD_COUNT`. Reject values over 4 digits. After both loops, if `SHARDED` is 1 and the count of suites run is 0, print a message and `exit 2`. Print the suites-run count in the summary so a reviewer sees it. Add dummy-suite cases for `08 09` and for an index above the suite count to `test-0000037-req-010-windows-git-bash-leg.sh`.

**Nested runs:** The runner unsets both variables at line 25 before it validates them. A nested runner on a fixture does not inherit the shard. A suite at `test-0000037-req-010-windows-git-bash-leg.sh:117-122` checks this. No finding.

### F-02 (Medium): setup.ps1 hides a failed `git config` and prints success

**Where:** `planifest-framework/setup.ps1:786-796`.

**Evidence:** The call is `git config core.hooksPath planifest-framework/hooks 2>&1 | Out-Null` under `$ErrorActionPreference = 'Continue'`. The code never reads `$LASTEXITCODE`. Line 796 then prints `+ git config core.hooksPath ...` and line 831 prints `Git guardrails activated`. If `git config` fails, `core.hooksPath` stays unset. The blocking `commit-msg` hook then never runs, and setup still reports success. A failure has several causes: no repository, a locked `.git/config`, or a read-only `.git`. `setup.sh:700-703` prints a warning for the same case, so the two scripts disagree.

The relaxed preference is scoped correctly. A `try/finally` restores it, and it covers one statement only. The fault is the missing exit-code check.

**Fix:** Capture the output with `$out = git config ... 2>&1`, then test `$LASTEXITCODE -ne 0`. Print `! Warning: not in a git repository, skipping core.hooksPath config` or the captured text, and skip the success line. Do not stop setup, to match `setup.sh`. Add a case to `test_setup.ps1` that runs setup in a folder with no `.git` and expects the warning.

### F-03 (Medium): credential guard tests lost coverage of some refusal rules

**Where:** `planifest-framework/tests/test-0000033-req-013-clean-close-out.sh:132-148, 182-198` and the same lines in `planifest-framework/tests/regression/test-0000033-req-013-clean-close-out.sh`.

**Evidence:** The two files differ only in relative paths, so they carry identical logic. The old assertions matched the full inline `grep` string, which named every pattern including `-----BEGIN .*PRIVATE KEY-----`. The new assertions check that `credential-scan.mjs` source contains some pattern strings and run four fixtures.

- Runtime fixtures cover `AKIA`, `github_pat_`, `sk-`, and `AIza` only (lines 164-166, 190-193).
- `ghp_` and `xox` are matched as text in the script source only (line 146). A comment holding the string would satisfy them.
- `grep -rn "PRIVATE KEY" planifest-framework/tests` finds no file. The `private-key-block` rule has no assertion left anywhere.
- Name rules `id_rsa*`, `*.p12`, `*.key`, `.npmrc`, `credentials.json`, `*.keystore`, and `.netrc` are checked as skill text. `test-0000037-req-003-credential-scan.sh:121-126` runs only `.env` and `*.pem` at runtime.
- `scan_hits` counts exit 1 only. An exit 2 (scan could not run) reads as no hit. The positive fixtures would fail then, so this is safe for them.

The guard still refuses what it refused. The test no longer proves it for six content and name rules. A bad edit to `CONTENT_RULES` or `NAME_RULES` in `planifest-framework/scripts/credential-scan.mjs:27-47` would pass.

**Fix:** Add one fixture file per remaining rule to `test-0000037-req-003-credential-scan.sh` and assert `{path}:{line} {rule}` for each. Build secret strings by concatenation so the test file does not match its own rules. Replace the source-text assertions for `ghp_` and `xox` with those fixtures.

### F-04 (Medium): backlog 0000204, Git Bash style paths read as outside the repository

**Where:** `planifest-framework/hooks/enforcement/path-rules.mjs:248-261, 395-407`. No `win32`, `msys`, or `/c/` handling exists in any file under `hooks/enforcement/`.

**Evidence:** Node on Windows resolves `/c/proj/src/a.js` to `C:\c\proj\src\a.js`. That is outside the project root, so the hook applies "paths outside the repository are never gated". I read this from code and from the CI failure in 0000204. I did not run it on Windows.

Real-world severity for a Windows user:

- `gate-write` and `ratchet-check` receive `file_path` from the Write and Edit tools. Claude Code on Windows gives native `C:\...` paths there. If a tool did pass `/c/...`, the tool would resolve it the same way as the hook. Both would see the outside path, so no bypass. Low exposure.
- `shell-write-guard` parses paths out of Bash command text. Claude Code on Windows runs Bash through Git Bash, where `/c/proj/src/a.js` names the real project file. A command such as `echo x > /c/proj/src/a.js` writes inside the repository, and the guard reads the target as `C:\c\proj\src\a.js`. This path is plausible because agents often write `/c/...` paths in Git Bash.
- The guard is a heuristic. Hard Limit 8 and the Write-or-Edit rule stay as the primary control. The bypass needs an agent that ignores that rule.

**Verdict:** Medium for Windows users, because it weakens the shell guard. It does not block this release. The guard is documented as a heuristic, and the fix needs its own design decision. Keep 0000204 open and schedule it soon.

**Fix:** In `path-rules.mjs`, on `process.platform === 'win32'`, translate `^/([a-zA-Z])/` to `$1:\` and `/tmp` to the temp directory before resolving. Apply it to the Bash command paths in `shell-write-guard.mjs` first. Add a Windows suite case that passes `/c/...` for a path inside the fixture.

### F-05 (Low): workflow permissions, checkout pinning, and `base_ref` in `run` (backlog 0000218)

**Where:** `.github/workflows/planifest.yml:8` and `:52` (no `permissions:`), `:11, 55, 94, 110, 136` (`actions/checkout@v4`), `:17-18` (`${{ github.base_ref }}` in `run`). The consumer copy `planifest-framework/hooks/planifest.yml:17-18` has the same expansion.

**Evidence:** The `pull_request` trigger on a fork gives a read-only token and no secrets, whatever the default scope. In a same-repository PR, the two older jobs take the repository default, which may be read and write. `test-suite`, `setup-powershell`, and `setup-powershell-51` each set `contents: read`, so R-011 holds for new jobs. The `base_ref` expansion is safe while `branches: [ main, master ]` stays. Matrix values and `matrix.shard && 7 || ''` use no attacker input.

**Fix:** Add a top-level `permissions: contents: read`. Pin `actions/checkout` to a commit SHA. Pass `base_ref` through `env:`. Tracked as 0000218 because the lines pre-date this feature.

### F-06 (Low): backlog 0000209, symlink swap with no `O_NOFOLLOW` on Windows

**Where:** `planifest-framework/hooks/enforcement/path-rules.mjs:764-767`.

**Evidence:** A link already in place is caught by `lstatSync`. The gap is the interval between `lstatSync` and `open`. An attacker needs write access to `plan/current/` and the privilege to create a symlink on Windows, which needs Developer Mode or elevation. The window lasts microseconds. The outcome is that the gate reads another file as `design.md`. The agent is the only realistic actor, and it has the Write tool already for `plan/`.

**Verdict:** Low. It does not block this release. Keep 0000209 open. The suggested fix in the entry is sound: compare `dev` and `ino` after the open.

**Fix:** After `openSync`, call `fstatSync(fd)` and `lstatSync(path)`. Treat the file as non-regular if `dev` or `ino` differ. Then remove the Windows guard at `tests/test-0000036-req-008-non-regular-design-md.sh:336`.

### F-07 (Low): Windows skips leave link handling in enforcement code untested

I judged each skip. Most skips build an NTFS-only case that cannot occur on Windows (`chmod`, FIFOs, newline or colon file names, deleting the current directory). Those hide nothing real. Two groups matter.

- **Link cases:** `test-0000035-req-005-ratchet-check-shared-root.sh:113` (10-link chain and link loop), `test-0000035-req-008-sanctioned-scripts.sh:93, 173, 206, 341, 505, 517, 567, 594, 622`, `test-0000033-req-001-run-mode-script.sh:189`, `test-0000033-req-012-archive-script-without-glob-delete.sh:216`, `test-0000033-req-017-join-owner-and-reconciliation.sh:215`, and `test-0000030-req-004-install-clean-up-and-retired-flags.sh:409`. Git Bash `ln -s` copies, so the link refusals in `path-rules.mjs` and the sanctioned scripts (Hard Limit 8) have no Windows coverage. NTFS junctions need no privilege (`cmd /c mklink /J`), so a Windows user can create the case. Severity Low, because the code path is shared with the Linux and macOS runs.
- **Forged names:** `test-0000035-req-005-ratchet-check-shared-root.sh:192, 205` skip the control-character sanitising of block reasons. The sanitiser is plain string code that Linux and macOS exercise. Low.

The remaining skips (`chmod 555/000`, mode bits, FIFO, cwd deletion, gitleaks stand-in, bare `.mjs`, newline folder name, git shim) are test-fixture limits. They are tracked in 0000208, 0000210, 0000211, and 0000212.

**Fix:** In the link suites, build the case with `cmd //c mklink //J` on Windows for directory links, and drop the skip where it works. Keep the skip table row for file symlinks.

### F-08 (Low): draft PR text differs from the design text and the scan was regex only

**Where:** PR #64 body, `plan/current/design.md:35-38`, build-log line `Credential scan (P3)`.

**Evidence:** The step is sound. It writes the title and body to files outside the repository, scans both, then runs `gh pr create --draft --body-file`. PR #64 is a draft and holds no credential, no attribution line, and paths only. The posted body has a second paragraph that the design text does not give. The build log records the scan result but not a hash of the scanned file, so a reviewer cannot prove the posted text equals the scanned text. The log also notes `gitleaks not found`, so only regex rules ran (R-008).

**Fix:** In the draft PR step, log `sha256` of each scanned file and re-read the PR body with `gh pr view --json body` after creation to compare. Update the design text to match the body that the orchestrator uses. P9 Step 10 rescans the final body, which closes the gap at ship.

### F-09 (Low): `ConvertTo-PlanifestHashtable` slows on large arrays and collapses case-variant keys

**Where:** `planifest-framework/setup.ps1:411-433`, with the rewrite at `:456`.

**Evidence:**

- Deep nesting: `Merge-AllowedTools` calls `Test-SettingsFileReadable` first (line 81-87). Both PowerShell versions reject over-deep JSON there, and the file stays unchanged. Fails closed.
- Huge arrays: `$items += , (...)` copies the array on each item, so time grows with the square of the length. A 100,000-item array stalls setup for minutes. The file belongs to the person running setup, so this is a self-inflicted slowdown.
- Odd types: scalars, nulls, and empty arrays pass through. Hashtable keys are case-insensitive, so `Agent` and `agent` collapse and one value is lost. Depth over 10 and non-object roots lose data. See backlog 0000219.
- `[char]0x2705` at line 831 is correct on 5.1 and 7. No finding.

**Fix:** Use `[System.Collections.Generic.List[object]]` and `.Add()` in the converter. See 0000219 for the data-loss cases.

### F-10 (Low): stale cost and README wording

**Where:** `plan/current/risk-register.md` R-013 and `planifest-framework/tests/README.md:54`.

**Evidence:** R-013 states the cost as 20 or 30 minutes per PR. After ADR-014 the worst case is seven Windows shards at 20 minutes, plus two 10-minute PowerShell jobs, plus the Linux and macOS legs. That is about 160 runner-minutes. README line 54 says a skipping suite "returns exit 0 early". The guards skip single checks in most suites, and the table rows say so.

**Fix:** Restate R-013 with the new figure. Reword README line 54 to "skips the checks it names and runs the rest".

## Risk register cross-reference

| Risk | Status after this review | Note |
|------|--------------------------|------|
| R-001 Git Bash leg fails many suites | Mitigated | Each skip has a table row and a backlog entry. F-04, F-06, and F-07 stay open as hardening. |
| R-002 PowerShell 5.1 differences | Partly mitigated | The 5.1 job and converter cover JSON. F-02 shows a gap in the guardrails step. |
| R-003 Credential scan false positives | Open | No change. |
| R-004 Slow runner | Open | Out of this surface. |
| R-006 Cancelled reads as pass | Open | A workflow timeout gives `cancelled`. The ship-skill mapping is outside this surface. |
| R-008 Scan misses a credential without `gitleaks` | Open | The draft PR scan was regex only (F-08). Test gaps in F-03. |
| R-009 PR body changes after the scan | Mostly mitigated | Draft PR text outside the repository was scanned. F-08 notes no hash. |
| R-010 Scan log copies the credential | Mitigated | `credential-scan.mjs` prints `{path}:{line} {rule}` and `safePath` strips unsafe characters. |
| R-011 New job gains secrets or permissions | Mitigated for new jobs | The two older jobs have no `permissions:` block (F-05). |
| R-012 Windows legs before the amending ADR | Mitigated | ADR-012 exists. |
| R-013 CI minutes | Open and stale | Restate it (F-10). |
| R-014 Consumer workflow unchanged | Open | F-05 applies to it too. |
| R-016 Test passes on macOS, fails on Windows | Partly mitigated | Windows now runs in CI. Skips in F-07 leave gaps. |
| R-017 Migration test skips without tags | Open | Out of this surface. |
| R-023 Git Bash cap | Mitigated | ADR-014 sets a 20-minute cap and seven shards. F-01 covers the shard parser. |
| R-024 Draft PR shows unfinished branch | Mitigated | PR #64 is a draft with a path-only body. F-08 notes one drift. |

No new risk ID is added, because the register is outside my write scope. The orchestrator can add F-01, F-02, and F-04 as R-025 to R-027.

## Summary

Top actions before ship:

1. Fix the shard parser so `08`, `09`, and a zero-suite shard fail (F-01).
2. Check `$LASTEXITCODE` after `git config core.hooksPath` and warn on failure (F-02).
3. Add runtime fixtures for the six uncovered credential rules (F-03).

Backlog filed: 0000218 and 0000219.
