<#
.SYNOPSIS
    RAVINTIO Setup - Configures skills for your agentic coding tool.

.DESCRIPTION
    Copies RAVINTIO skills into the directory structure each coding tool expects.
    Each tool's specific config lives in setup/<tool>.ps1.
    This script handles shared logic only.

.EXAMPLE
    .\ravintio-framework\setup.ps1 claude-code
    .\ravintio-framework\setup.ps1 all
#>

# Skill subcommands — delegate to skill-sync.ps1 and exit immediately (TD-006, REQ-024)
$_skillSubcmds = @('add-skill','remove-skill','preserve-skill','unpreserve-skill')
if ($args.Count -ge 1 -and $args[0] -in $_skillSubcmds) {
    $syncOp     = $args[0] -replace '-skill$',''   # add-skill→add, preserve-skill→preserve
    $syncScript = Join-Path $PSScriptRoot 'scripts\skill-sync.ps1'
    if (-not (Test-Path $syncScript)) {
        Write-Host "Error: skill-sync.ps1 not found. Re-run setup.ps1 first."
        exit 1
    }
    $restArgs = if ($args.Count -gt 1) { $args[1..($args.Count - 1)] } else { @() }
    & $syncScript -Operation $syncOp @restArgs
    exit $LASTEXITCODE
}

# Manual arg parsing — supports --flag style for cross-platform consistency
$Tool = $null
$StrictOrchestrator = $false
$IncludeFullSkillLibrary = $false
$i = 0
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        '--strict-orchestrator'       { $StrictOrchestrator = $true; $i++ }
        '--include-full-skill-library' { $IncludeFullSkillLibrary = $true; $i++ }
        # BEGIN retired-integrations (0000030)
        # Flags for the Context Mode and Telemetry integrations, removed in 0.29.0
        # (0000030 ADR-003). Setup still accepts them so a refresh from an old install
        # marker succeeds. Each prints one notice and changes nothing. None is ever
        # recorded in the install marker, and the --backend-url value is consumed
        # without validation. Parity with setup.sh.
        '--context-mode-mcp' {
            Write-Host "  ! --context-mode-mcp was removed in 0.29.0 and has no effect."; $i++
        }
        '--structured-telemetry-mcp' {
            Write-Host "  ! --structured-telemetry-mcp was removed in 0.29.0 and has no effect."; $i++
        }
        '--backend-url' {
            Write-Host "  ! --backend-url was removed in 0.29.0 and has no effect."; $i++
            if ($i -lt $args.Count -and $args[$i] -notlike '-*') { $i++ }
        }
        # END retired-integrations (0000030)
        default {
            if ($args[$i] -like '-*') { Write-Host "Unknown flag: $($args[$i])"; exit 1 }
            else { $Tool = $args[$i]; $i++ }
        }
    }
}

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$SkillsSrc = Join-Path $ScriptDir 'skills'
$WorkflowsSrc = Join-Path $ScriptDir 'workflows'
$SetupDir = Join-Path $ScriptDir 'setup'

# Old-name read kept through 0.x and removed at 1.0.0 (ADR-004, ADR-010):
# stop before any write while an old pack or overrides folder exists.
foreach ($oldDir in @('planifest-framework', 'planifest-overrides')) {
    if (Test-Path -LiteralPath (Join-Path $ProjectRoot $oldDir)) {
        [Console]::Error.WriteLine("Error: found the old folder ${oldDir}/ at the project root.")
        [Console]::Error.WriteLine("Run the migration migrate-0.37.0-ravintio-rename first, then run setup again.")
        exit 1
    }
}

$ValidTools = @('claude-code', 'cursor', 'codex', 'antigravity', 'copilot', 'windsurf', 'cline', 'roo-code', 'opencode')

# --- Shared functions ---

# Shared settings-file helpers (0000030 ADR-004). If a settings file is not valid
# JSON, every writer leaves it byte-identical and skips it, so setup still
# finishes. Every write goes to a temporary file in the same folder, which is
# then moved into place, so a crash can never leave a truncated file.
function Test-SettingsFileReadable {
    param([string]$SettingsPath, [string]$Label, [string]$What)
    if (-not (Test-Path $SettingsPath)) { return $true }
    try {
        Get-Content -Raw -Path $SettingsPath | ConvertFrom-Json -ErrorAction Stop | Out-Null
        return $true
    } catch {
        Write-Host "  ! $Label is not valid JSON - left unchanged, skipped $What"
        return $false
    }
}

function Write-SettingsFile {
    param([string]$SettingsPath, [string]$Content)
    $dir = Split-Path -Parent $SettingsPath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    # The temporary file has a random name and is created exclusively
    # (CreateNew), so a planted file or link at that name makes the write fail
    # rather than write through. It is UTF-8 without a byte order mark.
    $tmp = Join-Path $dir (".{0}.ravintio-tmp-{1}" -f (Split-Path -Leaf $SettingsPath), [guid]::NewGuid().ToString('N'))
    $created = $false
    # A failed write or rename warns, removes the temporary file, and leaves the
    # original untouched. Setup carries on (ADR-004 fails open). Returns $true
    # when the file was written.
    try {
        $stream = [System.IO.File]::Open($tmp, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write)
        $created = $true
        try {
            $bytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes($Content + [Environment]::NewLine)
            $stream.Write($bytes, 0, $bytes.Length)
        } finally {
            $stream.Dispose()
        }
        Move-Item -LiteralPath $tmp -Destination $SettingsPath -Force -ErrorAction Stop
        return $true
    } catch {
        if ($created) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
        Write-Host "  ! could not write $SettingsPath ($($_.Exception.Message)) - left unchanged"
        return $false
    }
}

# The same helpers for inline Node scripts, mirroring SETTINGS_JS_HELPERS in
# setup.sh. The JavaScript uses single quotes only, because Windows PowerShell
# does not escape embedded double quotes in arguments to native commands.
$SettingsJsHelpers = @'
const __fs = require('fs'), __path = require('path');
function readSettings(sf, label, what) {
  if (!__fs.existsSync(sf)) return {};
  try {
    return JSON.parse(__fs.readFileSync(sf, 'utf8').replace(/^﻿/, ''));
  } catch (e) {
    console.log('  ! ' + label + ' is not valid JSON (' + e.message + ') - left unchanged, skipped ' + what);
    return null;
  }
}
function writeSettings(sf, s) {
  // The temporary file has a random name and is created exclusively (wx), so a
  // planted file or link at that name makes the write fail rather than write
  // through. It keeps the mode of the target. On any failure the temporary file is
  // removed, the target is left unchanged, and a warning is printed.
  let tmp = null, created = false;
  try {
    __fs.mkdirSync(__path.dirname(sf), { recursive: true });
    let mode = null;
    try { mode = __fs.statSync(sf).mode & 0o7777; } catch (e) { mode = null; }
    tmp = __path.join(__path.dirname(sf), '.' + __path.basename(sf) + '.ravintio-tmp-' +
                      require('crypto').randomBytes(8).toString('hex'));
    const fd = __fs.openSync(tmp, 'wx', mode === null ? 0o666 : mode);
    created = true;
    try { __fs.writeFileSync(fd, JSON.stringify(s, null, 2) + '\n'); } finally { __fs.closeSync(fd); }
    if (mode !== null) __fs.chmodSync(tmp, mode);
    __fs.renameSync(tmp, sf);
    return true;
  } catch (e) {
    if (created) { try { __fs.unlinkSync(tmp); } catch (e2) {} }
    console.log('  ! could not write ' + sf + ' (' + e.message + ') - left unchanged');
    return false;
  }
}
'@

