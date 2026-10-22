# Security Report - 0000036-pipeline-friction-and-gate-fixes

Two fresh-context reviewers examined this feature in parallel. Their full findings and reproductions are in `security-review-hooks.md` and `security-review-scripts.md`. This report combines them and records what P5 does with each finding.

## Threat Model (STRIDE)

| Threat | Category | Severity | Mitigation |
|---|---|---|---|
| The build-log template puts the run-mode anchor at column 1, so every copied build log holds an anchor (S-1) | Elevation of privilege | High | Fixed at P5: the template quotes the line, and `run-mode.mjs` requires a full anchor line with a real timestamp |
| A trailing-text anchor such as `autonomous-NOT` counts (S-2) | Tampering | Low | Fixed at P5 by the full-line match |
| A FIFO or a link to `/dev/zero` at an installed `SKILL.md` or marker stalls the drift check (S-3) | Denial of service | Medium | Fixed at P5: `lstat`, regular-file check, and a 1 MiB cap |
| The drift check follows links out of `--root` (S-4) | Information disclosure | Low | Fixed at P5: a linked copy counts as stale |
| Step 1b loads source skills after step 1a rejects a framework update (S-5) | Elevation of privilege | Medium | Fixed at P5: step 1b loads no source copy when step 1a rejected the update |
| A failed setup run can record `applied` (S-6) | Repudiation | Medium | Fixed at P5: the migration defines a completed run and records nothing on failure |
| The migration runs setup before findings reach the human on the loop (S-7) | Elevation of privilege | Low | Accepted. Pre-existing pattern, backlog 0000180 |
| A link swapped in between `lstat` and the open fails the gate open (hooks 1) | Tampering | Low | Fixed at P5: an open error after `lstat` reads as no design |
| A regular `design.md` over about 512 MiB fails the gate open (hooks 2) | Tampering | Medium | Fixed at P5: a 1 MiB size cap after `fstat` reads an oversize file as no design. Closes backlog 0000178 |
| A linked `plan/` or `plan/current/` folder serves a design from elsewhere (hooks 3) | Spoofing | Low | Accepted. Pre-existing |
| Enforcement globs below `plan/` or `docs/` stay permitted (hooks 4) | Tampering | Low | Accepted in ADR-003 |
| `shown()` leaves a literal backslash and lone surrogates ambiguous (hooks 5) | Spoofing | Low | Accepted. No line can be forged |
| An always-permitted `.gitattributes` can hide hook diffs (hooks 6) | Repudiation | Low | Accepted. Backlog 0000179 |
| `em-dash-guard.mjs` exits 1 on a partial install without `path-rules.mjs` (hooks 7) | Denial of service | Low | Accepted. Setup copies every `*.mjs` |

## Dependency Audit

Not applicable. The feature adds no dependency. Hooks and scripts import only `node:` modules and the framework's own modules (NFR-003 holds).

## Secrets Management

A grep of the branch diff found no credentials or tokens.

## Authentication & Authorisation Review

Not applicable. The feature builds no API. The authorisation control under change is the write gate, covered in the threat model.

## Input Validation Review

The hooks handled non-string fields, NUL bytes, lone surrogates, and very long paths with exit 0 or 2 only. `shown()` escapes every Cc, Cf, Zl, and Zp code point at every cap tested.

## Network Policy

Not applicable. No network surface.

## Infrastructure as Code Review

Not applicable. No IaC.

## Summary

Overall risk rating before the P5 fixes: High, from S-1. After the fixes, and once the fresh-context re-reviews confirm them, the expected rating is Low.

Top actions before production:
1. Fix S-1 and S-2 in `run-mode.mjs` and the build-log template.
2. Fix the two gate fail-open paths in `readDesign`.
3. Fix S-3 to S-6 in the drift check, the orchestrator step, and the migration.
