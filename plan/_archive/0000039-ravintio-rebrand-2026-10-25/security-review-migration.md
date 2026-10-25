# Security Report - 0000039-ravintio-rebrand (consumer migration)

Scope: the consumer migration that runs inside other people's repositories.

- `ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.sh`
- `ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.ps1`
- `ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.md`
- `ravintio-framework/skills/ravintio-migrator/SKILL.md` (old-path mapping, Applies when, check pass)

Reviewer: fresh-context security agent, 2026-10-25. The review read the code and ran both helpers in `mktemp -d` scratch repos with macOS Bash and PowerShell 7. Windows PowerShell 5.1 and real junctions were not available, so the 5.1 notes come from reading the code.

Overall rating: **Medium**. No finding can delete or overwrite a file outside the project. The prior-art High (PowerShell 5.1 `Remove-Item -Recurse` through nested junctions) can't recur, because neither helper holds a recursive delete.

## Findings

| ID | Severity | File and line | Finding |
|---|---|---|---|
| M-001 | Medium | `.sh` 36 and 107-136, `.ps1` 38-41 and 157, `.md` 44 | The rewrite renames consumer secret references |
| M-002 | Medium | `.sh` 280, `.ps1` 354, `.md` 101-103 | The branch protection warning names a check that never reports |
| L-001 | Low | `.sh` 87, 89, and 242, `.ps1` 135 | A target that appears after step 2 makes `mv` or `git mv` move into it |
| L-002 | Low | `.sh` 114, `.ps1` 161 | The pack path rewrite has no left boundary |
| L-003 | Low | `.sh` 203-206 | The rewrite resets the workflow mode to `644` |
| L-004 | Low | `.sh` 198, `.ps1` 154-166 | A file with no trailing newline, or with NUL bytes, gets rewritten |
| L-005 | Low | `.sh` and `.ps1`, whole file | Two runs at once have no lock |
| L-006 | Low | `.md` 107-109 | `git clean -x` deletes the backup |
| L-007 | Low | `.sh` 238-242, `.ps1` 289-303 | A pack held as a git submodule leaves a broken backup |
| L-008 | Low | `SKILL.md` 65-75, `migrate-product-yml-component-paths.md` 30 | The mapping scope is undefined, and one older body searches the whole project |
| L-009 | Low | `SKILL.md` 96-102, `.md` 113-124 | The check pass and the Migrator Instructions disagree |

### M-001 The rewrite renames consumer secret references

The `.md` says at line 44 that "a consumer secret or any other name keeps its old prefix". That is false for any consumer name whose suffix is on the pack list. The list holds generic suffixes such as `NAME`, `TMP`, `BOOT`, `DESIGN`, `GATE`, `TIER`, `TRIGGER`, and `SETTINGS`. The rewrite matches whole names anywhere in the file, including `secrets.` and `vars.` references.

Proof, in a scratch repo with both helpers:

```
before:  Z: ${{ secrets.PLANIFEST_NAME }}
after:   Z: ${{ secrets.RAVINTIO_NAME }}
```

The repository secret keeps its old name, so the step now reads an empty string with no error. A step that gates on a token, such as a scanner licence or a deploy key, can then skip its check or fail open.

Fix: in both helpers, skip a match whose preceding text ends in `secrets.` or `vars.`. In `.sh`, build `ctx = out substr(line, 1, i - 1)` before line 125. Treat the match as a non-match when `ctx` ends in `secrets.` or `vars.`. In `.ps1`, add `(?<!secrets\.)(?<!vars\.)` to the pattern at line 157. Add a fixture with `${{ secrets.PLANIFEST_NAME }}` that must survive. Then correct `.md` line 44 to state the rule exactly.

### M-002 The branch protection warning names a check that never reports

GitHub reports a required status check under the job name. The old and new workflows both name the job `validate-branch`. `Planifest Strict Pipeline` and `RAVINTIO Strict Pipeline` are workflow names, which branch protection never matches. The helper also leaves `name: Planifest Strict Pipeline` in the rewritten `ravintio.yml`. Setup then skips it because the file exists (`setup.sh` 803-807).

A consumer who follows the warning requires a check that never reports, so every pull request stays blocked. This is a denial of service on the consumer's merge path, and it inverts the R-007 mitigation.

Fix: change the warning at `.sh` 280, `.ps1` 354, and `.md` 101-103 to say the required check name `validate-branch` is unchanged. If the design wants the workflow renamed, add `name:` to the step 4 rewrite as an exact first-line match `name: Planifest Strict Pipeline`. Update R-007 to match.

### L-001 A target that appears after step 2 makes `mv` or `git mv` move into it

Step 2 checks that each target is absent and not a link. The move runs later. If a folder or a link to a folder appears at the target in between, Bash `mv` and `git mv` move the source inside it. The target could then sit outside the project. `System.IO.Directory.Move` and `File.Move` refuse an existing target, so the `.ps1` plain-rename path is safe. The `.ps1` `git mv` path at line 135 is not. The attacker needs write access to the project, so the practical risk is low.

