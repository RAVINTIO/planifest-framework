# Security Report - 0000039-ravintio-rebrand

Two fresh-context reviewers covered the feature in parallel, and a third re-reviewed every fix. The detail is in three files beside this one:

- `security-review-migration.md`: the consumer migration helpers and the migrator changes
- `security-review-setup-hooks.md`: setup, the enforcement hooks, `archive-current.mjs`, the OpenCode adapter, secrets, and dependencies
- `security-rereview.md`: one verdict per fixed finding, with evidence

## Threat Model (STRIDE)

| Threat | Category | Severity | Mitigation |
|---|---|---|---|
| Setup's old-manifest prune deletes a folder outside the skills folder through an absolute path, `..`, or a linked parent (S-01) | Tampering | Medium | Fixed in 19e485f5. The prune acts only on a folder whose real parent is the real skills folder. The re-review confirmed it closed. |
| The helper renames a consumer's `secrets.` or `vars.` reference, so the secret reads as empty (M-001) | Tampering | Medium | Fixed in 19e485f5. Other reference forms remain, rated Low, backlog 0000257. |
| The branch protection warning names the wrong check, so a consumer who follows it blocks every PR (M-002) | Denial of service | Medium | Fixed in 19e485f5. The warning says the job check `validate-branch` keeps its name, and the helper rewrites the workflow `name:` line. |
| The rename dropped the old OpenCode plugin and workflow from the enforcement paths (S-02) | Elevation | Low | Fixed in 19e485f5. The old OpenCode registration stays, backlog 0000258. |
| A folder appears at a move target between the check and the move (L-001) | Tampering | Low | Fixed. Each move rechecks its target. |
| A linked skills folder prunes in Bash and not in PowerShell (N-01) | Tampering | Low | Open, backlog 0000259. |
| The helper deletes or loses the old pack | Tampering | Low | Mitigated by design (ADR-005). The helpers hold no recursive delete. Their only removal is the session marker, after a link check. |

## Dependency Audit

No new tool or library. The OpenCode `package.json` changed its name and scope only.

## Secrets Management

The credential scan ran before every commit in this autonomous run. It matched four lines in three vendored external-skills files. All four are false positives: two match the risk skill's folder name, and two are the security skill's example search patterns. The human on the loop cleared them on 2026-10-25, and the scan rule's false positive is backlog 0000253. The setup and hooks reviewer scanned 576 changed paths and found no credential.

## Authentication & Authorisation Review

Not applicable. The feature adds no API.

## Input Validation Review

The files a consumer controls, such as `.planifest-setup-flags`, `.planifest-manifest`, and the workflow file, are the inputs. S-01 and M-001 covered them, and both are fixed. The flags file only sets flags setup already accepts.

## Network Policy

Not applicable. Nothing listens on a port or calls out.

## Infrastructure as Code Review

Not applicable. The CI change gives the test job full history (`fetch-depth: 0`) and grants no new permission.

## Summary

Overall risk rating: Low. All three Medium findings are fixed and re-reviewed as closed. Every remaining finding is Low and has a backlog entry or an accepted reason in the review files.

Top actions before production:
1. Backlog 0000255: give the older current-manifest prune the same path check that S-01 added.
2. Backlog 0000257: stop the rename helper from touching other consumer expression forms.
3. Backlog 0000258: remove the old OpenCode registration on upgrade.
