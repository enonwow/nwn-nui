param()

$testsRoot = Split-Path -Parent $PSScriptRoot
$readmePath = Join-Path $testsRoot "README.md"
$resultsPath = Join-Path $testsRoot "TEST_RESULTS.md"
$encSyncValidatePath = Join-Path $PSScriptRoot "it_validate_nuiencsync.ps1"

$violations = @()

$scripts = Get-ChildItem -LiteralPath $testsRoot -Recurse -File -Filter "*.nss" |
    Where-Object { $_.FullName -notlike "*\_tools\*" }

foreach ($file in $scripts) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    if ($base.Length -gt 16) {
        $violations += "Basename >16 chars: $($file.FullName) (len=$($base.Length))"
    }
}

if (-not (Test-Path -LiteralPath $readmePath)) {
    $violations += "Missing README.md at $readmePath"
} else {
    $readmeRaw = Get-Content -LiteralPath $readmePath -Raw
    $mainScripts = $scripts | Where-Object { $_.BaseName -notlike "*_ev" }
    foreach ($file in $mainScripts) {
        $rel = $file.FullName.Substring($testsRoot.Length + 1).Replace("\", "/")
        if ($readmeRaw -notmatch [regex]::Escape($rel)) {
            $violations += "README missing case entry: $rel"
        }
    }
}

if (-not (Test-Path -LiteralPath $resultsPath)) {
    $violations += "Missing TEST_RESULTS.md at $resultsPath"
}

if (-not (Test-Path -LiteralPath $encSyncValidatePath)) {
    $violations += "Missing nuiencsync validator: $encSyncValidatePath"
} else {
    $encOutput = & powershell -ExecutionPolicy Bypass -File $encSyncValidatePath 2>&1
    if ($LASTEXITCODE -ne 0) {
        $violations += "nuiencsync validator failed:"
        $violations += ($encOutput | ForEach-Object { "  $_" })
    }
}

if ($violations.Count -eq 0) {
    Write-Output "OK: validation passed."
    exit 0
}

Write-Output "VALIDATION ERRORS:"
$violations | ForEach-Object { Write-Output ("- " + $_) }
exit 1
