# Security Report - 0000032-governance-continuity-and-write-gate-scope

Two parallel reviews produced this report. One attacked the enforcement hooks with real fixtures and exit codes. The other covered setup scripts, skill text, the migration, boot templates, secrets, and dependencies.

## Threat Model (STRIDE)

### Medium

| ID | Threat | Category | Severity | Mitigation |
|---|---|---|---|---|
| F1 | A planted root marker moves the root. `touch plan/x/.git` passes because `plan/` is always permitted. After `cd plan/x`, `gate-write` and the shell guard treat the real `src/` as outside and pass it. The pre-0000032 gate blocked it. (`path-rules.mjs` `resolveRoot`) | Tampering, Elevation of privilege | Medium | Prefer `CLAUDE_PROJECT_DIR` when set. Otherwise take the outermost ancestor holding `planifest-framework/`, then the nearest `.git`. Never accept a marker inside an always-permitted prefix. |
| F2 | A `cd` that never runs still moves the shell guard's base. `false && cd /tmp; echo hi > src/x.js`, `(cd /tmp); …`, and `cd /tmp \| true; …` all pass. (`shell-write-guard.mjs:486-493`) | Tampering | Medium | Judge each relative target against both the starting base and the tracked base, and block if either blocks. Restore the base at `)`, `\|`, `\|\|`, and `&`. |
| K-1 | Resume step 2a uses the sentinel's text unchecked. `../../x` or `*` sends the archive glob outside `plan/_archive/`, and the ID later reaches `git commit` and `git tag` commands. (`planifest-orchestrator/SKILL.md:78-79`) | Tampering, Elevation of privilege | Medium | Check the ID against `^[0-9]{7}-[a-z0-9-]+$` or `pending` before use, and stop on a mismatch. Confirm the chosen directory sits inside `plan/_archive/`. Quote the ID in commands. |
| K-2 | The P9 marker step runs `git add plan/_archive/`, which stages stray changes in other features' archives. (`planifest-ship-agent/SKILL.md:160`) | Tampering, Information disclosure | Medium | Stage only this feature's archive directory, after a `git status --porcelain plan/_archive/` check. |
| K-3 | The P9 marker step deletes the markers before it commits. An interruption in that window leaves no sentinel, so step 2a never fires and the unfinished close-out goes unreported. (`planifest-ship-agent/SKILL.md:152-161`) | Repudiation | Medium | Delete, stage, and commit as one sequence right before `git commit`. Add a P0 check that flags an archive with `build-report.md` but no P9 commit. |

### Low

| ID | Threat | Category | Severity | Mitigation |
|---|---|---|---|---|
| F3 | Wrappers hide the writer: `command`, `env`, `sudo`, `nohup`, `xargs`, `time -p`, and `bash -c "…"`. | Tampering | Low | Strip wrapper prefixes, or list them as limits in the header and ADR-006. |
| F4 | Option clusters misparse: `cp -vt src/ a`, `perl -lpi -e … src/x`. | Tampering | Low | Walk short-option clusters one character at a time. |
| F5 | Arithmetic `<<` reads as a here-document and hides later lines. | Tampering | Low | Skip `((…))` and `$[…]` as one unit. Judge an unterminated here-document body as commands. |
| F6 | A dangling symbolic link in `plan/` writes into a gated path. The old gate had the same gap. | Tampering | Low | Follow link targets with `lstatSync` and `readlink`, with a hop limit. |
| F7 | Very deep paths take 15 to 45 seconds. A hook that runs past Claude Code's timeout fails open. | Denial of service | Low | Treat a path over 4096 characters or 256 segments as unjudgeable and warn. |
| F8 | 20,000 nested `"$(` overflow the stack and pass with no warning. | Tampering | Low | Cap nesting depth, or catch `RangeError` and warn. |
| F9 | A deleted `cwd` disables both gates. | Tampering | Low | Resolve the root from the nearest existing parent, or `CLAUDE_PROJECT_DIR`. |
| F10 | `$'…'` targets read as variables and pass with a warning. | Tampering | Low | Decode ANSI-C quoting as a literal. |
| F11 | A repeated target produces 1.7 MB of stderr. | Denial of service | Low | Remove duplicate reasons and cap at 20. |
| F12 | `ratchet-check.mjs` still uses `process.cwd()`, so a subfolder `cwd` disarms it. This predates 0000032. | Tampering | Low | Use `resolveRoot` and `toRootRelative`. |
| S-1 | Setup drops a whole Bash group if any hook in it is the guard, so a human hook in that group is lost. | Tampering | Low | Remove only the guard entry, and drop the group only when empty. |
| S-2 | A guard entry under a matcher such as `Bash\|Write` is never removed, so re-runs duplicate it. | Tampering | Low | Match any matcher that contains `Bash`. |
| S-3 | On Windows, shell writes through a PowerShell tool would skip a `Bash`-only guard. | Elevation of privilege | Low | Confirm the shell tool name Claude Code uses on Windows. |
| K-4 | The P9 marker step gives no rule for "nothing to commit". | Denial of service | Low | Skip the commit when nothing is staged and no marker is tracked. |
| K-5 | The post-P9 refusal is instruction only. `gate-write` still blocks code paths once `design.md` is archived. | Elevation of privilege | Low | Accept as residual risk. |
| M-1 | The boot file lists what the guard passes, including git commands. | Information disclosure | Low | Name `git checkout`, `restore`, `apply`, and `stash` in Hard Limit 8. |

