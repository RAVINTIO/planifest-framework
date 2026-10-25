# migrate-0.37.0-ravintio-rename.ps1 - move a consumer repo to the RAVINTIO names.
# Run it from the project root, after you copy ravintio-framework/ in and
# before you run ravintio-framework/setup.ps1. The project root may sit below
# the git top level.
#
# The helper deletes the session marker and its own leftover temporary
# manifest and workflow files, and no other file. On Windows it also makes and
# deletes its own probe file. It moves the old pack into .ravintio-backup/
# with a plain rename, which moves a nested link or junction as a link and
# follows none. Every step skips work that is already
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
$OldC = 'Plan' + 'ifest'
# Step 4 rewrites this workflow name line when it matches the whole line.
$OldWfName = 'name: ' + $OldC + ' Strict Pipeline'
$NewWfName = 'name: RAVINTIO Strict Pipeline'
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
# Step 5 renames the markers in each of these tool folders.
$ToolDirs = @('.claude', '.cursor', '.windsurf', '.clinerules', '.agents', '.github', '.gemini', '.opencode')
$OldFlags = '.' + $Old + '-setup-flags'
$NewFlags = '.ravintio-setup-flags'
$OldManifest = '.' + $Old + '-manifest'
$NewManifest = '.ravintio-manifest'
# Step 7 prints a saved tool only when setup accepts it.
$SetupTools = @('claude-code', 'cursor', 'codex', 'antigravity', 'copilot', 'windsurf', 'cline', 'roo-code', 'opencode')
# A kept manifest name and a leftover temporary manifest must match these.
# Use them with -cmatch, so case folding can't widen a range.
$NameRe = '^[A-Za-z0-9][A-Za-z0-9._-]*\z'
$TmpRe = '^\.ravintio-manifest\.[A-Za-z0-9]{6}\z'
$WfTmpRe = '^\.ravintio\.yml\.[A-Za-z0-9]{6}\z'
# A last part whose base, before the first dot, matches this in upper case is
# a Windows device name.
$DeviceRe = '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])\z'
$OnWindows = ($env:OS -eq 'Windows_NT')
$Utf8 = New-Object System.Text.UTF8Encoding($false)

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

