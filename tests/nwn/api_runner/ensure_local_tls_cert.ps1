param(
    [string]$ApiHost = "localhost",
    [string]$CertPath = "",
    [string]$KeyPath = "",
    [switch]$ForceRegenerate,
    [switch]$TrustCurrentUserRoot
)

$ErrorActionPreference = "Stop"

function ConvertTo-PemText {
    param(
        [string]$Header,
        [string]$Footer,
        [byte[]]$Bytes
    )

    $base64 = [Convert]::ToBase64String($Bytes)
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add($Header) | Out-Null
    for ($i = 0; $i -lt $base64.Length; $i += 64) {
        $len = [Math]::Min(64, $base64.Length - $i)
        $lines.Add($base64.Substring($i, $len)) | Out-Null
    }
    $lines.Add($Footer) | Out-Null
    return ($lines -join "`n") + "`n"
}

function Test-CertDnsNames {
    param(
        [string]$ExistingCertPath,
        [string[]]$RequiredDnsNames
    )

    if (-not (Test-Path -LiteralPath $ExistingCertPath)) {
        return $false
    }

    try {
        $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($ExistingCertPath)
        $ext = $cert.Extensions | Where-Object { $_.Oid.Value -eq "2.5.29.17" } | Select-Object -First 1
        if ($null -eq $ext) {
            return $false
        }

        $formatted = $ext.Format($false)
        if ([string]::IsNullOrWhiteSpace($formatted)) {
            return $false
        }

        $found = @()
        foreach ($line in ($formatted -split "[,\r\n]+")) {
            $part = $line.Trim()
            if ($part -eq "") { continue }
            $idx = $part.IndexOf("=")
            if ($idx -lt 0) { continue }
            $value = $part.Substring($idx + 1).Trim()
            if ($value -ne "") {
                $found += $value.ToLowerInvariant()
            }
        }

        foreach ($dnsName in $RequiredDnsNames) {
            if ([string]::IsNullOrWhiteSpace($dnsName)) { continue }
            $needle = $dnsName.Trim().ToLowerInvariant()
            if (-not ($found -contains $needle)) {
                return $false
            }
        }

        return $true
    }
    catch {
        return $false
    }
}

function New-DerLengthBytes {
    param([int]$Length)

    if ($Length -lt 128) {
        return [byte[]]@([byte]$Length)
    }

    $stack = New-Object System.Collections.Generic.List[byte]
    $n = $Length
    while ($n -gt 0) {
        $stack.Insert(0, [byte]($n -band 0xFF))
        $n = [Math]::Floor($n / 256)
    }

    $out = New-Object System.Collections.Generic.List[byte]
    $out.Add([byte](0x80 -bor $stack.Count)) | Out-Null
    foreach ($b in $stack) {
        $out.Add($b) | Out-Null
    }
    return $out.ToArray()
}

function New-DerIntegerBytes {
    param([byte[]]$ValueBytes)

    if ($null -eq $ValueBytes -or $ValueBytes.Length -eq 0) {
        $ValueBytes = [byte[]]@([byte]0)
    }

    $first = 0
    while ($first -lt ($ValueBytes.Length - 1) -and $ValueBytes[$first] -eq 0) {
        $first++
    }
    if ($first -gt 0) {
        $ValueBytes = $ValueBytes[$first..($ValueBytes.Length - 1)]
    }

    if (($ValueBytes[0] -band 0x80) -ne 0) {
        $ValueBytes = [byte[]]@([byte]0) + $ValueBytes
    }

    $out = New-Object System.Collections.Generic.List[byte]
    $out.Add([byte]0x02) | Out-Null
    foreach ($b in (New-DerLengthBytes -Length $ValueBytes.Length)) {
        $out.Add($b) | Out-Null
    }
    foreach ($b in $ValueBytes) {
        $out.Add($b) | Out-Null
    }
    return $out.ToArray()
}

function ConvertTo-RsaPrivateKeyDer {
    param([System.Security.Cryptography.RSAParameters]$Params)

    $items = @(
        (New-DerIntegerBytes -ValueBytes ([byte[]]@([byte]0))),
        (New-DerIntegerBytes -ValueBytes $Params.Modulus),
        (New-DerIntegerBytes -ValueBytes $Params.Exponent),
        (New-DerIntegerBytes -ValueBytes $Params.D),
        (New-DerIntegerBytes -ValueBytes $Params.P),
        (New-DerIntegerBytes -ValueBytes $Params.Q),
        (New-DerIntegerBytes -ValueBytes $Params.DP),
        (New-DerIntegerBytes -ValueBytes $Params.DQ),
        (New-DerIntegerBytes -ValueBytes $Params.InverseQ)
    )

    $payload = New-Object System.Collections.Generic.List[byte]
    foreach ($item in $items) {
        foreach ($b in $item) {
            $payload.Add($b) | Out-Null
        }
    }

    $out = New-Object System.Collections.Generic.List[byte]
    $out.Add([byte]0x30) | Out-Null
    foreach ($b in (New-DerLengthBytes -Length $payload.Count)) {
        $out.Add($b) | Out-Null
    }
    foreach ($b in $payload) {
        $out.Add($b) | Out-Null
    }
    return $out.ToArray()
}

