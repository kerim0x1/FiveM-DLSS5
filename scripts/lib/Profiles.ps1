# Client profile loader and detector.

function Get-ProfileDir {
    return (Join-Path $script:RepoRoot 'profiles')
}

function Read-ClientProfile {
    param([string]$Id)
    $path = Join-Path (Get-ProfileDir) ($Id.ToLowerInvariant() + '.json')
    if (-not (Test-FileHere $path)) { throw "Unknown client profile: $Id" }
    return (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json)
}

function Get-AllClientProfiles {
    Get-ChildItem -LiteralPath (Get-ProfileDir) -Filter '*.json' | ForEach-Object {
        Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
    }
}

function Test-MarkerExists {
    param([string]$Marker)
    $p = Expand-EnvPath $Marker
    if (-not $p) { return $false }
    return (Test-Path -LiteralPath $p)
}

function Get-RunningClientLock {
    param($Profile)
    $names = @()
    if ($Profile.detect.processes) { $names += @($Profile.detect.processes) }
    $glob = $Profile.detect.processGlob
    $hits = @()
    if ($names.Count -gt 0) {
        $hits += @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $names -contains $_.ProcessName })
    }
    if ($glob) {
        $hits += @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like $glob })
    }
    return @($hits | Sort-Object Id -Unique)
}

function Resolve-InstallDir {
    param($Profile, [string]$Target)
    if ($Target) {
        $t = (Resolve-Path -LiteralPath $Target -ErrorAction Stop).Path
        if (Test-FileHere $t) { return [IO.Path]::GetDirectoryName($t) }
        return $t
    }
    $primary = Expand-EnvPath $Profile.installDir
    if ($primary -and (Test-DirHere $primary -or $Profile.id -eq 'fivem' -or $Profile.id -eq 'redm')) {
        New-DirSafe $primary
        return $primary
    }
    if ($Profile.installDirFallbacks) {
        foreach ($fb in @($Profile.installDirFallbacks)) {
            $p = Expand-EnvPath $fb
            if ($p -and (Test-DirHere $p)) { return $p }
        }
    }
    return $primary
}

function Find-ClientProfile {
    param([string]$Client, [string]$Target)
    if ($Client -and $Client -ne 'Auto') {
        return (Read-ClientProfile $Client)
    }
    foreach ($id in @('fivem','redm','ragemp','altv')) {
        $p = Read-ClientProfile $id
        $matched = $false
        foreach ($m in @($p.detect.markers)) {
            if (Test-MarkerExists $m) { $matched = $true; break }
        }
        if ($matched) { return $p }
    }
    if ($Target) { return (Read-ClientProfile 'generic') }
    throw 'No client detected. Pass -Client FiveM|RedM|RageMP|AltV|Generic and optionally -Target.'
}
