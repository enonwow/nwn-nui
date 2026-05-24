param()

$ErrorActionPreference = "Stop"

$suiteRoot = Split-Path -Parent $PSScriptRoot
$testsRoot = $suiteRoot
$resultsPath = Join-Path $suiteRoot "TEST_RESULTS.md"

if (-not (Test-Path -LiteralPath $testsRoot)) {
    throw "Missing tests root: $testsRoot"
}

$statusByTest = @{}
if (Test-Path -LiteralPath $resultsPath) {
    $lines = Get-Content -LiteralPath $resultsPath
    foreach ($line in $lines) {
        if ($line -match '^\d+\.\s+`(?<name>[^`]+)`\s+-\s+`(?<status>[^`]+)`') {
            $statusByTest[$matches["name"]] = $matches["status"]
        }
    }
}

$rows = @()
$testFolders = Get-ChildItem -LiteralPath $testsRoot -Directory | Where-Object { $_.Name -notlike "_*" } | Sort-Object Name
foreach ($folder in $testFolders) {
    $nss = (Get-ChildItem -LiteralPath $folder.FullName -File -Filter "*.nss" -ErrorAction SilentlyContinue).Count
    $jui = (Get-ChildItem -LiteralPath $folder.FullName -File -Filter "*.jui" -ErrorAction SilentlyContinue).Count
    $png = (Get-ChildItem -LiteralPath $folder.FullName -File -Filter "*.png" -ErrorAction SilentlyContinue).Count
    $status = if ($statusByTest.ContainsKey($folder.Name)) { $statusByTest[$folder.Name] } else { "MISSING" }

    $rows += [PSCustomObject]@{
        Test   = $folder.Name
        Nss    = $nss
        Jui    = $jui
        Png    = $png
        Status = $status
    }
}

if (-not $rows) {
    Write-Output "No tests found."
    exit 0
}

$rows | Format-Table -AutoSize
