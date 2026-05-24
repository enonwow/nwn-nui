param()

$ErrorActionPreference = "Stop"

$testsRoot = Split-Path -Parent $PSScriptRoot
$suiteDir = Join-Path $testsRoot "nuiencsync"
$readmePath = Join-Path $suiteDir "README.md"

$violations = @()

function Add-Violation {
    param([string]$Message)
    $script:violations += $Message
}

function Has-Prop {
    param($Object, [string]$Name)
    if ($null -eq $Object) { return $false }
    return $Object.PSObject.Properties.Name -contains $Name
}

function Collect-EncouragedControls {
    param(
        $Node,
        [string]$FileName,
        [bool]$InListRow = $false
    )

    $controls = @()
    if ($null -eq $Node) { return $controls }

    if ($Node -is [System.Array]) {
        foreach ($entry in $Node) {
            $controls += Collect-EncouragedControls -Node $entry -FileName $FileName -InListRow $InListRow
        }
        return $controls
    }

    if ($Node -isnot [pscustomobject]) {
        return $controls
    }

    if (Has-Prop $Node "encouraged") {
        $enc = $Node.encouraged
        $bind = $null
        if ($enc -is [pscustomobject] -and (Has-Prop $enc "bind")) {
            $bind = [string]$enc.bind
        } elseif ($enc -is [bool]) {
            $bind = if ($enc) { "<literal:true>" } else { "<literal:false>" }
        } elseif ($null -ne $enc) {
            $bind = [string]$enc
        }

        $controls += [PSCustomObject]@{
            File      = $FileName
            Type      = if (Has-Prop $Node "type") { [string]$Node.type } else { "" }
            Id        = if (Has-Prop $Node "id") { [string]$Node.id } else { "" }
            Bind      = if ($null -ne $bind) { $bind } else { "" }
            Label     = if (Has-Prop $Node "label") { [string]$Node.label } else { "" }
            InListRow = $InListRow
        }
    }

    if ((Has-Prop $Node "children") -and $null -ne $Node.children) {
        $controls += Collect-EncouragedControls -Node $Node.children -FileName $FileName -InListRow $InListRow
    }

    if ((Has-Prop $Node "row_template") -and $null -ne $Node.row_template) {
        foreach ($cell in $Node.row_template) {
            if ($cell -is [System.Array] -and $cell.Count -gt 0) {
                $controls += Collect-EncouragedControls -Node $cell[0] -FileName $FileName -InListRow $true
            }
        }
    }

    return $controls
}

function Assert-FileExists {
    param([string]$FileName)
    $path = Join-Path $suiteDir $FileName
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Violation "Missing nuiencsync fixture: $FileName"
        return $null
    }
    return $path
}

function Assert-ContainsText {
    param([string]$Text, [string]$Needle, [string]$Message)
    if ($Text -notmatch [regex]::Escape($Needle)) {
        Add-Violation $Message
    }
}

if (-not (Test-Path -LiteralPath $suiteDir)) {
    Add-Violation "Missing suite directory: $suiteDir"
}

if (-not (Test-Path -LiteralPath $readmePath)) {
    Add-Violation "Missing nuiencsync README: $readmePath"
}

$requiredFiles = @(
    "nuiencsync_shared_buttonselect.jui",
    "nuiencsync_shared_checks.jui",
    "nuiencsync_shared_id_dual_bind.jui",
    "nuiencsync_unique_buttonselect.jui",
    "nuiencsync_unique_id_shared_bind.jui",
    "nuiencsync_toggle_btn.jui",
    "encouraged-force-off-btn.jui",
    "nuiencsync_toggle_list.jui",
    "encouraged-force-off-list.jui",
    "nuiencsync_list_dual_track_toggle.jui",
    "nuiencsync_listcell_shards.jui"
)

$cases = @{}
$caseRaw = @{}
$allControls = @()

foreach ($fileName in $requiredFiles) {
    $path = Assert-FileExists -FileName $fileName
    if ($null -eq $path) { continue }

    $raw = Get-Content -LiteralPath $path -Raw
    $caseRaw[$fileName] = $raw
    try {
        $jui = $raw | ConvertFrom-Json
    } catch {
        Add-Violation "Invalid JSON in ${fileName}: $($_.Exception.Message)"
        continue
    }

    $cases[$fileName] = $jui
    $controls = @(Collect-EncouragedControls -Node $jui.root -FileName $fileName -InListRow $false)
    if ($controls.Count -eq 0) {
        Add-Violation "$fileName has no encouraged controls."
    }
    $allControls += $controls
}

function Get-CaseControls {
    param([string]$FileName)
    return @($allControls | Where-Object { $_.File -eq $FileName })
}

function Get-ListNode {
    param($CaseJui)
    if ($null -eq $CaseJui -or -not (Has-Prop $CaseJui "root")) { return $null }
    return @($CaseJui.root.children | Where-Object { $_.type -eq "list" }) | Select-Object -First 1
}

# Shared ID: at least two encouraged controls with duplicate IDs.
foreach ($fileName in @("nuiencsync_shared_buttonselect.jui", "nuiencsync_shared_checks.jui", "nuiencsync_shared_id_dual_bind.jui")) {
    $controls = @(Get-CaseControls -FileName $fileName)
    $ids = @($controls | ForEach-Object { $_.Id } | Where-Object { $_ -ne "" })
    if ($ids.Count -lt 2) {
        Add-Violation "$fileName expected at least 2 encouraged controls with IDs."
        continue
    }
    $uniqueIds = @($ids | Select-Object -Unique)
    if ($uniqueIds.Count -ne 1) {
        Add-Violation "$fileName expected duplicated shared ID, got: $($uniqueIds -join ', ')"
    }
}

