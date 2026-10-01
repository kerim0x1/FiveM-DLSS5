<#
.SYNOPSIS
    Deploys the working FiveM DLSS 5 stack to FiveM, RedM, RageMP, alt:V, or a generic game folder.

.DESCRIPTION
    The payload is stack\fivem — a snapshot of a known-good
    %LOCALAPPDATA%\FiveM\FiveM.app\plugins tree. This installer copies that
    layout. It does not re-download the feeder as the primary path.

    FiveM / RedM  ->  <Client>.app\plugins\d3d11.dll
    RageMP        ->  install dir\d3d11.dll
    alt:V         ->  install dir\dxgi.dll
    Generic       ->  -Target folder, ReShade name from the profile

    Helper mode is refused on every bundled profile (D3D12 / in-process only).

.PARAMETER Client
    Auto, FiveM, RedM, RageMP, AltV, Generic.

.PARAMETER Target
    Override the install directory. Required for Generic.

.PARAMETER Force
    Overwrite existing ReShade / feeder files after backing them up.

.PARAMETER Yes
    Skip the confirmation prompt.

.PARAMETER SyncFromPlugins
    Refresh stack\fivem from the live FiveM plugins folder first.

.PARAMETER NoPause
    Do not wait for Enter at the end.
#>
[CmdletBinding()]
param(
    [ValidateSet('Auto','FiveM','RedM','RageMP','AltV','Generic')]
    [string]$Client = 'Auto',

    [string]$Target,

    [switch]$Force,
    [switch]$Yes,
    [switch]$SyncFromPlugins,
    [switch]$NoPause
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib\Common.ps1')
. (Join-Path $PSScriptRoot 'lib\Profiles.ps1')

Write-Banner 'Install from the live FiveM plugins snapshot'

$stack = Join-Path $script:RepoRoot 'stack\fivem'
$livePlugins = Join-Path $env:LOCALAPPDATA 'FiveM\FiveM.app\plugins'

if ($SyncFromPlugins -or -not (Test-DirHere $stack)) {
    if (-not (Test-DirHere $livePlugins)) {
        throw "Live FiveM plugins folder not found: $livePlugins"
    }
    Write-Section 'Snapshot'
    New-DirSafe $stack
    robocopy $livePlugins $stack /E /NFL /NDL /NJH /NJS /nc /ns /np /XF *.log *.bak | Out-Null
    Report Done "Refreshed stack from $livePlugins"
}

if (-not (Test-FileHere (Join-Path $stack 'dlss5-feed.addon64'))) {
    throw "stack\fivem is incomplete. Run with -SyncFromPlugins while FiveM plugins exist."
}

$profile = Find-ClientProfile -Client $Client -Target $Target
$installDir = Resolve-InstallDir -Profile $profile -Target $Target
if (-not $installDir) { throw "Could not resolve an install directory for $($profile.name). Pass -Target." }
New-DirSafe $installDir

Write-Section 'Client'
Report Info "$($profile.name)  ($($profile.id))"
Report Info "API $($profile.api)  ReShade $($profile.reshadeFileName)"
Report Info "Target $installDir"

if ($profile.helperMode -eq $true) {
    throw "This pack refuses helper mode. $($profile.name) must use in-process dlss5-feed.addon64."
}

$locks = Get-RunningClientLock $profile
if ($locks.Count -gt 0) {
    $names = ($locks | ForEach-Object { $_.ProcessName + '#' + $_.Id }) -join ', '
    throw "Close the game first. Running: $names"
}

if (-not $Yes) {
    Write-Host ''
    Write-Chunk "  Deploy the FiveM-DLSS5 stack to $installDir ? [y/N] " 'Cyan' -NoNewline
    $a = Read-Host
    if ($a -notmatch '^(?i)y(es)?$') { throw 'Cancelled.' }
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $installDir ('.fivem-dlss5-backup-' + $stamp)
$manifest = New-Object System.Collections.Generic.List[string]
$copied = 0
$skipped = 0

function Backup-IfExists {
    param([string]$Path)
    if (Test-FileHere $Path) {
        New-DirSafe $backupDir
        Copy-Item -LiteralPath $Path -Destination (Join-Path $backupDir ([IO.Path]::GetFileName($Path))) -Force
    } elseif (Test-DirHere $Path) {
        New-DirSafe $backupDir
        $name = Split-Path $Path -Leaf
        Copy-Item -LiteralPath $Path -Destination (Join-Path $backupDir $name) -Recurse -Force
    }
}

function Publish-File {
    param([string]$From, [string]$To)
    if ((Test-FileHere $To) -and -not $Force) {
        $script:skipped++
        Report Skip (Split-Path $To -Leaf)
        return
    }
    Backup-IfExists $To
    Copy-Tracked -From $From -To $To -Manifest $manifest
    $script:copied++
}

Write-Section 'Deploy'

# Core binaries / configs sitting in the snapshot root
Get-ChildItem -LiteralPath $stack -File | Where-Object {
    $_.Name -notmatch '\.log$' -and $_.Name -notmatch '\.bak'
} | ForEach-Object {
    $destName = $_.Name
    if ($_.Name -eq 'd3d11.dll') { $destName = $profile.reshadeFileName }
    if ($destName -eq 'dxgi.dll' -and $profile.reshadeFileName -eq 'd3d11.dll') { $destName = 'd3d11.dll' }
    Publish-File $_.FullName (Join-Path $installDir $destName)
}

# Shaders
$shaderSrc = Join-Path $stack 'reshade-shaders'
$shaderDst = Join-Path $installDir 'reshade-shaders'
if (Test-DirHere $shaderSrc) {
    if ((Test-DirHere $shaderDst) -and $Force) { Backup-IfExists $shaderDst }
    New-DirSafe $shaderDst
    robocopy $shaderSrc $shaderDst /E /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    Get-ChildItem $shaderDst -Recurse -File | ForEach-Object { [void]$manifest.Add($_.FullName) }
    Report Done 'reshade-shaders'
}

# Never leave helper mode next to in-process
foreach ($bad in @('dlss5-feed-helper.addon64')) {
    $p = Join-Path $installDir $bad
    if (Test-FileHere $p) {
        Backup-IfExists $p
        Remove-Item -LiteralPath $p -Force
        Report Warn "Removed $bad (in-process addon64 must own the session)"
    }
}
$host64 = Join-Path $installDir 'host64'
if (Test-DirHere $host64) {
    Backup-IfExists $host64
    Remove-Item -LiteralPath $host64 -Recurse -Force
    Report Warn 'Removed host64 (FiveM / D3D12 cannot use helper mode)'
}

$manifestPath = Join-Path $installDir 'fivem-dlss5.manifest.json'
$manifestObj = [pscustomobject]@{
    product     = 'FiveM-DLSS5'
    version     = $script:Version
    client      = $profile.id
    installedAt = (Get-Date).ToString('o')
    source      = $stack
    contact     = 'contact@kerim0x1.com'
    files       = @($manifest)
}
$manifestObj | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
[void]$manifest.Add($manifestPath)

Write-Section 'Layout check'
$need = @(
    $profile.reshadeFileName,
    'dlss5-feed.addon64',
    'renodx-dlss5.addon64',
    'nvngx_dlss.dll',
    'nvngx_dlssnr.dll',
    'ReShade.ini',
    'preset_3_high.ini'
)
$missing = @()
foreach ($n in $need) {
    $p = Join-Path $installDir $n
    if (Test-FileHere $p) { Report Ok $n } else { Report Fail $n; $missing += $n }
}
$fx = Join-Path $installDir 'reshade-shaders\Shaders\DLSS5_Feed.fx'
$kn = Join-Path $installDir 'reshade-shaders\Shaders\lumenite_Kernel.fx'
if (Test-FileHere $fx) { Report Ok 'DLSS5_Feed.fx' } else { Report Fail 'DLSS5_Feed.fx'; $missing += 'DLSS5_Feed.fx' }
if (Test-FileHere $kn) { Report Ok 'lumenite_Kernel.fx' } else { Report Fail 'lumenite_Kernel.fx'; $missing += 'lumenite_Kernel.fx' }

$reshade = Join-Path $installDir $profile.reshadeFileName
if (Test-FileHere $reshade) {
    $prod = Get-ProductNameSafe $reshade
    $ver  = Get-FileVersionSafe $reshade
    Report Info "$($profile.reshadeFileName): $prod | $ver"
}

Write-Host ''
Report Done ("Copied $copied file(s), skipped $skipped")
if (Test-DirHere $backupDir) { Report Info "Backup $backupDir" }

Write-Section 'Next'
Write-Chunk '  1. Launch the client.' 'White'
Write-Chunk '  2. Press Home for the ReShade overlay.' 'White'
Write-Chunk '  3. Keep Lumenite Kernel above DLSS 5 Feed.' 'White'
Write-Chunk '  4. Keys 1-4 switch Balanced / Quality / High / Ultra.' 'White'
Write-Chunk '  5. RenoDX panel: neural rendering on, upscaling off.' 'White'
Write-Host ''
Write-Chunk '  contact@kerim0x1.com' 'DarkGray'
Write-Host ''

if ($missing.Count -gt 0) {
    Write-Chunk '  Install finished with missing files. Re-run with -SyncFromPlugins.' 'Yellow'
    if (-not $NoPause) { try { [void](Read-Host '  Press Enter to exit') } catch { } }
    exit 1
}

if (-not $NoPause) { try { [void](Read-Host '  Press Enter to exit') } catch { } }
exit 0