function Copy-RavintioSkills {
    param($TargetDir)

    Get-ChildItem -Path $SkillsSrc -Directory | ForEach-Object {
        $skillName = $_.Name
        $srcDir = $_.FullName
        $destDir = Join-Path $TargetDir $skillName
        
        $srcSkillMd = Join-Path $srcDir "SKILL.md"
        if (Test-Path $srcSkillMd) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            Copy-Item -Path $srcSkillMd -Destination $destDir -Force

            # Rewrite relative paths to match bundled directory structure
            $skillMdPath = Join-Path $destDir "SKILL.md"
            $skillContent = Get-Content -Path $skillMdPath -Raw -Encoding UTF8
            $skillContent = $skillContent -replace '\.\./templates/', './assets/templates/'
            $skillContent = $skillContent -replace '\.\./standards/reference/', './references/reference/'
            $skillContent = $skillContent -replace '\.\./standards/', './references/'
            $skillContent = $skillContent -replace '\.\./schemas/', './assets/schemas/'
            [System.IO.File]::WriteAllText($skillMdPath, $skillContent, (New-Object System.Text.UTF8Encoding $false))

            Write-Host "  + $skillName/SKILL.md"
            
            foreach ($optDir in @('scripts', 'assets', 'references')) {
                $srcOptDir = Join-Path $srcDir $optDir
                if (Test-Path $srcOptDir) {
                    Copy-Item -Path $srcOptDir -Destination $destDir -Recurse -Force
                }
            }

            # The skill's own references/*.md link to ../standards/. Bundled standards
            # land beside them, so rewrite those links. Bundled standards stay untouched.
            $srcRefsDir = Join-Path $srcDir "references"
            if (Test-Path $srcRefsDir) {
                Get-ChildItem -Path $srcRefsDir -Recurse -File -Filter '*.md' | ForEach-Object {
                    $relPath = $_.FullName.Substring($srcRefsDir.Length).TrimStart('\', '/')
                    $destRef = Join-Path (Join-Path $destDir "references") $relPath
                    $refContent = Get-Content -Path $destRef -Raw -Encoding UTF8
                    $refContent = $refContent -replace '\.\./standards/reference/', './reference/'
                    $refContent = $refContent -replace '\.\./standards/', './'
                    [System.IO.File]::WriteAllText($destRef, $refContent, (New-Object System.Text.UTF8Encoding $false))
                }
            }

            # Parse bundle_templates and bundle_standards from SKILL.md frontmatter
            $rawContent = Get-Content -Path $srcSkillMd -Raw
            $bundleTemplates = @()
            $bundleStandards = @()
            if ($rawContent -match '(?m)^bundle_templates:\s*\[([^\]]*)\]') {
                $bundleTemplates = $Matches[1].Trim() -split '\s*,\s*' | Where-Object { $_ }
            }
            if ($rawContent -match '(?m)^bundle_standards:\s*\[([^\]]*)\]') {
                $bundleStandards = $Matches[1].Trim() -split '\s*,\s*' | Where-Object { $_ }
            }

            # Bundle only declared templates (or all if no manifest found)
            $templatesSrc = Join-Path $ScriptDir "templates"
            if (Test-Path $templatesSrc) {
                $destTemplates = Join-Path $destDir "assets\templates"
                New-Item -ItemType Directory -Path $destTemplates -Force | Out-Null
                if ($bundleTemplates.Count -gt 0) {
                    foreach ($tpl in $bundleTemplates) {
                        $tplPath = Join-Path $templatesSrc $tpl
                        if (Test-Path $tplPath) {
                            Copy-Item -Path $tplPath -Destination $destTemplates -Force
                        }
                    }
                    Write-Host "    templates: selective ($($bundleTemplates.Count) files)"
                }
                else {
                    Copy-Item -Path "$templatesSrc\*" -Destination $destTemplates -Recurse -Force
                    Write-Host "    templates: all (no manifest)"
                }
            }

            # Always bundle schemas (small, universally needed)
            $schemasSrc = Join-Path $ScriptDir "schemas"
            if (Test-Path $schemasSrc) {
                $destSchemas = Join-Path $destDir "assets\schemas"
                New-Item -ItemType Directory -Path $destSchemas -Force | Out-Null
                Copy-Item -Path "$schemasSrc\*" -Destination $destSchemas -Recurse -Force
            }

            # Bundle only declared standards (or all top-level if no manifest found)
            $standardsSrc = Join-Path $ScriptDir "standards"
            if (Test-Path $standardsSrc) {
                $destRefs = Join-Path $destDir "references"
                New-Item -ItemType Directory -Path $destRefs -Force | Out-Null
                if ($bundleStandards.Count -gt 0) {
                    foreach ($std in $bundleStandards) {
                        $stdPath = Join-Path $standardsSrc $std
                        if (Test-Path $stdPath) {
                            Copy-Item -Path $stdPath -Destination $destRefs -Force
                        }
                    }
                    Write-Host "    standards: selective ($($bundleStandards.Count) files)"
                }
                else {
                    # No manifest - copy all top-level standards (skip reference/ subdirectory)
                    Get-ChildItem -Path $standardsSrc -File | ForEach-Object {
                        Copy-Item -Path $_.FullName -Destination $destRefs -Force
                    }
                    Write-Host "    standards: all top-level (no manifest)"
                }
            }
        }
    }
}

function Copy-ExternalSkills {
    param($TargetDir)

    $extSkillsDir = Join-Path $ScriptDir 'external-skills'
    if (-not (Test-Path $extSkillsDir)) {
        Write-Host "  ! Warning: external-skills/ not found — skipping"
        return
    }

    $count = 0
    Get-ChildItem -Path $extSkillsDir -Directory | ForEach-Object {
        $skillName = $_.Name
        $srcDir = $_.FullName

        $srcSkillMd = Join-Path $srcDir 'SKILL.md'
        if (-not (Test-Path $srcSkillMd)) {
            Write-Host "  ! [external] $skillName — missing SKILL.md, skipping"
            return
        }
        $srcAttrib = Join-Path $srcDir 'attribution.txt'
        if (-not (Test-Path $srcAttrib)) {
            Write-Host "  ! [external] $skillName — missing attribution.txt, skipping"
            return
        }

        $destDir = Join-Path $TargetDir $skillName
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        Copy-Item -Path $srcSkillMd -Destination $destDir -Force
        Copy-Item -Path $srcAttrib -Destination $destDir -Force
        Write-Host "  + [external] $skillName/SKILL.md"
        $count++
    }

    if ($count -gt 0) {
        Write-Host "  [external-skills] $count skill(s) installed"
    } else {
        Write-Host "  [external-skills] no valid skills found (each needs SKILL.md + attribution.txt)"
    }
}

function Write-RavintioBootFile {
    # Boot files are disposable build outputs (0000029 ADR-001): always
    # regenerate from the current template so template fixes propagate on
    # every run. Durable local customization lives in
    # ravintio-overrides/instructions/ and is re-applied by
    # Append-OverrideInstructions after this write.
    param($RelPath, $Content)

    $fullPath = Join-Path $ProjectRoot $RelPath
    $dir = Split-Path -Parent $fullPath
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    if (-not (Test-Path $fullPath)) {
        Set-Content -Path $fullPath -Value $Content -Encoding UTF8
        Write-Host "  + $RelPath (created)"
    }
    else {
        Set-Content -Path $fullPath -Value $Content -Encoding UTF8
        Write-Host "  ~ $RelPath (regenerated from template)"
    }
}

function Copy-RavintioWorkflow {
    param($WorkflowFile, $TargetDir)

    $name = [System.IO.Path]::GetFileNameWithoutExtension($WorkflowFile)
    $destFile = Join-Path $TargetDir "$name.md"

    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    Copy-Item -Path $WorkflowFile -Destination $destFile -Force
    Write-Host "  + workflows/$name.md"
}

function Merge-EnforcementHookSettings {
    # Merge gate-write and shell-write-guard (PreToolUse), auto-trigger-orchestrator, check-orchestrator-presence,
    # and check-design (UserPromptSubmit) into settings.json. Always installed,
    # whatever flags are passed. Idempotent.
    param(
        [string]$SettingsPath,
        [string]$SettingsRel,
        [string]$HooksDir
    )

    if (-not (Test-SettingsFileReadable -SettingsPath $SettingsPath -Label $SettingsRel -What 'enforcement hook wiring')) { return }

    $preToolEntry = @{
        matcher = 'Write|Edit'
        hooks   = @(@{ type = 'command'; command = "node $HooksDir/gate-write.mjs" })
    }
    # req-010 (ADR-006): the Bash shell-write guard, registered for Claude Code only.
    $shellGuardEntry = @{
        matcher = 'Bash'
        hooks   = @(@{ type = 'command'; command = "node $HooksDir/shell-write-guard.mjs" })
    }
    $autoTriggerEntry = @{
        matcher = '.*'
        hooks   = @(@{ type = 'command'; command = "node $HooksDir/auto-trigger-orchestrator.mjs" })
    }
    $presenceEntry = @{
        matcher = '.*'
        hooks   = @(@{ type = 'command'; command = "node $HooksDir/check-orchestrator-presence.mjs" })
    }
    $userPromptEntry = @{
        matcher = '.*'
        hooks   = @(@{ type = 'command'; command = "node $HooksDir/check-design.mjs" })
    }

    if (Test-Path $SettingsPath) {
        $existing = Get-Content -Raw -Path $SettingsPath | ConvertFrom-Json

        if (-not $existing.hooks) {
            $existing | Add-Member -NotePropertyName 'hooks' -NotePropertyValue ([PSCustomObject]@{}) -Force
        }

        # Merge PreToolUse — remove stale gate-write entry, append fresh one
        if (-not $existing.hooks.PreToolUse) {
            $existing.hooks | Add-Member -NotePropertyName 'PreToolUse' -NotePropertyValue @() -Force
        }
        $filtered = @($existing.hooks.PreToolUse | Where-Object {
            -not ($_.hooks | Where-Object { $_.command -match 'gate-write' })
        })
        # Remove only the RAVINTIO Bash group, so a Bash group the human on the loop added stays
        $filtered = @($filtered | Where-Object {
            -not ($_.matcher -eq 'Bash' -and ($_.hooks | Where-Object { $_.command -match 'shell-write-guard' }))
        })
        $existing.hooks.PreToolUse = $filtered + $preToolEntry + $shellGuardEntry

        # Merge UserPromptSubmit — remove stale entries, append fresh ones in order
        if (-not $existing.hooks.UserPromptSubmit) {
            $existing.hooks | Add-Member -NotePropertyName 'UserPromptSubmit' -NotePropertyValue @() -Force
        }
        $filtered = @($existing.hooks.UserPromptSubmit | Where-Object {
            -not ($_.hooks | Where-Object {
                $_.command -match 'auto-trigger-orchestrator' -or
                $_.command -match 'check-orchestrator-presence' -or
                $_.command -match 'check-design'
            })
        })
        $existing.hooks.UserPromptSubmit = $filtered + $autoTriggerEntry + $presenceEntry + $userPromptEntry

        $null = Write-SettingsFile -SettingsPath $SettingsPath -Content ($existing | ConvertTo-Json -Depth 10)
        Write-Host "  ~ $SettingsRel (enforcement hook entries merged)"
    }
    else {
        $settings = [PSCustomObject]@{
            hooks = [PSCustomObject]@{
                PreToolUse       = @($preToolEntry, $shellGuardEntry)
                UserPromptSubmit = @($autoTriggerEntry, $presenceEntry, $userPromptEntry)
            }
        }
        $null = Write-SettingsFile -SettingsPath $SettingsPath -Content ($settings | ConvertTo-Json -Depth 10)
        Write-Host "  + $SettingsRel (created with enforcement hook entries)"
    }
}

