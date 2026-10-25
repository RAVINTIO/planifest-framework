$ErrorActionPreference = 'Stop'

Write-Host "Running setup.ps1 tests..."

# Create a temporary test workspace
$tempDirPattern = "ravintio_test_" + [guid]::NewGuid().ToString()
$testDir = Join-Path $env:TEMP $tempDirPattern
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$originalLocation = Get-Location

# Checks the .ravintio-setup-flags marker that Write-SetupFlagsMarker writes.
# Every failure throws a FAIL message that names the field and the value found.
function Assert-SetupFlagsMarker {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$ExpectedTool = 'claude-code',
        [string[]]$ExpectedFlags = @()
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "FAIL: setup-flags marker not found at '$Path'"
    }

    $raw = Get-Content -LiteralPath $Path -Raw
    try {
        $marker = $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "FAIL: setup-flags marker is not valid JSON (found: '$raw'): $($_.Exception.Message)"
    }
    if ($null -eq $marker) {
        throw "FAIL: setup-flags marker parsed to nothing (found: '$raw')"
    }

    $present = @($marker.PSObject.Properties.Name)
    foreach ($field in @('tool', 'flags', 'writtenAt', 'attemptStatus')) {
        if ($present -notcontains $field) {
            throw "FAIL: setup-flags marker is missing field '$field' (found fields: $($present -join ', '))"
        }
    }

    if ($marker.tool -ne $ExpectedTool) {
        throw "FAIL: setup-flags marker field 'tool' expected '$ExpectedTool' but found '$($marker.tool)'"
    }

    if ($marker.attemptStatus -ne 'completed') {
        throw "FAIL: setup-flags marker field 'attemptStatus' expected 'completed' but found '$($marker.attemptStatus)'"
    }

    # Read writtenAt from the raw text. ConvertFrom-Json in PowerShell 7 turns
    # ISO date strings into DateTime objects, which would hide the written format.
    if ($raw -match '"writtenAt"\s*:\s*"([^"]*)"') {
        $writtenAt = $Matches[1]
    }
    else {
        throw "FAIL: setup-flags marker field 'writtenAt' is not a string in the raw text (found: '$raw')"
    }
    if ($writtenAt -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$') {
        throw "FAIL: setup-flags marker field 'writtenAt' expected yyyy-MM-ddTHH:mm:ssZ but found '$writtenAt'"
    }

    # ConvertTo-Json can collapse a one-item array to a string, so check the raw text too.
    if ($raw -notmatch '"flags"\s*:\s*\[') {
        throw "FAIL: setup-flags marker field 'flags' is not a JSON array literal in the raw text (found: '$raw')"
    }

    # Wrap in @() so an empty or one-item value does not unroll.
    $actualFlags = @($marker.flags)
    $expected = @($ExpectedFlags)
    $foundText = $actualFlags -join ', '
    if ($actualFlags.Count -ne $expected.Count) {
        throw "FAIL: setup-flags marker field 'flags' expected $($expected.Count) item(s) [$($expected -join ', ')] but found $($actualFlags.Count) [$foundText]"
    }
    for ($i = 0; $i -lt $expected.Count; $i++) {
        if ($actualFlags[$i] -ne $expected[$i]) {
            throw "FAIL: setup-flags marker field 'flags' item $i expected '$($expected[$i])' but found '$($actualFlags[$i])'"
        }
    }

    Write-Host "  PASS: setup-flags marker at '$Path' is valid (flags: [$foundText])"
}

# Writes a broken marker and expects Assert-SetupFlagsMarker to throw a FAIL
# message. Throws if the helper accepts the broken marker.
function Assert-MarkerRejected {
    param(
        [Parameter(Mandatory = $true)][string]$Case,
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Folder
    )

    $path = Join-Path $Folder ".ravintio-setup-flags-$([guid]::NewGuid().ToString())"
    Set-Content -LiteralPath $path -Value $Content -NoNewline -Encoding UTF8
    $rejected = $false
    try { Assert-SetupFlagsMarker -Path $path -ExpectedFlags @() }
    catch {
        if ($_.Exception.Message -notlike 'FAIL: setup-flags marker*') {
            throw "FAIL: broken marker case '$Case' threw an unexpected error: $($_.Exception.Message)"
        }
        $rejected = $true
    }
    if (-not $rejected) {
        throw "FAIL: broken marker case '$Case' was accepted"
    }
    Write-Host "  PASS: broken marker case '$Case' was rejected"
}

