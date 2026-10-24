# Security Report - 0000038-token-efficiency-windows-shard

Scope: `git diff main...HEAD -- planifest-framework/ planifest-overrides/`. The feature changes framework prose, test harnesses, and installer scripts. It adds no API, network listener, or dependency.

## Threat model (STRIDE)

| Threat | Category | Severity | Mitigation |
|---|---|---|---|
| A failed suite reads as passed in `run-tests.sh --quiet` | Tampering | Low | Suite fails on non-zero exit, on a `FAIL:` line, or when the capture cannot be made or read. A failed `wait` returns non-zero and also fails (`planifest-framework/tests/run-tests.sh` 108-143). Shard guard and exit 3 are intact (233-237). |
| Capture file predictable or readable by others | Info disclosure | Low | `mktemp` makes a random name with mode 0600. The runner removes the file after each suite and on EXIT, INT, and TERM. |
| Stray capture file after SIGKILL or SIGHUP | Info disclosure | Low | Not mitigated. See finding L1. |
| `rewrite_skill_reference_links` writes outside `references/` | Tampering | Low | Paths come from `find -type f -name '*.md'` under the skill's own `references/`. Every sed target is `$dest_dir/references/$ref_md`. Patterns are fixed strings. Variables are quoted. No glob expansion. |
| Model value `haiku` or `sonnet` weakens a review | Elevation | Low | Alias change only. The P4 probe confirmed the alias resolves. Security review, design critic, and cross-model review stay exempt from the size floor. |
| Size floor removes a maker-checker split | Tampering | Low | Text states the floor never removes a maker-checker split or a TDD step. Fresh-context roles stay in subagents. |
| Partial-read directive skips a needed rule | Tampering | Low | See finding L3. |
| Slow hook passes the timing test | Denial of service | Low | See finding L2. |

## Dependency audit

No new dependency. Tests use `bash`, `node`, `perl`, and `awk`, all already in use.

## Secrets management

No credential, token, or key in the diff. The `credential-scan.mjs` run on the report and build log is recorded in the commit step. Capture files can hold test output, so they stay at mode 0600 and are short-lived.

## Authentication and authorisation review

Not applicable. No API. Hard limits in `CLAUDE.md` are unchanged. The new text does not touch `gate-write`, `shell-write-guard`, or `ratchet-check`.

## Input validation review

`rewrite_skill_reference_links` reads file names with `IFS= read -r`, so spaces and backslashes survive. A file name with a newline would split. The source tree is trusted framework content, so this is not exploitable.

## Network policy

No network surface added.

## Infrastructure as Code review

No IaC.

## Findings

### Critical, High, Medium

None.

### Low

- **L1: quiet mode leaks a capture file if the runner is stopped by SIGKILL or SIGHUP, and the child suite can outlive it.** `planifest-framework/tests/run-tests.sh` lines 72-99 trap only INT and TERM. `kill "$CHILD_PID"` stops the suite shell and not its own children. Impact: a stale file in `$TMPDIR` with test output, mode 0600. Action: optional. Add `HUP` to the trap list.
- **L2: warm-up call hides a cold-start regression.** `planifest-framework/tests/test-0000032-req-007-stderr-block-reasons.sh` line 52, `planifest-framework/tests/test-0000032-req-009-shell-guard-path-parity.sh` line 313 and the `regression/` copies. A hook slow only on first run now passes. A hook slow on every run still fails (`test-0000038-req-001-stable-windows-timing.sh` proves this with a 250 ms stub). The limit stays at 200 ms. This is a deliberate trade in ADR-005. No gate weakened beyond that.
- **L3: partial-read directive is advisory and has no rule-file exemption.** `planifest-framework/templates/standard-boot.md` line 20 says to read files over about 20 KB in part. An agent could search a long skill or standard and miss a hard limit. Impact is low because `CLAUDE.md` and the boot file are well under 20 KB and the orchestrator now loads phase files whole. Action: consider adding "except files that state rules you must obey".
- **L4: PowerShell rewrite can corrupt non-ASCII text under Windows PowerShell 5.1.** `planifest-framework/setup.ps1` lines 198-201. `Get-Content -Raw` has no `-Encoding`, and `Set-Content -Encoding UTF8` adds a BOM on 5.1. Two reference files hold non-ASCII characters (`adoption-modes.md`, `phase-0-assess-and-coach.md`). This is an integrity issue and not exploitable. The same pattern already exists at line 180. Action: read with `-Encoding UTF8`.
- **L5: the rewrite hides its own failure.** `planifest-framework/setup.sh` lines 73-77: a failed `sed` leaves the link unrewritten and the loop continues silently. In `setup.ps1`, a missing `$destRef` makes `Set-Content` write an empty file (line 201). Action: add an existence check.

### Informational

- I1: `setup.sh` rewrites `$dest_dir` in place. If a human points the target at the framework's own `skills/` folder, the source files change. The same exposure exists for `SKILL.md` at lines 92-97. Existing behaviour.
- I2: The size-floor text names its exempt roles in three places (`agent-dispatch-standards.md` line 35, `custom-002-prefer-subagent-decomposition.md`, and the dispatch standard it points to). The lists can drift apart.

## Risk register cross-check

No open risk from `plan/current/risk-register.md` conflicts with these findings. The quiet-mode false-pass risk is mitigated as shown above.

## Summary

Overall risk rating: Low

Top actions before production (none block the PR):
1. Read reference files with `-Encoding UTF8` in `setup.ps1` (L4).
2. Add `HUP` to the quiet-mode trap (L1).
3. Check for a missing destination file before the rewrite in both installers (L5).