function ConvertTo-RavintioHashtable {
    # Windows PowerShell 5.1 has no ConvertFrom-Json -AsHashtable (PowerShell 6+
    # only). Convert the parsed PSCustomObject tree to hashtables and arrays so
    # 5.1 and 7 give the same result. Scalars pass through unchanged.
    param($InputObject)

    if ($null -eq $InputObject) { return $null }
    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        $table = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $table[$property.Name] = ConvertTo-RavintioHashtable -InputObject $property.Value
        }
        return $table
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        $items = @()
        foreach ($item in $InputObject) {
            $items += , (ConvertTo-RavintioHashtable -InputObject $item)
        }
        return , $items
    }
    return $InputObject
}

function Merge-AllowedTools {
    # Idempotently add "Agent" to allowedTools in .claude/settings.json (REQ-002).
    # Preserves existing allowedTools entries — additive merge only.
    param([string]$SettingsPath)

    if (-not (Test-SettingsFileReadable -SettingsPath $SettingsPath -Label '.claude/settings.json' -What 'allowedTools update')) { return }

    $settings = @{}
    if (Test-Path $SettingsPath) {
        $raw = Get-Content -Raw -Path $SettingsPath -Encoding UTF8
        $parsed = $raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        $settings = ConvertTo-RavintioHashtable -InputObject $parsed
        if (-not ($settings -is [hashtable])) { $settings = @{} }
    }

    $existing = if ($settings.ContainsKey('allowedTools') -and $settings['allowedTools']) {
        @($settings['allowedTools'])
    } else { @() }

    if ($existing -notcontains 'Agent') {
        $settings['allowedTools'] = $existing + @('Agent')
        $null = Write-SettingsFile -SettingsPath $SettingsPath -Content ($settings | ConvertTo-Json -Depth 10)
        Write-Host "  ~ .claude/settings.json (Agent added to allowedTools)"
    } else {
        Write-Host "  - .claude/settings.json (Agent already in allowedTools)"
    }
}

function Install-EnforcementHooks {
    # Copy the enforcement hooks (gate-write.mjs, check-design.mjs, and their shared
    # modules) and wire settings.json. Always runs — no flag required.
    param(
        [string]$HooksSrcRel,
        [string]$HooksDirRel,
        [string]$SettingsRel
    )

    $src      = Join-Path $ScriptDir $HooksSrcRel
    $dest     = Join-Path $ProjectRoot $HooksDirRel
    $settings = Join-Path $ProjectRoot $SettingsRel

    if (-not (Test-Path $src)) {
        Write-Host "  ! Warning: enforcement hook scripts not found at $src — skipping"
        return
    }

    Write-Host ""
    Write-Host "  Installing RAVINTIO enforcement hooks"

    New-Item -ItemType Directory -Path $dest -Force | Out-Null

    Get-ChildItem -Path $src -Filter '*.mjs' | ForEach-Object {
        $destFile = Join-Path $dest $_.Name
        Copy-Item -Path $_.FullName -Destination $destFile -Force
        Write-Host "  + $HooksDirRel/$($_.Name)"
    }

    Merge-EnforcementHookSettings -SettingsPath $settings -SettingsRel $SettingsRel -HooksDir $HooksDirRel
}

function Install-Tier1Hooks {
    # Copies the Tier 1 adapter + shared enforcement scripts (REQ-009).
    param(
        [string]$AdapterSrcRel,   # e.g. hooks\adapters\cursor.mjs
        [string]$AdapterDestRel,  # e.g. .cursor\hooks\adapters\cursor.mjs
        [string]$HooksInstallDir  # e.g. .cursor\hooks
    )

    $adapterSrc  = Join-Path $ScriptDir $AdapterSrcRel
    $adapterDest = Join-Path $ProjectRoot $AdapterDestRel
    $hooksDir    = Join-Path $ProjectRoot $HooksInstallDir

    if (-not (Test-Path $adapterSrc)) {
        Write-Host "  ! Warning: Tier 1 adapter not found at $adapterSrc — skipping"
        return
    }

    Write-Host ""
    Write-Host "  Installing RAVINTIO Tier 1 adapter hooks (REQ-009)"

    # Copy adapter
    $adapterDir = Split-Path -Parent $adapterDest
    New-Item -ItemType Directory -Path $adapterDir -Force | Out-Null
    Copy-Item -Path $adapterSrc -Destination $adapterDest -Force
    Write-Host "  + $AdapterDestRel"

    # Copy enforcement scripts (gate-write, check-design, auto-trigger-orchestrator)
    $enfSrc  = Join-Path $ScriptDir 'hooks\enforcement'
    $enfDest = Join-Path $hooksDir 'enforcement'
    if (Test-Path $enfSrc) {
        New-Item -ItemType Directory -Path $enfDest -Force | Out-Null
        Get-ChildItem -Path $enfSrc -Filter '*.mjs' | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination (Join-Path $enfDest $_.Name) -Force
            Write-Host "  + $HooksInstallDir\enforcement\$($_.Name)"
        }
    }

    Write-Host "  [RAVINTIO] Tier 1 adapter hooks installed."
}

function Invoke-SettingsNodeScript {
    # Runs an inline Node script against one settings file, with the shared
    # helpers prepended. Values reach the script through environment variables,
    # never through string interpolation, so no quoting can break the script.
    param([string]$SettingsPath, [string]$SettingsRel, [string]$AdapterCmd, [string]$Js)

    $env:RAVINTIO_SETTINGS     = $SettingsPath
    $env:RAVINTIO_SETTINGS_REL = $SettingsRel
    $env:RAVINTIO_ADAPTER_CMD  = $AdapterCmd
    try {
        node -e ($SettingsJsHelpers + $Js)
    } finally {
        Remove-Item Env:RAVINTIO_SETTINGS, Env:RAVINTIO_SETTINGS_REL, Env:RAVINTIO_ADAPTER_CMD -ErrorAction SilentlyContinue
    }
}

function Install-Tier1HookRegistration {
    # Writes PreToolUse hook registration pointing to the Tier 1 adapter (REQ-009).
    param(
        [string]$AdapterDestRel,  # e.g. .cursor\hooks\adapters\cursor.mjs
        [string]$SettingsRel      # e.g. .cursor\settings.json
    )

    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host "  ! Warning: node not found — skipping $SettingsRel Tier 1 hook registration"
        return
    }

    $js = @'
const adapterCmd = process.env.RAVINTIO_ADAPTER_CMD;
const sf  = process.env.RAVINTIO_SETTINGS;
const rel = process.env.RAVINTIO_SETTINGS_REL;
const s = readSettings(sf, rel, 'Tier 1 adapter hook registration');
if (s === null) process.exit(0);
s.hooks = s.hooks || {};
s.hooks.PreToolUse = (s.hooks.PreToolUse || [])
  .filter(h => !['Write','Edit'].includes(h.matcher) ||
               !(h.hooks||[]).some(e => (e.command||'').includes('gate-write')));
