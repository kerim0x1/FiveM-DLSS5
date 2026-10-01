# Shared helpers for FiveM-DLSS5. Windows PowerShell 5.1 compatible.
Set-StrictMode -Version 2.0

$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script:Version  = (Get-Content -LiteralPath (Join-Path $script:RepoRoot 'VERSION') -Raw).Trim()
$script:UserAgent = "FiveM-DLSS5/$script:Version (+https://github.com/; contact@kerim0x1.com)"

$script:Sources = @{
    FeederReleases = 'https://api.github.com/repos/jlrouzies-fr/DLSS5-Feeder/releases'
    FeederRepo     = 'https://github.com/jlrouzies-fr/DLSS5-Feeder'
    ReShadeHome    = 'https://reshade.me'
    ReShadeSetup   = 'https://reshade.me/downloads/ReShade_Setup_6.8.0_Addon.exe'
    HeadersBase    = 'https://raw.githubusercontent.com/crosire/reshade-shaders/slim/Shaders/'
    LumeniteZip    = 'https://codeload.github.com/umar-afzaal/LumeniteFX/zip/refs/heads/mainline'
    RhiReleases    = 'https://api.github.com/repos/RankFTW/rhi-repo/releases?per_page=100'
    SevenZipExtra  = 'https://www.7-zip.org/a/7zr.exe'
    RenoDxDiscord  = 'https://discord.com/invite/renodx'
    DfcDiscord     = 'https://discord.gg/g2v2XGqvR'
}

$script:UseColour = $true
try {
    if ($null -eq $Host -or $null -eq $Host.UI -or $null -eq $Host.UI.RawUI) { $script:UseColour = $false }
    else { $null = $Host.UI.RawUI.ForegroundColor }
} catch { $script:UseColour = $false }

function Write-Chunk {
    param([string]$Text, [string]$Colour, [switch]$NoNewline)
    try {
        if ($script:UseColour -and $Colour) { Write-Host $Text -ForegroundColor $Colour -NoNewline:$NoNewline }
        else { Write-Host $Text -NoNewline:$NoNewline }
    } catch { Write-Host $Text -NoNewline:$NoNewline }
}

function Write-Banner {
    param([string]$Subtitle = 'FiveM / RedM / RageMP / alt:V neural stack')
    $box = 'DarkGray'
    $w = 72
    Write-Host ''
    Write-Chunk ('  ' + [char]0x2554 + ([string][char]0x2550) * $w + [char]0x2557) $box
    $rows = @(
        @{ C = 'Green'; T = ('  FiveM-DLSS5  v' + $script:Version) },
        @{ C = 'DarkGray'; T = ('  ' + $Subtitle) },
        @{ C = 'DarkGray'; T = '  Built on DLSS5-Feeder  ·  contact@kerim0x1.com' }
    )
    foreach ($r in $rows) {
        Write-Chunk ('  ' + [char]0x2551) $box -NoNewline
        Write-Chunk $r.T $r.C -NoNewline
        $pad = $w - $r.T.Length
        if ($pad -lt 0) { $pad = 0 }
        Write-Chunk ((' ') * $pad) $null -NoNewline
        Write-Chunk ([string][char]0x2551) $box
    }
    Write-Chunk ('  ' + [char]0x255A + ([string][char]0x2550) * $w + [char]0x255D) $box
    Write-Host ''
}

function Write-Section {
    param([string]$Title)
    Write-Host ''
    Write-Chunk ('  ' + [char]0x2500 + [char]0x2500 + ' ') 'Green' -NoNewline
    Write-Chunk $Title 'White'
}

function Report {
    param(
        [ValidateSet('Done','Ok','Skip','Warn','Fail','Info')]
        [string]$Status,
        [string]$Text,
        [string]$Detail
    )
    switch ($Status) {
        'Done' { $g = '[DONE]'; $c = 'Green' }
        'Ok'   { $g = '[ OK ]'; $c = 'Green' }
        'Skip' { $g = '[ -- ]'; $c = 'DarkGray' }
        'Warn' { $g = '[WARN]'; $c = 'Yellow' }
        'Fail' { $g = '[FAIL]'; $c = 'Red' }
        'Info' { $g = '[ .. ]'; $c = 'DarkGray' }
    }
    Write-Chunk ('  ' + $g + ' ') $c -NoNewline
    Write-Host $Text
    if ($Detail) {
        foreach ($line in ($Detail -split "`n")) {
            if ($line.Trim()) { Write-Chunk ('         ' + $line.Trim()) 'DarkGray' }
        }
    }
}

function Expand-EnvPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    return [Environment]::ExpandEnvironmentVariables($Path)
}

function Test-FileHere {
    param([string]$Path)
    if (-not $Path) { return $false }
    try { return (Test-Path -LiteralPath $Path -PathType Leaf) } catch { return $false }
}

function Test-DirHere {
    param([string]$Path)
    if (-not $Path) { return $false }
    try { return (Test-Path -LiteralPath $Path -PathType Container) } catch { return $false }
}

function New-DirSafe {
    param([string]$Path)
    if ($Path -and -not (Test-DirHere $Path)) {
        $null = New-Item -ItemType Directory -Path $Path -Force
    }
}