if ([string]::IsNullOrWhiteSpace($CertPath)) {
    throw "CertPath is required."
}
if ([string]::IsNullOrWhiteSpace($KeyPath)) {
    throw "KeyPath is required."
}

$resolvedCertPath = [System.IO.Path]::GetFullPath($CertPath)
$resolvedKeyPath = [System.IO.Path]::GetFullPath($KeyPath)

$requiredDnsNames = New-Object System.Collections.Generic.List[string]
$requiredDnsNames.Add("localhost") | Out-Null
$requiredDnsNames.Add("127.0.0.1") | Out-Null
$requiredDnsNames.Add("host.docker.internal") | Out-Null
if (-not [string]::IsNullOrWhiteSpace($ApiHost)) {
    if (-not $requiredDnsNames.Contains($ApiHost)) {
        $requiredDnsNames.Add($ApiHost) | Out-Null
    }
}
if (-not [string]::IsNullOrWhiteSpace($env:COMPUTERNAME)) {
    if (-not $requiredDnsNames.Contains($env:COMPUTERNAME)) {
        $requiredDnsNames.Add($env:COMPUTERNAME) | Out-Null
    }
}

if ((Test-Path -LiteralPath $resolvedCertPath) -and (Test-Path -LiteralPath $resolvedKeyPath) -and -not $ForceRegenerate) {
    $sanOk = Test-CertDnsNames -ExistingCertPath $resolvedCertPath -RequiredDnsNames $requiredDnsNames.ToArray()
    if ($sanOk) {
        Write-Host ("TLS cert/key already present and SAN-complete: cert={0} key={1}" -f $resolvedCertPath, $resolvedKeyPath)
        exit 0
    }

    Write-Host ("TLS cert exists but SAN is incomplete. Regenerating cert/key: cert={0} key={1}" -f $resolvedCertPath, $resolvedKeyPath)
    Remove-Item -LiteralPath $resolvedCertPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $resolvedKeyPath -Force -ErrorAction SilentlyContinue
}

$certDir = Split-Path -Parent $resolvedCertPath
$keyDir = Split-Path -Parent $resolvedKeyPath
New-Item -ItemType Directory -Path $certDir -Force | Out-Null
New-Item -ItemType Directory -Path $keyDir -Force | Out-Null

$dnsNames = New-Object System.Collections.Generic.List[string]
foreach ($dnsName in $requiredDnsNames) {
    if (-not [string]::IsNullOrWhiteSpace($dnsName)) {
        if (-not $dnsNames.Contains($dnsName)) {
            $dnsNames.Add($dnsName) | Out-Null
        }
    }
}

$cert = New-SelfSignedCertificate `
    -Subject "CN=localhost" `
    -DnsName $dnsNames.ToArray() `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -KeyAlgorithm RSA `
    -KeyLength 2048 `
    -HashAlgorithm SHA256 `
    -NotAfter (Get-Date).AddYears(2) `
    -KeyExportPolicy Exportable `
    -Provider "Microsoft Software Key Storage Provider"

$certPem = ConvertTo-PemText `
    -Header "-----BEGIN CERTIFICATE-----" `
    -Footer "-----END CERTIFICATE-----" `
    -Bytes $cert.RawData
[System.IO.File]::WriteAllText($resolvedCertPath, $certPem, [System.Text.Encoding]::ASCII)

$rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
if ($null -eq $rsa) {
    throw "Could not load RSA private key from generated certificate."
}

$rsaParams = $rsa.ExportParameters($true)
$derKey = ConvertTo-RsaPrivateKeyDer -Params $rsaParams
$keyPem = ConvertTo-PemText `
    -Header "-----BEGIN RSA PRIVATE KEY-----" `
    -Footer "-----END RSA PRIVATE KEY-----" `
    -Bytes $derKey
[System.IO.File]::WriteAllText($resolvedKeyPath, $keyPem, [System.Text.Encoding]::ASCII)

if ($TrustCurrentUserRoot) {
    $rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "CurrentUser")
    $rootStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    try {
        $existing = $rootStore.Certificates.Find(
            [System.Security.Cryptography.X509Certificates.X509FindType]::FindByThumbprint,
            $cert.Thumbprint,
            $false
        )
        if ($existing.Count -eq 0) {
            $rootStore.Add($cert)
            Write-Host ("Trusted certificate in CurrentUser\\Root: {0}" -f $cert.Thumbprint)
        }
        else {
            Write-Host ("Certificate already trusted in CurrentUser\\Root: {0}" -f $cert.Thumbprint)
        }
    }
    finally {
        $rootStore.Close()
    }
}

Write-Host ("Generated local TLS cert/key for API runner: cert={0} key={1}" -f $resolvedCertPath, $resolvedKeyPath)