# Get-Full REL: a rooted REL, such as the git output in step 6, as is. Else a
# string join, not Combine, so a rooted part inside REL can't replace the
# project root. Callers never pass raw manifest text.
function Get-Full([string]$Rel) {
    if ([System.IO.Path]::IsPathRooted($Rel)) { return $Rel }
    $sep = [string][System.IO.Path]::DirectorySeparatorChar
    if ($Root.EndsWith($sep)) { return $Root + $Rel }
    return $Root + $sep + $Rel
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

# Stop-IfPresent DST STEP: stop when DST appeared after the step 2 check,
# because git mv would move the source inside it.
function Stop-IfPresent([string]$Dst, [string]$Step) {
    if (Test-Present $Dst) {
        Stop-At $Step "$Dst appeared after step 2. Move it aside, then run this helper again."
    }
}

# Move-Entry SRC DST STEP: git mv when git tracks SRC, else a plain rename.
function Move-Entry([string]$Src, [string]$Dst, [string]$Step) {
    $useGit = Test-Tracked $Src
    Stop-IfPresent $Dst $Step
    if ($useGit) {
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

# Get-MarkerLink DIR: DIR/skills or the first marker file in DIR that is a
# link, or an empty string.
function Get-MarkerLink([string]$Dir) {
    return (Get-FirstLink @(($Dir + '/skills'), ($Dir + '/' + $OldFlags), ($Dir + '/' + $NewFlags),
        ($Dir + '/skills/' + $OldManifest), ($Dir + '/skills/' + $NewManifest)))
}

# Test-MarkerSkip DIR: true when step 5 leaves the markers in DIR alone. That
# is when DIR is not a real folder, or DIR/skills or a marker file is a link.
function Test-MarkerSkip([string]$Dir) {
    if ((-not (Test-Dir $Dir)) -or (Test-Link $Dir)) { return $true }
    return ((Get-MarkerLink $Dir) -ne '')
}

# Rename-Marker SRC DST: step 5 renames the marker file SRC to DST, or warns
# when SRC is present but not a regular file.
function Rename-Marker([string]$Src, [string]$Dst) {
    if (Test-File $Src) {
        Move-Entry $Src $Dst '5'
        Write-Host "Step 5: renamed $Src to $Dst."
        $script:Moved += "$Src to $Dst"
        $script:Changed = $true
    } elseif (Test-Present $Src) {
        Write-Host "WARNING: $Src is not a regular file. Left it in place."
    }
}

# Get-RealPath FULL: FULL with every link resolved, part by part, or an empty
# string when a part is missing or a link can't be resolved.
function Get-RealPath([string]$Full) {
    $seps = @([char]'/')
    if ($OnWindows) { $seps = @([char]'/', [char]'\') }
    $path = [System.IO.Path]::Combine($Root, $Full)
    for ($round = 0; $round -lt 40; $round++) {
        $rootPart = [System.IO.Path]::GetPathRoot($path)
        if (-not $rootPart) { return '' }
        $parts = $path.Substring($rootPart.Length).Split($seps, [System.StringSplitOptions]::RemoveEmptyEntries)
        $cur = $rootPart
        $next = ''
        for ($i = 0; $i -lt $parts.Length; $i++) {
            $part = $parts[$i]
            if ($part -eq '.') { continue }
            if ($part -eq '..') {
                $up = [System.IO.Path]::GetDirectoryName($cur)
                if ($up) { $cur = $up }
                continue
            }
            $step = [System.IO.Path]::Combine($cur, $part)
            $item = Get-Item -LiteralPath $step -Force -ErrorAction SilentlyContinue
            if ($null -eq $item) { return '' }
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                $target = [string](@($item.Target) | Select-Object -First 1)
                if (-not $target) { return '' }
                $next = [System.IO.Path]::Combine($cur, $target)
                for ($j = $i + 1; $j -lt $parts.Length; $j++) {
                    $next = [System.IO.Path]::Combine($next, $parts[$j])
                }
                break
            }
            $cur = $step
        }
        if ($next -eq '') { return $cur }
        $path = $next
    }
    return ''
}

function Test-SamePath([string]$A, [string]$B) {
    if ($OnWindows) {
        # Windows reads / and \ alike, so compare them alike.
        return [string]::Equals($A.Replace('/', '\'), $B.Replace('/', '\'), [System.StringComparison]::OrdinalIgnoreCase)
    }
    return [string]::Equals($A, $B, [System.StringComparison]::Ordinal)
}

# Get-KeptName ENTRY REAL_SKILLS: the last part of a manifest entry when the
# helper keeps it, else an empty string. It keeps an entry whose parent
# resolves to the real skills folder and whose last part matches NameRe and
# does not end in a dot. So a last part never holds a separator, a drive
# colon, a space, or a wildcard. Before any lookup or probe, it drops an
# entry whose first two characters are both / or \ in any mix, or that starts
# with \??\. Windows reads each of these as a share or device path, so no
# share host is ever reached. It also drops a last part whose base, before
# the first dot, is a Windows device name in any case.
#
# On Windows, two paths to one folder can differ as text, for example an 8.3
# short name against the long name. So there a parent also counts when the
# probe file PROBE, made in the real skills folder, shows through it. Only
# the same folder can show a file with that random name. Elsewhere PowerShell
# reads \ as a separator and the .sh twin does not, so the text compare alone
# keeps both twins alike.
function Get-KeptName([string]$Entry, [string]$RealSkills, [string]$Probe) {
    if ($Entry.Length -ge 2 -and '/\'.IndexOf($Entry[0]) -ge 0 -and '/\'.IndexOf($Entry[1]) -ge 0) { return '' }
    if ($Entry.StartsWith('\??\', [System.StringComparison]::Ordinal)) { return '' }
    $idx = $Entry.LastIndexOf('/')
    if ($OnWindows) { $idx = [Math]::Max($idx, $Entry.LastIndexOf('\')) }
    if ($idx -lt 0) {
        $parent = '.'
        $last = $Entry
    } else {
        $parent = $Entry.Substring(0, $idx)
        $last = $Entry.Substring($idx + 1)
        if ($parent -eq '') { $parent = '/' }
        if ($parent.EndsWith(':')) { $parent = $parent + '\' }
    }
    if ((-not ($last -cmatch $NameRe)) -or $last.EndsWith('.')) { return '' }
    if ($last.Split([char]'.')[0].ToUpperInvariant() -cmatch $DeviceRe) { return '' }
    $real = Get-RealPath $parent
    if (($real -ne '') -and (Test-SamePath $real $RealSkills)) { return $last }
    if ($OnWindows -and ($Probe -ne '')) {
        $pf = $parent
        if (-not [System.IO.Path]::IsPathRooted($pf)) { $pf = Get-Full $pf }
        $sep = [string][System.IO.Path]::DirectorySeparatorChar
        if (-not $pf.EndsWith($sep)) { $pf = $pf + $sep }
        if (Test-Path -LiteralPath ($pf + $Probe) -PathType Leaf) { return $last }
    }
    return ''
}

# New-Probe DIR: make an empty probe file in DIR with a new random name that
# matches TmpRe, and return the name. Return an empty string when that fails.
# Only Windows needs a probe.
function New-Probe([string]$Dir) {
    if (-not $OnWindows) { return '' }
    $name = $NewManifest + '.' + ([System.IO.Path]::GetRandomFileName().Replace('.', '').Substring(0, 6))
    try {
        $fs = New-Object System.IO.FileStream((Get-Full ($Dir + '/' + $name)), [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write)
        $fs.Close()
    } catch {
        return ''
    }
    return $name
}

# Remove-Probe DIR NAME: remove the probe file NAME from DIR, if one was made.
function Remove-Probe([string]$Dir, [string]$Name) {
    if ($Name -eq '') { return }
    try { [System.IO.File]::Delete((Get-Full ($Dir + '/' + $Name))) } catch { }
}

# Remove-TempFiles DIR RE STEP: remove each regular file in DIR whose name
# matches RE, which a stopped run of this helper can leave. Any other name
# stays.
function Remove-TempFiles([string]$Dir, [string]$Re, [string]$Step) {
    [string[]]$names = @(Get-ChildItem -LiteralPath (Get-Full $Dir) -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -cmatch $Re } | ForEach-Object { $_.Name })
    # Sort by byte order, as the .sh twin does, so both print the same lines.
    [System.Array]::Sort($names, [System.StringComparer]::Ordinal)
    foreach ($f in $names) {
        $rel = $Dir + '/' + $f
        if ((Test-Link $rel) -or (-not (Test-File $rel))) { continue }
        try {
            [System.IO.File]::Delete((Get-Full $rel))
        } catch {
            Stop-At $Step "could not remove $rel."
        }
        Write-Host "Step ${Step}: removed the leftover temporary file $rel."
        $script:Changed = $true
    }
}

# Get-Lines FILE: the lines of FILE, without a trailing carriage return.
function Get-Lines([string]$Rel) {
    $text = $Utf8.GetString([System.IO.File]::ReadAllBytes((Get-Full $Rel)))
    $lines = @()
    foreach ($line in $text.Split([char]10)) {
        if ($line.EndsWith("`r")) { $line = $line.Substring(0, $line.Length - 1) }
        $lines += $line
    }
    return $lines
}

# Get-FlagsArgs DIR: the setup arguments DIR's flags file holds, or an empty
# string when its tool is not one setup accepts. Only the two known flags
# pass, in setup order.
function Get-FlagsArgs([string]$Dir) {
    $rel = $Dir + '/' + $NewFlags
    if ((-not (Test-File $rel)) -or (Test-Link $rel)) { return '' }
    $tool = $null
    $flagLine = $null
    foreach ($line in (Get-Lines $rel)) {
        if (($null -eq $tool) -and ($line -cmatch '^\s*"tool"\s*:\s*"([^"]*)"')) { $tool = $Matches[1] }
        if (($null -eq $flagLine) -and ($line -cmatch '^\s*"flags"\s*:(.*)$')) { $flagLine = $Matches[1] }
    }
    foreach ($t in $SetupTools) {
        if ($t -ceq $tool) {
            $out = $t
            if ("$flagLine".Contains('"--include-full-skill-library"')) { $out += ' --include-full-skill-library' }
            if ("$flagLine".Contains('"--strict-orchestrator"')) { $out += ' --strict-orchestrator' }
            return $out
        }
    }
    return ''
}

# Get-Rewritten TEXT: TEXT with the workflow name line, the pack path, and
# the pack-owned variable names rewritten, line by line, each line ending in a
# newline. A name counts only as a whole name, and never after secrets. or
# vars., where it names a consumer secret or variable.
function Get-Rewritten([string]$Text) {
    if ($Text.Length -eq 0) { return '' }
    $body = $Text
    if ($body.EndsWith("`n")) { $body = $body.Substring(0, $body.Length - 1) }
    $pattern = '(?<![A-Za-z0-9_])(?<!secrets\.)(?<!vars\.)' + $OldU + '_(' + ($PackVars -join '|') + ')(?![A-Za-z0-9_])'
    $regex = New-Object System.Text.RegularExpressions.Regex($pattern)
    $sb = New-Object System.Text.StringBuilder
    foreach ($line in $body.Split([char]10)) {
        $l = $line
        if (($l -ceq $OldWfName) -or ($l -ceq ($OldWfName + "`r"))) {
            $l = $NewWfName + $l.Substring($OldWfName.Length)
        }
        $l = $l.Replace($OldPack + '/', $NewPack + '/')
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
if ($InGit) {
    $stage = & git ls-files -s -- $OldPack 2>$null
    if (@($stage | Where-Object { "$_" -like '160000 *' }).Count -gt 0) {
        Stop-At '2' "$OldPack/ is a git submodule. Run git submodule deinit and git rm on it first, then run this helper again."
    }
}
# The marker clashes, for each tool folder step 5 works in.
foreach ($t in $ToolDirs) {
    if (Test-MarkerSkip $t) { continue }
    if ((Test-Present ($t + '/' + $OldFlags)) -and (Test-Present ($t + '/' + $NewFlags))) {
        Stop-At '2' "both $t/$OldFlags and $t/$NewFlags exist. Keep one of them, then run this helper again."
    }
    if ((Test-Present ($t + '/skills/' + $OldManifest)) -and (Test-Present ($t + '/skills/' + $NewManifest))) {
        Stop-At '2' "both $t/skills/$OldManifest and $t/skills/$NewManifest exist. Keep one of them, then run this helper again."
    }
    $scan = ''
    if (Test-File ($t + '/skills/' + $OldManifest)) {
        $scan = $t + '/skills/' + $OldManifest
    } elseif (Test-File ($t + '/skills/' + $NewManifest)) {
        $scan = $t + '/skills/' + $NewManifest
    }
    if (($scan -ne '') -and (Test-Dir ($t + '/skills'))) {
        $rs = Get-RealPath ($t + '/skills')
        $probe = New-Probe ($t + '/skills')
        try {
            foreach ($entry in (Get-Lines $scan)) {
                if ($entry -eq '') { continue }
                $name = Get-KeptName $entry $rs $probe
                if ($name.StartsWith($Old + '-', [System.StringComparison]::Ordinal)) {
                    $nn = 'ravintio-' + $name.Substring($Old.Length + 1)
                    if ((Test-Present ($t + '/skills/' + $name)) -and (Test-Present ($t + '/skills/' + $nn))) {
                        Stop-At '2' "both $t/skills/$name and $t/skills/$nn exist. Keep one of them, then run this helper again."
                    }
                }
            }
        } finally {
            Remove-Probe ($t + '/skills') $probe
        }
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
    if (Test-Dir $WfDir) { Remove-TempFiles $WfDir $WfTmpRe '4' }
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
            # over the target. The finally block removes the temporary file
            # when the write fails or the run is stopped.
            $tmpRel = $WfDir + '/.ravintio.yml.' + ([System.IO.Path]::GetRandomFileName().Replace('.', '').Substring(0, 6))
            $tmpFull = Get-Full $tmpRel
            $made = $false
            $fs = $null
            try {
                try {
                    $fs = New-Object System.IO.FileStream($tmpFull, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write)
                    $made = $true
                    $buf = $Bytes1.GetBytes($newText)
                    $fs.Write($buf, 0, $buf.Length)
                    $fs.Close()
                } catch {
                    if ($fs) { $fs.Dispose() }
                    Stop-At '4' "could not rewrite $NewWf."
                }
                # PowerShell turns $null into an empty string for a .NET string
                # argument, and File.Replace rejects an empty backup path.
                # NullString passes a real null, so no backup file is made.
                try {
                    [System.IO.File]::Replace($tmpFull, $wfFull, [System.Management.Automation.Language.NullString]::Value)
                    $made = $false
                } catch {
                    Stop-At '4' "could not replace $NewWf."
                }
            } finally {
                if ($made) { [System.IO.File]::Delete($tmpFull) }
            }
            Write-Host "Step 4: rewrote the pack path and pack-owned names in $NewWf."
            $script:Changed = $true
        }
    }
}
Invoke-Hook '4'

# Step 5: remove the session marker, then rename the markers in each tool
# folder.
if (Test-Link '.claude') {
    Write-Host 'WARNING: .claude is a symlink. Skipped the marker under it, so nothing is removed through it.'
} else {
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
foreach ($t in $ToolDirs) {
    if (Test-Link $t) {
        # The .claude warning above already names a linked .claude.
        if ($t -ne '.claude') {
            Write-Host "WARNING: $t is a symlink. Skipped the markers in it, so nothing is written through it."
        }
        continue
    }
    if (-not (Test-Dir $t)) { continue }
    $skipLink = Get-MarkerLink $t
    if ($skipLink -ne '') {
        Write-Host "WARNING: $skipLink is a symlink. Skipped the markers in $t, so nothing is written through it."
        continue
    }
    # The flags file keeps its content.
    Rename-Marker ($t + '/' + $OldFlags) ($t + '/' + $NewFlags)
    $skillsRel = $t + '/skills'
    if (-not (Test-Dir $skillsRel)) { continue }
    Remove-TempFiles $skillsRel $TmpRe '5'
    $manRel = $skillsRel + '/' + $NewManifest
    Rename-Marker ($skillsRel + '/' + $OldManifest) $manRel
    if (-not (Test-File $manRel)) { continue }
    # Keep each entry inside the real skills folder, rename each listed old
    # skill folder, and write each kept entry as the real path.
    $rs = Get-RealPath $skillsRel
    $sb = New-Object System.Text.StringBuilder
    $probe = New-Probe $skillsRel
    try {
        foreach ($entry in (Get-Lines $manRel)) {
            if ($entry -eq '') { continue }
            $name = Get-KeptName $entry $rs $probe
            if ($name -eq '') {
                Write-Host "WARNING: dropped manifest entry $entry"
                continue
            }
            if ($name.StartsWith($Old + '-', [System.StringComparison]::Ordinal)) {
                $nn = 'ravintio-' + $name.Substring($Old.Length + 1)
                if (Test-Present ($skillsRel + '/' + $name)) {
                    Move-Entry ($skillsRel + '/' + $name) ($skillsRel + '/' + $nn) '5'
                    Write-Host "Step 5: renamed $skillsRel/$name to $skillsRel/$nn."
                    $script:Moved += "$skillsRel/$name to $skillsRel/$nn"
                    $script:Changed = $true
                }
                $name = $nn
            }
            # A string join, not Combine, so a rooted name can't replace $rs.
            [void]$sb.Append($rs + [string][System.IO.Path]::DirectorySeparatorChar + $name)
            [void]$sb.Append("`n")
        }
    } finally {
        Remove-Probe $skillsRel $probe
    }
    $manFull = Get-Full $manRel
    $newBytes = $Utf8.GetBytes($sb.ToString())
    $oldBytes = [System.IO.File]::ReadAllBytes($manFull)
    $same = ($newBytes.Length -eq $oldBytes.Length)
    if ($same) {
        for ($k = 0; $k -lt $newBytes.Length; $k++) {
            if ($newBytes[$k] -ne $oldBytes[$k]) { $same = $false; break }
        }
    }
    if (-not $same) {
        # Write to a temporary file in the same folder, then rename it over
        # the target. The finally block removes the temporary file when the
        # write fails or the run is stopped.
        $tmpRel = $manRel + '.' + ([System.IO.Path]::GetRandomFileName().Replace('.', '').Substring(0, 6))
        $tmpFull = Get-Full $tmpRel
        $made = $false
        $fs = $null
        try {
            try {
                $fs = New-Object System.IO.FileStream($tmpFull, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write)
                $made = $true
                $fs.Write($newBytes, 0, $newBytes.Length)
                $fs.Close()
            } catch {
                if ($fs) { $fs.Dispose() }
                Stop-At '5' "could not rewrite $manRel."
            }
            # NullString passes a real null, so File.Replace makes no backup file.
            try {
                [System.IO.File]::Replace($tmpFull, $manFull, [System.Management.Automation.Language.NullString]::Value)
                $made = $false
            } catch {
                Stop-At '5' "could not replace $manRel."
            }
        } finally {
            if ($made) { [System.IO.File]::Delete($tmpFull) }
        }
        Write-Host "Step 5: rewrote the entries in $manRel."
        $script:Changed = $true
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
    Stop-IfPresent ($Backup + '/' + $OldPack) '6'
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

# Step 7: the next step, with the setup arguments each saved flags file
# holds, or the generic command when none names a tool setup accepts.
$saved = $false
foreach ($t in $ToolDirs) {
    if ((Test-Link $t) -or (-not (Test-Dir $t))) { continue }
    $flagArgs = Get-FlagsArgs $t
    if ($flagArgs -ne '') {
        Write-Host "Next step: run $NewPack/setup.sh $flagArgs, or setup.ps1 with the same arguments, before the next commit."
        $saved = $true
    }
}
if (-not $saved) {
    Write-Host "Next step: run $NewPack/setup.sh claude-code, or setup.ps1, or the tool this project uses, before the next commit."
}
if (Test-Dir ($Backup + '/' + $OldPack)) {
    Write-Host "The old pack is in $Backup/$OldPack/. Delete $Backup/ after you check that nothing of yours is in it. git clean -x deletes it too."
}
Invoke-Hook '7'

# Step 8: branch protection.
Write-Host 'WARNING: the workflow name is now RAVINTIO Strict Pipeline. The required check validate-branch keeps its name, so a branch protection rule that requires validate-branch needs no change.'
Invoke-Hook '8'

exit 0
