# OpenCode - tool configuration (Tier 2: Bun/TS plugin shim)
# Windows PowerShell equivalent of setup/opencode.sh

# This file lives in ravintio-framework\setup\, so the framework root is one
# level up and the project root two levels up. Parity with setup/opencode.sh.
$ScriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ProjectRoot = Split-Path -Parent $ScriptDir
$OpenCodeJson = Join-Path $ProjectRoot "opencode.json"
$PluginSrc = Join-Path $ScriptDir "hooks\adapters\opencode"
$PluginDest = Join-Path $ProjectRoot ".opencode\plugins\@ravintio\opencode-hooks"
$HooksDest = Join-Path $ProjectRoot ".opencode\hooks"

Write-Host ""
Write-Host "  Setting up OpenCode (Tier 2: plugin shim)"

# Verify Bun
if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
    Write-Host "  ! Warning: bun not found in PATH. Ensure OpenCode is installed and bun is in your PATH."
}

# Copy plugin source
New-Item -ItemType Directory -Force -Path $PluginDest | Out-Null
Copy-Item "$PluginSrc\index.ts" "$PluginDest\index.ts" -Force
Copy-Item "$PluginSrc\package.json" "$PluginDest\package.json" -Force
Write-Host "  + .opencode\plugins\@ravintio\opencode-hooks\"

# Copy shared hook scripts
New-Item -ItemType Directory -Force -Path "$HooksDest\enforcement" | Out-Null
Get-ChildItem "$ScriptDir\hooks\enforcement\*.mjs" | ForEach-Object {
    Copy-Item $_.FullName "$HooksDest\enforcement\$($_.Name)" -Force
    Write-Host "  + .opencode\hooks\enforcement\$($_.Name)"
}

# Register plugin in opencode.json (idempotent). Parity with setup/opencode.sh:
# if the file exists but is not valid JSON, it is left byte-identical and setup
# carries on with a warning. Every write goes through Write-SettingsFile from
# setup.ps1 (temporary file, then a rename), or the same pattern when this
# script runs on its own.
$pluginRef = ".opencode/plugins/@ravintio/opencode-hooks/index.ts"

function Write-OpenCodeJson {
    param([string]$Content)
    if (Get-Command Write-SettingsFile -ErrorAction SilentlyContinue) {
        $written = Write-SettingsFile -SettingsPath $OpenCodeJson -Content $Content
        return ($written -ne $false)
    }
    $tmp = Join-Path $ProjectRoot (".opencode.json.ravintio-tmp-{0}" -f [guid]::NewGuid().ToString('N'))
    try {
        [System.IO.File]::WriteAllText($tmp, $Content + "`n", (New-Object System.Text.UTF8Encoding($false)))
        Move-Item -LiteralPath $tmp -Destination $OpenCodeJson -Force -ErrorAction Stop
        return $true
    } catch {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        Write-Host "  ! could not write opencode.json ($($_.Exception.Message)) - left unchanged"
        return $false
    }
}

if (Get-Item -LiteralPath $OpenCodeJson -Force -ErrorAction SilentlyContinue) {
    $json = $null
    $reason = $null
    try {
        $json = Get-Content -LiteralPath $OpenCodeJson -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($json -isnot [System.Management.Automation.PSCustomObject]) { $reason = 'not a JSON object' }
        elseif ($json.PSObject.Properties['plugins'] -and $null -ne $json.plugins -and
                $json.plugins -isnot [System.Array]) { $reason = 'no plugins list' }
    } catch {
        $reason = $_.Exception.Message
    }
    if ($reason) {
        Write-Host "  ! opencode.json is not valid JSON ($reason) - left unchanged, skipped plugin registration"
    } else {
        $plugins = @()
        if ($json.PSObject.Properties['plugins'] -and $null -ne $json.plugins) { $plugins = @($json.plugins) }
        if ($plugins -contains $pluginRef) {
            Write-Host "  - opencode.json (plugin already registered)"
        } else {
            $plugins += $pluginRef
            if ($json.PSObject.Properties['plugins']) { $json.plugins = $plugins }
            else { $json | Add-Member -MemberType NoteProperty -Name plugins -Value $plugins }
            if (Write-OpenCodeJson -Content ($json | ConvertTo-Json -Depth 10)) {
                Write-Host "  ~ opencode.json (plugin registered)"
            }
        }
    }
} else {
    if (Write-OpenCodeJson -Content (@{ plugins = @($pluginRef) } | ConvertTo-Json)) {
        Write-Host "  + opencode.json (created)"
    }
}

Write-Host "  [RAVINTIO] OpenCode hooks installed."
