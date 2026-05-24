param(
    [int]$KeepRecentApiRuns = 2
)

$ErrorActionPreference = "Stop"

$testsRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$archiveRoot = Join-Path $testsRoot "_archive"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$batchDir = Join-Path $archiveRoot ("cleanup_api_runner_" + $stamp)

$candidates = @(
    (Join-Path $testsRoot "nwn\_artifacts"),
    (Join-Path $testsRoot "nwn\api_runner\__pycache__"),
    (Join-Path $testsRoot "nwn\_tools\__pycache__")
)

New-Item -ItemType Directory -Path $batchDir -Force | Out-Null

foreach ($path in @($candidates | Where-Object { Test-Path -LiteralPath $_ })) {
    $full = [System.IO.Path]::GetFullPath($path)
    $testsFull = [System.IO.Path]::GetFullPath($testsRoot)
    if (-not $full.StartsWith($testsFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to move path outside tests root: $full"
    }

    $rel = $full.Substring($testsFull.Length).TrimStart('\', '/')
    $target = Join-Path $batchDir $rel
    $targetParent = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $targetParent)) {
        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
    }

    Move-Item -LiteralPath $full -Destination $target
    Write-Host ("Moved: {0} -> {1}" -f $rel, $target)
}

if ($KeepRecentApiRuns -lt 0) {
    $KeepRecentApiRuns = 0
}
$runsDir = Join-Path $testsRoot "_artifacts\api_runner\runs"
if (Test-Path -LiteralPath $runsDir) {
    $runDirs = @(Get-ChildItem -LiteralPath $runsDir -Directory | Sort-Object LastWriteTime -Descending)
    $toArchive = @($runDirs | Select-Object -Skip $KeepRecentApiRuns)
    if ($toArchive.Count -gt 0) {
        foreach ($run in $toArchive) {
            $rel = [System.IO.Path]::GetFullPath($run.FullName).Substring([System.IO.Path]::GetFullPath($testsRoot).Length).TrimStart('\', '/')
            $target = Join-Path $batchDir $rel
            $targetParent = Split-Path -Parent $target
            if (-not (Test-Path -LiteralPath $targetParent)) {
                New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
            }
            Move-Item -LiteralPath $run.FullName -Destination $target
            Write-Host ("Archived run: {0}" -f $run.Name)
        }
    }
}

if ((Get-ChildItem -LiteralPath $batchDir -Recurse -Force | Measure-Object).Count -le 1) {
    Remove-Item -LiteralPath $batchDir -Recurse -Force
    Write-Host "No legacy artifacts found. Nothing to clean."
    exit 0
}

Write-Host ("Cleanup complete. Archive batch: {0}" -f $batchDir)