try {
    # Copy the framework into the test workspace
    $scriptPath = $MyInvocation.MyCommand.Path
    $frameworkSrc = Split-Path (Split-Path $scriptPath -Parent) -Parent
    
    Copy-Item -Path $frameworkSrc -Destination (Join-Path $testDir "ravintio-framework") -Recurse -Force
    
    Set-Location $testDir

    Write-Host "--- Testing: claude-code ---"
    & .\ravintio-framework\setup.ps1 claude-code

    if (-not (Test-Path ".claude\skills")) {
        throw "FAIL: .claude\skills directory not created"
    }

    if (-not (Test-Path ".claude\skills\ravintio-orchestrator\SKILL.md")) {
        throw "FAIL: SKILL.md not copied for claude-code"
    }

    if (-not (Test-Path "CLAUDE.md")) {
        throw "FAIL: CLAUDE.md boot file not created"
    }

    if (-not (Test-Path ".claude\commands\feature-pipeline.md")) {
        throw "FAIL: Workflow command not created for claude-code"
    }

    Assert-SetupFlagsMarker -Path ".claude\.ravintio-setup-flags" -ExpectedTool 'claude-code' -ExpectedFlags @()

    $brokenDir = Join-Path $testDir 'broken-markers'
    New-Item -ItemType Directory -Path $brokenDir -Force | Out-Null
    Assert-MarkerRejected -Case 'invalid JSON' -Folder $brokenDir -Content '{ "tool": "claude-code", "flags": [ '
    Assert-MarkerRejected -Case 'missing field' -Folder $brokenDir -Content '{ "tool": "claude-code", "flags": [], "writtenAt": "2026-01-01T00:00:00Z" }'
    Assert-MarkerRejected -Case 'flags as a string' -Folder $brokenDir -Content '{ "tool": "claude-code", "flags": "--strict-orchestrator", "writtenAt": "2026-01-01T00:00:00Z", "attemptStatus": "completed" }'

    # 0000039 P5 finding S-01: the old manifest prune never leaves the skills
    # folder. The old brand word is built from parts.
    Write-Host "--- Testing: old manifest prune stays in the skills folder ---"
    $oldWord = 'plan' + 'ifest'
    $victimA = Join-Path $testDir ("outside\" + $oldWord + '-victim')
    $victimB = Join-Path $testDir ($oldWord + '-victim2')
    New-Item -ItemType Directory -Path $victimA -Force | Out-Null
    New-Item -ItemType Directory -Path $victimB -Force | Out-Null
    Set-Content -Path (Join-Path $victimA 'keep.txt') -Value 'keep'
    Set-Content -Path (Join-Path $victimB 'keep.txt') -Value 'keep'
    $oldManifestLines = @($victimA, (Join-Path $testDir (".claude\skills\..\..\" + $oldWord + '-victim2')))
    Set-Content -Path (Join-Path $testDir (".claude\skills\." + $oldWord + '-manifest')) -Value $oldManifestLines
    & .\ravintio-framework\setup.ps1 claude-code
    if (-not (Test-Path -LiteralPath (Join-Path $victimA 'keep.txt'))) {
        throw "FAIL: 0000039 S-01: the prune deleted an absolute path outside the skills folder"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $victimB 'keep.txt'))) {
        throw "FAIL: 0000039 S-01: the prune deleted a .. path out of the skills folder"
    }
    Write-Host "  PASS: 0000039 S-01: absolute and .. manifest entries survive the prune"

    Write-Host "--- Testing: cursor ---"
    & .\ravintio-framework\setup.ps1 cursor

    if (-not (Test-Path ".cursor\skills")) {
        throw "FAIL: .cursor\skills directory not created"
    }

    if (-not (Test-Path ".cursor\skills\ravintio-orchestrator\SKILL.md")) {
        throw "FAIL: SKILL.md not copied for cursor"
    }

    Write-Host "--- Testing: --include-full-skill-library ---"
    & .\ravintio-framework\setup.ps1 claude-code --include-full-skill-library

    $extSkillDirs = @(Get-ChildItem -Path ".claude\skills" -Directory | Where-Object {
        (Test-Path (Join-Path $_.FullName "SKILL.md")) -and
        (Test-Path (Join-Path $_.FullName "attribution.txt"))
    })
    if ($extSkillDirs.Count -eq 0) {
        throw "FAIL: no external skill dirs with SKILL.md + attribution.txt found after --include-full-skill-library"
    }
    Write-Host "  PASS: $($extSkillDirs.Count) external skill(s) installed"

    Assert-SetupFlagsMarker -Path ".claude\.ravintio-setup-flags" -ExpectedTool 'claude-code' -ExpectedFlags @('--include-full-skill-library')

    $manifest = Get-Content -Path ".claude\skills\.ravintio-manifest" -Raw
    $extSkillName = $extSkillDirs[0].Name
    if ($manifest -notmatch [regex]::Escape($extSkillName)) {
        throw "FAIL: .ravintio-manifest does not contain external skill '$extSkillName'"
    }
    Write-Host "  PASS: .ravintio-manifest includes external skill path"

    # Re-run without flag — external skills must not remain
    & .\ravintio-framework\setup.ps1 claude-code

    $orphaned = @(Get-ChildItem -Path ".claude\skills" -Directory | Where-Object {
        Test-Path (Join-Path $_.FullName "attribution.txt")
    })
    if ($orphaned.Count -gt 0) {
        throw "FAIL: external skill dirs remain after plain re-run (orphaned: $($orphaned.Name -join ', '))"
    }
    Write-Host "  PASS: external skill dirs removed on plain re-run"

    # req-010 (feature 0000032): setup registers shell-write-guard.mjs for the
    # Bash tool exactly once, and a Bash group the human on the loop added survives.
    Write-Host "--- Testing: req-010 shell-write-guard registration ---"
    $regDir = Join-Path $testDir 'req-010'
    New-Item -ItemType Directory -Path (Join-Path $regDir '.claude') -Force | Out-Null
    Copy-Item -Path $frameworkSrc -Destination (Join-Path $regDir 'ravintio-framework') -Recurse -Force
    $humanSettings = '{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"echo human-bash-hook"}]}]}}'
    Set-Content -LiteralPath (Join-Path $regDir '.claude\settings.json') -Value $humanSettings -NoNewline -Encoding UTF8

    Push-Location $regDir
    try {
        & .\ravintio-framework\setup.ps1 claude-code | Out-Null
        & .\ravintio-framework\setup.ps1 claude-code | Out-Null
    }
    finally {
        Pop-Location
    }

    $regSettings = Get-Content -Raw -LiteralPath (Join-Path $regDir '.claude\settings.json') | ConvertFrom-Json
    $bashGroups = @($regSettings.hooks.PreToolUse | Where-Object { $_.matcher -eq 'Bash' })
    $guardGroups = @($bashGroups | Where-Object { $_.hooks | Where-Object { $_.command -match 'shell-write-guard\.mjs' } })
    $humanGroups = @($bashGroups | Where-Object { $_.hooks | Where-Object { $_.command -match 'human-bash-hook' } })
    if ($guardGroups.Count -ne 1) {
        throw "FAIL: req-010: expected one shell-write-guard Bash group after two runs, found $($guardGroups.Count)"
    }
    Write-Host "  PASS: req-010: two setup.ps1 runs leave one shell-write-guard Bash group"
    if ($humanGroups.Count -ne 1) {
        throw "FAIL: req-010: expected the human Bash group to survive both runs, found $($humanGroups.Count)"
    }
    Write-Host "  PASS: req-010: the human Bash group survives both runs"
    if (-not (Test-Path (Join-Path $regDir '.claude\hooks\enforcement\shell-write-guard.mjs'))) {
        throw "FAIL: req-010: .claude\hooks\enforcement\shell-write-guard.mjs not installed"
    }
    Write-Host "  PASS: req-010: shell-write-guard.mjs is installed"

    # req-011 (feature 0000037): seed a stale Claude Code state, run a retired flag,
    # and check the clean-up runs live. Runs under PowerShell 7 and Windows PowerShell 5.1.
    # The seed copies the fixtures from test-0000030-req-004-install-clean-up-and-retired-flags.sh.
    # BEGIN retired-integrations (0000037 req-011 fixtures for the 0000030 clean-up)
    Write-Host "--- Testing: req-011 stale clean-up and retired flag ---"
    $staleDir = Join-Path $testDir 'req-011'
    New-Item -ItemType Directory -Path (Join-Path $staleDir '.claude\hooks\telemetry') -Force | Out-Null
    Copy-Item -Path $frameworkSrc -Destination (Join-Path $staleDir 'ravintio-framework') -Recurse -Force
    Set-Content -LiteralPath (Join-Path $staleDir '.claude\hooks\telemetry\emit-phase-start.mjs') -Value '// stale' -Encoding ASCII
    $staleSettings = @'
{
  "hooks": {
    "PreToolUse": [
      {"matcher": "Grep", "hooks": [{"type": "command", "command": "node \".claude/hooks/context-mode/block-grep.mjs\" || echo \"[RAVINTIO] did not run\" 1>&2"}]},
      {"matcher": "Bash", "hooks": [{"type": "command", "command": "node scripts/my-own-bash-guard.mjs"}]}
    ]
  }
}
'@
    # Write without a byte order mark so both PowerShell versions write the same bytes.
    [System.IO.File]::WriteAllText((Join-Path $staleDir '.claude\settings.json'), $staleSettings, (New-Object System.Text.UTF8Encoding($false)))

    Push-Location $staleDir
    # Windows PowerShell 5.1 turns native stderr merged with *>&1 into a terminating
    # error under 'Stop', so relax the preference for this one call.
    $savedPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $global:LASTEXITCODE = 0
        $staleOut = & .\ravintio-framework\setup.ps1 claude-code --context-mode-mcp *>&1 | Out-String
        $staleExit = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $savedPreference
        Pop-Location
    }

    if ($staleExit -ne 0 -and $null -ne $staleExit) {
        throw "FAIL: req-011: setup.ps1 claude-code --context-mode-mcp exited $staleExit"
    }
    Write-Host "  PASS: req-011: setup.ps1 exits 0 with a retired flag"

    $noticeLines = @($staleOut -split "\r?\n" | Where-Object { $_ -like '*--context-mode-mcp was removed in 0.29.0 and has no effect*' })
    if ($noticeLines.Count -ne 1) {
        throw "FAIL: req-011: expected exactly one removal notice line, found $($noticeLines.Count)"
    }
    Write-Host "  PASS: req-011: exactly one removal notice"

    if (Test-Path -LiteralPath (Join-Path $staleDir '.claude\hooks\telemetry')) {
        throw "FAIL: req-011: stale hook folder .claude\hooks\telemetry was not removed"
    }
    $cleanSettings = Get-Content -Raw -LiteralPath (Join-Path $staleDir '.claude\settings.json')
    if ($cleanSettings -match 'context-mode') {
        throw "FAIL: req-011: stale context-mode entry remains in settings.json"
    }
    Write-Host "  PASS: req-011: stale entry and stale folder are gone"

    if ($cleanSettings -notmatch 'my-own-bash-guard\.mjs') {
        throw "FAIL: req-011: the hand-added Bash hook did not survive the clean-up"
    }
    Write-Host "  PASS: req-011: the hand-added hook survives"

    $staleMarker = Get-Content -Raw -LiteralPath (Join-Path $staleDir '.claude\.ravintio-setup-flags')
    if ($staleMarker -match 'context-mode-mcp') {
        throw "FAIL: req-011: the retired flag appears in .ravintio-setup-flags (found: '$staleMarker')"
    }
    Write-Host "  PASS: req-011: .ravintio-setup-flags holds no retired flag"
    # END retired-integrations

    Write-Host "SUCCESS: All setup.ps1 tests passed."
}
finally {
    Set-Location $originalLocation
    if (Test-Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }
}