Fix: just before each move at `.sh` 87, 89, and 242 and at `.ps1` 135, re-check `present "$2"` (or `Test-Present $Dst`) and stop if it holds.

### L-002 The pack path rewrite has no left boundary

`index(line, "planifest-framework/")` also matches `my-planifest-framework/` and `org/planifest-framework/`. The scratch run turned `my-planifest-framework/z` into `my-ravintio-framework/z`. A `uses: org/planifest-framework/...@ref` line would then fetch a different repository.

Fix: rewrite only when the match starts the line or follows one of these characters: space, tab, `.`, `/`, `"`, `'`, or `=`. When it follows `/`, also require that the text before that `/` is `.` or empty. That keeps `./planifest-framework/` and excludes `org/planifest-framework/`.

### L-003 The rewrite resets the workflow mode to `644`

`mktemp` creates the file as `600`, and line 205 forces `644`. A `600` or `755` workflow changes mode, and git records a mode change. On Windows, `File.Replace` keeps the destination's attributes, so the twins differ.

Fix: copy the mode before the rename with `chmod "$(stat -c %a "$NEW_WF" 2>/dev/null || stat -f %Lp "$NEW_WF")" "$TMP"`.

### L-004 A file with no trailing newline, or with NUL bytes, gets rewritten

Both helpers rebuild the file line by line and end each line with a newline. A file with no trailing newline gains one and reports `rewrote the pack path`, though it held no old name. BSD `awk` truncates a line at a NUL byte, so a UTF-16 file would be damaged.

Fix: skip the rewrite unless the file holds `planifest-framework/` or `PLANIFEST_` (`grep -q`, or `.Contains` in `.ps1`). Stop with exit 1 if the file holds a NUL byte.

### L-005 Two runs at once have no lock

Two runs can both pass step 2. The second then fails a move with exit 1, or appends `.ravintio-backup/` to the exclude file twice. No data is lost, because every move is a rename and both runs refuse a clash.

Fix: take `mkdir .ravintio-migrate.lock` at step 1 and remove it on exit with a `trap`, or `try` and `finally` in `.ps1`. Stop with exit 1 if the lock exists.

### L-006 `git clean -x` deletes the backup

The helper lists `.ravintio-backup/` in `.git/info/exclude`. `git clean -fdx` and `-fdX` delete ignored files, so they delete the only copy of any custom file in the old pack.

Fix: add one sentence to `.md` Backup clean-up and to the step 7 message. It should say that `git clean -x` deletes the backup.

### L-007 A pack held as a git submodule leaves a broken backup

The scratch run with the old pack as a submodule removed the gitlink and moved the folder. The moved `.git` file still says `gitdir: ../.git/modules/planifest-framework`, which no longer resolves. `.gitmodules` keeps the old entry. Local submodule commits stay in `.git/modules/`, so nothing is lost, but the backup can't show them.

Fix: in step 2, stop with exit 1 when `git ls-files -s -- planifest-framework` shows mode `160000`. Tell the human on the loop to run `git submodule deinit` and `git rm` first.

### L-008 The mapping scope is undefined, and one older body searches the whole project

`SKILL.md` line 69 applies the mapping to "a migration shipped before 0.37.0". No list or field says which files those are. An agent that applies it to the rename migration reads its Applies when line as `ravintio-framework/`, which is always true.

`migrate-product-yml-component-paths.md` line 30 searches the whole project for `component.yml`, except `node_modules/` and `.git/`. It would find `.ravintio-backup/planifest-framework/component.yml`. Only the general rule at `SKILL.md` line 75 keeps the agent out. Each proposal still needs the human on the loop to confirm it.

Fix: list the mapped migrations by name in `SKILL.md`, or define them as every migration except `migrate-0.37.0-ravintio-rename.md` and later. Add `.ravintio-backup/` to every search, glob, and scan the migrator runs.

### L-009 The check pass and the Migrator Instructions disagree

`SKILL.md` check pass step 1 says to confirm the old folders are gone. It gives no action if they are still there. The `.md` Migrator Instructions run the helper and then setup. The check pass runs no setup.

Fix: make the `SKILL.md` check pass defer to the `.md` Migrator Instructions. If the old folders are still present, run the helper as a normal run.

## Threat Model (STRIDE)

