# Security Report - 0000037-green-ci-before-ship

> Consolidated P5 report. Detailed reviews: `security-review-credentials.md` and `security-review-ci-and-setup.md`. Fresh-context re-reviews: `security-rereview.md` to `security-rereview-6.md`. Every finding cites a path and a result, never raw output.

## Threat Model (STRIDE)

| Threat | Category | Severity | Mitigation |
|---|---|---|---|
| A credential in a mid-run `autonomous` commit reaches the remote | Information Disclosure | High | `credential-scan.mjs --safe-paths` decides each P7 to P9 commit's paths. Scan-then-commit in `standards/autonomous-run-standards.md` commits only the safe list with `git --literal-pathspecs` and an empty-list guard. |
| A credential in PR text (title, body, comments) | Information Disclosure | Medium | Ship Step 10 scans the title and body files with `--file` before `gh pr create` or `gh pr edit`. The PR-text rule covers comments and review replies, and PR text cites paths only. |
| A file that hides a key from the scanner (NUL bytes, UTF-16, a long line, a large blob) | Tampering | High | The scanner strips NUL bytes, decodes UTF-16 with a BOM, uses a linear private-key rule, and reads blobs with no buffer limit. Any read error exits 2. |
| A safe file name that acts as a git pathspec and pulls in a held-back file | Tampering | Medium | Every scan-then-commit git call runs with `git --literal-pathspecs`, and blobs are read as `:./{path}`. |
| A red or unreadable CI result reported as done | Repudiation | Medium | Step 10c judges from the JSON, maps `cancel` and timeouts to unknown, and treats `no checks reported` as an empty list. Any result other than all passed writes `Progress: P9 blocked`. |
| A shard that runs no suite and passes | Denial of Service (silent coverage loss) | Medium | `run-tests.sh` accepts only shard values 1 to 99 with no leading zero, exits 2 on a bad value, and exits 3 when a shard runs no suite. |
| `setup.ps1` reports guardrails active when `git config` failed | Elevation (lost enforcement) | Medium | `setup.ps1` resets `$LASTEXITCODE`, checks `Get-Command git`, and warns on any failure. |
| A Git Bash path such as `/c/proj/src/a.js` read as outside the repository by `shell-write-guard` on Windows | Elevation | Medium | Not mitigated in this feature. Pre-existing, deferred as backlog 0000204. |
| A `design.md` link swapped in between `lstat` and open on Windows | Tampering | Low | Not mitigated. Needs a symlink privilege and a microsecond window. Backlog 0000209. |

## Dependency Audit

No new dependency. `credential-scan.mjs` uses Node built-ins only (ADR-001), plus `git` and an optional `gitleaks` on PATH. The workflow uses `actions/checkout@v4` on a floating tag, which predates this feature (backlog 0000218).

## Secrets Management

No secret is stored or read. The new CI jobs declare `permissions: contents: read`, use no `secrets.` reference, and run on `pull_request` only (0000031 ADR 003). Every suite assembles its fixture keys at run time, so no file holds a literal key. The scanner never prints a matched value (NFR-004), as verify by execution and five re-reviews confirmed.

## Authentication & Authorisation Review

Not applicable. The feature adds no API. `gh` uses the human on the loop's existing sign-in, read-only for checks.

## Input Validation Review

- `credential-scan.mjs` validates its mode arguments and exits 2 on misuse.
- `run-tests.sh` validates the shard variables and fails closed.
- GUTD step 5 requests only `number,url,mergedAt`, and treats check names and links as data.

## Network Policy

No change. CI talks to GitHub only. The ship skill and GUTD read GitHub through `gh`.

## Infrastructure as Code Review

The workflow is the only infrastructure file. Its new jobs follow 0000031 ADR 002 and ADR 003: repository-only, read-only token, no secrets, and capped timeouts (10 minutes, or 20 for the seven Windows shards under ADR-014).

## Re-review history

| Round | Verdict | Open High or Medium after the round |
|---|---|---|
| Review 1 (two reviewers) | Medium overall | 1 High, 8 Medium |
| Re-review 1 | REJECT | credentials F-04 (partly), N-01 |
| Re-review 2 | REJECT | N-07, N-08 (High) |
| Re-review 3 | REJECT | N-09 |
| Re-review 4 (approach 2) | REJECT | N-12 |
| Re-review 5 | APPROVE | none (N-15 and N-16 Low) |
| Re-review 6 | see `security-rereview-6.md` | N-15 and N-16 fixes |

## Summary

Overall risk rating: Medium. Every finding this feature introduced is closed. The rating stays Medium for one pre-existing Windows gap, backlog 0000204.

Top actions before production:
1. Fix 0000204, so `shell-write-guard` reads Git Bash paths on Windows as repository paths.
2. Pin `actions/checkout` to a commit SHA and add `permissions:` to the two older jobs (0000218).
3. Add `gitleaks` to the environments that run `autonomous`, so the scan isn't regex only (0000216).
