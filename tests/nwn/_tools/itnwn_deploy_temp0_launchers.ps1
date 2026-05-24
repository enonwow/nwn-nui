param(
    [string]$SourceDir = "",
    [string]$Temp0Path = "$env:USERPROFILE\Documents\Neverwinter Nights\modules\temp0",
    [switch]$ForceReplace
)

$ErrorActionPreference = "Stop"

$toolsRoot = $PSScriptRoot
$suiteRoot = Split-Path -Parent $toolsRoot
if (-not $SourceDir) {
    $SourceDir = $suiteRoot
}

if (-not (Test-Path -LiteralPath $SourceDir)) {
    throw "SourceDir not found: $SourceDir"
}

if (-not (Test-Path -LiteralPath $Temp0Path)) {
    throw "temp0 path not found: $Temp0Path"
}

$incomingLaunchers = Get-ChildItem -LiteralPath $SourceDir -Recurse -File -Filter "nuitst_*.nss"
$incomingSupport = Get-ChildItem -LiteralPath $SourceDir -Recurse -File -Filter "itnwn_*.nss"
$incomingScripts = @($incomingLaunchers + $incomingSupport)
if (-not $incomingScripts -or $incomingScripts.Count -eq 0) {
    throw "No integration scripts (nuitst_*.nss / itnwn_*.nss) found in: $SourceDir"
}

foreach ($script in $incomingScripts) {
    if ($script.BaseName.Length -gt 16) {
        throw "Launcher script name exceeds 16 chars: $($script.Name)"
    }
}

$dupIncoming = $incomingScripts | Group-Object Name | Where-Object { $_.Count -gt 1 }
if ($dupIncoming) {
    $list = ($dupIncoming | ForEach-Object { $_.Name }) -join ", "
    throw "Duplicate launcher filenames in source set: $list"
}

$existingScripts = Get-ChildItem -LiteralPath $Temp0Path -File -Filter "*.nss" | Select-Object -ExpandProperty Name
$existingSet = @{}
foreach ($name in $existingScripts) {
    $existingSet[$name.ToLowerInvariant()] = $true
}

$collisions = @()
foreach ($script in $incomingScripts) {
    $nameKey = $script.Name.ToLowerInvariant()
    if ($existingSet.ContainsKey($nameKey)) {
        $collisions += $script.Name
    }
}

if ($collisions.Count -gt 0 -and -not $ForceReplace) {
    $list = ($collisions | Sort-Object -Unique) -join ", "
    throw "Name collision with temp0 scripts detected: $list. Use -ForceReplace if you intentionally want to overwrite."
}

$copied = 0
foreach ($script in $incomingScripts) {
    $dest = Join-Path $Temp0Path $script.Name
    Copy-Item -LiteralPath $script.FullName -Destination $dest -Force
    $copied++
}

Write-Host "Deployed $copied integration scripts to $Temp0Path"
