# Security re-review - 0000039-ravintio-rebrand (marker rename)

Reviewer: fresh-context security agent, 2026-10-25. Scope: commits 0b23a3a4, 56b5c3a1, and 1b2d2c53.

Overall rating: **High**. The helpers keep a manifest entry when its parent resolves to the real skills folder. They don't check the last part well enough. Setup's unguarded prune in `setup.ps1` then reads some kept names as paths that point outside the skills folder (backlog 0000255). The helper is meant to write only checked entries, so this defeats its stated control.

Method:

- Read `git show` for each commit, the spec bullets, and the earlier reviews.
- Built a scratch project with a crafted `.planifest-manifest` and flags file. Ran both helpers in it: bash 3.2.57 and pwsh 7.6.8 on macOS.
- Fed the rewritten manifest to the same `Test-Path` call that `setup.ps1` line 1321 uses, with a resolve in place of the delete.
- Nothing ran in the repo. Windows, Windows PowerShell 5.1, NTFS, and Git Bash were not available. M-002 and part of M-003 rest on documented .NET and Win32 path rules, not on a run.

## Findings

| ID | Severity | File:line | Description | Suggested fix |
|---|---|---|---|---|
| M-001 | High | `migrations/migrate-0.37.0-ravintio-rename.sh:168`, `migrations/migrate-0.37.0-ravintio-rename.ps1:251` and `:261` | On macOS and Linux, both helpers split an entry on `/` only. They reject a last part only when it is empty, `.`, or `..`. So `{skills}/..\..\..\victim` keeps the last part `..\..\..\victim`, and the helper writes `{real skills}/..\..\..\victim` (`.sh:406`, `.ps1:517`). PowerShell on Unix reads `\` as a separator. The scratch run resolved that line to `{project}/../victim`, outside the project. It resolved `{skills}/a\..\..\settings.json` to `.claude/settings.json`. `setup.ps1:1321-1322` then runs `Remove-Item -Recurse -Force` on it. Both helpers gave the same output. `setup.sh` treats the name as one literal part and is not affected. The `.claude/skills/` folder is not in the pack `.gitignore`, so a committed manifest can carry the entry. | Keep a last part only when it matches a strict allowlist, such as `^[A-Za-z0-9][A-Za-z0-9._-]*$` with no trailing `.`. Use the same rule in both twins. Fix 0000255 in the same change: `setup.ps1` should use `-LiteralPath` and the parent check that S-01 added. |
| M-002 | High | `migrations/migrate-0.37.0-ravintio-rename.ps1:517` | On Windows, an entry `.claude/skills/C:` passes `Get-KeptName`. The parent resolves to the skills folder, and the last part `C:` is not empty, `.`, or `..`. Line 517 builds the line with `[System.IO.Path]::Combine($rs, $name)`. .NET treats `C:` as rooted, so `Combine` returns `C:` and drops the skills folder. Then `setup.ps1:1321-1322` runs `Test-Path C:` and `Remove-Item -Path C: -Recurse -Force`, which acts on the current folder of drive C:. `D:` and `C:name` behave the same way. This was not run, because no Windows host was available. | Reject a last part that holds `:`. Build the line as `$rs + [IO.Path]::DirectorySeparatorChar + $name` rather than `Combine`. Then check that the line's parent is still the real skills folder before writing it. |
| M-003 | Medium | `migrations/migrate-0.37.0-ravintio-rename.sh:168`, `migrations/migrate-0.37.0-ravintio-rename.ps1:261` | Both helpers keep a last part such as `.. ` (dot, dot, space), `...`, or `*`. Win32 strips trailing spaces and dots from a path part. So on Windows, `setup.ps1` would read `{skills}\.. ` as `.claude\` and delete the whole tool folder, with its settings and hooks. That part was not run. `*` was run on macOS. `Test-Path` expanded it to every folder in the skills folder, because `setup.ps1:1321-1322` uses `-Path`, which reads wildcards. That stays inside the skills folder. | Use the M-001 allowlist. It rejects spaces, a trailing `.`, and the wildcard characters `*`, `?`, `[`, and `]`. |
| M-004 | Low | `migrations/migrate-0.37.0-ravintio-rename.sh:411-414`, `migrations/migrate-0.37.0-ravintio-rename.ps1:532-546` | Neither helper removes its temporary manifest when the run is stopped by an interrupt, such as Ctrl+C. A `.ravintio-manifest.XXXXXX` file stays in the skills folder. Setup lists only folders, so the file is never pruned or listed. The `.sh` `mv -f` would move the temporary file into `.ravintio-manifest` if a folder took that name after the `-f` check. That needs local write access during the run. Both shells create the temporary file with an exclusive create (`mktemp`, `FileMode.CreateNew`). Both replace by rename, so a planted link or hard link is replaced and never written through. | In `.sh`, add `trap 'rm -f -- "$TMP"' EXIT INT TERM` around the write, and check `[ -d "$MANIFEST" ]` again before `mv`. In `.ps1`, delete the temporary file in a `finally` block when `Replace` did not run. |

## Checks with no finding

- **Entries kept only inside the skills folder.** Both helpers dropped `/etc` and `{skills}/../x` with a warning. The earlier probes also covered an absolute path outside, `..`, and a linked parent. Each kept line is written as `{real skills}/{name}`, with links resolved part by part. `Get-RealPath` handles relative link targets, `..` after a link, and link loops (40 rounds). An entry name can't hold a newline, because both helpers read the file line by line.
- **Links at each part.** Step 2 and step 5 skip a tool folder when the folder, its `skills` folder, or any marker file is a link (`.sh:130-139`, `.ps1:176-186`). A kept name that is a link is renamed as a link. On re-run, `setup.sh:1069-1070` unlinks it without recursing, because the line has no trailing slash. `setup.ps1` 5.1 and junctions are covered by 0000255.
- **Case.** The `.ps1` helper compares paths without case on Windows and with case elsewhere (`.ps1:241-244`). On macOS, a differently cased parent fails the compare, and the helper drops the entry. A dropped entry is safe, because setup then deletes nothing for it.
- **Stop checks before any move.** Step 2 checks each flags and manifest clash and each `planifest-X` and `ravintio-X` pair (`.sh:270-300`, `.ps1:366-393`). `move_path` and `Move-Entry` check the target again just before each move.
- **Resume.** If a run stops after a folder rename and before the manifest rewrite, the next run finds `planifest-X` gone and writes `ravintio-X`. A finished run compares its output with the manifest and writes nothing.
- **Step 7.** The printed tool must equal one entry of the fixed setup tool list (`.sh:181-182`, `.ps1:290-291`). Each flag prints only as one of two fixed strings. No text from the flags file reaches the output, so a crafted file can't inject text. The helper skips a flags file that is a link.
- **Setup stop.** Both setups stop before their first write, with exit 1, when an old marker or a link to one exists (`setup.sh:1340-1349`, `setup.ps1:80-91`). They test all eight folders that hold a skills folder. Roo Code only prints an error. The skill subcommands run before the stop, but they don't read the old markers. If the human on the loop deletes the old flags file to get past the stop, setup loses the saved flags. `plan/.orchestrator-strict` stays, because setup never removes it. So strict mode is not silently lost.

## Top actions

1. Add one last-part allowlist to `kept_name` and `Get-KeptName`, and stop using `Combine` for the written line (M-001, M-002, M-003).
2. Fix backlog 0000255 in this feature. A guarded `setup.ps1` prune would make M-001 to M-003 harmless even with a bad manifest line.
3. Add a test case for each M-001 to M-003 entry form, run through both helpers.

## Re-review of the fixes

Reviewer: fresh-context security agent, 2026-10-25. Scope: commits 72ac382d and dae0eaf5.

Updated overall rating: **Medium**. The helpers now close M-001 to M-004. The fix to `Get-Full` brings in N-001. In a linked git worktree, the `.ps1` helper writes the exclude line to a stray file inside the project, so git doesn't ignore `.ravintio-backup/`. Backlog 0000255 is still open. It covers the unguarded prune at `setup.ps1:1319-1322` and `setup.sh:1068-1070`, so a manifest that the helper never wrote can still steer setup.

Method:

- Read `git show` for both commits and the current helper files.
- Ran both helpers on scratch fixtures with bash 3.2.57 and pwsh 7.6.8 on macOS. The fixtures held every M-001 to M-003 entry form, a CRLF manifest, and leftover temporary files of several shapes.
- Ran the `.ps1` helper with `OS=Windows_NT` to reach its Windows branches, including the probe file. That run used macOS paths and links. It is not a Windows run. Windows, junctions, 8.3 names, UNC paths, and Windows PowerShell 5.1 were not tested.
- Ran step 6 of both helpers in a project below the git top level and in a linked git worktree.
- Nothing ran in the repo.

### Status of M-001 to M-004

| ID | Status | Evidence |
|---|---|---|
| M-001 | Closed | `migrate-0.37.0-ravintio-rename.sh:175-176` and `migrate-0.37.0-ravintio-rename.ps1:281` keep a last part only when it matches `^[A-Za-z0-9][A-Za-z0-9._-]*$` and doesn't end in `.`. Both helpers dropped `{skills}/..\..\..\victim` and `{skills}/a\..\..\settings.json` with a `WARNING:` line, and both wrote the same manifest. The helper side is closed. The `setup.ps1` guard that M-001 also asked for is still backlog 0000255. |
| M-002 | Closed | The name rule rejects `:`. Both helpers dropped `C:`, `D:`, and `C:name`. The written line is now a string join, `$rs + DirectorySeparatorChar + $name` (`.ps1:594`), so a rooted name can't replace the skills folder. `Get-Full` no longer uses `Combine` either (`.ps1:70-74`). |
| M-003 | Closed | Both helpers dropped `.. `, `...`, `*`, `a.`, `a b`, `-x`, and `ok~1`. The rule has no space, wildcard, or trailing dot. Parity holds for `é`, the Kelvin sign U+212A, the fullwidth digit U+FF11, a tab, and a newline. Both twins dropped all of them. Bash lists its letters in full (`.sh:44-46`), and the `.ps1` twin uses `-cmatch` (`.ps1:49`), so no locale or case folding widens a range. |
| M-004 | Closed | `.sh:436` traps INT and TERM and removes the temporary file. `.sh:437-444` removes it on every failure path and checks `-d` and `-L` again before `mv`. The `.ps1` `finally` block removes it unless `Replace` ran (`.ps1:634-636`). A hard stop, such as SIGKILL or a closed terminal (HUP is not trapped), can still leave the file. The next run removes it in step 5 (`.sh:401`, `.ps1:566`). |

### Questions from the brief

- **Can the probe accept a parent outside the skills folder?** No. `New-Probe` gives the probe a random name and makes it with `CreateNew` in the real skills folder (`.ps1:297-307`). Only another path to that same folder, such as a link, an 8.3 name, or a share, can show it. `Test-Path -LiteralPath` reads no wildcards (`.ps1:288`). Even when the probe accepts a parent, the line written is the real skills folder joined with a checked name (`.ps1:594`). In the emulated run, `other/evil`, `/etc/passwd`, `\\localhost\nope\x`, and `{skills}/sub/inner` were dropped. `lnk/viaLink`, where `lnk` links to the skills folder, became `{real skills}/viaLink`.
- **Is the probe always removed?** On every normal path, yes. The `finally` blocks at `.ps1:462-463` and `.ps1:597-598` remove it. The emulated run confirmed removal after a full run and after `Stop-At` exited in step 2 on a `planifest-foo` and `ravintio-foo` clash. A hard stop of the process can leave it. Its name matches `TmpRe`, so the next run's step 5 removes it.
- **Does the step 2 probe break the "no write before the first move" promise?** Not in a way that matters. The probe is an empty file in the helper's own name space. Step 2 makes it and removes it, and it moves or changes no consumer file. If the skills folder is read-only, `New-Probe` returns an empty string, and the check falls back to the text compare. The docs don't mention the probe (see N-002).
- **Could the temporary-file clean-up delete a consumer file?** Only a regular file named exactly `.ravintio-manifest.` plus six ASCII letters or digits, directly in a tool's `skills` folder (`.sh:183-193`, `.ps1:317-331`). It skips links and folders. The fixture kept a five-character name, a seven-character name, a folder, and a link to a file outside the project. It removed only `.ravintio-manifest.abc123`. Setup writes no file with that name. So a consumer file is at risk only if the consumer picked that exact name.
- **Parity of the name rule.** The output was the same in both twins for every fixture. On macOS and Linux, the `.ps1` twin splits only on `/`, like the `.sh` twin. A `\` in a last part then fails the rule in both.

### Commit 72ac382d

`setup.sh:1192-1202` now writes each manifest line as the real skills folder joined with the folder name. That matches what the helper writes, so a second helper run writes nothing. If `cd -P` fails, setup keeps the old glob path. The prune at `setup.sh:1068-1070` deletes the same folders as before, because a real path names the same folder as the glob path. No new finding.

### New findings

| ID | Severity | File:line | Description | Suggested fix |
|---|---|---|---|---|
| N-001 | Medium | `migrate-0.37.0-ravintio-rename.ps1:70-74`, `:667-688` | `Get-Full` now joins its argument to the project root even when the argument is absolute. Step 6 passes the output of `git rev-parse --git-path info/exclude` to it. In a linked worktree that output is absolute. The run made the folder tree `{project}/private/tmp/.../main/.git/info/` inside the project and wrote `.ravintio-backup/` to an `exclude` file there. The real `.git/info/exclude` stayed unchanged, so git doesn't ignore the backup, and `git add -A` would stage the old pack. The `.sh` twin wrote the real file. On Windows the joined path holds a second drive colon, so step 6 is expected to stop after the pack move. That was not run. | Use the `git` output as is when `IsPathRooted` is true, or resolve it with `Combine` in step 6 only. Add a linked-worktree case to the tests for both twins. |
| N-002 | Low | `migrate-0.37.0-ravintio-rename.sh:7`, `migrate-0.37.0-ravintio-rename.ps1:6`, `migrate-0.37.0-ravintio-rename.md:14` | Both headers say the helper deletes no file except the session marker. The guide says the same. Both helpers now also delete leftover temporary manifests, and the `.ps1` helper makes and deletes a probe file on Windows. The guide doesn't describe the probe. | Update the three places to name the leftover temporary files and the Windows probe (boot Hard Limit 7). |
| N-003 | Low | `migrate-0.37.0-ravintio-rename.sh:46`, `migrate-0.37.0-ravintio-rename.ps1:49` | The rule keeps Windows device names such as `NUL`, `CON`, and `CON.txt`. Both helpers kept `{skills}/NUL` and `{skills}/CON.txt`. On Windows, `setup.ps1:1321-1322` would then run `Remove-Item -Recurse -Force` on a device path. That is expected to fail with an error and delete nothing. It was not run. | Drop a name whose part before the first `.` is `CON`, `PRN`, `AUX`, `NUL`, `COM1` to `COM9`, or `LPT1` to `LPT9`, ignoring case. |
| N-004 | Low | `migrate-0.37.0-ravintio-rename.ps1:230`, `:288` | This finding predates the fix. On Windows, a manifest entry with a UNC parent, such as `\\host\share\x`, makes `Get-RealPath` call `Get-Item` on the remote path before the entry is dropped. The probe check adds one more `Test-Path` to the same host. A committed manifest can so make Windows send the person's NTLM credentials to that host over SMB. This was not run, because no Windows host was available. | Drop an entry whose parent starts with `\\` or `//` before any lookup. |
| N-005 | Low | `migrate-0.37.0-ravintio-rename.sh:355-358`, `migrate-0.37.0-ravintio-rename.ps1:503-517` | Step 4 has the M-004 gap for the workflow file. A stop during the rewrite leaves `.github/workflows/.ravintio.yml.XXXXXX`, and no later run removes it. GitHub Actions doesn't run it, because the name doesn't end in `.yml`. It can still be committed by mistake. | Use the M-004 pattern in step 4: a trap or `finally` that removes the file, and a clean-up of leftover names. |

### Top actions

1. Fix N-001 before the P5 gate, and add a linked-worktree test for both twins.
2. Fix backlog 0000255 in this feature. A guarded prune in both setups would stop any bad manifest line, including one the helper never wrote.
3. Update the helper headers and the guide for N-002.