### What held

- The shell guard blocked all 57 AC-8 writer forms tried, including `>|`, `&>`, fd redirects, `tee -a`, `sed -i` variants, quoting tricks, absolute paths, `cd` chains, separators, and subshells.
- `gate-write` passed or blocked correctly on case folding, `..`, the root itself, backslash paths, a `cwd` inside `plan/`, and symbolic links in both directions.
- All six hooks exit 0 on 60 malformed-input cases.

## Dependency Audit

No dependency manifest or lockfile changed. New code imports only `node:fs`, `node:path`, `node:os`, and local modules.

## Secrets Management

No credentials, tokens, private keys, or email addresses appear in the diff or `plan/current/`.

## Authentication & Authorisation Review

Not applicable. The feature exposes no API.

## Input Validation Review

Hooks treat stdin as untrusted and fail open on malformed input. The sentinel text is the one unvalidated input (K-1).

## Network Policy

No hook or script opens a network connection. The only process spawn is the existing `git` call in `ratchet-check.mjs`.

## Infrastructure as Code Review

Not applicable. The feature has no IaC.

## Risk Register Cross-Check

| ID | Status as implemented |
|----|-----------------------|
| R-001 | Mitigated by the false-positive corpus |
| R-002 | Accepted, but F2 to F5, F8, and F10 miss writes beyond the documented limits |
| R-003 | Mitigated in design. K-3 leaves an interruption window. |
| R-004 | Mitigated. S-1 and S-2 are edge cases. |
| R-005 | Mitigated for normal input. F7 breaks the target on crafted input. |
| R-006 | Mitigated. Stdout is unchanged. |
| R-007 | Accepted, but F1 widens it |
| Execution-plan A-001 to A-003 | Open. They can't be tested offline. Backlog 0000118 tracks a live check. |

## Re-review rounds

The human on the loop chose three fix rounds at the P5 gate. Two re-reviews and a final scripted check followed.

| Round | Fixed | New findings from the re-review |
|---|---|---|
| 1 | F1, F2, F4, F5, F7, F8, F11, K-1 to K-4 | N-1, N-2, N-4, N-5 (Medium), K-2 partial, N-3, N-6 to N-8 (Low) |
| 2 | N-1 to N-5, N-8, rest of K-2 | G-1 (Medium), G-2, G-3 (Low). A safety classifier stopped this review partway. |
| 3 | G-1, G-2 | None. Scripted exit-code checks covered the items round 2 didn't reach. |

The final check ran 103 exit-code cases across `gate-write` and the shell guard. One expectation was wrong, and every other case matched. Each hook's own work takes about 20 ms per call over Node start-up.

Residual risk:
- With `CLAUDE_PROJECT_DIR` unset, an agent can `cd` into another marked repository and write back by absolute path (ADR-004).
- The shell guard stays a heuristic with the limits in ADR-006. The boot rule sends code changes through **Write** or **Edit**.

Backlog: F3, F6, F9, F10, F12, S-1 to S-3, K-5, and M-1 (0000105 to 0000113). N-6, N-7, and the older `cd` gaps (0000114 to 0000116). G-3 (0000117).

## Summary

Overall risk rating: Low (Medium before the fix rounds)

Top actions before production: none open. Every Medium finding is fixed and verified. The Low findings are in the backlog.
