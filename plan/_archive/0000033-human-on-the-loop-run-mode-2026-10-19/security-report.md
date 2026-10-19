# Security Report - 0000033-human-on-the-loop-run-mode

> Produced at P5 from four fresh-context, REJECT-default reviews and three fix cycles. Every finding below names its file. Severities are the reviewers' ratings before the fix.

## Threat Model (STRIDE)

| Threat | Category | Severity | Mitigation |
|---|---|---|---|
| A symbolic link at `plan/_archive/` or the archive target makes `archive-current.mjs` move files into `src/` (S1) | Tampering, Elevation | High | Fixed. The script refuses linked `plan/`, `plan/current/`, `plan/_archive/`, and target paths, and checks real paths sit under `plan/_archive/`. Exit 2. |
| A symbolic link at `plan/current/` makes `archive-current.mjs` delete files in `src/` (S2) | Tampering | High | Fixed. Exit 2 before any change. |
| A dangling link at `.archive-target` creates a file in `src/` (S3) | Tampering | Medium | Fixed. The script refuses a linked `.archive-target` and writes it with an exclusive create. |
| A linked `.archive-target` prints a secret file's first 120 characters (S4) | Information disclosure | Low | Fixed. Errors never print the raw value. |
| `stream-reconcile.mjs` reads `/dev/zero`, a FIFO, or paths outside the repo (S5) | Denial of service, Information disclosure | Medium | Fixed. Only regular files inside the repo, up to 1 MB each. |
| A join record lists a file it never changed, so the consumer check passes (S6) | Tampering | Low | Fixed for unchanged files. Residual Low: a join can claim another stream's file in the same range. Backlog 0000120. |
| An entry named `*` globs through git pathspecs (S7) | Denial of service | Low | Fixed. Every git call sets `GIT_LITERAL_PATHSPECS=1`. |
| Control characters in names forge output lines (S8) | Spoofing | Low | Fixed. Printed names pass through a control-character filter. |
| An explicit `off` toggle removes every checker in `autonomous` (G1) | Elevation | High | Fixed. An explicit `off` or `report-only` checker key blocks `autonomous` at P0 and again at P1. The P1 toggle record freezes the checker keys. |
| An override outranks the hard limits (G2) | Elevation | High | Fixed. The standing rules rank above every override in `standards/autonomous-run-standards.md`. |
| `autonomous` pushes from the default branch (G3) | Tampering | High | Fixed. `autonomous` needs a `feat/` branch at P0, and ship Step 10 checks the branch before any push. |
| The maker classifies its own deviation (G4) | Repudiation | Medium | Fixed. The maker writes `unclassified`. A pre-P7 deviation review by the fresh-context reversal assessor sets the class. |
| A leftover commit carries a credential (G5) | Information disclosure | Medium | Fixed. `--untracked-files=all`, a filename and content credential guard, and `gitleaks` when installed. Refused files become exception items. |
| A file write switches the run to `autonomous` (G6, cycle 2 finding 1) | Spoofing, Elevation | Medium | Fixed. `scripts/run-mode.mjs` prints `autonomous` only when git history anchors it, and every reader calls it. Residual Low: see the next row. |
| Git textconv or replace refs forge the run-mode anchor (cycle 2 findings 1 and 2) | Spoofing | High | Fixed. The script passes `--no-textconv`, `--no-ext-diff`, and `--no-replace-objects`, and drops inherited `GIT_*` variables. Suite fixtures reproduce both attacks. |
| User or repo git config, alternates, grafts, or a shallow file forge the anchor | Spoofing | Low | Not mitigated. Needs deliberate multi-step tampering. Backlog 0000121. The script's header states it is an integrity check, not a security boundary. |
| The final report is lost at the context clear (G7) | Repudiation | Medium | Fixed. Ship writes `{archive-dir}/final-report.md`, commits it, and pushes it. |
| `git push --tags` pushes stray tags, and no force ban exists (G9) | Tampering | Low | Fixed. Explicit push lines, and no step uses `--force`. |
| Fast Path admits changes to enforcement code or the exception list (G12) | Elevation | Low | Fixed. Fast Path never admits `hooks/`, `scripts/`, setup scripts, or `autonomous-run-standards.md`. |

## Dependency Audit

No new dependencies. The three new scripts, `archive-current.mjs`, `stream-reconcile.mjs`, and `run-mode.mjs`, import only Node built-ins. Every git call passes an argument array with no shell.

## Secrets Management

No secrets in the change. The leftover credential guard (G5) covers credential file names and content patterns, and an exception item reports each refusal. A credential sighting is a seventh exception item in `autonomous` (G11). Hard Limit 6 is in the standing rules.

## Authentication & Authorisation Review

Not applicable as an API. The authorisation question is which actions an `autonomous` run may take alone:

- Merging stays human-only in every mode. No step runs `gh pr merge`.
- Schema changes, destructive operations, data ownership, and credentials stay in the standing rules, which outrank overrides. None of them depends on the run mode.
- `autonomous` skips the human's phase confirmations and lets P9 raise a PR without asking. Run-mode trust therefore rests on `run-mode.mjs`, and only the orchestrator writes run-mode records.

## Input Validation Review

Agent-written inputs reach the three scripts: `.archive-target`, stream state files, join records, artifact IDs, start commits, stream IDs, and build-log lines.

- `start-commit` must match `^[0-9a-f]{7,40}$`.
- Paths pass `realpath` and `lstat` checks, and reads are capped at 1 MB.
- `--grep` values are escaped and passed as separate arguments.

## Network Policy

No network surface. The scripts run locally. Push and PR creation use `git` and `gh`, under the branch check and the `local-git-only` override.

## Infrastructure as Code Review

No IaC in the stack.

## Risk Register Cross-Reference

| Risk | Status |
|---|---|
| R-005 an autonomous run skips a human-only item | Mitigated. The standing rules outrank overrides, and the hard limits don't depend on the run mode. |
| R-006 a fresh-context checker approves a defect | Partly mitigated. Checkers can't be turned off in `autonomous`. A checker can still miss a defect. The human reviews before merging. |
| R-013 push from the default branch | Mitigated (G3). |
| R-014 leftover auto-commit carries a credential | Mitigated (G5). Residual: a pattern gap for unusual formats. |
| R-015 run-mode spoofing | Mitigated by the git-anchored script. Residual Low (backlog 0000121). |
| R-016 final report lost | Mitigated (G7). |

## Summary

Overall risk rating: Low

The first reviews rated the change High. Three fix cycles closed every Critical, High, and Medium finding. Two Low residuals remain, filed as backlog 0000120 and 0000121.

Top actions before production:
1. Run one `autonomous` pipeline end to end on a test product, and check every stop that happens is on the exception list.
2. Pick up backlog 0000121 to close the remaining git-config paths in `run-mode.mjs`.
3. Pick up backlog 0000120 so a join can claim only its own changed files.
