---
title: "Backlog Entry: 0000203 - setup.ps1 writes a byte order mark under Windows PowerShell 5.1"
summary: "setup.ps1 writes JSON and text files with Set-Content -Encoding UTF8. Under Windows PowerShell 5.1 that adds a byte order mark. PowerShell 7 does not."
status: "open"
---
# Backlog Entry: 0000203 - setup.ps1 writes a byte order mark under Windows PowerShell 5.1

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

While P3 removed the PowerShell 6+ only `ConvertFrom-Json -AsHashtable` call from `ravintio-framework/setup.ps1`, a scan of the file found a second 5.1 and 7 difference. Several writes use `Set-Content -Encoding UTF8` or `Add-Content -Encoding UTF8`. These include the boot files, the tracked config file, the setup-flags marker, and the ignore files (lines near 309, 1024, 1138, 1161, 1361, and 1392).

Under Windows PowerShell 5.1, `-Encoding UTF8` writes a byte order mark. Under PowerShell 7 it writes none. `Write-SettingsFile` already avoids this for `settings.json` by writing bytes directly. The other files do not.

No CI run has shown a failure from this. A JSON file with a byte order mark can fail in `JSON.parse` in Node, so any hook that reads the marker or the config file could be affected.

## Suggested Action

Write those files through one helper that uses `[System.IO.File]::WriteAllText` with `New-Object System.Text.UTF8Encoding($false)`, as `Write-SettingsFile` does. Add a test that checks the first bytes of each file under the 5.1 job.

## Why Deferred

Nothing fails today, and the change touches many write sites in `setup.ps1` that req-011 does not cover. It needs its own scope and a 5.1 run to confirm.
