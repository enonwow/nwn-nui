param(
    [Parameter(Mandatory = $true)]
    [string]$Test,

    [string]$BuilderDir = "",

    [string]$TestsRoot = "",

    [int]$Port = 4174,

    [double]$MinSimilarity = 97.0,

    [switch]$Headed,

    [switch]$KeepSession,

    [switch]$CaptureOnly
)

$ErrorActionPreference = "Stop"

$suiteRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent (Split-Path -Parent $suiteRoot)
$BuilderDir = if ([string]::IsNullOrWhiteSpace($BuilderDir)) {
    Join-Path $repoRoot "nui-builder"
}
else {
    $BuilderDir
}
$testsRoot = if ([string]::IsNullOrWhiteSpace($TestsRoot)) {
    Join-Path $repoRoot "tests\nwn"
}
else {
    $TestsRoot
}
$testsRoot = [System.IO.Path]::GetFullPath($testsRoot)
$testDir = Join-Path $testsRoot $Test
$artifactsRoot = Join-Path $suiteRoot "_artifacts"
$candidateRoot = Join-Path $artifactsRoot "app-screenshots"
$compareRoot = Join-Path $artifactsRoot "aurora-compare"
$sessionRoot = Join-Path $artifactsRoot ("_capture_session_" + $Test)
$sessionIntegrationRoot = Join-Path $sessionRoot "reference"
$sessionTestDir = Join-Path $sessionIntegrationRoot $Test

function Convert-ToRepoRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue
    )

    try {
        $full = [System.IO.Path]::GetFullPath($PathValue)
        $repo = [System.IO.Path]::GetFullPath($repoRoot)
        if ($full.StartsWith($repo, [System.StringComparison]::OrdinalIgnoreCase)) {
            $trimmed = $full.Substring($repo.Length).TrimStart('\', '/')
            return ($trimmed -replace '\\', '/')
        }
        return ($full -replace '\\', '/')
    }
    catch {
        return ($PathValue -replace '\\', '/')
    }
}

if (-not (Test-Path -LiteralPath $BuilderDir)) {
    throw "Builder folder not found: $BuilderDir"
}

if (-not (Test-Path -LiteralPath $testsRoot)) {
    throw "Tests root not found: $testsRoot"
}

if (-not (Test-Path -LiteralPath $testDir)) {
    throw "Test folder not found: $testDir"
}

$juiFiles = @(Get-ChildItem -LiteralPath $testDir -File -Filter "*.jui" -ErrorAction SilentlyContinue)
if ($juiFiles.Count -eq 0) {
    throw "No .jui file in test '$Test'. Add at least one JUI file first."
}

$referencePngs = @(
    Get-ChildItem -LiteralPath $testDir -File -Filter "*.png" -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -notmatch '^app_' -and
        $_.Name -notmatch '^diff_' -and
        $_.Name -notmatch '^candidate_'
    }
)

if ($referencePngs.Count -eq 0 -and -not $CaptureOnly) {
    throw "No Aurora/reference .png found in '$Test'. Add reference screenshots first."
}

New-Item -ItemType Directory -Path $candidateRoot -Force | Out-Null
New-Item -ItemType Directory -Path $compareRoot -Force | Out-Null

if (Test-Path -LiteralPath $sessionRoot) {
    Remove-Item -LiteralPath $sessionRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $sessionTestDir -Force | Out-Null

foreach ($file in $juiFiles) {
    Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $sessionTestDir $file.Name) -Force
}
foreach ($file in $referencePngs) {
    Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $sessionTestDir $file.Name) -Force
}

$minSimilarityText = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:0.###}", $MinSimilarity)

