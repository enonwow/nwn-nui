param(
    [Parameter(Mandatory = $true)]
    [string]$Test
)

$ErrorActionPreference = "Stop"

$testsRoot = Split-Path -Parent $PSScriptRoot
$testDir = Join-Path $testsRoot $Test

if (-not (Test-Path -LiteralPath $testDir -PathType Container)) {
    throw "Test folder not found: $testDir"
}

$scriptPath = Join-Path $testDir ($Test + ".nss")
if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Script not found for test '$Test': $scriptPath"
}

$jsonText = Get-Clipboard -Raw
if ([string]::IsNullOrWhiteSpace($jsonText)) {
    throw "Clipboard is empty. Copy JSON from NUI exporter first."
}

try {
    $null = $jsonText | ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "Clipboard does not contain valid JSON. Copy again from exporter text area."
}

$outPath = Join-Path $testDir ($Test + ".jui")
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outPath, $jsonText, $utf8NoBom)

Write-Output "Saved JUI: $outPath"

