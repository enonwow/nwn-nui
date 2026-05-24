param()

$ErrorActionPreference = "Stop"

$suiteRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent (Split-Path -Parent $suiteRoot)
$testsRoot = $suiteRoot
$resultsPath = Join-Path $testsRoot "TEST_RESULTS.md"

if (-not (Test-Path -LiteralPath $testsRoot)) {
    throw "Missing tests root: $testsRoot"
}

$violations = @()
$allNss = @()
$allJui = @()

$testFolders = Get-ChildItem -LiteralPath $testsRoot -Directory | Where-Object { $_.Name -notlike "_*" }
if (-not $testFolders) {
    $violations += "No test folders found under tests/"
}

foreach ($folder in $testFolders) {
    $nssFiles = Get-ChildItem -LiteralPath $folder.FullName -File -Filter "*.nss" -ErrorAction SilentlyContinue
    $juiFiles = Get-ChildItem -LiteralPath $folder.FullName -File -Filter "*.jui" -ErrorAction SilentlyContinue
    $pngFiles = Get-ChildItem -LiteralPath $folder.FullName -File -Filter "*.png" -ErrorAction SilentlyContinue

    if (($nssFiles.Count + $juiFiles.Count) -eq 0) {
        $violations += "Test '$($folder.Name)' has no .nss/.jui files."
    }

    foreach ($file in @(@($nssFiles) + @($juiFiles))) {
        if ($file.BaseName.Length -gt 16) {
            $violations += "$($folder.Name)/$($file.Name): basename exceeds 16 chars."
        }
    }

    $allNss += $nssFiles
    $allJui += $juiFiles
}

$dupNss = $allNss | Group-Object Name | Where-Object { $_.Count -gt 1 }
foreach ($group in $dupNss) {
    $violations += "Duplicate .nss filename across tests: $($group.Name)"
}

$dupJui = $allJui | Group-Object Name | Where-Object { $_.Count -gt 1 }
foreach ($group in $dupJui) {
    $violations += "Duplicate .jui filename across tests: $($group.Name)"
}

if (-not (Test-Path -LiteralPath $resultsPath)) {
    $violations += "Missing TEST_RESULTS.md at $resultsPath"
}

if ($violations.Count -eq 0) {
    Write-Output "OK: tests/nwn validation passed."
    exit 0
}

Write-Output "VALIDATION ERRORS:"
$violations | ForEach-Object { Write-Output ("- " + $_) }
exit 1
