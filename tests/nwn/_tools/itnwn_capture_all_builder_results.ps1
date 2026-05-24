param(
    [string]$BuilderDir = "",
    [string]$TestsRoot = "",
    [int]$Port = 4174,
    [double]$MinSimilarity = 97.0,
    [string[]]$Match = @(),
    [switch]$Headed,
    [switch]$KeepSession,
    [switch]$CaptureOnly,
    [switch]$StopOnFailure,
    [switch]$SkipValidate
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
$captureScript = Join-Path $PSScriptRoot "itnwn_capture_builder_result.ps1"
$validateScript = Join-Path $PSScriptRoot "itnwn_validate.ps1"
$artifactsRoot = Join-Path $suiteRoot "_artifacts"
$aggregatePath = Join-Path $artifactsRoot "app_compare_all_summary.json"

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
if (-not (Test-Path -LiteralPath $captureScript)) {
    throw "Capture script not found: $captureScript"
}
if (-not (Test-Path -LiteralPath $validateScript)) {
    throw "Validate script not found: $validateScript"
}

if (-not $SkipValidate) {
    Write-Host "Running tests/nwn validation..."
    & powershell -ExecutionPolicy Bypass -File $validateScript
    if ($LASTEXITCODE -ne 0) {
        throw "Validation failed. Fix suite issues or use -SkipValidate."
    }
}

New-Item -ItemType Directory -Path $artifactsRoot -Force | Out-Null

$allTestDirs = Get-ChildItem -LiteralPath $testsRoot -Directory | Sort-Object Name
$tests = @()
foreach ($dir in $allTestDirs) {
    $juiCount = (Get-ChildItem -LiteralPath $dir.FullName -File -Filter "*.jui" -ErrorAction SilentlyContinue).Count
    if ($juiCount -gt 0) {
        $tests += $dir
    }
}

if ($Match.Count -gt 0) {
    $needles = @($Match | ForEach-Object { $_.ToLowerInvariant() })
    $tests = @(
        $tests | Where-Object {
            $name = $_.Name.ToLowerInvariant()
            $ok = $true
            foreach ($needle in $needles) {
                if ($name -notlike "*$needle*") {
                    $ok = $false
                    break
                }
            }
            $ok
        }
    )
}

if ($tests.Count -eq 0) {
    throw "No tests with .jui found after filtering."
}

$results = @()
$anyHardFailure = $false
$startAt = Get-Date

foreach ($test in $tests) {
    $testName = $test.Name
    Write-Host ""
    Write-Host ("=== Running test: {0} ===" -f $testName)

    $captureArgs = @(
        "-ExecutionPolicy", "Bypass",
        "-File", $captureScript,
        "-Test", $testName,
        "-BuilderDir", $BuilderDir,
        "-TestsRoot", $testsRoot,
        "-Port", [string]$Port,
        "-MinSimilarity", [string]$MinSimilarity
    )
    if ($Headed) { $captureArgs += "-Headed" }
    if ($KeepSession) { $captureArgs += "-KeepSession" }
    if ($CaptureOnly) { $captureArgs += "-CaptureOnly" }

    $runError = $null
    try {
        & powershell @captureArgs
    }
    catch {
        $runError = $_.Exception.Message
    }

    $summaryPath = Join-Path $test.FullName "app_compare_summary.json"
    $row = [ordered]@{
        test = $testName
        status = "UNKNOWN"
        mode = if ($CaptureOnly) { "capture_only" } else { "compare" }
        passes = 0
        fails = 0
        missing_candidates = 0
        compared = 0
        similarity_threshold = $MinSimilarity
        summary_path = (Convert-ToRepoRelativePath -PathValue $summaryPath)
        error = $null
    }

    if ($runError) {
        $row.status = "RUN_ERROR"
        $row.error = $runError
        $anyHardFailure = $true
    }
    elseif (-not (Test-Path -LiteralPath $summaryPath)) {
        $row.status = "NO_SUMMARY"
        $row.error = "Missing app_compare_summary.json"
        $anyHardFailure = $true
    }
    else {
        try {
            $summary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
            $row.mode = [string]$summary.mode

            if ($summary.mode -eq "compare") {
                $totals = $summary.totals
                $row.passes = [int]$totals.passes
                $row.fails = [int]$totals.fails
                $row.missing_candidates = [int]$totals.missing_candidates
                $row.compared = [int]$totals.compared
                if ($row.fails -gt 0 -or $row.missing_candidates -gt 0) {
                    $row.status = "FAIL"
                    $anyHardFailure = $true
                }
                else {
                    $row.status = "PASS"
                }
            }
            else {
                $row.status = "CAPTURED"
            }
        }
        catch {
            $row.status = "SUMMARY_ERROR"
            $row.error = $_.Exception.Message
            $anyHardFailure = $true
        }
    }

    $results += [PSCustomObject]$row

    if ($StopOnFailure -and $row.status -in @("RUN_ERROR", "NO_SUMMARY", "SUMMARY_ERROR", "FAIL")) {
        Write-Host ("Stopping early because -StopOnFailure is set (test: {0})." -f $testName)
        break
    }
}

$endAt = Get-Date
$elapsed = [math]::Round(($endAt - $startAt).TotalSeconds, 2)

$totals = [ordered]@{
    tests_total = $results.Count
    pass = @($results | Where-Object { $_.status -eq "PASS" }).Count
    fail = @($results | Where-Object { $_.status -eq "FAIL" }).Count
    captured = @($results | Where-Object { $_.status -eq "CAPTURED" }).Count
    run_errors = @($results | Where-Object { $_.status -in @("RUN_ERROR", "NO_SUMMARY", "SUMMARY_ERROR") }).Count
    compared_rows = ($results | Measure-Object -Property compared -Sum).Sum
    failed_rows = ($results | Measure-Object -Property fails -Sum).Sum
    missing_candidates = ($results | Measure-Object -Property missing_candidates -Sum).Sum
    elapsed_seconds = $elapsed
}

$aggregate = [ordered]@{
    generated_at = (Get-Date).ToString("s")
    suite_root = (Convert-ToRepoRelativePath -PathValue $suiteRoot)
    tests_root = (Convert-ToRepoRelativePath -PathValue $testsRoot)
    builder_dir = (Convert-ToRepoRelativePath -PathValue $BuilderDir)
    port = $Port
    min_similarity = $MinSimilarity
    capture_only = [bool]$CaptureOnly
    match = $Match
    totals = $totals
    tests = $results
}

$aggregate | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $aggregatePath -Encoding UTF8

Write-Host ""
Write-Host "=== Aggregate Integration Summary ==="
$results |
    Select-Object test, status, compared, passes, fails, missing_candidates |
    Format-Table -AutoSize

Write-Host ("Summary JSON: {0}" -f (Convert-ToRepoRelativePath -PathValue $aggregatePath))
Write-Host ("Elapsed: {0}s" -f $elapsed)

if ($anyHardFailure) {
    exit 1
}
exit 0
