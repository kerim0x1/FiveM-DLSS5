<#
.SYNOPSIS
    Removes a FiveM-DLSS5 deploy using the manifest written by the installer.
#>
[CmdletBinding()]
param(
    [ValidateSet('Auto','FiveM','RedM','RageMP','AltV','Generic')]
    [string]$Client = 'Auto',
    [string]$Target,
    [switch]$Yes,
    [switch]$NoPause
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib\Common.ps1')
. (Join-Path $PSScriptRoot 'lib\Profiles.ps1')

Write-Banner 'Uninstall'

$profile = Find-ClientProfile -Client $Client -Target $Target
$dir = Resolve-InstallDir -Profile $profile -Target $Target
$manifestPath = Join-Path $dir 'fivem-dlss5.manifest.json'

$locks = Get-RunningClientLock $profile
if ($locks.Count -gt 0) { throw 'Close the game before uninstalling.' }

if (-not (Test-FileHere $manifestPath)) {
    throw "No fivem-dlss5.manifest.json in $dir. Refusing to delete files by guesswork."
}

$man = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
Write-Section "$($profile.name)"
Report Info "version $($man.version)  installed $($man.installedAt)"

if (-not $Yes) {
    Write-Chunk "  Remove FiveM-DLSS5 files from $dir ? [y/N] " 'Cyan' -NoNewline
    $a = Read-Host
    if ($a -notmatch '^(?i)y(es)?$') { throw 'Cancelled.' }
}

$removed = 0
foreach ($f in @($man.files)) {
    if (Test-FileHere $f) {
        Remove-Item -LiteralPath $f -Force
        $removed++
    }
}

$shaderDir = Join-Path $dir 'reshade-shaders'
if (Test-DirHere $shaderDir) {
    $left = @(Get-ChildItem $shaderDir -Recurse -File -ErrorAction SilentlyContinue)
    if ($left.Count -eq 0) { Remove-Item -LiteralPath $shaderDir -Recurse -Force }
}

if (Test-FileHere $manifestPath) { Remove-Item -LiteralPath $manifestPath -Force }

Report Done "Removed $removed tracked file(s)"
if (-not $NoPause) { try { [void](Read-Host '  Press Enter to exit') } catch { } }
