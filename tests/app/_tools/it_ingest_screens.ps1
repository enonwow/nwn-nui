param(
    [Parameter(Mandatory = $true)]
    [string]$Test,

    [string[]]$States = @(),

    [string]$SourceDir = "$env:USERPROFILE\Pictures\Screenshots",

    [switch]$DryRun
)

$normalizedStates = @()
if ($States.Count -eq 1 -and $States[0] -match ',') {
    $normalizedStates = $States[0].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
}
elseif ($States.Count -gt 0) {
    $normalizedStates = $States | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
}

$States = $normalizedStates

$testsRoot = Split-Path -Parent $PSScriptRoot
$testDir = Join-Path $testsRoot $Test

if (-not (Test-Path -LiteralPath $testDir)) {
    throw "Test folder not found: $testDir"
}

if (-not (Test-Path -LiteralPath $SourceDir)) {
    throw "Screenshot source folder not found: $SourceDir"
}

$needed = if ($States.Count -gt 0) { $States.Count } else { 1 }

$latest = Get-ChildItem -LiteralPath $SourceDir -File -Filter "*.png" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First $needed |
    Sort-Object LastWriteTime

if ($latest.Count -lt $needed) {
    throw "Not enough screenshots in $SourceDir. Needed: $needed, found: $($latest.Count)."
}

$results = @()

for ($i = 0; $i -lt $needed; $i++) {
    $src = $latest[$i].FullName
    $destName = if ($States.Count -gt 0) {
        "{0}_{1}.png" -f $Test, $States[$i]
    } else {
        "{0}.png" -f $Test
    }
    $dest = Join-Path $testDir $destName

    $results += [PSCustomObject]@{
        Source      = $src
        Destination = $dest
    }

    if (-not $DryRun) {
        Copy-Item -LiteralPath $src -Destination $dest -Force
    }
}

if ($DryRun) {
    Write-Output "DRY RUN - no files copied."
}

$results | Format-Table -AutoSize
