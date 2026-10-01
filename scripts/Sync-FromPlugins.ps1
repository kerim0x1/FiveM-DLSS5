<#
.SYNOPSIS
    Refresh stack\fivem from the live FiveM plugins folder.
#>
[CmdletBinding()]
param(
    [string]$Plugins = $(Join-Path $env:LOCALAPPDATA 'FiveM\FiveM.app\plugins'),
    [switch]$NoPause
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib\Common.ps1')

Write-Banner 'Sync stack from live plugins'

if (-not (Test-DirHere $Plugins)) { throw "Plugins folder not found: $Plugins" }

$stack = Join-Path $script:RepoRoot 'stack\fivem'
New-DirSafe $stack
robocopy $Plugins $stack /E /NFL /NDL /NJH /NJS /nc /ns /np /XF *.log *.bak | Out-Null

$ini = Join-Path $stack 'ReShade.ini'
if (Test-FileHere $ini) {
    $t = [IO.File]::ReadAllText($ini)
    $t = $t -replace 'IntermediateCachePath=[^\r\n]*', 'IntermediateCachePath='
    $t = $t -replace '(?m)^OverlayCollapsed=.*\r?\n', ''
    $t = $t -replace '(?m)^Docking=.*\r?\n', ''
    $t = $t -replace '(?m)^Window=.*\r?\n', ''
    [IO.File]::WriteAllText($ini, $t)
}

Report Done "stack\fivem <- $Plugins"
Get-ChildItem $stack -File | Format-Table Name, Length
if (-not $NoPause) { try { [void](Read-Host '  Press Enter to exit') } catch { } }
