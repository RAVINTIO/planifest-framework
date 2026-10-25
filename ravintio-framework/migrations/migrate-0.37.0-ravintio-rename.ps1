# migrate-0.37.0-ravintio-rename.ps1 - move a consumer repo to the RAVINTIO names.
# Run it from the project root, after you copy ravintio-framework/ in and
# before you run ravintio-framework/setup.ps1. The project root may sit below
# the git top level.
#
# The helper deletes no file except the one session marker. It moves the old
# pack into .ravintio-backup/ with a plain rename, which moves a nested link or
# junction as a link and follows none. Every step skips work that is already
# done, so a rerun is safe. A run stopped after any step resumes on the next run.
#
# The .sh twin prints the same text and exits with the same codes:
#   0  done, or nothing to do
#   1  stopped before a move, or a move failed
#   3  stopped by the test hook RAVINTIO_MIGRATE_STOP_AFTER=N
#
# Parses on Windows PowerShell 5.1 and PowerShell 7. Write ${Var}: when a
# colon follows a variable inside a double-quoted string.
#
# The old brand word is built from parts so this file holds no literal copy.

$ErrorActionPreference = 'Continue'

$Old = 'plan' + 'ifest'
$OldU = 'PLAN' + 'IFEST'
$NewPack = 'ravintio-framework'
$OldPack = $Old + '-framework'
$OldOvr = $Old + '-overrides'
$NewOvr = 'ravintio-overrides'
$WfDir = '.github/workflows'
$OldWf = $WfDir + '/' + $Old + '.yml'
$NewWf = $WfDir + '/ravintio.yml'
$Backup = '.ravintio-backup'
$Session = '.claude/.' + $Old + '-session'
$StopAfter = [string]$env:RAVINTIO_MIGRATE_STOP_AFTER

# Pack-owned variable names (the req-003 inventory, retired telemetry names
# left out). Step 4 rewrites these whole names and no other.
$PackVars = @('ADAPTER_CMD', 'BASENAME', 'BOOT', 'DESIGN', 'EM_DASH', 'FILE_PATH', 'GATE', 'GITLEAKS',
    'HOOKS_BASE', 'NAME', 'OPENCODE_JSON', 'PLUGIN_REF', 'PRESENCE', 'RATCHET', 'SETTINGS',
    'SETTINGS_JS_HELPERS', 'SETTINGS_REL', 'SHELL_GUARD', 'TIER', 'TMP', 'TRIGGER', 'PROMOTED_BY',
    'PROMOTION_DATE', 'REGRESSION_DIR', 'SOURCE_FEATURE', 'SHARD_INDEX', 'SHARD_COUNT', 'SESSION_ID')

# ISO-8859-1 maps every byte to one character, so a read and a write keep the
# bytes the .sh helper keeps.
$Bytes1 = [System.Text.Encoding]::GetEncoding(28591)
$Root = (Get-Location).ProviderPath
$script:Moved = @()
$script:Changed = $false

function Get-Full([string]$Rel) {
    return [System.IO.Path]::Combine($Root, $Rel)
}

function Write-Moved {
    if ($script:Moved.Count -eq 0) {
        Write-Host 'Moved so far: nothing.'
    } else {
        Write-Host 'Moved so far:'
        foreach ($m in $script:Moved) { Write-Host "  $m" }
    }
}

# Stop-At N MESSAGE: stop with exit 1.
function Stop-At([string]$Step, [string]$Message) {
    Write-Host "ERROR: $Message"
    Write-Host "Stopped at step $Step."
    Write-Moved
    exit 1
}

# Invoke-Hook N: the test hook stops the run right after step N with exit 3.
function Invoke-Hook([string]$Step) {
    if ($StopAfter -eq $Step) {
        Write-Host "Stopped at step $Step (RAVINTIO_MIGRATE_STOP_AFTER)."
        Write-Moved
        exit 3
    }
}