s.hooks.PreToolUse.push(
  {matcher:'Write', hooks:[{type:'command',command:adapterCmd}]},
  {matcher:'Edit',  hooks:[{type:'command',command:adapterCmd}]}
);
writeSettings(sf, s);
console.log('  ~ ' + rel + ' (Tier 1 adapter hook registration written)');
'@
    Invoke-SettingsNodeScript -SettingsPath (Join-Path $ProjectRoot $SettingsRel) -SettingsRel $SettingsRel `
        -AdapterCmd "node $AdapterDestRel gate-write" -Js $js
}

function Install-BeforeSubmitHookRegistration {
    # Wires beforeSubmitPrompt → check-design for tools that expose that event (REQ-018).
    param(
        [string]$AdapterDestRel,  # e.g. .cursor\hooks\adapters\cursor.mjs
        [string]$SettingsRel      # e.g. .cursor\settings.json
    )

    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host "  ! Warning: node not found — skipping beforeSubmitPrompt check-design registration"
        return
    }

    $js = @'
const adapterCmd = process.env.RAVINTIO_ADAPTER_CMD;
const sf  = process.env.RAVINTIO_SETTINGS;
const rel = process.env.RAVINTIO_SETTINGS_REL;
const s = readSettings(sf, rel, 'beforeSubmitPrompt check-design registration');
if (s === null) process.exit(0);
s.hooks = s.hooks || {};
s.hooks.beforeSubmitPrompt = (s.hooks.beforeSubmitPrompt || [])
  .filter(h => !(h.hooks||[]).some(e => (e.command||'').includes('check-design')));
s.hooks.beforeSubmitPrompt.push(
  {matcher:'*', hooks:[{type:'command',command:adapterCmd}]}
);
writeSettings(sf, s);
console.log('  ~ ' + rel + ' (beforeSubmitPrompt check-design hook registered)');
'@
    Invoke-SettingsNodeScript -SettingsPath (Join-Path $ProjectRoot $SettingsRel) -SettingsRel $SettingsRel `
        -AdapterCmd "node $AdapterDestRel check-design" -Js $js
}

