[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$HapPath,
    [string]$Java = 'D:/ProgramFiles/Huawei/DevEco Studio/jbr/bin/java.exe',
    [string]$SignTool = 'D:/ProgramFiles/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/lib/hap-sign-tool.jar',
    # Pin the exact artifact so a rebuild cannot be substituted for the verified one.
    [string]$ExpectedSha256,
    [ValidateSet('release', 'debug', 'profile')][string]$ExpectedProfileType = 'release',
    [string]$ExpectedDistribution = 'app_gallery',
    # Compare the signer chain with the configured release certificate. This reads
    # only the certificate path from build-profile.json5, never a password.
    [switch]$SkipReleaseCertificateCheck
)

# Public signature verification only: no credentials, signing or device actions.
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$hap = (Get-Item -LiteralPath $HapPath -ErrorAction Stop).FullName
$hapHash = (Get-FileHash -LiteralPath $hap -Algorithm SHA256).Hash.ToLowerInvariant()
if ($ExpectedSha256 -and $hapHash -ne $ExpectedSha256.ToLowerInvariant()) {
    throw "HAP fingerprint $hapHash differs from the pinned $($ExpectedSha256.ToLowerInvariant())"
}
$stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff')
$work = Join-Path $projectRoot "build/dart-audit/verify-$stamp"
[IO.Directory]::CreateDirectory($work) | Out-Null
$certificatePath = Join-Path $work 'certificate-chain.cer'
$profilePath = Join-Path $work 'profile.p7b'
$profileResultPath = Join-Path $work 'profile-result.json'
$appLog = Join-Path $work 'verify-app.log'
$profileLog = Join-Path $work 'verify-profile.log'
$javaOptions = @('-Xms16m', '-Xmx256m', '-XX:+UseSerialGC', '-jar', $SignTool)
& $Java @javaOptions verify-app -inFile $hap -outCertChain $certificatePath -outProfile $profilePath *> $appLog
if ($LASTEXITCODE -ne 0 -or (Get-Content -Raw -LiteralPath $appLog) -notmatch 'verify-app success') {
    throw "HAP signature verification failed; see $appLog"
}
& $Java @javaOptions verify-profile -inFile $profilePath -outFile $profileResultPath *> $profileLog
if ($LASTEXITCODE -ne 0) { throw "Profile verification failed; see $profileLog" }
$envelope = Get-Content -Raw -LiteralPath $profileResultPath | ConvertFrom-Json
if ($envelope.verifiedPassed -ne $true) { throw 'Profile signature was not verified' }
$profile = $envelope.content
$expectedBundle = (Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'ohos/AppScope/app.json5') | ConvertFrom-Json).app.bundleName
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($hap)
try {
    $manifestEntry = $archive.GetEntry('module.json')
    if ($null -eq $manifestEntry) { throw 'HAP has no module.json' }
    $reader = [IO.StreamReader]::new($manifestEntry.Open())
    try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json }
    finally { $reader.Dispose() }
}
finally { $archive.Dispose() }
if ($profile.'bundle-info'.'bundle-name' -ne $expectedBundle -or $manifest.app.bundleName -ne $expectedBundle) {
    throw 'Profile, packaged manifest and Dart product bundle must agree'
}
# A signed file name does not prove a release package: check the packaged flags.
if ($manifest.app.debug -ne $false) {
    throw "Packaged app.debug is '$($manifest.app.debug)'; a release artifact must be false"
}
if ($manifest.app.buildMode -ne 'release') {
    throw "Packaged app.buildMode is '$($manifest.app.buildMode)'; expected release"
}
if ($profile.type -ne $ExpectedProfileType) {
    throw "Embedded profile type is '$($profile.type)'; expected $ExpectedProfileType"
}
if ($ExpectedDistribution -and $profile.'app-distribution-type' -ne $ExpectedDistribution) {
    throw "Profile distribution is '$($profile.'app-distribution-type')'; expected $ExpectedDistribution"
}
$now = [DateTimeOffset]::UtcNow
$profileStart = [DateTimeOffset]::FromUnixTimeSeconds([long]$profile.validity.'not-before')
$profileEnd = [DateTimeOffset]::FromUnixTimeSeconds([long]$profile.validity.'not-after')
if ($now -lt $profileStart -or $now -gt $profileEnd) { throw 'Signing profile is outside its validity interval' }
$certificateMatches = [regex]::Matches((Get-Content -Raw -LiteralPath $certificatePath),
    '-----BEGIN CERTIFICATE-----\s*(.*?)\s*-----END CERTIFICATE-----', 'Singleline')