# Test-Link PATH: true for a symbolic link or junction, dangling or not.
function Test-Link([string]$Rel) {
    $full = Get-Full $Rel
    $item = Get-Item -LiteralPath $full -Force -ErrorAction SilentlyContinue
    if ($null -eq $item) {
        # A dangling link can fail Get-Item on Windows PowerShell 5.1, but it
        # still shows in its parent folder's listing.
        $parent = Split-Path -Parent $full
        $leaf = Split-Path -Leaf $full
        if ($parent -and (Test-Path -LiteralPath $parent -PathType Container)) {
            $item = Get-ChildItem -LiteralPath $parent -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -eq $leaf } | Select-Object -First 1
        }
    }
    if ($null -eq $item) { return $false }
    if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { return $true }
    if ($item.PSObject.Properties['LinkType'] -and $item.LinkType) { return $true }
    return $false
}

function Test-Present([string]$Rel) {
    return ((Test-Path -LiteralPath (Get-Full $Rel)) -or (Test-Link $Rel))
}

function Test-Dir([string]$Rel) {
    return (Test-Path -LiteralPath (Get-Full $Rel) -PathType Container)
}

function Test-File([string]$Rel) {
    return (Test-Path -LiteralPath (Get-Full $Rel) -PathType Leaf)
}

# First-Link PATH...: the first path that is a link, or an empty string.
function Get-FirstLink([string[]]$Paths) {
    foreach ($p in $Paths) {
        if (Test-Link $p) { return $p }
    }
    return ''
}

$InGit = $false
if (Get-Command git -ErrorAction SilentlyContinue) {
    $inside = & git rev-parse --is-inside-work-tree 2>$null
    if ("$inside" -eq 'true') { $InGit = $true }
}

function Test-Tracked([string]$Rel) {
    if (-not $InGit) { return $false }
    $out = & git ls-files -- $Rel 2>$null
    return ("$out" -ne '')
}

# Move-Entry SRC DST STEP: git mv when git tracks SRC, else a plain rename.
function Move-Entry([string]$Src, [string]$Dst, [string]$Step) {
    if (Test-Tracked $Src) {
        & git mv $Src $Dst 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { Stop-At $Step "could not move $Src to $Dst." }
        return
    }
    try {
        if (Test-Dir $Src) {
            [System.IO.Directory]::Move((Get-Full $Src), (Get-Full $Dst))
        } else {
            [System.IO.File]::Move((Get-Full $Src), (Get-Full $Dst))
        }
    } catch {
        Stop-At $Step "could not move $Src to $Dst."
    }
}

# Get-Rewritten TEXT: TEXT with the pack path and the pack-owned variable
# names rewritten, line by line, each line ending in a newline. A name counts
# only as a whole name.
function Get-Rewritten([string]$Text) {
    if ($Text.Length -eq 0) { return '' }
    $body = $Text
    if ($body.EndsWith("`n")) { $body = $body.Substring(0, $body.Length - 1) }
    $pattern = '(?<![A-Za-z0-9_])' + $OldU + '_(' + ($PackVars -join '|') + ')(?![A-Za-z0-9_])'
    $regex = New-Object System.Text.RegularExpressions.Regex($pattern)
    $sb = New-Object System.Text.StringBuilder
    foreach ($line in $body.Split([char]10)) {
        $l = $line.Replace($OldPack + '/', $NewPack + '/')
        $l = $regex.Replace($l, 'RAVINTIO_$1')
        [void]$sb.Append($l)
        [void]$sb.Append("`n")
    }
    return $sb.ToString()
}

# Step 1: the new pack must be in place.
if (-not (Test-Dir $NewPack)) {
    Stop-At '1' "$NewPack/ not found. Copy the new $NewPack/ folder into this project, then run this helper again."
}
Write-Host "Step 1: found $NewPack/."
Invoke-Hook '1'