| Threat | Category | Severity | Mitigation |
|---|---|---|---|
| A link or junction at a moved path sends a move or write outside the project | Tampering | Low | Mitigated. Step 2 refuses links at every moved path, dangling or not (`.sh` 151-155, `.ps1` 180-184). A parent link skips its step. A plain rename moves nested links as links. |
| A recursive delete follows a nested junction (prior art) | Tampering | Low | Mitigated. No recursive delete exists. The only delete is the session marker, after a link check (`.sh` 222-225, `.ps1` 270-274). |
| A target appears between the step 2 check and the move | Tampering | Low | Not mitigated for `mv` and `git mv` (L-001). |
| The rewrite changes consumer-owned names | Tampering | Medium | Not mitigated (M-001, L-002). |
| The exclude write follows a link | Tampering | Low | Mitigated. `info/` and `info/exclude` link checks (`.sh` 252, `.ps1` 316-323). `.git` itself is not checked, but git owns that path. |
| Command injection through a path or git output | Elevation | Low | Mitigated. Every path is a constant. git output (`--git-path`) is only quoted and passed as one argument. |
| The old pack is lost | Denial of service | Low | Mitigated by rename into a backup. `git clean -x` remains a gap (L-006). |
| Branch protection blocks every merge | Denial of service | Medium | Not mitigated (M-002). |
| A concurrent run or a wrong folder | Denial of service | Low | Step 1 needs `ravintio-framework/` in the current folder, so a wrong folder stops at once. Concurrency has no lock (L-005). |
| An older migration reads the backup as a live pack | Information disclosure | Low | Partly mitigated by `SKILL.md` 75 (L-008). |

## Specific checks

- **Removal or overwrite outside the project.** None found. Links at all moved paths and parent folders are refused or skipped. A project below its git top level works: the scratch run wrote `.ravintio-backup/` to `../.git/info/exclude`, and the pattern has no leading slash, so it matches. git pathspecs resolve against the current folder.
- **TOCTOU.** See L-001. The `rm -f` at `.sh` 225 is safe even if a link replaces the file, because `rm` removes the link and not its target.
- **Workflow rewrite.** The temp file sits in the same folder. Its name does not end in `.yml`, so a leftover file never runs as a workflow. `.ps1` reads and writes ISO-8859-1, so bytes survive, and the output matched `.sh` byte for byte in the scratch run. CRLF lines keep their `\r` in both. The rewrite reads no secret value. See M-001, L-002, L-003, and L-004.
- **`.git/info/exclude`.** One append, guarded by an exact-line check. A linked worktree resolves to the shared exclude file, which is correct. If `git rev-parse` prints nothing, both helpers stop at step 6 with exit 1 after the moves. A rerun then resumes.
- **Command injection.** None. All names are built from constants.
- **Run twice.** The scratch rerun printed `Nothing to do` and exited 0 in both shells. Running `.sh` after `.ps1` also exited 0.
- **Old pack loss.** Not lost in any tested path. A `git reset --hard` after step 6 restores the old pack from `HEAD`. The next run then stops on the backup clash and moves nothing.
- **PowerShell 5.1 versus 7.** The file is pure ASCII, so 5.1 reads it without a BOM. Link detection uses `Get-Item -Force` and `ReparsePoint`, with a parent listing for a dangling link on 5.1. `NullString` exists on 5.1. `Directory.Move` renames a nested junction as a junction on both. Every .NET call uses a full path from `Get-Location`, so a stale `[Environment]::CurrentDirectory` can't misdirect it. The 5.1 leg must still run in CI, as R-004 states.

## Dependency Audit

The helpers call `git`, `awk`, `mktemp`, `cmp`, `mv`, `chmod`, and `tail`. The `.ps1` uses .NET base classes only. No package dependency exists.

## Secrets Management

The helpers hold no credential and read no secret value. M-001 is the one secrets risk, which breaks a consumer's secret reference.

## Authentication and Authorisation Review

Not applicable. The migration exposes no API.

## Input Validation Review

The inputs are the file system layout, the workflow text, and git output. The layout checks are sound, apart from L-001 and L-007. The workflow text needs the bounds in M-001, L-002, and L-004.

## Network Policy

Not applicable. The helpers make no network call.

## Infrastructure as Code Review

The only IaC touched is the consumer's GitHub Actions workflow. See M-001, M-002, and L-002.

## Risk register cross-check

| Row | Status after review |
|---|---|
| R-004 | Mitigated in code. The PowerShell 5.1 CI leg is still needed to close it. |
| R-007 | Not mitigated. The warning names the wrong check (M-002). |
| R-008 | Mitigated in `SKILL.md`, with the gap in L-008. |
| R-011 | Mitigated. The helper removes `.planifest-session` only, as designed. |
| R-012 | Mitigated. `setup.sh` 1370-1377 stops while an old folder exists. |
| R-013 | Mitigated. The body lists all 28 names. |
| R-017 | Mitigated, with the over-reach in M-001 and L-002. |
| R-018 | Mitigated, apart from the race in L-001. |
| R-019 | Accepted. L-006 adds a gap the row doesn't name. |
| R-020 | Confirmed. The helper doesn't touch `core.hooksPath`. |

## Summary

Overall risk rating: **Medium**

Top actions before production:

1. Stop the step 4 rewrite from renaming `secrets.` and `vars.` references, and correct `.md` line 44 (M-001).
2. Correct the branch protection warning to name the `validate-branch` check (M-002).
3. Re-check each move target just before the move (L-001), and bound the pack path rewrite (L-002).