if ($certificateMatches.Count -eq 0) { throw 'Signature tool returned no certificate chain' }
$certificates = @(
    foreach ($match in $certificateMatches) {
        $bytes = [Convert]::FromBase64String(($match.Groups[1].Value -replace '\s', ''))
        $certificate = [Security.Cryptography.X509Certificates.X509Certificate2]::new($bytes)
        try {
            if ($now.UtcDateTime -lt $certificate.NotBefore.ToUniversalTime() -or
                $now.UtcDateTime -gt $certificate.NotAfter.ToUniversalTime()) {
                throw 'Signing certificate is outside its validity interval'
            }
            [ordered]@{ thumbprint = $certificate.Thumbprint
                subject = $certificate.Subject
                notBeforeUtc = $certificate.NotBefore.ToUniversalTime().ToString('o')
                notAfterUtc = $certificate.NotAfter.ToUniversalTime().ToString('o') }
        }
        finally { $certificate.Dispose() }
    }
)
# The configured release certificate must appear in the verified chain. Only the
# certificate path is read; passwords and keys stay untouched and unreported.
$releaseCertificate = [ordered]@{ configuredPath = $null; thumbprint = $null; matched = $null }
if (-not $SkipReleaseCertificateCheck) {
    $buildProfile = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'ohos/build-profile.json5') | ConvertFrom-Json
    $releaseConfig = @($buildProfile.app.signingConfigs | Where-Object name -eq 'releaseKey')[0]
    if ($null -eq $releaseConfig) { throw 'No releaseKey signing config in ohos/build-profile.json5' }
    $configuredCertPath = [string]$releaseConfig.material.certpath
    if (-not $configuredCertPath) { throw 'releaseKey signing config has no certpath' }
    $resolvedCertPath = if ([IO.Path]::IsPathRooted($configuredCertPath)) {
        $configuredCertPath
    } else {
        Join-Path $projectRoot $configuredCertPath
    }
    if (-not (Test-Path -LiteralPath $resolvedCertPath -PathType Leaf)) {
        throw "Configured release certificate is missing: $configuredCertPath"
    }
    $releaseCertificate.configuredPath = $configuredCertPath
    $releasePem = [regex]::Match((Get-Content -Raw -LiteralPath $resolvedCertPath),
        '-----BEGIN CERTIFICATE-----\s*(.*?)\s*-----END CERTIFICATE-----', 'Singleline')
    if (-not $releasePem.Success) { throw 'Configured release certificate is not a PEM certificate' }
    $releaseBytes = [Convert]::FromBase64String(($releasePem.Groups[1].Value -replace '\s', ''))
    $releaseX509 = [Security.Cryptography.X509Certificates.X509Certificate2]::new($releaseBytes)
    try { $releaseCertificate.thumbprint = $releaseX509.Thumbprint }
    finally { $releaseX509.Dispose() }
    $releaseCertificate.matched = $certificates.thumbprint -contains $releaseCertificate.thumbprint
    if (-not $releaseCertificate.matched) {
        throw "Verified chain does not contain the configured release certificate $($releaseCertificate.thumbprint)"
    }
}
# Pin the identity/tool inputs so this signature report is self-contained.
$identitySources = [ordered]@{
    appScope = (Get-FileHash -LiteralPath (Join-Path $projectRoot 'ohos/AppScope/app.json5') -Algorithm SHA256).Hash.ToLowerInvariant()
    module = (Get-FileHash -LiteralPath (Join-Path $projectRoot 'ohos/entry/src/main/module.json5') -Algorithm SHA256).Hash.ToLowerInvariant()
    pubspec = (Get-FileHash -LiteralPath (Join-Path $projectRoot 'pubspec.yaml') -Algorithm SHA256).Hash.ToLowerInvariant()
}
$report = [ordered]@{
    verifiedUtc = $now.ToString('o'); hap = $hap
    bytes = (Get-Item -LiteralPath $hap).Length
    sha256 = $hapHash; expectedSha256 = if ($ExpectedSha256) { $ExpectedSha256.ToLowerInvariant() } else { $null }
    fingerprintPinned = [bool]$ExpectedSha256
    bundleName = $expectedBundle; signatureVerified = $true; profileVerified = $true
    identitySources = $identitySources
    toolSha256 = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToLowerInvariant()
    packagedDebug = $manifest.app.debug; packagedBuildMode = $manifest.app.buildMode
    packagedVersionName = $manifest.app.versionName; packagedVersionCode = $manifest.app.versionCode
    profileType = $profile.type; distribution = $profile.'app-distribution-type'
    profileNotBeforeUtc = $profileStart.ToString('o'); profileNotAfterUtc = $profileEnd.ToString('o')
    releaseCertificate = $releaseCertificate
    certificates = $certificates
    # Cryptography and profile validity only; these gates stay explicitly open.
    deviceVerified = $false; nativeGuardVerified = $false
    trustScope = 'SDK cryptographic verification and validity; installed OS acceptance and the native offline guard remain separate'
    verifyAppLog = $appLog; verifyProfileLog = $profileLog
}
$reportPath = Join-Path $work 'signature-report.json'
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $reportPath -Encoding utf8
Write-Output "Dart HAP signature/profile verified: $reportPath"