# Step 2: check every stop condition before the first move.
$WfParentLink = Get-FirstLink @('.github', $WfDir)
$linkChecks = @($OldPack, $OldOvr, $NewOvr, $Backup)
if ($WfParentLink -eq '') { $linkChecks += @($OldWf, $NewWf) }
foreach ($p in $linkChecks) {
    if (Test-Link $p) {
        Stop-At '2' "$p is a symlink or junction. The helper leaves it and its target untouched. Replace it with a real file or folder, then run this helper again."
    }
}
if ((Test-Present $OldOvr) -and (Test-Present $NewOvr)) {
    Stop-At '2' "both $OldOvr/ and $NewOvr/ exist. Merge them into $NewOvr/ by hand, then run this helper again."
}
if (($WfParentLink -eq '') -and (Test-Present $OldWf) -and (Test-Present $NewWf)) {
    Stop-At '2' "both $OldWf and $NewWf exist. Keep one of them, then run this helper again."
}
if ((Test-Present $Backup) -and -not (Test-Dir $Backup)) {
    Stop-At '2' "$Backup exists and is not a folder. Move it aside, then run this helper again."
}
if ((Test-Present ($Backup + '/' + $OldPack)) -and (Test-Present $OldPack)) {
    Stop-At '2' "$Backup/$OldPack/ exists while $OldPack/ is still in place. Check the older backup and move it aside, then run this helper again."
}
if ($InGit) {
    & git diff --cached --quiet --diff-filter=ACMRT -- $OldPack 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Stop-At '2' "git holds a staged edit under $OldPack/. Commit it or unstage it, then run this helper again."
    }
}
Write-Host 'Step 2: no stop condition found.'
Invoke-Hook '2'

# Step 3: move the overrides folder.
if (Test-Dir $OldOvr) {
    Move-Entry $OldOvr $NewOvr '3'
    Write-Host "Step 3: moved $OldOvr/ to $NewOvr/."
    $script:Moved += "$OldOvr/ to $NewOvr/"
    $script:Changed = $true
} else {
    Write-Host "Step 3: skipped, $OldOvr/ is not present."
}
Invoke-Hook '3'

# Step 4: rename the workflow and rewrite the pack-owned names in it.
if ($WfParentLink -ne '') {
    Write-Host "WARNING: $WfParentLink is a symlink. Skipped step 4, so nothing is written through it."
} else {
    if (Test-File $OldWf) {
        Move-Entry $OldWf $NewWf '4'
        Write-Host "Step 4: renamed $OldWf to $NewWf."
        $script:Moved += "$OldWf to $NewWf"
        $script:Changed = $true
    } else {
        Write-Host "Step 4: skipped the rename, $OldWf is not present."
    }
    if (Test-File $NewWf) {
        $wfFull = Get-Full $NewWf
        $text = $Bytes1.GetString([System.IO.File]::ReadAllBytes($wfFull))
        $newText = Get-Rewritten $text
        if ([string]::Equals($text, $newText, [System.StringComparison]::Ordinal)) {
            Write-Host "Step 4: skipped the rewrite, $NewWf holds no pack-owned old name."
        } else {
            # Write to a temporary file in the same folder, then rename it
            # over the target.
            $tmpRel = $WfDir + '/.ravintio.yml.' + ([System.IO.Path]::GetRandomFileName().Replace('.', '').Substring(0, 6))
            $tmpFull = Get-Full $tmpRel
            try {
                $fs = New-Object System.IO.FileStream($tmpFull, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write)
                $buf = $Bytes1.GetBytes($newText)
                $fs.Write($buf, 0, $buf.Length)
                $fs.Close()
            } catch {
                Stop-At '4' "could not rewrite $NewWf. The temporary file $tmpRel is left for you to check."
            }
            try {
                [System.IO.File]::Replace($tmpFull, $wfFull, $null)
            } catch {
                Stop-At '4' "could not replace $NewWf. The temporary file $tmpRel is left for you to check."
            }
            Write-Host "Step 4: rewrote the pack path and pack-owned names in $NewWf."
            $script:Changed = $true
        }
    }
}
Invoke-Hook '4'

