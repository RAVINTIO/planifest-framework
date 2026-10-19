# Security Report - 0000031-ci-test-and-powershell-coverage

Scope: the diff on `feat/0000031-ci-tests-and-governance-lapses` against `main` for this feature. That covers `.github/workflows/planifest.yml`, `planifest-framework/tests/run-tests.sh`, `planifest-framework/tests/test_setup.ps1`, three new `test-0000031-*.sh` files, and one edited 0000030 test.

## Threat Model (STRIDE)

| Threat | Category | Severity | Mitigation |
|---|---|---|---|
| A fork pull request changes `run-tests.sh` or `setup.ps1` to run hostile code on the runner. | Elevation | Low | The jobs use the `pull_request` trigger, so fork runs get a read-only token and no secrets (ADR-003). The runner is discarded after the job. |
| Hostile pull request code reads the `GITHUB_TOKEN` that `actions/checkout@v4` stores in `.git/config`. | Info Disclosure | Low | The new jobs set `permissions: contents: read`, and the repository default token permission is `read`. The token can only read a public repository. Setting `persist-credentials: false` would remove the stored token, but the suite may need git access, so this report doesn't require it. |
| A mutable action tag (`actions/checkout@v4`) moves to compromised code. | Tampering | Low | Same tag as the existing jobs. Pinning to a commit SHA is a repository-wide change and out of scope. |
| A hanging suite or setup run uses runner minutes without limit. | DoS | Low | Each new job sets `timeout-minutes: 10`. |
| `test_setup.ps1` leaves a workspace on the runner. | Info Disclosure | Low | The script deletes the workspace in a `finally` block, and the runner is discarded after the job. |

## Dependency Audit

No dependency manifest changed. The workflow adds no new third-party action. It uses `actions/checkout@v4`, which the existing jobs already use.

## Secrets Management

No new job reads a secret. A grep of the new jobs for `secrets.` finds nothing, and `test-0000031-req-001-003-ci-jobs.sh` asserts this. No credentials appear in the diff.

## Authentication & Authorisation Review

Not applicable: no API. Token scope: both new jobs declare `permissions: contents: read`. The repository default workflow permission is `read` (checked with the GitHub API on 2026-10-16), so the existing jobs also run read-only today.

## Input Validation Review

Not applicable: no API. `Assert-SetupFlagsMarker` treats the marker file as untrusted input. It catches parse errors and checks each field, and it echoes the raw marker text only into the job log.

## Network Policy

GitHub-hosted runners have open egress. The new jobs fetch nothing beyond the checkout. `--include-full-skill-library` copies the skill library from the checked-out tree, with no network fetch.

## Infrastructure as Code Review

Not applicable: no IaC declared.

## Risk Register Cross-Reference

| Risk | Status after implementation |
|------|------------------------------|
| R-001 Linux-only failures | Mitigated. The first CI run failed on Linux and macOS for a version-check reason, not a platform one. Both legs pass. |
| R-002 Large `setup.ps1` defects | Mitigated. The Windows job passed on its first run. |
| R-003 Runner image drift | Open, accepted. Timeouts are in place. |
| R-004 One-item array hidden by `ConvertFrom-Json` | Mitigated. The raw-text array check runs live, and the `flags as a string` case is rejected. |
| R-005 Wider token or `pull_request_target` | Mitigated. See the threat model above. |
| R-006 Red checks don't block merges | Accepted. Branch protection is for the human on the loop. |

## Summary

Overall risk rating: Low

Findings: 0 critical, 0 high, 0 medium, 5 low.

Top actions before production:
1. In branch protection, mark `Test suite (ubuntu-latest)`, `Test suite (macos-latest)`, and `Setup under PowerShell 7 (Windows)` as required checks. Only the human on the loop can do this.
2. Consider pinning `actions/checkout` to a commit SHA across every job, in a separate change.