# Unique ID: no duplicated encouraged IDs.
foreach ($fileName in @("nuiencsync_unique_buttonselect.jui", "nuiencsync_unique_id_shared_bind.jui")) {
    $controls = @(Get-CaseControls -FileName $fileName)
    $ids = @($controls | ForEach-Object { $_.Id } | Where-Object { $_ -ne "" })
    if ($ids.Count -lt 2) {
        Add-Violation "$fileName expected at least 2 encouraged controls with IDs."
        continue
    }
    $uniqueIds = @($ids | Select-Object -Unique)
    if ($uniqueIds.Count -ne $ids.Count) {
        Add-Violation "$fileName expected unique IDs, got duplicates in: $($ids -join ', ')"
    }
}

# Force-OFF button copies should both describe ON/OFF in fixture labels.
foreach ($fileName in @("nuiencsync_toggle_btn.jui", "encouraged-force-off-btn.jui")) {
    if (-not $cases.ContainsKey($fileName)) { continue }
    $serialized = [string]$caseRaw[$fileName]
    Assert-ContainsText -Text $serialized -Needle "click #2 -> pulse OFF" -Message "$fileName should document second-click OFF expectation."
    $controls = @(Get-CaseControls -FileName $fileName)
    if ($controls.Count -ne 1) {
        Add-Violation "$fileName expected exactly 1 encouraged target for single-control force-off check."
    }
}

# Force-OFF list row and list-row toggle should use row template + row bind.
foreach ($fileName in @("nuiencsync_toggle_list.jui", "encouraged-force-off-list.jui")) {
    if (-not $cases.ContainsKey($fileName)) { continue }
    $list = Get-ListNode -CaseJui $cases[$fileName]
    if ($null -eq $list) {
        Add-Violation "$fileName missing list node."
        continue
    }
    if (-not (Has-Prop $list "row_template")) {
        Add-Violation "$fileName missing row_template on list."
    }
    if (-not (Has-Prop $list "row_count") -or [int]$list.row_count -lt 2) {
        Add-Violation "$fileName row_count should be >= 2 for row isolation regression."
    }
    $controls = @(Get-CaseControls -FileName $fileName)
    if (@($controls | Where-Object { $_.InListRow }).Count -eq 0) {
        Add-Violation "$fileName expected encouraged control(s) inside list row template."
    }
}

# Dual-track list toggle: two distinct track IDs and binds in row template.
$dualTrackFile = "nuiencsync_list_dual_track_toggle.jui"
if ($cases.ContainsKey($dualTrackFile)) {
    $controls = @((Get-CaseControls -FileName $dualTrackFile) | Where-Object { $_.InListRow })
    $ids = @($controls | ForEach-Object { $_.Id } | Where-Object { $_ -ne "" } | Select-Object -Unique)
    $binds = @($controls | ForEach-Object { $_.Bind } | Where-Object { $_ -ne "" } | Select-Object -Unique)
    if ($ids.Count -lt 2) {
        Add-Violation "$dualTrackFile expected at least two distinct encouraged IDs in row template."
    }
    if ($binds.Count -lt 2) {
        Add-Violation "$dualTrackFile expected at least two distinct encouraged binds in row template."
    }
}

# List-cell shards: two shard IDs with independent binds.
$listShardFile = "nuiencsync_listcell_shards.jui"
if ($cases.ContainsKey($listShardFile)) {
    $controls = @((Get-CaseControls -FileName $listShardFile) | Where-Object { $_.InListRow })
    $ids = @($controls | ForEach-Object { $_.Id } | Where-Object { $_ -ne "" } | Select-Object -Unique)
    $binds = @($controls | ForEach-Object { $_.Bind } | Where-Object { $_ -ne "" } | Select-Object -Unique)
    if ($ids.Count -lt 2) {
        Add-Violation "$listShardFile expected at least two shard IDs in row template."
    }
    if ($binds.Count -lt 2) {
        Add-Violation "$listShardFile expected at least two shard binds in row template."
    }
}

if ($violations.Count -gt 0) {
    Write-Output "VALIDATION ERRORS (nuiencsync):"
    $violations | ForEach-Object { Write-Output ("- " + $_) }
    exit 1
}

$summary = $allControls |
    Group-Object File |
    Sort-Object Name |
    ForEach-Object {
        $ids = @($_.Group | ForEach-Object { $_.Id } | Where-Object { $_ -ne "" } | Select-Object -Unique)
        $binds = @($_.Group | ForEach-Object { $_.Bind } | Where-Object { $_ -ne "" } | Select-Object -Unique)
        [PSCustomObject]@{
            File            = $_.Name
            EncouragedCount = $_.Count
            UniqueIds       = $ids.Count
            UniqueBinds     = $binds.Count
            ListRowCount    = @($_.Group | Where-Object { $_.InListRow }).Count
        }
    }

Write-Output "OK: nuiencsync regression validation passed."
$summary | Format-Table -AutoSize
exit 0
