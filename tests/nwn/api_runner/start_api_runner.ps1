param(
    [string]$ApiHost = "host.docker.internal",
    [string]$ApiHostFallback = "",
    [string]$ApiHostFallback2 = "",
    [string]$BindHost = "0.0.0.0",
    [int]$Port = 51871,
    [string]$NwscriptDir = "",
    [string]$ModulePath = "",
    [string]$Manifest = "",
    [string]$RunId = "",
    [switch]$OverwriteRun,
    [ValidateSet("safe", "force")]
    [string]$NssOverwriteMode = "force",
    [string]$TlsCertPath = "",
    [string]$TlsKeyPath = "",
    [switch]$SkipTlsCertEnsure,
    [switch]$SkipNssSync,
    [switch]$SkipRunnerCompile,
    [switch]$CleanupLegacyArtifacts
)

$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "itnwn_api_server.py"
if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Missing API server script: $scriptPath"
}

if ([string]::IsNullOrWhiteSpace($TlsCertPath)) {
    $TlsCertPath = Join-Path $PSScriptRoot "certs\itnwn_api_localhost.crt"
}
if ([string]::IsNullOrWhiteSpace($TlsKeyPath)) {
    $TlsKeyPath = Join-Path $PSScriptRoot "certs\itnwn_api_localhost.key"
}