# BEGIN retired-integrations (0000030)
# Always-on clean-up of the Context Mode and Telemetry integrations removed in
# 0.29.0 (0000030 ADR-004, ADR-005). Parity with cleanup_retired_integrations in
# setup.sh: same order, same rules, same output. Runs for every tool on every
# setup run, before normal wiring:
#   1. settings hook entries, under any event, whose command runs a file under
#      the tool's hooks/context-mode/ or hooks/telemetry/ folder, or
#      hooks/enforcement/check-telemetry-failures.mjs or check-telemetry-receipts.mjs.
#      A group left with no hooks is dropped.
#   2. settings hook groups whose matcher is mcp__structured-telemetry-mcp__emit_event
#   3. the stale hook folders and the check-telemetry-*.mjs and phase-enum.mjs copies
#   4. .claude/telemetry-enabled, plan/.telemetry-failures/ and plan/.telemetry-receipts/
# Entries match on command path, never on matcher alone, so a hand-added hook
# stays. Prints one line per removal and nothing when nothing is found. A
# settings file that is not valid JSON is left byte-identical and only its
# clean-up is skipped. Without Node the whole pass is skipped. Setup carries on
# in every case.
function Invoke-RetiredIntegrationCleanup {
    param(
        [string]$HooksBaseRel,   # e.g. .claude/hooks or .cursor\hooks, empty if the tool installs no hook scripts
        [string]$SettingsRel     # e.g. .claude/settings.json, empty if the tool has no settings file
    )

    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host "  ! Warning: Node.js not found - skipped the retired Context Mode and Telemetry clean-up, stale entries may remain"
        return
    }

    $base = if ($HooksBaseRel) { $HooksBaseRel.Replace('\', '/').TrimEnd('/') } else { '' }

    # Steps 1 and 2: settings hook entries and groups
    if ($base -and $SettingsRel -and (Test-Path (Join-Path $ProjectRoot $SettingsRel))) {
        $cleanupJs = @'
const sf   = process.env.RAVINTIO_SETTINGS;
const rel  = process.env.RAVINTIO_SETTINGS_REL;
const base = process.env.RAVINTIO_HOOKS_BASE;
let s;
try {
  s = JSON.parse(__fs.readFileSync(sf, 'utf8').replace(/^﻿/, ''));
} catch (e) {
  console.log('  ! ' + rel + ' is not valid JSON (' + e.message + ') - left unchanged, clean-up skipped for this file');
  process.exit(0);
}
if (!s || typeof s !== 'object' || !s.hooks || typeof s.hooks !== 'object') process.exit(0);
const staleFolders = [base + '/context-mode/', base + '/telemetry/'];
const staleFiles = [base + '/enforcement/check-telemetry-failures.mjs',
                    base + '/enforcement/check-telemetry-receipts.mjs'];
const STALE_MATCHER = 'mcp__structured-telemetry-mcp__emit_event';
const stalePath = (cmd) => {
  const c = String(cmd || '').replace(/\\/g, '/');
  for (const f of staleFolders) {
    const i = c.indexOf(f);
    if (i >= 0) return c.slice(i).match(/^[^\s\x22\x27]+/)[0];
  }
  return staleFiles.find(f => c.includes(f)) || null;
};
let changed = false;
for (const event of Object.keys(s.hooks)) {
  const groups = s.hooks[event];
  if (!Array.isArray(groups)) continue;
  let kept = [];
  for (const g of groups) {
    if (g && typeof g === 'object' && Array.isArray(g.hooks)) {
      const hooks = g.hooks.filter(h => {
        const p = stalePath(h && h.command);
        if (p) console.log('  - ' + rel + ': removed ' + event + ' hook running ' + p);
        return !p;
      });
      if (hooks.length !== g.hooks.length) {
        changed = true;
        if (hooks.length === 0) continue;
        g.hooks = hooks;
      }
    } else if (g && typeof g === 'object' && 'command' in g) {
      const p = stalePath(g.command);
      if (p) {
        console.log('  - ' + rel + ': removed ' + event + ' hook running ' + p);
        changed = true;
        continue;
      }
    }
    kept.push(g);
  }
  kept = kept.filter(g => {
    if (g && g.matcher === STALE_MATCHER) {
      console.log('  - ' + rel + ': removed ' + event + ' group for matcher ' + STALE_MATCHER);
      changed = true;
      return false;
    }
    return true;
  });
  if (kept.length === 0 && groups.length > 0) delete s.hooks[event];
  else s.hooks[event] = kept;
}
if (changed) writeSettings(sf, s);
'@
        $env:RAVINTIO_SETTINGS     = Join-Path $ProjectRoot $SettingsRel
        $env:RAVINTIO_SETTINGS_REL = $SettingsRel
        $env:RAVINTIO_HOOKS_BASE   = $base
        try {
            node -e ($SettingsJsHelpers + $cleanupJs)
            if ($LASTEXITCODE -ne 0) {
                Write-Host "  ! Warning: clean-up of $SettingsRel did not finish - stale entries may remain"
            }
        } catch {
            Write-Host "  ! Warning: clean-up of $SettingsRel did not finish - stale entries may remain"
        } finally {
            Remove-Item Env:RAVINTIO_SETTINGS, Env:RAVINTIO_SETTINGS_REL, Env:RAVINTIO_HOOKS_BASE -ErrorAction SilentlyContinue
        }
    }

    # Step 3: stale hook folders and installed copies
    $stale = @()
    if ($base) {
        $stale += "$base/context-mode", "$base/telemetry"
        $enfDir = Join-Path $ProjectRoot "$base/enforcement"
        if (Test-Path -LiteralPath $enfDir) {
            Get-ChildItem -LiteralPath $enfDir -Filter 'check-telemetry-*.mjs' -Force -ErrorAction SilentlyContinue | ForEach-Object {
                $stale += "$base/enforcement/$($_.Name)"
            }
        }
        $stale += "$base/enforcement/phase-enum.mjs"
    }
    # Step 4: project-level state the retired hooks and setup wrote
    $stale += '.claude/telemetry-enabled', 'plan/.telemetry-failures', 'plan/.telemetry-receipts'

    # -LiteralPath, because -Path treats [ and * as wildcards. Get-Item -Force
    # also finds a dangling link, which Test-Path reports as missing. A symlink
    # or junction is deleted as a link, so Windows PowerShell 5.1 never recurses
    # into the folder it points to.
    # Parity with setup.sh: before a delete, every folder between the project
    # root and the stale path must be a real folder, not a symlink or junction,
    # so a linked plan\ or .claude\ never leads the delete out of the project.
    $rootFull = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/')
    foreach ($p in $stale) {
        $full = Join-Path $ProjectRoot $p
        $item = Get-Item -LiteralPath $full -Force -ErrorAction SilentlyContinue
        if ($item) {
            $inside = $false
            $dir = Split-Path -Parent $full
            while ($dir) {
                if ([System.IO.Path]::GetFullPath($dir).TrimEnd('\', '/') -eq $rootFull) { $inside = $true; break }
                $d = Get-Item -LiteralPath $dir -Force -ErrorAction SilentlyContinue
                if (-not $d -or ($d.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) { break }
                $dir = Split-Path -Parent $dir
            }
            if (-not $inside) {
                Write-Host "  ! $p resolves outside the project - not removed"
                continue
            }
            # A failed delete warns and setup carries on (ADR-004 fails open)
            try {
                if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                    (Get-Item -LiteralPath $full -Force).Delete()
                } else {
                    Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction Stop
                }
                Write-Host "  - $p (retired, removed)"
            } catch {
                Write-Host "  ! could not remove $p - left in place, delete it by hand"
            }
        }
    }
}
# END retired-integrations (0000030)

function Invoke-RavintioGuardrails {
    Write-Host ""
    Write-Host "  Activating RAVINTIO Git Guardrails"

    # Point Git to the version-controlled hooks directory
    # Windows PowerShell 5.1 turns native stderr into a terminating error under
    # $ErrorActionPreference = 'Stop'. Outside a git repository, git config writes
    # "fatal: not in a git directory", so relax the preference for this call only.
    $savedErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $hooksPathSet = $false
    try {
        # Reset first so a stale exit code from an earlier native command cannot read as success.
        $global:LASTEXITCODE = 0
        if (Get-Command git -ErrorAction SilentlyContinue) {
            git config core.hooksPath ravintio-framework/hooks 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { $hooksPathSet = $false } else { $hooksPathSet = $true }
        }
    } finally {
        $ErrorActionPreference = $savedErrorAction
    }
    if (-not $hooksPathSet) {
        # Match setup.sh: warn and carry on, but never report guardrails as active.
        Write-Host "  ! Warning: could not set core.hooksPath, the commit-msg hook is not active"
    } else {
        Write-Host "  + git config core.hooksPath ravintio-framework/hooks"
    }

    # Note: chmod is not available on Windows; hooks are made executable by setup.sh on Unix.
    # On Windows, Git for Windows respects the executable bit stored in the repo,
    # so no additional step is required here.

    # Deploy the CI/CD pipeline workflow
    $githubWorkflows = Join-Path $ProjectRoot '.github\workflows'
    $workflowSrc = Join-Path $ScriptDir 'hooks\ravintio.yml'
    if (Test-Path $workflowSrc) {
        New-Item -ItemType Directory -Path $githubWorkflows -Force | Out-Null
        $dest = Join-Path $githubWorkflows 'ravintio.yml'
        if (-not (Test-Path $dest)) {
            Copy-Item -Path $workflowSrc -Destination $dest -Force
            Write-Host "  + .github/workflows/ravintio.yml (created)"
        }
        else {
            Write-Host "  - .github/workflows/ravintio.yml (already exists, skipped)"
        }
    }

    # Deploy .gitattributes to enforce LF endings on hook scripts.
    # Without this, Git for Windows re-adds CRLF on checkout, breaking the bash shebang.
    $gitattributesSrc = Join-Path $ScriptDir '.gitattributes'
    $gitattributesDest = Join-Path $ProjectRoot '.gitattributes'
    if (Test-Path $gitattributesSrc) {
        if (-not (Test-Path $gitattributesDest)) {
            Copy-Item -Path $gitattributesSrc -Destination $gitattributesDest -Force
            Write-Host "  + .gitattributes (created - enforces LF on hook scripts)"
        }
        else {
            Write-Host "  - .gitattributes (already exists, skipped)"
        }
    }

    if ($hooksPathSet) {
        Write-Host "  $([char]0x2705) Git guardrails activated."
    }
}

function Initialize-RavintioRepo {
    Write-Host ""
    Write-Host "  Initializing Repository Structure"

    $gitignoreSrc = Join-Path $ScriptDir ".gitignore"
    $gitignoreDest = Join-Path $ProjectRoot ".gitignore"
    
    if (Test-Path $gitignoreSrc) {
        if (-not (Test-Path $gitignoreDest)) {
            Copy-Item -Path $gitignoreSrc -Destination $gitignoreDest
            Write-Host "  + .gitignore (copied)"
        }
        else {
            Write-Host "  - .gitignore (already exists at root, skipped)"
        }
    }
    else {
        Write-Host "  ! Warning: .gitignore not found in framework directory ($gitignoreSrc)"
    }

    $srcDir = Join-Path $ProjectRoot "src"
    if (-not (Test-Path $srcDir)) {
        New-Item -ItemType Directory -Path $srcDir -Force | Out-Null
        Write-Host "  + src/ (created)"
    }
    
    $srcReadme = Join-Path $srcDir "README.md"
    if (-not (Test-Path $srcReadme)) {
        Set-Content -Path $srcReadme -Value @'
# src/

Components live here. Each component is a subfolder with a `component.yml` manifest.

See [ravintio/spec/feature-structure.md](../ravintio/spec/feature-structure.md) for the canonical layout.
'@ -Encoding UTF8
        Write-Host "  + src/README.md (created)"
    }

    $planDir = Join-Path $ProjectRoot "plan"
    if (-not (Test-Path $planDir)) {
        New-Item -ItemType Directory -Path $planDir -Force | Out-Null
        Write-Host "  + plan/ (created)"
    }
    
    $planReadme = Join-Path $planDir "README.md"
    if (-not (Test-Path $planReadme)) {
        Set-Content -Path $planReadme -Value @'
# plan/

Feature specifications live here. Each feature gets a subfolder.

See [plan/feature-structure.md](feature-structure.md) for the canonical layout.
'@ -Encoding UTF8
        Write-Host "  + plan/README.md (created)"
    }

    $planStructure = Join-Path $planDir "feature-structure.md"
    if (-not (Test-Path $planStructure)) {
        Set-Content -Path $planStructure -Value @'
# RAVINTIO - Repository Structure

> The canonical layout for a RAVINTIO-managed repository. Three top-level folders, three concerns.

---

## The Three Folders

```
repo/
+-- ravintio-framework/        <- The framework (skills, templates, schemas, standards)
|                                  Drop this in. Don't modify it per-project.
|
+-- plan/                       <- The specifications (organized by feature)
|                                  Plans, briefs, specs, ADRs, risk, scope, glossary.
|                                  Everything that describes WHAT to build and WHY.
|
+-- src/                        <- The code (organized by component)
                                   Implementation, tests, config, manifests.
                                   Everything that IS the built thing.
```

---

## `ravintio-framework/` - The Framework

This folder is the RAVINTIO framework itself. It is the same across every project. You do not modify it per-feature - you update it when the framework evolves.

```
ravintio/
+-- skills/           <- Agent instructions (orchestrator + phase skills)
+-- templates/        <- File format templates for every artifact
+-- schemas/          <- JSON Schema validation definitions
+-- standards/        <- Code quality standards
+-- spec/             <- This file - the canonical structure definition
```

---

## `plan/` - The Plan/Specifications

Organized by feature. Each feature gets a subfolder. This is where humans write briefs and agents write specs. No code lives here.

```
plan/
+-- {feature-id}/
    +-- feature-brief.md          <- Human input (start here)
    +-- design.md                 <- Validated plan (orchestrator output)
    +-- pipeline-run.md              <- Audit trail (per run)
    +-- pipeline-run-phase-2.md      <- Phase 2 audit (if phased)
    |
    +-- design-requirements.md               <- Functional & non-functional requirements
    +-- design-spec-phase-2.md       <- Phase 2 spec (if phased)
    +-- openapi-spec.yaml            <- API contract
    +-- scope.md                     <- In / Out / Deferred
    +-- risk-register.md             <- Risk items with likelihood & impact
    +-- domain-glossary.md           <- Ubiquitous language
    +-- security-report.md           <- Security review findings
    +-- quirks.md                    <- Quirks and workarounds
    +-- recommendations.md           <- Improvement suggestions
    |
    +-- adr/
        +-- ADR-001-{title}.md       <- Architecture decision records
        +-- ADR-002-{title}.md
        +-- ...
```

### Path Rules - plan/

1. **Feature ID** follows the format `{0000000}-{kebab-case-name}` - a 7-digit zero-padded number prefix for chronological ordering, followed by a human-chosen kebab-case name.
2. **No nesting** - specs, ADRs, and supporting docs are flat within the feature folder. One level of subfolders only (adr/).
3. **No code** - nothing executable lives in `plan/`. If it runs, it belongs in `src/`.
4. **Phased features** append the phase number: `design-spec-phase-2.md`, `pipeline-run-phase-2.md`. The `design.md` is updated per phase, not duplicated.
5. **ADRs** are numbered sequentially. Never renumber. Superseded ADRs stay with `status: superseded`.

---

## `src/` - The Code

Organized by component. Each component is a subfolder at the top level of `src/`. The component manifest lives with the code, not with the plan.

```
src/
+-- {component-id}/
    +-- component.yml               <- Component manifest (from template)
    +-- package.json                  <- (or equivalent for the stack)
    |
    +-- src/                          <- Implementation (structure varies by stack)
    |   +-- ...
    |
    +-- tests/                        <- Tests
    |   +-- ...
    |
    +-- docs/
        +-- data-contract.md          <- Schema ownership & invariants
        +-- migrations/
            +-- proposed-{desc}.md    <- Migration proposals
```

### Path Rules - src/

1. **Component ID** is kebab-case, matches the `id` in `component.yml`.
2. **component.yml is mandatory** - every component has one. Read it before any work; update it after every build.
3. **Component-specific docs** live with the component at `src/{component-id}/docs/`. These describe the component's data contract, migrations, and technical specifics.
4. **Feature-level docs** live in `plan/`. The component's `component.yml` references the feature via the `feature` field.
5. **Existing components** that predate RAVINTIO are retrofitted by adding a `component.yml` at their root.

---

## How the Three Folders Connect

```
plan/current/design.md
    +-- lists component IDs -> src/{component-id}/component.yml
                                    +-- references feature -> plan/

plan/current/design-requirements.md
    +-- functional requirements -> implemented in -> src/{component-id}/src/

plan/current/adr/ADR-001-*.md
    +-- decisions -> followed by -> src/{component-id}/src/

plan/current/openapi-spec.yaml
    +-- API contract -> implemented in -> src/{component-id}/src/
```

The relationship is bidirectional:
- `design.md` lists all component IDs
- Each `component.yml` references its feature ID
- The plan describes WHAT; the code IS the WHAT

---

## Retrofit Ã¢â‚¬â€ Adding RAVINTIO to an Existing Repo

If the repo already has code:

1. Drop `ravintio/` into the repo root
2. Create `plan/` for the first feature
3. Move existing components under `src/` (or leave them if they're already there)
4. Add a `component.yml` to each existing component
5. The orchestrator's retrofit mode will read the codebase and infer the existing architecture

---

*Templates for each file are in [ravintio/templates/](../templates/). Skills reference these paths.*
'@ -Encoding UTF8
        Write-Host "  + plan/feature-structure.md (created)"
    }

    # Add tool ignore rules to keep context windows lean
    $ignoreContent = @"

# RAVINTIO - Token Reduction (keeps agent semantic search from bloating context)
plan/_archive/
node_modules/
dist/
build/
out/
.next/
"@

    foreach ($ignoreFile in @('.cursorignore', '.claudeignore', '.windsurfignore', '.clineignore')) {
        $ignorePath = Join-Path $ProjectRoot $ignoreFile
        Remove-OldIgnoreBlock -Path $ignorePath -Header 'Planifest - Token Reduction'
        if (-not (Test-Path $ignorePath)) {
            Set-Content -Path $ignorePath -Value $ignoreContent -Encoding UTF8
            Write-Host "  + $ignoreFile (created)"
        }
        else {
            $existing = Get-Content -Path $ignorePath -Raw
            if ($existing -notmatch "RAVINTIO - Token Reduction") {
                Add-Content -Path $ignorePath -Value $ignoreContent -Encoding UTF8
                Write-Host "  + $ignoreFile (appended RAVINTIO ignore rules)"
            }
        }
    }

    # Deploy .cursorindexingignore - excludes large reference docs from semantic
    # search indexing but keeps them accessible via explicit @ mention
    $indexingIgnoreContent = @"

# RAVINTIO - Indexing Exclusions (files accessible via @ mention but excluded from search)
*-evaluation.md
*-guide.md
tool-setup-reference.md
getting-started.md
"@

    $indexingIgnorePath = Join-Path $ProjectRoot ".cursorindexingignore"
    Remove-OldIgnoreBlock -Path $indexingIgnorePath -Header 'Planifest - Indexing Exclusions'
    if (-not (Test-Path $indexingIgnorePath)) {
        Set-Content -Path $indexingIgnorePath -Value $indexingIgnoreContent -Encoding UTF8
        Write-Host "  + .cursorindexingignore (created)"
    }
    else {
        $existing = Get-Content -Path $indexingIgnorePath -Raw
        if ($existing -notmatch "RAVINTIO - Indexing Exclusions") {
            Add-Content -Path $indexingIgnorePath -Value $indexingIgnoreContent -Encoding UTF8
            Write-Host "  + .cursorindexingignore (appended RAVINTIO rules)"
        }
    }
}

function Copy-CapabilitySkills {
    # Copies permanent capability skills from ravintio-overrides/capability-skills/
    # into the tool's skill directory (ADR-006). The tool discovers them the same way
    # it discovers built-in skills — no separate registry file needed.
    param($TargetDir)

    $capSkillsDir = Join-Path $ProjectRoot 'ravintio-overrides\capability-skills'
    if (-not (Test-Path $capSkillsDir)) { return }

    $found = @(Get-ChildItem -Path $capSkillsDir -Directory | Where-Object {
        Test-Path (Join-Path $_.FullName 'SKILL.md')
    })
    if ($found.Count -eq 0) { return }

    Write-Host ""
    Write-Host "  Syncing capability skills from ravintio-overrides/capability-skills/"
    foreach ($dir in $found) {
        $destDir = Join-Path $TargetDir $dir.Name
        Copy-Item -Path $dir.FullName -Destination $destDir -Recurse -Force
        Write-Host "  + capability-skill: $($dir.Name)"
    }
}

# Old-name read kept through 0.x and removed at 1.0.0 (ADR-004).
# Remove an ignore-file block whose header carries the old name. The block runs
# from the header line to the next blank line.
function Remove-OldIgnoreBlock {
    param([string]$Path, [string]$Header)
    if (-not (Test-Path $Path)) { return }
    $lines = @(Get-Content -Path $Path)
    if (-not ($lines | Where-Object { $_.Contains($Header) })) { return }
    $kept = @()
    $skip = $false
    foreach ($line in $lines) {
        if ($line.Contains($Header)) { $skip = $true; continue }
        if ($skip -and $line -eq '') { $skip = $false; continue }
        if (-not $skip) { $kept += $line }
    }
    Set-Content -Path $Path -Value $kept -Encoding UTF8
}

function Append-OverrideInstructions {
    # Appends project-specific instructions from ravintio-overrides/instructions/
    # to the tool's boot file. Idempotent — strips and replaces the override block
    # on every re-run so changes in ravintio-overrides/ are always reflected.
    param($BootFilePath)

    $bootPath = Join-Path $ProjectRoot $BootFilePath
    if (-not (Test-Path $bootPath)) { return }

    # Old-name read kept through 0.x and removed at 1.0.0 (ADR-004): drop a block
    # written under the old marker names so no block appears twice.
    $oldStart = '<!-- planifest-overrides:instructions:start -->'
    $oldEnd   = '<!-- planifest-overrides:instructions:end -->'
    $oldCurrent = Get-Content -Path $bootPath -Raw
    if ($oldCurrent -match [regex]::Escape($oldStart)) {
        $oldPattern = "(?s)\r?\n$([regex]::Escape($oldStart)).*?$([regex]::Escape($oldEnd))\r?\n?"
        $oldCurrent = [regex]::Replace($oldCurrent, $oldPattern, '')
        Set-Content -Path $bootPath -Value $oldCurrent.TrimEnd() -Encoding UTF8 -NoNewline
    }

    $startMarker = '<!-- ravintio-overrides:instructions:start -->'
    $endMarker   = '<!-- ravintio-overrides:instructions:end -->'

    # Strip any existing override block from a previous run
    $current = Get-Content -Path $bootPath -Raw
    if ($current -match [regex]::Escape($startMarker)) {
        $pattern = "(?s)\r?\n$([regex]::Escape($startMarker)).*?$([regex]::Escape($endMarker))\r?\n?"
        $current = [regex]::Replace($current, $pattern, '')
        Set-Content -Path $bootPath -Value $current.TrimEnd() -Encoding UTF8 -NoNewline
    }

    $instrDir = Join-Path $ProjectRoot 'ravintio-overrides\instructions'
    if (-not (Test-Path $instrDir)) { return }
    $files = @(Get-ChildItem -Path $instrDir -File -Filter '*.md' | Sort-Object Name)
    if ($files.Count -eq 0) { return }

    Write-Host ""
    Write-Host "  Appending override instructions from ravintio-overrides/instructions/"

    $block = "`n`n$startMarker`n"
    foreach ($file in $files) {
        $block += "`n" + (Get-Content -Path $file.FullName -Raw).TrimEnd() + "`n"
        Write-Host "  + $($file.Name)"
    }
    $block += "`n$endMarker"

    Add-Content -Path $bootPath -Value $block -Encoding UTF8
    Write-Host "  ~ $BootFilePath updated with override instructions"
}

function Install-WindsurfHookConfig {
    # Writes .windsurf/hooks.json registering pre_write_code, pre_mcp_tool_use,
    # and pre_user_prompt (ADR-002, REQ-016). RAVINTIO owns this file entirely.
    $windsurfDir = Join-Path $ProjectRoot '.windsurf'
    New-Item -ItemType Directory -Path $windsurfDir -Force | Out-Null

    $cmd = "node ravintio-framework/hooks/adapters/windsurf.mjs"
    $config = @{
        hooks = @{
            pre_write_code = @(@{ command = $cmd; powershell = "node ravintio-framework/hooks/adapters/windsurf.mjs" })
            pre_mcp_tool_use = @(@{ command = $cmd; powershell = "node ravintio-framework/hooks/adapters/windsurf.mjs" })
            pre_user_prompt = @(@{ command = $cmd; powershell = "node ravintio-framework/hooks/adapters/windsurf.mjs" })
        }
    }
    $configPath = Join-Path $windsurfDir 'hooks.json'
    $config | ConvertTo-Json -Depth 6 | Set-Content -Path $configPath -Encoding UTF8
    Write-Host "  + .windsurf/hooks.json (Windsurf hook registration)"
}

function Install-CopilotAdapter {
    # Writes .github/hooks/ravintio.json registering both hook events (REQ-015).
    # The adapter is copied to .github/hooks/adapters/copilot.mjs by Install-Tier1Hooks
    # and invoked from there.
    $hooksDir = Join-Path $ProjectRoot '.github\hooks'
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null

    $configPath = Join-Path $hooksDir 'ravintio.json'
    $config = @{
        version = 1
        hooks = @{
            preToolUse = @(
                @{ type = "command"; command = "node .github/hooks/adapters/copilot.mjs" }
            )
            userPromptSubmitted = @(
                @{ type = "command"; command = "node .github/hooks/adapters/copilot.mjs" }
            )
        }
    }
    $config | ConvertTo-Json -Depth 6 | Set-Content -Path $configPath -Encoding UTF8
    Write-Host "  + .github/hooks/ravintio.json (Copilot hook registration)"
}

function Invoke-RavintioSetup {
    param($ToolName)

    $toolConfigPath = Join-Path $SetupDir "$ToolName.ps1"
    if (-not (Test-Path $toolConfigPath)) {
        Write-Host "Error: no config file at setup/$ToolName.ps1"
        exit 1
    }

    # OpenCode's tool script installs as it runs, so its retired integration
    # clean-up (0000030 ADR-004) runs before the script is invoked. opencode.json
    # registers plugins only, so there are no settings hook entries to scan.
    if ($ToolName -eq 'opencode') {
        Invoke-RetiredIntegrationCleanup -HooksBaseRel '.opencode/hooks' -SettingsRel ''
    }

    # Load tool-specific config
    $toolConfig = & $toolConfigPath

    # Remove stale state from integrations retired in 0.29.0, before any wiring
    # (0000030 ADR-004). Parity with setup_tool in setup.sh: Tier 1 tools keep hook
    # scripts under HooksInstallDir, and tools with a settings file but no Tier 1
    # adapter (Claude Code) use .claude/hooks, the parent of EnforcementHooksDir.
    if ($ToolName -ne 'opencode' -and $toolConfig) {
        $hooksBaseRel = ''
        if ($toolConfig.HooksInstallDir) { $hooksBaseRel = $toolConfig.HooksInstallDir }
        elseif ($toolConfig.SettingsFile) { $hooksBaseRel = '.claude/hooks' }
        Invoke-RetiredIntegrationCleanup -HooksBaseRel $hooksBaseRel -SettingsRel $toolConfig.SettingsFile
    }

    $skillsDir = Join-Path $ProjectRoot $toolConfig.SkillsDir

    Write-Host ""
    Write-Host "  Setting up $ToolName"
    Write-Host "  Skills directory: $($toolConfig.SkillsDir)/"

    # One-time read of the old-name state (ADR-004). Old-name read kept through 0.x, removed at 1.0.0.
    $oldFlagsPath = Join-Path (Split-Path -Parent $skillsDir) '.planifest-setup-flags'
    if (Test-Path $oldFlagsPath) {
        $oldFlagsRaw = Get-Content -Path $oldFlagsPath -Raw
        if ($oldFlagsRaw -match '"--include-full-skill-library"') { $script:IncludeFullSkillLibrary = $true }
        if ($oldFlagsRaw -match '"--strict-orchestrator"') {
            $script:StrictOrchestrator = $true
            $strictPlanDir = Join-Path $ProjectRoot 'plan'
            New-Item -ItemType Directory -Path $strictPlanDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $strictPlanDir '.orchestrator-strict') -Force | Out-Null
        }
        Remove-Item -Path $oldFlagsPath -Force
        Write-Host "  ~ carried old setup flags into .ravintio-setup-flags"
    }
    $oldManifest = Join-Path $skillsDir '.planifest-manifest'
    if (Test-Path $oldManifest) {
        Get-Content -Path $oldManifest | Where-Object { $_ -ne '' } | ForEach-Object {
            $oldDirPath = $_.TrimEnd('/', '\')
            if ((Test-Path -LiteralPath $oldDirPath -PathType Container) -and ((Split-Path -Leaf $oldDirPath) -like 'planifest-*')) {
                $oldItem = Get-Item -LiteralPath $oldDirPath -Force
                if ($oldItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                    $oldItem.Delete() # unlink only, never recurse into the link target
                } else {
                    Remove-Item -LiteralPath $oldDirPath -Recurse -Force
                }
                Write-Host "  - removed old skill: $(Split-Path -Leaf $oldDirPath)"
            }
        }
        Remove-Item -Path $oldManifest -Force
    }

    # Manifest cleanup — remove only previously installed directories on re-run
    $manifest = Join-Path $skillsDir ".ravintio-manifest"
    if (Test-Path $manifest) {
        Write-Host "  Re-run detected — removing previously installed directories"
        Get-Content -Path $manifest | Where-Object { $_ -ne '' } | ForEach-Object {
            if (Test-Path $_) {
                Remove-Item -Path $_ -Recurse -Force
                Write-Host "  - removed: $(Split-Path -Leaf $_)"
            }
        }
        Remove-Item -Path $manifest -Force
    }

    # Copy skills (now automatically bundles supporting files)
    Copy-RavintioSkills -TargetDir $skillsDir

    # Copy external skills if --include-full-skill-library flag is set (REQ-001)
    if ($IncludeFullSkillLibrary) {
        Write-Host ""
        Write-Host "  Installing external skill library"
        Copy-ExternalSkills -TargetDir $skillsDir
    }

    # Copy permanent capability skills from ravintio-overrides/ (ADR-006)
    Copy-CapabilitySkills -TargetDir $skillsDir

    # Copy workflows (if tool defines a workflow dir)
    if ($toolConfig.WorkflowsDir -and (Test-Path $WorkflowsSrc)) {
        $workflowsDir = Join-Path $ProjectRoot $toolConfig.WorkflowsDir
        Get-ChildItem -Path $WorkflowsSrc -Filter '*.md' | ForEach-Object {
            Copy-RavintioWorkflow -WorkflowFile $_.FullName -TargetDir $workflowsDir
        }
    }

    # Create boot file (if tool defines one)
    if ($toolConfig.BootFile) {
        $bootContent = $toolConfig.BootContent
        if (-not $bootContent -and $toolConfig.BootTemplate) {
            $bootContentPath = Join-Path $ProjectRoot $toolConfig.BootTemplate
            $bootContent = Get-Content -Raw -Path $bootContentPath
        }
        Write-RavintioBootFile -RelPath $toolConfig.BootFile -Content $bootContent
    }

    # Append project-specific instructions to boot file (idempotent on re-run)
    if ($toolConfig.BootFile) {
        Append-OverrideInstructions -BootFilePath $toolConfig.BootFile
    }

    # Install RAVINTIO enforcement hooks unconditionally (gate-write, check-design)
    if ($toolConfig.EnforcementHooksSrc -and $toolConfig.EnforcementHooksDir -and $toolConfig.SettingsFile) {
        Install-EnforcementHooks `
            -HooksSrcRel $toolConfig.EnforcementHooksSrc `
            -HooksDirRel $toolConfig.EnforcementHooksDir `
            -SettingsRel $toolConfig.SettingsFile
    }

    # Add Agent to allowedTools so sub-agent dispatch works without per-use confirmation (REQ-002)
    if ($toolConfig.SettingsFile) {
        $settingsPath = Join-Path $ProjectRoot $toolConfig.SettingsFile
        Merge-AllowedTools -SettingsPath $settingsPath
    }

    # Install Copilot adapter when tool is copilot (REQ-015)
    if ($ToolName -eq 'copilot') {
        Write-Host ""
        Write-Host "  Installing Copilot hook registration"
        Install-CopilotAdapter
    }

    # Write Windsurf hook config when tool is windsurf (REQ-016)
    if ($ToolName -eq 'windsurf') {
        Write-Host ""
        Write-Host "  Writing Windsurf hook configuration"
        Install-WindsurfHookConfig
    }

    # Install Tier 1 adapter for tools with native hook support (REQ-009)
    if ($toolConfig.Tier -eq 1 -and $toolConfig.HookAdapterSrc) {
        Install-Tier1Hooks `
            -AdapterSrcRel  $toolConfig.HookAdapterSrc `
            -AdapterDestRel $toolConfig.HookAdapterDest `
            -HooksInstallDir $toolConfig.HooksInstallDir

        # Tier 1 hook registration requires a SettingsFile — the generic PreToolUse
        # JSON shape Install-Tier1HookRegistration writes into. Copilot has no
        # SettingsFile (it registers via its own .github/hooks/ravintio.json shape,
        # written by Install-CopilotAdapter above), so this must be independently
        # gated — mirroring setup.sh's two separate guards on TOOL_SETTINGS_FILE
        # (setup.sh ~line 1102-1103 for the copy, ~1107-1108 for the registration).
        if ($toolConfig.SettingsFile) {
            Install-Tier1HookRegistration `
                -AdapterDestRel $toolConfig.HookAdapterDest `
                -SettingsRel    $toolConfig.SettingsFile

            # Wire beforeSubmitPrompt → check-design for tools that support it (REQ-018)
            if ($toolConfig.BeforeSubmitHook -eq $true) {
                Install-BeforeSubmitHookRegistration `
                    -AdapterDestRel $toolConfig.HookAdapterDest `
                    -SettingsRel    $toolConfig.SettingsFile
            }
        }
    }

    # Write manifest listing all installed skill directories (enables safe re-run cleanup)
    New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
    $installedDirs = @(Get-ChildItem -Path $skillsDir -Directory | ForEach-Object { $_.FullName })
    if ($installedDirs.Count -gt 0) {
        $installedDirs | Set-Content -Path $manifest -Encoding UTF8
        Write-Host "  + .ravintio-manifest ($($installedDirs.Count) entries)"
    }

    # Write the flags-used marker recording what was applied at install time (REQ-008, ADR-002).
    # Guarded on SkillsDir being present: OpenCode's tool config does not return an object with
    # a SkillsDir property (pre-existing setup.ps1/opencode gap, out of scope for this feature per
    # scope.md), so this silently skips there rather than erroring under $ErrorActionPreference = 'Stop'.
    if ($toolConfig -and $toolConfig.SkillsDir) {
        $toolDir = Split-Path -Parent $toolConfig.SkillsDir
        Write-SetupConfigOverride -ToolName $ToolName | Out-Null
        Write-SetupFlagsMarker -ToolName $ToolName -ToolDir $toolDir
    }

    Write-Host "  Done."
}

# Write ravintio-overrides/setup-config/{tool}.md — the tracked, git-versioned source
# of truth for active setup flags (0000025 req-004, ADR-002 decision 1). This
# is additive: it does not replace Write-SetupFlagsMarker, and it is called BEFORE it so
# the gitignored marker is always (re)written to match this file's values for the current
# run (ADR-002 decision 3). On failure to write (e.g. permissions), warns and returns
# $false so the caller falls back to existing marker-only behavior rather than aborting
# setup (req-004 acceptance criteria, sad path).
function Write-SetupConfigOverride {
    param($ToolName)

    $configDir = Join-Path $ProjectRoot 'ravintio-overrides\setup-config'
    $configFile = Join-Path $configDir "$ToolName.md"

    $flags = @()
    if ($IncludeFullSkillLibrary) { $flags += '--include-full-skill-library' }
    if ($StrictOrchestrator) { $flags += '--strict-orchestrator' }

    $writtenAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

    $configJson = [ordered]@{
        tool       = $ToolName
        flags      = $flags
        writtenAt  = $writtenAt
    } | ConvertTo-Json -Depth 10

    $fence = [char]96 + [char]96 + [char]96
    $content = "# Setup config: $ToolName`n`n" +
        "> Tracked source of truth for active setup flags for **$ToolName**`n" +
        "> (0000025 req-004, ADR-002). The gitignored ``.ravintio-setup-flags`` marker in`n" +
        "> this tool's config directory is a local completion-status cache, reconciled to`n" +
        "> match this file on every ``setup.sh``/``setup.ps1`` run.`n`n" +
        "$fence" + "json`n$configJson`n$fence`n"

    try {
        New-Item -ItemType Directory -Path $configDir -Force -ErrorAction Stop | Out-Null
        Set-Content -Path $configFile -Value $content -Encoding UTF8 -ErrorAction Stop
        Write-Host "  + ravintio-overrides\setup-config\$ToolName.md"
        return $true
    } catch {
        Write-Warning "Could not write ravintio-overrides/setup-config/$ToolName.md — continuing with .ravintio-setup-flags-only behavior"
        return $false
    }
}

# Write the flags-used marker recording what was applied at install time (REQ-008, ADR-002).
# Called only after a tool's setup completes successfully. $ErrorActionPreference = 'Stop' means
# a failed Invoke-RavintioSetup call halts the script before this function is ever reached,
# satisfying REQ-008's "a failed install does not write the marker" requirement.
function Write-SetupFlagsMarker {
    param($ToolName, $ToolDir)

    $targetDir = Join-Path $ProjectRoot $ToolDir
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    $markerPath = Join-Path $targetDir '.ravintio-setup-flags'

    $flags = @()
    if ($IncludeFullSkillLibrary) { $flags += '--include-full-skill-library' }
    if ($StrictOrchestrator) { $flags += '--strict-orchestrator' }

    $marker = [ordered]@{
        tool          = $ToolName
        flags         = $flags
        writtenAt     = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        attemptStatus = 'completed'
    }

    $marker | ConvertTo-Json -Depth 10 | Set-Content -Path $markerPath -Encoding UTF8
    Write-Host "  + $ToolDir\.ravintio-setup-flags"
}

# --- Main ---

if (-not $Tool) {
    Write-Host ""
    Write-Host "RAVINTIO Setup"
    Write-Host ""
    Write-Host "Usage: .\ravintio-framework\setup.ps1 [tool] [flags]"
    Write-Host ""
    Write-Host "Tools:"
    foreach ($t in $ValidTools) {
        Write-Host "  $t"
    }
    Write-Host "  all"
    Write-Host ""
    Write-Host "Flags:"
    Write-Host "  --strict-orchestrator        Write plan/.orchestrator-strict to enable strict mode."
    Write-Host "                               The check-orchestrator-presence hook will require the"
    Write-Host "                               orchestrator to ack each new session before proceeding."
    Write-Host "  --include-full-skill-library Copy the curated external skill library into the tool's"
    Write-Host "                               skill directory (200+ open-source skills). Opt-in only."
    Write-Host ""
    Write-Host "Run from the repository root."
    Write-Host "Each tool's config: ravintio-framework\setup\[tool].ps1"
    exit 0
}

Write-Host "RAVINTIO Setup"
Write-Host ("=" * 40)

Initialize-RavintioRepo
Invoke-RavintioGuardrails

# Write strict-mode sentinel if --strict-orchestrator flag was passed (REQ-008)
if ($StrictOrchestrator) {
    $planDir = Join-Path $ProjectRoot 'plan'
    New-Item -ItemType Directory -Path $planDir -Force | Out-Null
    $strictPath = Join-Path $planDir '.orchestrator-strict'
    New-Item -ItemType File -Path $strictPath -Force | Out-Null
    Write-Host "  + plan/.orchestrator-strict (strict orchestrator mode enabled)"
}

$ToolLower = $Tool.ToLower()

$_syncScript = Join-Path $ScriptDir 'scripts\skill-sync.ps1'

function Invoke-SkillSync {
    param($ToolName)
    if (-not (Test-Path $_syncScript)) { return }
    try {
        & $_syncScript sync $ToolName -ErrorAction SilentlyContinue 2>$null
    } catch { }
}

if ($ToolLower -eq 'all') {
    foreach ($t in $ValidTools) {
        Invoke-RavintioSetup -ToolName $t
        Invoke-SkillSync -ToolName $t
    }
}
elseif ($ValidTools -contains $ToolLower) {
    Invoke-RavintioSetup -ToolName $ToolLower
    Invoke-SkillSync -ToolName $ToolLower
}
else {
    Write-Host "Unknown tool: $Tool"
    Write-Host "Valid tools: $($ValidTools -join ', '), all"
    exit 1
}

Write-Host ""
Write-Host "Setup complete."
Write-Host "  Source of truth: ravintio-framework/"
Write-Host "  Re-run after updating framework files."