function Get-FileVersionSafe {
    param([string]$Path)
    if (-not (Test-FileHere $Path)) { return $null }
    try {
        $vi = (Get-Item -LiteralPath $Path -ErrorAction Stop).VersionInfo
        if ($vi -and $vi.FileVersion) { return ($vi.FileVersion.Trim() -replace '\s*,\s*', '.') }
    } catch { }
    return $null
}

function Get-ProductNameSafe {
    param([string]$Path)
    if (-not (Test-FileHere $Path)) { return $null }
    try {
        $vi = (Get-Item -LiteralPath $Path -ErrorAction Stop).VersionInfo
        $bits = @()
        if ($vi.ProductName) { $bits += $vi.ProductName }
        if ($vi.FileDescription) { $bits += $vi.FileDescription }
        return ($bits -join ' | ')
    } catch { }
    return $null
}

function Get-Sha256 {
    param([string]$Path)
    try { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant() } catch { return $null }
}

function Enable-Tls12 {
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch { }
}

function Invoke-JsonGet {
    param([string]$Url)
    Enable-Tls12
    $headers = @{ 'User-Agent' = $script:UserAgent; 'Accept' = 'application/vnd.github+json' }
    return Invoke-RestMethod -Uri $Url -Headers $headers -UseBasicParsing
}

function Save-Url {
    param([string]$Url, [string]$OutFile)
    Enable-Tls12
    New-DirSafe ([IO.Path]::GetDirectoryName($OutFile))
    $headers = @{ 'User-Agent' = $script:UserAgent }
    Invoke-WebRequest -Uri $Url -OutFile $OutFile -Headers $headers -UseBasicParsing
    if (-not (Test-FileHere $OutFile) -or ((Get-Item -LiteralPath $OutFile).Length -lt 16)) {
        throw "Download produced an empty file: $Url"
    }
}

function Get-CacheDir {
    $d = Join-Path $env:LOCALAPPDATA 'FiveM-DLSS5\downloads'
    New-DirSafe $d
    return $d
}

function Get-LatestFeederRelease {
    param([switch]$Prerelease)
    $releases = Invoke-JsonGet $script:Sources.FeederReleases
    foreach ($r in $releases) {
        if (-not $Prerelease -and $r.prerelease) { continue }
        $asset = @($r.assets) | Where-Object { $_.name -match '^DLSS5-Feeder-.*\.zip$' } | Select-Object -First 1
        if ($asset) {
            return [pscustomobject]@{
                Tag  = [string]$r.tag_name
                Name = [string]$r.name
                Zip  = [string]$asset.browser_download_url
                File = [string]$asset.name
            }
        }
    }
    throw 'No DLSS5-Feeder zip found on GitHub releases.'
}

function Get-RhiAsset {
    param([string]$NamePattern, [string]$TagPattern)
    $releases = Invoke-JsonGet $script:Sources.RhiReleases
    foreach ($r in $releases) {
        if ($TagPattern -and ([string]$r.tag_name -notmatch $TagPattern)) { continue }
        $asset = @($r.assets) | Where-Object { $_.name -match $NamePattern } | Select-Object -First 1
        if ($asset) {
            return [pscustomobject]@{
                Tag  = [string]$r.tag_name
                Url  = [string]$asset.browser_download_url
                File = [string]$asset.name
            }
        }
    }
    return $null
}

function Expand-ZipTo {
    param([string]$Zip, [string]$Dest)
    New-DirSafe $Dest
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($Zip, $Dest)
}

function Get-7zr {
    param([string]$CacheDir)
    $local = @(
        'C:\Program Files\7-Zip\7z.exe',
        'C:\Program Files (x86)\7-Zip\7z.exe'
    ) | Where-Object { Test-FileHere $_ } | Select-Object -First 1
    if ($local) { return $local }
    $seven = Join-Path $CacheDir '7zr.exe'
    if (-not (Test-FileHere $seven)) {
        Save-Url $script:Sources.SevenZipExtra $seven
    }
    return $seven
}

function Expand-Sfx {
    param([string]$Archive, [string]$Dest, [string]$Seven)
    New-DirSafe $Dest
    & $Seven @('x', '-y', ("-o$Dest"), $Archive) | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "7-Zip extract failed for $Archive (exit $LASTEXITCODE)" }
}

function Find-FileUnder {
    param([string]$Dir, [string]$Name)
    if (-not (Test-DirHere $Dir)) { return $null }
    $hit = Get-ChildItem -LiteralPath $Dir -File -Filter $Name -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hit) { return $hit.FullName }
    return $null
}

function Copy-Tracked {
    param([string]$From, [string]$To, [System.Collections.IList]$Manifest)
    New-DirSafe ([IO.Path]::GetDirectoryName($To))
    Copy-Item -LiteralPath $From -Destination $To -Force
    if ($Manifest) { [void]$Manifest.Add($To) }
}

function Write-TextTracked {
    param([string]$Path, [string]$Text, [System.Collections.IList]$Manifest)
    New-DirSafe ([IO.Path]::GetDirectoryName($Path))
    [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding $false))
    if ($Manifest) { [void]$Manifest.Add($Path) }
}

function Get-ProductIsReShade {
    param([string]$Path)
    $n = Get-ProductNameSafe $Path
    if (-not $n) { return $false }
    return ($n -match 'ReShade')
}