if ($CleanupLegacyArtifacts) {
    $cleanupScript = Join-Path $PSScriptRoot "cleanup_api_runner_artifacts.ps1"
    if (-not (Test-Path -LiteralPath $cleanupScript)) {
        throw "Missing cleanup script: $cleanupScript"
    }
    & powershell -ExecutionPolicy Bypass -File $cleanupScript
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

function Update-NwnRunnerDefaults {
    param(
        [string]$HostValue,
        [string]$HostFallbackValue,
        [string]$HostFallback2Value,
        [int]$PortValue
    )

    $apicfgPath = Join-Path $PSScriptRoot "nuitst_apicfg.nss"
    $apirunPath = Join-Path $PSScriptRoot "nuitst_apirun.nss"

    if (-not (Test-Path -LiteralPath $apicfgPath)) {
        throw "Missing NWN config script: $apicfgPath"
    }
    if (-not (Test-Path -LiteralPath $apirunPath)) {
        throw "Missing NWN runner script: $apirunPath"
    }

    $apicfgContent = [System.IO.File]::ReadAllText($apicfgPath)
    $fallback1 = "127.0.0.1"
    $fallback2 = "localhost"
    if ($HostValue -eq "127.0.0.1") {
        $fallback1 = "host.docker.internal"
        $fallback2 = "localhost"
    } elseif ($HostValue -eq "localhost") {
        $fallback1 = "host.docker.internal"
        $fallback2 = "127.0.0.1"
    } elseif ($HostValue -eq "host.docker.internal") {
        $fallback1 = "127.0.0.1"
        $fallback2 = "localhost"
    }

    if (-not [string]::IsNullOrWhiteSpace($HostFallbackValue)) {
        $fallback1 = $HostFallbackValue
    }
    if (-not [string]::IsNullOrWhiteSpace($HostFallback2Value)) {
        $fallback2 = $HostFallback2Value
    }

    $apicfgContent = [regex]::Replace(
        $apicfgContent,
        'const string ITAPI_SET_HOST = ".*?";',
        ('const string ITAPI_SET_HOST = "{0}";' -f $HostValue)
    )
    $apicfgContent = [regex]::Replace(
        $apicfgContent,
        'const string ITAPI_SET_HOST_FALLBACK = ".*?";',
        ('const string ITAPI_SET_HOST_FALLBACK = "{0}";' -f $fallback1)
    )
    $apicfgContent = [regex]::Replace(
        $apicfgContent,
        'const string ITAPI_SET_HOST_FALLBACK_2 = ".*?";',
        ('const string ITAPI_SET_HOST_FALLBACK_2 = "{0}";' -f $fallback2)
    )
    $apicfgContent = [regex]::Replace(
        $apicfgContent,
        'const int\s+ITAPI_SET_PORT = \d+;',
        ('const int    ITAPI_SET_PORT = {0};' -f $PortValue)
    )
    [System.IO.File]::WriteAllText($apicfgPath, $apicfgContent, [System.Text.Encoding]::ASCII)

    $apirunContent = [System.IO.File]::ReadAllText($apirunPath)
    $apirunContent = [regex]::Replace(
        $apirunContent,
        'const string ITAPI_HOST_DEFAULT = ".*?";',
        ('const string ITAPI_HOST_DEFAULT = "{0}";' -f $HostValue)
    )
    $apirunContent = [regex]::Replace(
        $apirunContent,
        'const string ITAPI_HOST_FALLBACK = ".*?";',
        ('const string ITAPI_HOST_FALLBACK = "{0}";' -f $fallback1)
    )
    $apirunContent = [regex]::Replace(
        $apirunContent,
        'const string ITAPI_HOST_FALLBACK_2 = ".*?";',
        ('const string ITAPI_HOST_FALLBACK_2 = "{0}";' -f $fallback2)
    )
    $apirunContent = [regex]::Replace(
        $apirunContent,
        'const int\s+ITAPI_PORT_DEFAULT = \d+;',
        ('const int    ITAPI_PORT_DEFAULT = {0};' -f $PortValue)
    )
    [System.IO.File]::WriteAllText($apirunPath, $apirunContent, [System.Text.Encoding]::ASCII)
}

Update-NwnRunnerDefaults `
    -HostValue $ApiHost `
    -HostFallbackValue $ApiHostFallback `
    -HostFallback2Value $ApiHostFallback2 `
    -PortValue $Port

if (-not $SkipTlsCertEnsure) {
    $ensureTlsPath = Join-Path $PSScriptRoot "ensure_local_tls_cert.ps1"
    if (-not (Test-Path -LiteralPath $ensureTlsPath)) {
        throw "Missing TLS ensure script: $ensureTlsPath"
    }
    & powershell -ExecutionPolicy Bypass -File $ensureTlsPath `
        -ApiHost $ApiHost `
        -CertPath $TlsCertPath `
        -KeyPath $TlsKeyPath `
        -TrustCurrentUserRoot
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$args = @(
    $scriptPath,
    "--host", $BindHost,
    "--port", [string]$Port,
    "--tls-cert", $TlsCertPath,
    "--tls-key", $TlsKeyPath
)

if (-not [string]::IsNullOrWhiteSpace($NwscriptDir)) {
    $args += @("--nwnscript-dir", $NwscriptDir)
}
if (-not [string]::IsNullOrWhiteSpace($Manifest)) {
    $args += @("--manifest", $Manifest)
}
if (-not [string]::IsNullOrWhiteSpace($ModulePath)) {
    $args += @("--module-path", $ModulePath)
}
if (-not [string]::IsNullOrWhiteSpace($RunId)) {
    $args += @("--run-id", $RunId)
}
if ($OverwriteRun) {
    $args += "--overwrite-run"
}
if ($NssOverwriteMode -eq "force") {
    $args += "--force-replace-nss"
}
if ($SkipNssSync) {
    $args += "--skip-nss-sync"
}
if ($SkipRunnerCompile) {
    $args += "--skip-runner-compile"
}

Write-Host ("Starting ITNWN API runner host={0} port={1} nssOverwriteMode={2}" -f $ApiHost, $Port, $NssOverwriteMode)
Write-Host ("Bind host={0}" -f $BindHost)
Write-Host ("TLS cert={0}" -f ([System.IO.Path]::GetFullPath($TlsCertPath)))
Write-Host ("TLS key={0}" -f ([System.IO.Path]::GetFullPath($TlsKeyPath)))
& python @args
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

