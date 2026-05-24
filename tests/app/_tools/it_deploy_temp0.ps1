param(
    [string]$SourceRoot = "",
    [string]$Temp0Path = "$env:USERPROFILE\Documents\Neverwinter Nights\modules\temp0"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $SourceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

if (-not (Test-Path -LiteralPath $SourceRoot)) {
    throw "SourceRoot not found: $SourceRoot"
}

if (-not (Test-Path -LiteralPath $Temp0Path)) {
    throw "temp0 path not found: $Temp0Path (open the correct module in Aurora first)."
}

$scripts = Get-ChildItem -Path $SourceRoot -Recurse -Filter *.nss |
    Where-Object { $_.FullName -notmatch '\\_tools\\' }

if (-not $scripts) {
    throw "No .nss scripts found under: $SourceRoot"
}

$dupGroups = $scripts | Group-Object -Property Name | Where-Object { $_.Count -gt 1 }
if ($dupGroups) {
    $names = ($dupGroups | ForEach-Object { $_.Name }) -join ", "
    throw "Duplicate script filenames detected (cannot flatten to temp0): $names"
}

$tooLong = $scripts | Where-Object { $_.BaseName.Length -gt 16 }
if ($tooLong) {
    $bad = ($tooLong | ForEach-Object { $_.Name }) -join ", "
    throw "Script name(s) exceed 16 chars: $bad"
}

$copied = 0
foreach ($script in $scripts) {
    $dest = Join-Path $Temp0Path $script.Name
    Copy-Item -LiteralPath $script.FullName -Destination $dest -Force
    $copied++
}

Write-Host "Deployed $copied scripts to $Temp0Path"
