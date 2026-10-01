<#
.SYNOPSIS
    Verifies a FiveM-DLSS5 install against the live snapshot rules.
#>
[CmdletBinding()]
param(
    [ValidateSet('Auto','FiveM','RedM','RageMP','AltV','Generic')]
    [string]$Client = 'Auto',
    [string]$Target,
    [switch]$NoPause
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib\Common.ps1')
. (Join-Path $PSScriptRoot 'lib\Profiles.ps1')

Write-Banner 'Verify'

$ok = 0; $warn = 0; $fail = 0
function Score {
    param([string]$Status, [string]$Text, [string]$Detail)
    Report $Status $Text $Detail
    switch ($Status) {
        'Ok'   { $script:ok++ }
        'Done' { $script:ok++ }
        'Warn' { $script:warn++ }
        'Fail' { $script:fail++ }
    }
}

$profile = Find-ClientProfile -Client $Client -Target $Target
$dir = Resolve-InstallDir -Profile $profile -Target $Target
if (-not (Test-DirHere $dir)) { throw "Install directory missing: $dir" }

Write-Section "$($profile.name)"
Score Info $dir

function Need-File([string]$Name, [string]$Hint) {
    $p = Join-Path $dir $Name
    if (Test-FileHere $p) { Score Ok $Name (Get-ProductNameSafe $p) }
    else { Score Fail $Name $Hint }
}

Need-File $profile.reshadeFileName 'ReShade 6.8+ with add-on support, this exact file name.'
Need-File 'dlss5-feed.addon64' 'In-process feeder. Helper mode is not supported here.'
Need-File 'renodx-dlss5.addon64' 'Neural consumer. Without it you only get DLAA.'
Need-File 'nvngx_dlss.dll' 'NVIDIA SuperSampling runtime.'
Need-File 'nvngx_dlssnr.dll' 'NVIDIA neural runtime. Signed 310.8 is RTX 50 only.'
Need-File 'ReShade.ini' 'Must set DLSS5_MV_PROVIDER=3 and PresetPath.'
Need-File 'preset_3_high.ini' 'Quality stages 1-4 live next to ReShade.ini.'

$reshade = Join-Path $dir $profile.reshadeFileName
if (Test-FileHere $reshade) {
    $prod = Get-ProductNameSafe $reshade
    $ver  = Get-FileVersionSafe $reshade
    if ($prod -match 'ReShade') { Score Ok "ReShade identity $ver" }
    else { Score Fail "$($profile.reshadeFileName) is not ReShade" $prod }
    if ($ver -and ([version]($ver.Split(' ')[0]) -lt [version]'6.8')) {
        Score Fail "ReShade $ver is too old" 'Need 6.8 or newer with add-on support.'
    }
}

if (Test-FileHere (Join-Path $dir 'dlss5-feed-helper.addon64')) {
    Score Fail 'dlss5-feed-helper.addon64 present' 'Remove it. addon64 stands down when helper sits beside it. Helper cannot run D3D12.'
} else { Score Ok 'No helper add-on' }

if (Test-DirHere (Join-Path $dir 'host64')) {
    Score Fail 'host64\ present' 'FiveM is D3D12. Helper/host64 is the wrong layout.'
} else { Score Ok 'No host64' }

if (Test-FileHere (Join-Path $dir 'standalone-dlssnr.addon64')) {
    Score Warn 'standalone-dlssnr.addon64 present' 'AIO + Feeder together stretch or fight. Keep one stack.'
}

$ini = Join-Path $dir 'ReShade.ini'
if (Test-FileHere $ini) {
    $t = [IO.File]::ReadAllText($ini)
    if ($t -match 'DLSS5_MV_PROVIDER=3') { Score Ok 'MV provider = Lumenite Kernel (3)' }
    else { Score Fail 'DLSS5_MV_PROVIDER is not 3' 'Kernel must feed the shader.' }
    if ($t -match 'NREnableUpscaling=0') { Score Ok 'NR upscaling off (no 32:9 stretch)' }
    else { Score Warn 'NREnableUpscaling is not 0' 'Ultrawide monitors stretch when NR upscales to native.' }
    if ($t -match 'Standalone\.DLSSNR\][\s\S]*Enabled=1') {
        Score Warn 'Standalone.DLSSNR Enabled=1' 'Disable AIO if Feeder is the stack.'
    }
}

$preset = Join-Path $dir 'preset_3_high.ini'
if (Test-FileHere $preset) {
    $pt = [IO.File]::ReadAllText($preset)
    if ($pt -match 'Lumenite_Kernel@lumenite_Kernel\.fx,DLSS5_Feed@DLSS5_Feed\.fx') {
        Score Ok 'Kernel is listed before Feed'
    } else { Score Warn 'Could not confirm Kernel-before-Feed order' }
}

Need-File 'reshade-shaders\Shaders\DLSS5_Feed.fx' 'Feeder shader.'
Need-File 'reshade-shaders\Shaders\lumenite_Kernel.fx' 'Motion vectors. Official LumeniteFX, AGNYA license.'

$feedLog = Join-Path $dir 'dlss5-feed.log'
if (Test-FileHere $feedLog) {
    $tail = Get-Content -LiteralPath $feedLog -Tail 80
    $joined = $tail -join "`n"
    if ($joined -match 'frame \d+ delivered') { Score Ok 'Feeder has delivered frames' }
    else { Score Info 'No delivered-frame line yet' 'Launch the game once.' }
    if ($joined -match 'helper') { Score Warn 'Log mentions helper mode' }
    if ($joined -match 'CreateFeature raised 0xC0000005') {
        Score Warn 'RenoDX CreateFeature crashed in a previous session' 'Fully restart the game. Do not toggle feeder on/off mid-session after a fault.'
    }
} else { Score Info 'No dlss5-feed.log yet' }

Write-Host ''
Write-Chunk ("  $ok OK   $warn warnings   $fail failures") $(if ($fail -gt 0) { 'Red' } elseif ($warn -gt 0) { 'Yellow' } else { 'Green' })
Write-Host ''
if ($fail -gt 0) { $code = 1 } else { $code = 0 }
if (-not $NoPause) { try { [void](Read-Host '  Press Enter to exit') } catch { } }
exit $code
