[CmdletBinding()]
param(
    [string]$Target = 'tool/dart_catalog_ohos_audit.dart',
    # 0 derives the exact denominator from the authored assets. A positive value
    # must agree with them, so a stale literal cannot silently pass.
    [int]$ExpectedTopics = 0,
    [string]$CoreRevision = 'daddce27',
    # 0 keeps the current behaviour (wait indefinitely). A positive value kills the
    # build process tree and records the timeout as a failure.
    [int]$TimeoutMinutes = 0,
    [switch]$NoCodesign
)

# Own build only. No device install/start/stop or shared-core mutation.
$ErrorActionPreference = 'Stop'

function Get-StringSha256([string]$Text) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))
        return ([BitConverter]::ToString($bytes) -replace '-', '').ToLowerInvariant()
    }
    finally { $sha.Dispose() }
}

function Get-FileSha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$buildRoot = Join-Path $projectRoot 'build/dart-audit'
[IO.Directory]::CreateDirectory($buildRoot) | Out-Null
$profilePath = Join-Path $projectRoot 'ohos/entry/build-profile.json5'
$targetPath = [IO.Path]::GetFullPath((Join-Path $projectRoot $Target))
if (-not $targetPath.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar) -or
    -not (Test-Path -LiteralPath $targetPath -PathType Leaf)) { throw 'Invalid audit target' }
