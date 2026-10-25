---
title: "Backlog Entry: 0000270 - migration helper follows a link to a share"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000270 - migration helper follows a link to a share

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

Finding N-006 (Low), from the third re-review in the archived `security-rereview-markers.md` of 0000039. Say a link inside the project points to a Windows share, such as a link `lnk` whose target is `\\host\share`. A manifest entry such as `lnk/sub/i` then makes `ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.ps1` follow the link. `Get-RealPath` calls `Get-Item` on the remote path, near lines 238 to 243. The Windows probe's `Test-Path` follows it too, near lines 299 to 305. So does `cd -P` in the `.sh` twin under Git Bash, near line 190.

The helper still drops the entry, so it deletes nothing. The lookup can still send the person's NTLM credentials to the host, as N-004 could. A consumer repo can hold such a link only when git has `core.symlinks=true` and Windows lets the person create links. Nobody has tested this on Windows.

## Suggested Action

Stop resolution at any link whose target starts with a share prefix, and drop the entry with the existing warning. Run the probe only when `Get-RealPath` returned a path. Test it on a Windows runner with links enabled.

## Why Deferred

The finding is Low, and it needs a Windows link setup that CI doesn't have. It turned up in the fourth security review round of the marker rename. The orchestrator ended the loop there rather than open a fifth round of fixes. Backlog 0000255, for the setup prune, sits beside it.
