param()

$testsRoot = Split-Path -Parent $PSScriptRoot
$resultsPath = Join-Path $testsRoot "TEST_RESULTS.md"

$statusByName = @{}
if (Test-Path -LiteralPath $resultsPath) {
    $lines = Get-Content -LiteralPath $resultsPath
    foreach ($line in $lines) {
        if ($line -match '^\d+\.\s+`(?<name>[^`]+)`\s+-\s+`(?<status>[^`]+)`') {
            $statusByName[$matches["name"]] = $matches["status"]
        }
    }
}

$rows = @()

$testFolders = Get-ChildItem -LiteralPath $testsRoot -Directory |
    Where-Object { $_.Name -notin @("_tools", "assets") }

foreach ($folder in $testFolders) {
    $mainScripts = Get-ChildItem -LiteralPath $folder.FullName -File -Filter "*.nss" |
        Where-Object { $_.BaseName -notlike "*_ev" }

    foreach ($script in $mainScripts) {
        $base = $script.BaseName
        $pngCount = (Get-ChildItem -LiteralPath $folder.FullName -File -Filter "*.png" -ErrorAction SilentlyContinue).Count
        $rows += [PSCustomObject]@{
            Test     = $base
            Folder   = $folder.Name
            Script   = $script.Name
            Status   = $(if ($statusByName.ContainsKey($base)) { $statusByName[$base] } else { "MISSING" })
            PngCount = $pngCount
        }
    }
}

$rows | Sort-Object Folder, Script | Format-Table -AutoSize
