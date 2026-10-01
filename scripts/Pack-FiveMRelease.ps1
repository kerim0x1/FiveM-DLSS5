<#
.SYNOPSIS
    Builds FiveM-DLSS5-<version>-plugins.zip from stack\fivem.
    Players extract that zip into FiveM.app\plugins.
#>
[CmdletBinding()]
param(
    [switch]$SyncFromPlugins,
    [switch]$NoPause
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib\Common.ps1')

Write-Banner 'Pack FiveM plugins release'

if ($SyncFromPlugins) {
    & (Join-Path $PSScriptRoot 'Sync-FromPlugins.ps1') -NoPause
}

$stack = Join-Path $script:RepoRoot 'stack\fivem'
$required = @(
    'd3d11.dll',
    'dlss5-feed.addon64',
    'renodx-dlss5.addon64',
    'nvngx_dlss.dll',
    'nvngx_dlssnr.dll',
    'ReShade.ini',
    'preset_1_balanced.ini',
    'preset_2_quality.ini',
    'preset_3_high.ini',
    'preset_4_ultra.ini',
    'reshade-shaders\Shaders\DLSS5_Feed.fx',
    'reshade-shaders\Shaders\lumenite_Kernel.fx',
    'LESEN.txt'
)
$missing = @()
foreach ($n in $required) {
    $p = Join-Path $stack $n
    if (-not (Test-Path -LiteralPath $p)) { $missing += $n }
}
if ($missing.Count -gt 0) {
    throw ("stack\fivem incomplete:`n  " + ($missing -join "`n  "))
}

$releaseDir = Join-Path $script:RepoRoot 'release'
New-DirSafe $releaseDir
$zipName = "FiveM-DLSS5-$($script:Version)-plugins.zip"
$zipPath = Join-Path $releaseDir $zipName
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }

$staging = Join-Path $env:TEMP ("FiveM-DLSS5-pack-" + [guid]::NewGuid().ToString('N'))
New-DirSafe $staging
try {
    robocopy $stack $staging /E /NFL /NDL /NJH /NJS /nc /ns /np /XF *.log *.bak | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'NOTICE') -Destination (Join-Path $staging 'NOTICE.txt') -Force

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory(
        $staging,
        $zipPath,
        [IO.Compression.CompressionLevel]::Optimal,
        $false
    )
} finally {
    if (Test-DirHere $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
}

$item = Get-Item -LiteralPath $zipPath
$mb = '{0:N1} MB' -f ($item.Length / 1MB)
$sha = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash

$utf8 = New-Object Text.UTF8Encoding $false
$notes = @"
# FiveM-DLSS5 $($script:Version)

Spieler: Zip herunterladen, FiveM schliessen, Inhalt nach

``%LOCALAPPDATA%\FiveM\FiveM.app\plugins``

kopieren, FiveM starten, **Home**.

- Asset: ``$zipName``
- Groesse: $mb
- SHA-256: ``$sha``

Kontakt: contact@kerim0x1.com
"@
[IO.File]::WriteAllText((Join-Path $releaseDir 'GITHUB_RELEASE.md'), $notes.Trim() + "`n", $utf8)
[IO.File]::WriteAllText((Join-Path $releaseDir 'SHA256.txt'), "$sha  $zipName`n", $utf8)

Report Done $zipName
Report Info $mb
Report Info "SHA-256 $sha"
Report Info (Join-Path $releaseDir 'GITHUB_RELEASE.md')

if (-not $NoPause) { try { [void](Read-Host '  Press Enter to exit') } catch { } }
