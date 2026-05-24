param(
    [string]$SourceRoot = "",
    [string]$HakPath = "$env:USERPROFILE\Documents\Neverwinter Nights\hak\int_test_nwn.hak",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$toolsRoot = $PSScriptRoot
$suiteRoot = Split-Path -Parent $toolsRoot
$repoRoot = Split-Path -Parent (Split-Path -Parent $suiteRoot)
if (-not $SourceRoot) {
    $SourceRoot = $suiteRoot
}

$packerPath = Join-Path $toolsRoot "itnwn_pack_hak.mjs"
if (-not (Test-Path -LiteralPath $packerPath)) {
    throw "Packer script missing: $packerPath"
}

$args = @(
    $packerPath,
    "--source-root", $SourceRoot,
    "--output-hak", $HakPath
)
if ($DryRun) {
    $args += "--dry-run"
}

Write-Host "SourceRoot: $SourceRoot"
Write-Host "HakPath:    $HakPath"
if ($DryRun) {
    Write-Host "Mode:       dry-run"
}

Push-Location $repoRoot
try {
    & node @args
    if ($LASTEXITCODE -ne 0) {
        throw "HAK packing failed (exit code $LASTEXITCODE)."
    }
}
finally {
    Pop-Location
}
