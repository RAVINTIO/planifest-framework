# Security Report - 0000035-write-gate-scope-and-path-hardening

> Assembled by the orchestrator from two P5 reviews run in parallel on 2026-10-22. The gates review covers `path-rules.mjs`, `gate-write.mjs`, `shell-write-guard.mjs`, `ratchet-check.mjs`, and the scope record. The scripts review covers `set-product-release.mjs`, the `Sanctioned scripts:` sentence, and migration records. Finding IDs carry a `G-` (gates) or `P-` (scripts) prefix. Each review's probe scripts sit in the session scratchpad under `sec-gates/` and `sec-scripts/`.

## Threat Model (STRIDE)

### Write gates

| ID | Threat | Category | Severity | Mitigation | File and line |
|---|---|---|---|---|---|
| G-S01 | `resolveTarget` resolves `..` physically, but Claude Code's **Write** collapses `..` as text. With `docs/L -> ../plan/x/y`, `gate-write` judges `docs/L/../../src/a.js` as `plan/src/a.js` and passes it. **Write** lands in `src/a.js`. The same trick reaches `.claude/settings.json` under a scope record and skips the ratchet. `main` collapsed `..` first, so this is a regression. | Tampering / Elevation | High | Fix in progress | `path-rules.mjs:177-179`, `:217`, `:326`. `ratchet-check.mjs:211-212` |
| G-S02 | `isEnforcementPath` lowercases only. APFS folds `ſ` (U+017F) to `s`. Under a record for `.claude/` or `planifest-framework/`, `.claude/ſettings.json` and `planifest-framework/hookſ/…` pass, and **Write** replaces the real file. | Tampering / Elevation | High | Fix in progress | `path-rules.mjs:101-103`, `:457-470`, `:642` |
| G-S03 | The enforcement list omits `.github/workflows/planifest.yml`, which `setup.sh` installs and which enforces the `fix(fast-path)` commit rule. | Tampering | Medium | Fix in progress | `path-rules.mjs:426-451`, `workflows/fast-path.md` |
| G-S04 | Windows forms (`\\?\`, `\\.\`, UNC, trailing dots, `::$DATA`, 8.3 names) escape the root comparison or the enforcement list. Proved as string logic only. | Elevation | Medium | Deferred to backlog 0000144 (needs a Windows host) | `path-rules.mjs:168`, `:204-206`, `:298-305`, `:457-470` |
| G-S05 | With `CLAUDE_PROJECT_DIR` unset, a `planifest-framework/` folder inside a component becomes a nearer root. | Elevation | Medium | Partly mitigated when the variable is set (A-001). Backlog 0000146. Mostly predates 0000035. | `path-rules.mjs:258-261`, `:289-290` |
| G-S06 | With `CLAUDE_PROJECT_DIR` unset, an unreadable folder on the cwd path makes `resolveRoot` return `null`, and a `src/` write passes. | Elevation | Low | Accepted by ADR-006. Backlog 0000146. | `path-rules.mjs:289-292`, `:737` |
| G-S07 | A background shell job can swap a folder for a link between the hook verdict and the write. | Tampering | Low | Not mitigated. Inherent to PreToolUse hooks. | `path-rules.mjs:319-339` |
| G-S08 | The agent writes the scope record and reads the git state it binds to, so the binding limits staleness only. `.gitignore` hides a stale record from `git status`. | Spoofing / Repudiation | Medium | Accepted (R-002, R-005). Stderr notice and changelog list. | `path-rules.mjs:611-635`, `.gitignore:21-24` |
| G-S09 | A `.git` file's `gitdir:` and `commondir` can point anywhere, so the record validates against git state the agent controls. | Spoofing | Low | Accepted with G-S08. No disclosure, because error strings are fixed. | `path-rules.mjs:557-559`, `:574-575` |
| G-S10 | A hard link from `docs/` to `src/` passes both hooks. Claude Code's **Write** replaces the inode, so the `src/` file stays unchanged. | Tampering | Low | Mitigated for Claude Code by its write behaviour. Unverified for other tools. | `shell-write-guard.mjs` `ln` case, `path-rules.mjs:189-192` |
| G-S11 | Two reasons print `relPath` unescaped, so a target with a newline can forge an `admitted` line on stderr. | Repudiation | Low | Fix in progress | `path-rules.mjs:665`, `:717` |
| G-S12 | A folder or FIFO at `plan/current/design.md` makes the gate fail open or wait until the hook times out. | DoS / Elevation | Medium | Predates 0000035. Backlog 0000143. | `path-rules.mjs:701-707` |
| G-S13 | Link chains and loops. | DoS | Low | Mitigated. 40 hops in 46 ms. 41 hops and a loop block with exit 2. | `path-rules.mjs:194-197`, `:210` |
| G-S14 | Oversize or malformed record, `packed-refs`, or git files. | DoS | Low | Mitigated by the 16 KiB, 4 KiB, and 4 MiB caps. | `path-rules.mjs:409-417`, `:474-482`, `:619-621` |

### Release script, sanctioned scripts, and migration records

| ID | Threat | Category | Severity | Mitigation | File and line |
|---|---|---|---|---|---|
| P-S01 | YAML injection through newline, quote, backslash, U+2028, U+2029, NUL, or full-width digits. | Tampering | Low | Mitigated. 16 probes exited 2 and left `product.yml` byte-identical. | `set-product-release.mjs:53-64`, `:101-105` |
| P-S02 | `--root` points outside the repository. | Elevation | Low | Mitigated. | `set-product-release.mjs:111-137` |
| P-S03 | `CLAUDE_PROJECT_DIR` on the command line redirects the root. | Elevation | Low | Fix in progress | `set-product-release.mjs:118`, `path-rules.mjs:284-288` |
| P-S04 | A hard link at `{root}/product.yml` rewrites a file outside the root. | Tampering | Low | Fix in progress | `set-product-release.mjs:194-205`, `:294-304` |
| P-S05 | Check-then-use race between `lstat`, `readFileSync`, and `open`. | Tampering | Low | Fix in progress | `set-product-release.mjs:310`, `:314`, `:339` |
| P-S06 | `O_TRUNC` write isn't atomic, so a crash leaves `product.yml` empty or partial. | Tampering / DoS | Low | Fix in progress | `set-product-release.mjs:294-304` |
| P-S07 | EACCES and EISDIR escape as exit 1 with a stack trace and absolute path. | DoS / Info disclosure | Low | Fix in progress | `set-product-release.mjs:283`, `:298` |
| P-S08 | `components[].path` from an existing manifest skips the path rules, so `../` reads outside the root. | Info disclosure / Tampering | Low | Fix in progress | `set-product-release.mjs:274-286` |
| P-S09 | `promote-to-regression.sh` copies any existing file into the regression suite, and an environment variable can redirect the destination. | Elevation / Tampering | Medium | Fix in progress | `promote-to-regression.sh:22`, `:68` |
| P-S10 | The sanctioned sentence covers `setup.sh` with any arguments, including `add-skill`, which fetches remote content. | Elevation | Medium | Fix in progress | `standard-boot.md:14`, `cursor-boot.md:20`, `setup.sh:1247-1254` |
| P-S11 | `archive-current.mjs` accepts a free `--root`. It predates the feature, which now sanctions it. | Tampering | Low | Partly mitigated by its real-path checks. Backlog 0000142. | `archive-current.mjs:86` |
| P-S12 | `refresh-delete-boot-files.sh` and `.ps1`. | none | Low | Mitigated. No arguments and a fixed list of two files. | `refresh-delete-boot-files.sh:15-20` |
| P-S13 | Any agent can forge a `plan/_migrations/` record, because `plan/` is always permitted. A forged record stops a needed migration, such as the shell-write guard rerun. | Spoofing / Tampering | Medium | Accepted. Records show in the PR diff. Backlog 0000141 surfaces suspect records. | `planifest-migrator/SKILL.md:27`, `:45`, `:48`, `path-rules.mjs:50` |
| P-S14 | An agent can self-attest `not applicable` or `skipped` for a "Safe to skip: No" migration. | Repudiation | Low | Accepted. The body must name the reason. Backlog 0000141. | `planifest-migrator/SKILL.md:44-46` |
| P-S15 | `consistency-check.mjs` criteria limit. | none | Low | Governance only. | `consistency-check.mjs:65-73` |

## Dependency Audit

No new dependency. `set-product-release.mjs` imports `node:fs`, `node:path`, `node:url`, and the local `path-rules.mjs`. `path-rules.mjs` imports `node:fs` and `node:path` and spawns no process. The diff holds no package manifest or lockfile change. Nothing needs action.

## Secrets Management

No credential, token, or environment value appears in the new code, records, templates, or skills. `set-product-release.mjs` reads `CLAUDE_PROJECT_DIR` through `resolveRoot` and never prints it. Block reasons print at most 80 characters of the target and never link text. Before the P-S07 fix, stack traces showed the absolute repository path, which is information, not a secret.

## Authentication & Authorisation Review

Not applicable. The feature has no API. The write gates are the authorisation control under change. The scope record is accepted self-authorisation (R-005), bounded by the enforcement list.

## Input Validation Review

- **Scope record grammar:** holds. Line order, the 64-path and 16 KiB caps, `.` and `..` entries, absolute entries, and FIFO or folder records all behave as specified.
- **Target paths:** G-S01, G-S02, G-S04, and G-S11 are the gaps.
- **`set-product-release.mjs` arguments:** every req-008 pattern matches the code. Length caps apply before the regex. Repeated and unknown flags fail without echoing the value. P-S07 and P-S08 are the gaps.
- **`promote-to-regression.sh`:** no source path validation (P-S09).

## Network Policy

Not applicable. No network surface. `setup.sh add-skill` can fetch over HTTPS, which P-S10 removes from the sanctioned set.

## Infrastructure as Code Review

Not applicable. No IaC.

## Risk Register Cross-Reference

| Risk | Status | Evidence |
|---|---|---|
| R-001 latency | Mitigated | A 40-link chain judged in 46 ms. |
| R-002 stale record | Partly mitigated | Binding works. `.gitignore` hides a stale record (G-S08). |
| R-005 self-authorisation | Accepted, backstop under repair | G-S01, G-S02, and G-S03 bypass the enforcement list until fixed. |
| R-007 git state without spawn | Mitigated | Loose ref, `packed-refs`, and detached `HEAD` read. Unreadable state blocks. |
| R-008 worktree `.git` file | Mitigated | `gitdir:` followed but not confined (G-S09). |
| R-009 nested root | Mitigated | Only always-permitted segments count as planted. |
| R-011 fail-open scope | Mitigated in new code | G-S12 predates the feature. |
| R-012 deleted cwd | Partly mitigated | G-S05 and G-S06 pass with the variable unset. |
| R-014 unreadable record | Mitigated for damaged records | Doesn't cover a well-formed forged record (P-S13). |
| R-016 P7 stop before commit | Partly mitigated | P-S06 adds a corrupt-file case until fixed. |
| R-018 ratchet on shared rules | Partly mitigated | Inherits G-S01 until fixed. |
| R-019 gate and guard parity | Partly mitigated | The gate needs **Write** semantics, not shell semantics (G-S01). |
| R-020 carve-out | Partly mitigated | P-S03 to P-S06 open until fixed. |
| A-001 `CLAUDE_PROJECT_DIR` set | Open | G-S05 and G-S06 depend on it. Backlog 0000118. |

## Summary

Overall risk rating before fixes: **High**, from G-S01 and G-S02. Both are bypasses through **Write** alone.

Top actions before production:
1. Fix G-S01 in `gate-write` and `ratchet-check` by judging both the text-collapsed and the physical path.
2. Fix G-S02 by refusing non-ASCII targets admitted by a scope record, and folding Unicode case in the enforcement match.
3. Narrow the sanctioned sentence (P-S10), bind `promote-to-regression.sh` sources (P-S09), and harden `set-product-release.mjs` (P-S03 to P-S08).

## Fix Status

Fixes are in progress in three parallel agents. A fresh-context re-review follows each fix before the P5 gate.