# Step 5: remove the session marker. Setup removes the other two markers.
if (Test-Link '.claude') {
    Write-Host 'WARNING: .claude is a symlink. Skipped the marker under it, so nothing is removed through it.'
} else {
    if (Test-Link '.claude/skills') {
        Write-Host 'WARNING: .claude/skills is a symlink. Skipped the marker under it, so nothing is written through it.'
    }
    if (Test-Link $Session) {
        Write-Host "WARNING: $Session is a symlink. Left it in place."
    } elseif (Test-File $Session) {
        try {
            [System.IO.File]::Delete((Get-Full $Session))
        } catch {
            Stop-At '5' "could not remove $Session."
        }
        Write-Host "Step 5: removed $Session."
        $script:Changed = $true
    } elseif (Test-Present $Session) {
        Write-Host "WARNING: $Session is not a regular file. Left it in place."
    } else {
        Write-Host "Step 5: skipped, $Session is not present."
    }
}
Invoke-Hook '5'

# Step 6: stop git tracking of the old pack, then rename it into the backup.
if (Test-Dir $OldPack) {
    if (Test-Tracked $OldPack) {
        & git rm -r -q --cached -- $OldPack 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { Stop-At '6' "could not stop git tracking of $OldPack/." }
    }
    try {
        [void][System.IO.Directory]::CreateDirectory((Get-Full $Backup))
    } catch {
        Stop-At '6' "could not create $Backup/."
    }
    try {
        [System.IO.Directory]::Move((Get-Full $OldPack), (Get-Full ($Backup + '/' + $OldPack)))
    } catch {
        Stop-At '6' "could not move $OldPack/ to $Backup/$OldPack/."
    }
    Write-Host "Step 6: moved $OldPack/ to $Backup/$OldPack/."
    $script:Moved += "$OldPack/ to $Backup/$OldPack/"
    $script:Changed = $true
} else {
    Write-Host "Step 6: skipped, $OldPack/ is not present."
}
if ($InGit -and (Test-Dir $Backup)) {
    $exclude = & git rev-parse --git-path info/exclude 2>$null | Select-Object -First 1
    $exclude = [string]$exclude
    $infoDir = Split-Path -Parent $exclude
    $excludeFull = Get-Full $exclude
    $hasLine = $false
    if ((-not (Test-Link $infoDir)) -and (-not (Test-Link $exclude)) -and (Test-Path -LiteralPath $excludeFull -PathType Leaf)) {
        $excludeText = $Bytes1.GetString([System.IO.File]::ReadAllBytes($excludeFull))
        foreach ($line in $excludeText.Split([char]10)) {
            if ($line -ceq ($Backup + '/')) { $hasLine = $true }
        }
    }
    if ((Test-Link $infoDir) -or (Test-Link $exclude)) {
        Write-Host "WARNING: $exclude or its folder is a symlink. Skipped adding $Backup/ to it."
    } elseif (-not $hasLine) {
        try {
            [void][System.IO.Directory]::CreateDirectory((Get-Full $infoDir))
            $add = $Backup + "/`n"
            if (Test-Path -LiteralPath $excludeFull -PathType Leaf) {
                $existing = [System.IO.File]::ReadAllBytes($excludeFull)
                if ($existing.Length -gt 0 -and $existing[$existing.Length - 1] -ne 10) { $add = "`n" + $add }
            }
            [System.IO.File]::AppendAllText($excludeFull, $add, $Bytes1)
        } catch {
            Stop-At '6' "could not write $exclude."
        }
        Write-Host "Step 6: added $Backup/ to $exclude."
        $script:Changed = $true
    }
}
Invoke-Hook '6'

if (-not $script:Changed) {
    Write-Host 'Nothing to do. This project already uses the RAVINTIO names.'
}

# Step 7: the next step.
Write-Host "Next step: run $NewPack/setup.sh claude-code, or setup.ps1, or the tool this project uses, before the next commit."
if (Test-Dir ($Backup + '/' + $OldPack)) {
    Write-Host "The old pack is in $Backup/$OldPack/. Delete $Backup/ after you check that nothing of yours is in it."
}
Invoke-Hook '7'

# Step 8: branch protection.
Write-Host 'WARNING: a branch protection rule that requires the old check name must now require RAVINTIO Strict Pipeline.'
Invoke-Hook '8'

exit 0
