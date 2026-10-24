# Security re-review (P5) - 0000038-token-efficiency-windows-shard

Verdict: RESOLVED

Scope: `git show 2a981af` only, checked against `plan/current/security-report.md`.

## 1. Does the fix resolve L4?

Yes. `planifest-framework/setup.ps1` now reads the reference file (line 198) and `SKILL.md` (line 175) with `-Encoding UTF8`.

- Windows PowerShell 5.1: the default read uses the ANSI code page, which garbled the non-ASCII characters in `adoption-modes.md` and `phase-0-assess-and-coach.md`. The explicit read decodes them correctly and strips any BOM.
- PowerShell 7: the default is already UTF-8. The flag changes nothing and does no harm.

## 2. New risk?

None added. The write side was unchanged, so 5.1 still writes a BOM through `Set-Content -Encoding UTF8` and PowerShell 7 writes none. That BOM predates the fix and the new read strips it on a re-run, so it never compounds. The `SKILL.md` frontmatter parse after the rewrite works on the in-memory string, not on a re-read file. The fix writes no new file.

Residual note: a BOM at the start of a 5.1-written `SKILL.md` could matter to a consumer that parses frontmatter strictly. It is existing behaviour and not part of L4.

## 3. Do the static checks pin the fix?

Yes. Two `grep -F` assertions in `planifest-framework/tests/test-0000038-req-004-installed-reference-links.sh` match the exact read lines for `$destRef` and `$skillMdPath`. Removing either flag fails the suite. They check text, not behaviour, which fits because the suite cannot run 5.1 on this host.

## Other findings

- L1 and L5 are filed as backlog 0000233 (`plan/backlog/0000233-harden-quiet-runner-and-setup-rewrites/entry.md`). The entry names both and gives the suggested action.
- L2 matches the design. The warm-up and the unchanged 200 ms limit follow ADR-005 and `plan/current/design.md` (US-001, risk on cold-start cost).
- L3 matches the design. The advisory partial-read directive follows US-007 in `plan/current/design.md`.