if ($ExpectedTopics -lt 0) { throw 'ExpectedTopics must be zero or positive' }
if ($TimeoutMinutes -lt 0) { throw 'TimeoutMinutes must be zero or positive' }
$flutter = (Get-Command flutter -ErrorAction Stop).Source
$lock = [IO.File]::Open((Join-Path $buildRoot '.build.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
$profileBytes = [IO.File]::ReadAllBytes($profilePath)
$originalHash = Get-FileSha256 $profilePath
$packageConfigPath = Join-Path $projectRoot '.dart_tool/package_config.json'
$packageConfigBytes = [IO.File]::ReadAllBytes($packageConfigPath)
$packageConfigHash = Get-FileSha256 $packageConfigPath
$started = [DateTime]::UtcNow
$stamp = $started.ToString('yyyyMMddTHHmmssfff')
$logPath = Join-Path $buildRoot "build-$stamp.log"
$reportPath = Join-Path $buildRoot "build-$stamp.json"
$backupPath = Join-Path $buildRoot "profile-$stamp.original"
[IO.File]::WriteAllBytes($backupPath, $profileBytes)
$hadJavaOptions = Test-Path Env:JAVA_TOOL_OPTIONS
$oldJavaOptions = [Environment]::GetEnvironmentVariable('JAVA_TOOL_OPTIONS', 'Process')
$previousLocation = Get-Location
$coreArchive = $null
$coreSnapshot = $null
$report = [ordered]@{
    startedUtc = $started.ToString('o'); target = $Target; targetPlatform = 'ohos-x64'
    expectedTopics = $ExpectedTopics; noCodesign = [bool]$NoCodesign
    timeoutMinutes = $TimeoutMinutes; timedOut = $false
    buildExitCode = $null; profileRestored = $false; environmentRestored = $false
    packageConfigRestored = $false; coreRevision = $CoreRevision
    coreArchive = $null; coreArchiveSha256 = $null
    preservedHap = $null; hapSha256 = $null
    logPath = $logPath; recoveryProfilePath = $backupPath; hap = $null; error = $null
    fingerprints = $null
    gates = [ordered]@{
        packageInspected = $false; releaseModeVerified = $false
        signatureVerified = $false; deviceVerified = $false
        nativeGuardVerified = $false
        pending = @('verify_dart_hap.ps1 -ExpectedSha256 <hapSha256>',
            'native offline guard (test/native_entry_ability_test.cjs)',
            'installed device execution')
    }
}
try {
    # --- exact asset denominator, derived from the authored build assets ------
    $assetFingerprints = [ordered]@{}
    $assetCounts = [ordered]@{}
    foreach ($kind in @('tutorials', 'examples')) {
        $assetPath = Join-Path $projectRoot "assets/content/dart_$kind.json"
        if (-not (Test-Path -LiteralPath $assetPath -PathType Leaf)) {
            throw "Missing authored asset assets/content/dart_$kind.json"
        }
        $document = Get-Content -Raw -LiteralPath $assetPath | ConvertFrom-Json
        $count = @($document.entries).Count
        if ($count -le 0) { throw "Authored asset dart_$kind.json has no entries" }
        if ($document.kind -and $document.kind -ne $kind) {
            throw "assets/content/dart_$kind.json declares kind '$($document.kind)'"
        }
        $assetCounts[$kind] = $count
        $assetFingerprints[$kind] = [ordered]@{
            path = "assets/content/dart_$kind.json"
            entries = $count
            sha256 = Get-FileSha256 $assetPath
        }
    }
    if ($assetCounts['tutorials'] -ne $assetCounts['examples']) {
        throw ("Authored denominators differ (tutorials $($assetCounts['tutorials']), " +
            "examples $($assetCounts['examples'])); the audit target accepts a single count")
    }
    $authoredTopics = [int]$assetCounts['tutorials']
    if ($ExpectedTopics -gt 0 -and $ExpectedTopics -ne $authoredTopics) {
        throw "ExpectedTopics $ExpectedTopics differs from the authored denominator $authoredTopics"
    }
    $report.expectedTopics = $authoredTopics
    $report.fingerprints = [ordered]@{
        productHead = $null; productStatusDigest = $null; target = Get-FileSha256 $targetPath
        assets = $assetFingerprints
        # Pin the product-identity configs so the identity claims are self-contained.
        identitySources = [ordered]@{
            appScope = Get-FileSha256 (Join-Path $projectRoot 'ohos/AppScope/app.json5')
            module = Get-FileSha256 (Join-Path $projectRoot 'ohos/entry/src/main/module.json5')
            pubspec = Get-FileSha256 (Join-Path $projectRoot 'pubspec.yaml')
        }
        tools = [ordered]@{
            build = Get-FileSha256 $PSCommandPath
            inspect = Get-FileSha256 (Join-Path $PSScriptRoot 'inspect_dart_hap.py')
            verify = Get-FileSha256 (Join-Path $PSScriptRoot 'verify_dart_hap.ps1')
        }
        coreArchive = $null; profileOriginal = $originalHash
        profilePatched = $null; packageConfigOriginal = $packageConfigHash
        packageConfigPatched = $null
    }
    try {
        $head = & git -C $projectRoot rev-parse HEAD
        if ($LASTEXITCODE -eq 0) { $report.fingerprints.productHead = $head.Trim() }
        $statusText = (& git -C $projectRoot status --porcelain) -join "`n"
        $report.fingerprints.productStatusDigest = Get-StringSha256 $statusText
    }
    catch { $report.fingerprints.productHead = $null }

    # Freeze the explicitly reviewed common revision without modifying its repo.
    $coreRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot '../qfli_studio_core'))
    $resolvedCore = & git -C $coreRoot rev-parse --verify "$CoreRevision^{commit}"
    if ($LASTEXITCODE -ne 0) { throw 'Reviewed core revision does not exist' }
    $report.coreRevision = $resolvedCore.Trim()
    $coreArchive = Join-Path $buildRoot "core-$stamp.zip"
    $coreSnapshot = Join-Path $projectRoot ".dart_tool/dart-audit-core-$stamp"
    & git -C $coreRoot archive --format=zip "--output=$coreArchive" $report.coreRevision
    if ($LASTEXITCODE -ne 0) { throw 'Cannot archive reviewed common core' }
    Expand-Archive -LiteralPath $coreArchive -DestinationPath $coreSnapshot
    $report.coreArchive = $coreArchive
    $report.coreArchiveSha256 = Get-FileSha256 $coreArchive
    $report.fingerprints.coreArchive = $report.coreArchiveSha256
    $packageConfig = [Text.Encoding]::UTF8.GetString($packageConfigBytes) | ConvertFrom-Json
    foreach ($package in $packageConfig.packages) {
        if ($package.name -eq 'qfli_studio_core') {
            $package.rootUri = ([Uri]::new($coreSnapshot + '/')).AbsoluteUri
        }
        if ($package.name -eq 're_editor') {
            $package.rootUri = ([Uri]::new((Join-Path $coreSnapshot 'vendor/re_editor') + '/')).AbsoluteUri
        }
    }
    [IO.File]::WriteAllText($packageConfigPath, ($packageConfig | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
    $report.fingerprints.packageConfigPatched = Get-FileSha256 $packageConfigPath
    $profileText = [Text.Encoding]::UTF8.GetString($profileBytes)
    $pattern = '("abiFilters"\s*:\s*)\[\s*"arm64-v8a"\s*\]'
    if ([regex]::Matches($profileText, $pattern).Count -ne 1) { throw 'Expected one production ARM64 selection' }
    $profileText = [regex]::Replace($profileText, $pattern, '${1}["x86_64"]')
    [IO.File]::WriteAllText($profilePath, $profileText, [Text.UTF8Encoding]::new($false))
    $report.fingerprints.profilePatched = Get-FileSha256 $profilePath

    # hap-sign-tool reads the archive into memory; 256MiB is insufficient for
    # this AOT/analyzer package. Bound only this build process, then restore it.
    [Environment]::SetEnvironmentVariable('JAVA_TOOL_OPTIONS', '-Xms32m -Xmx1536m -XX:+UseSerialGC', 'Process')
    Set-Location -LiteralPath $projectRoot
    $arguments = @('build', 'hap', '--release', '--no-pub', '--target-platform', 'ohos-x64',
        '--target', $Target, "--dart-define=QFLI_DART_EXPECTED_TOPICS=$authoredTopics")
    if ($NoCodesign) { $arguments += '--no-codesign' }
    $ErrorActionPreference = 'Continue'
    if ($TimeoutMinutes -gt 0) {
        $stdoutLog = "$logPath.stdout"
        $stderrLog = "$logPath.stderr"
        $quoted = $arguments | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }
        $process = Start-Process -FilePath $flutter -ArgumentList $quoted -WorkingDirectory $projectRoot `
            -PassThru -NoNewWindow -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog
        if (-not $process.WaitForExit($TimeoutMinutes * 60000)) {
            $report.timedOut = $true
            & taskkill /PID $process.Id /T /F *> $null
            $process.WaitForExit(30000) | Out-Null
        }
        $report.buildExitCode = $process.ExitCode
        Get-Content -LiteralPath $stdoutLog, $stderrLog -ErrorAction SilentlyContinue |
            Set-Content -LiteralPath $logPath
    }
    else {
        & $flutter @arguments *> $logPath
        $report.buildExitCode = $LASTEXITCODE
    }
    $ErrorActionPreference = 'Stop'
    if ($report.timedOut) { throw "Flutter build exceeded $TimeoutMinutes minute(s); see $logPath" }
    if ($report.buildExitCode -ne 0) { throw "Flutter build failed: $($report.buildExitCode); see $logPath" }
    $suffix = if ($NoCodesign) { '*-unsigned.hap' } else { '*-signed.hap' }
    $outputs = Join-Path $projectRoot 'ohos/entry/build/default/outputs/default'
    $candidates = @(Get-ChildItem -LiteralPath $outputs -Filter $suffix |
        Where-Object LastWriteTimeUtc -GE $started.AddSeconds(-2) |
        Sort-Object LastWriteTimeUtc -Descending)
    if ($candidates.Count -eq 0) { throw 'No freshly built HAP; old packages are not evidence' }
    $sourceHap = $candidates[0].FullName
    $hash = Get-FileSha256 $sourceHap
    $preserved = Join-Path $buildRoot "dart-catalog-x64-$($hash.Substring(0, 16)).hap"
    Copy-Item -LiteralPath $sourceHap -Destination $preserved
    if ((Get-FileSha256 $preserved) -ne $hash) { throw 'Preserved HAP differs from the built HAP' }
    $report.preservedHap = $preserved
    $report.hapSha256 = $hash
    $packageReport = Join-Path $buildRoot "package-$stamp.json"
    $inspectArguments = @((Join-Path $PSScriptRoot 'inspect_dart_hap.py'), $preserved,
        '--abi', 'x86_64', '--topics', $authoredTopics, '--project', $projectRoot,
        '--expect-sha256', $hash, '--report', $packageReport)
    if ($NoCodesign) { $inspectArguments += '--allow-non-release' }
    & python @inspectArguments
    $report.gates.packageInspected = (Test-Path -LiteralPath $packageReport -PathType Leaf)
    if ($report.gates.packageInspected) {
        $report.hap = Get-Content -Raw -LiteralPath $packageReport | ConvertFrom-Json
        $report.gates.releaseModeVerified = [bool]$report.hap.releaseModeVerified
    }
    if ($LASTEXITCODE -ne 0) { throw 'Actual HAP inspection failed' }
}
catch { $report.error = $_.Exception.Message }
finally {
    try {
        [IO.File]::WriteAllBytes($profilePath, $profileBytes)
        $report.profileRestored = (Get-FileSha256 $profilePath) -eq $originalHash
        [IO.File]::WriteAllBytes($packageConfigPath, $packageConfigBytes)
        $report.packageConfigRestored = (Get-FileSha256 $packageConfigPath) -eq $packageConfigHash
    }
    finally {
        if ($hadJavaOptions) { [Environment]::SetEnvironmentVariable('JAVA_TOOL_OPTIONS', $oldJavaOptions, 'Process') }
        else { Remove-Item Env:JAVA_TOOL_OPTIONS -ErrorAction SilentlyContinue }
        $report.environmentRestored = ((Test-Path Env:JAVA_TOOL_OPTIONS) -eq $hadJavaOptions) -and
            ([Environment]::GetEnvironmentVariable('JAVA_TOOL_OPTIONS', 'Process') -eq $oldJavaOptions)
        Set-Location -LiteralPath $previousLocation.Path
        # The extracted core snapshot is a build input, not evidence; the archive is.
        if ($coreSnapshot -and (Test-Path -LiteralPath $coreSnapshot)) {
            Remove-Item -LiteralPath $coreSnapshot -Recurse -Force -ErrorAction SilentlyContinue
        }
        $lock.Dispose()
        $report.finishedUtc = [DateTime]::UtcNow.ToString('o')
        $report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $reportPath -Encoding utf8
    }
}
if (-not $report.profileRestored -or -not $report.packageConfigRestored -or -not $report.environmentRestored) { throw "Restoration failed; see $reportPath" }
if ($null -ne $report.error) { throw "$($report.error); report $reportPath" }
Write-Output "Audit HAP verified; signature and installed execution remain separate: $reportPath"
Write-Output "Pin this artifact: -ExpectedSha256 $($report.hapSha256)"