Push-Location $BuilderDir
try {
    $nodeArgs = @(
        "tools/capture_compare_e2e.mjs",
        "--host", "127.0.0.1",
        "--port", "$Port",
        "--integration-dir", $sessionIntegrationRoot,
        "--screens-dir", $candidateRoot,
        "--compare-dir", $compareRoot,
        "--min-similarity", $minSimilarityText,
        "--match", $Test
    )
    if ($Headed) {
        $nodeArgs += "--headed"
    }
    else {
        $nodeArgs += "--headless"
    }
    & node @nodeArgs
    if ($LASTEXITCODE -ne 0) {
        throw "capture tool failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}

$capturedDir = Join-Path $candidateRoot $Test
if (-not (Test-Path -LiteralPath $capturedDir)) {
    throw "No captured images for '$Test' in $capturedDir"
}

$capturedPngs = @(Get-ChildItem -LiteralPath $capturedDir -File -Filter "*.png" -ErrorAction SilentlyContinue)
if ($capturedPngs.Count -eq 0) {
    throw "Capture completed but found 0 screenshots for '$Test'."
}

$copiedAppShots = @()
foreach ($shot in $capturedPngs) {
    $destPath = Join-Path $testDir ("app_" + $shot.Name)
    Copy-Item -LiteralPath $shot.FullName -Destination $destPath -Force
    $copiedAppShots += (Convert-ToRepoRelativePath -PathValue $destPath)
}

$passes = 0
$fails = 0
$missing = 0
$testResults = @()
$summaryPath = ""
$latestCompareRun = $null

if (-not $CaptureOnly) {
    $latestCompareRun = Get-ChildItem -LiteralPath $compareRoot -Directory -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $latestCompareRun) {
        throw "Compare output folder not found under $compareRoot"
    }

    $summaryPath = Join-Path $latestCompareRun.FullName "summary.json"
    if (-not (Test-Path -LiteralPath $summaryPath)) {
        throw "Missing compare summary: $summaryPath"
    }

    $summary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
    $testResults = @(
        $summary.results | Where-Object { $_.reference -like "$Test/*" }
    )

    $passes = @($testResults | Where-Object { $_.status -eq "PASS" }).Count
    $fails = @($testResults | Where-Object { $_.status -eq "FAIL" }).Count
    $missing = @($testResults | Where-Object { $_.status -eq "MISSING_CANDIDATE" }).Count
}

$testSummary = if (-not $CaptureOnly) {
    [ordered]@{
        generated_at = (Get-Date).ToString("s")
        mode = "compare"
        test = $Test
        threshold_similarity_percent = $summary.threshold_similarity_percent
        source_summary = (Convert-ToRepoRelativePath -PathValue $summaryPath)
        totals = [ordered]@{
            compared = @($testResults | Where-Object { $_.status -in @("PASS", "FAIL") }).Count
            passes = $passes
            fails = $fails
            missing_candidates = $missing
        }
        results = $testResults
    }
}
else {
    [ordered]@{
        generated_at = (Get-Date).ToString("s")
        mode = "capture_only"
        test = $Test
        note = "No Aurora references in this folder. Saved app screenshots only."
        captures = $copiedAppShots
    }
}

$testSummaryPath = Join-Path $testDir "app_compare_summary.json"
$testSummary | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $testSummaryPath -Encoding UTF8

$copiedDiffs = @()
if (-not $CaptureOnly) {
    foreach ($row in $testResults) {
        if (-not $row.diff_image) {
            continue
        }
        $srcDiff = Join-Path $latestCompareRun.FullName $row.diff_image
        if (-not (Test-Path -LiteralPath $srcDiff)) {
            continue
        }
        $refStem = [System.IO.Path]::GetFileNameWithoutExtension([string]$row.reference)
        if ([string]::IsNullOrWhiteSpace($refStem)) {
            $refStem = [System.IO.Path]::GetFileNameWithoutExtension([string]$row.candidate)
        }
        if ([string]::IsNullOrWhiteSpace($refStem)) {
            $refStem = "unknown"
        }
        $destDiff = Join-Path $testDir ("diff_" + $refStem + ".png")
        Copy-Item -LiteralPath $srcDiff -Destination $destDiff -Force
        $copiedDiffs += (Convert-ToRepoRelativePath -PathValue $destDiff)
    }
}

Write-Output "OK: Builder capture + compare completed for '$Test'."
Write-Output "App screenshots copied to test folder:"
$copiedAppShots | ForEach-Object { Write-Output ("- " + $_) }
Write-Output "Summary:"
Write-Output ("- " + (Convert-ToRepoRelativePath -PathValue $testSummaryPath))
if ($copiedDiffs.Count -gt 0) {
    Write-Output "Diff images copied:"
    $copiedDiffs | ForEach-Object { Write-Output ("- " + $_) }
}
if (-not $CaptureOnly) {
    Write-Output ("PASS: {0}, FAIL: {1}, MISSING: {2}" -f $passes, $fails, $missing)
}

if (-not $KeepSession) {
    Remove-Item -LiteralPath $sessionRoot -Recurse -Force -ErrorAction SilentlyContinue
}
