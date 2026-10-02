param(
    [Parameter(Mandatory)][ValidateSet('arm64-v8a', 'x86_64')][string]$Abi,
    [Parameter(Mandatory)][string]$Sdk
)
$ErrorActionPreference = 'Stop'
$Sdk = (Resolve-Path -LiteralPath $Sdk).ProviderPath
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).ProviderPath
foreach ($required in @('bin/dartvm', 'bin/dart', 'bin/dartaotruntime', 'lib/core/core.dart', 'lib/_internal/vm_platform.dill', 'LICENSE', 'version')) {
    if (-not (Test-Path -LiteralPath (Join-Path $Sdk $required) -PathType Leaf)) {
        throw "Incomplete Android Dart SDK: $required"
    }
}
$out = Join-Path $repo 'native/build/android'
$native = Join-Path $out "jniLibs/$Abi"
$assets = Join-Path $out 'assets'
New-Item -ItemType Directory -Force -Path $native, $assets | Out-Null
$libraries = [Collections.Generic.List[object]]::new()
$data = [Collections.Generic.List[IO.FileInfo]]::new()
$digests = [Collections.Generic.List[string]]::new()
$names = @{}
foreach ($file in Get-ChildItem -LiteralPath $Sdk -Recurse -File | Sort-Object FullName) {
    if ($file.Name.EndsWith('.sym')) { continue }
    $relative = [IO.Path]::GetRelativePath($Sdk, $file.FullName).Replace('\', '/')
    $bytes = [IO.File]::ReadAllBytes($file.FullName)
    $isElf = $bytes.Length -ge 64 -and $bytes[0] -eq 127 -and $bytes[1] -eq 69 -and $bytes[2] -eq 76 -and $bytes[3] -eq 70
    if ($isElf) {
        $machine = [BitConverter]::ToUInt16($bytes, 18)
        $expected = if ($Abi -eq 'x86_64') { 62 } else { 183 }
        if ($bytes[4] -ne 2 -or $bytes[5] -ne 1 -or $machine -ne $expected) {
            throw "Wrong Android SDK ELF architecture: $relative"
        }
        $table = [BitConverter]::ToUInt64($bytes, 32)
        $size = [BitConverter]::ToUInt16($bytes, 54)
        $count = [BitConverter]::ToUInt16($bytes, 56)
        for ($index = 0; $index -lt $count; $index++) {
            $entry = [int]($table + $index * $size)
            if ([BitConverter]::ToUInt32($bytes, $entry) -ne 1) { continue }
            $alignment = [BitConverter]::ToUInt64($bytes, $entry + 48)
            $offset = [BitConverter]::ToUInt64($bytes, $entry + 8)
            $address = [BitConverter]::ToUInt64($bytes, $entry + 16)
            if ($alignment -lt 16384 -or $offset % 16384 -ne $address % 16384) {
                throw "Android SDK ELF lacks 16 KiB LOAD compatibility: $relative"
            }
        }
        $name = if ($relative -eq 'bin/dartvm') { 'libqfli_dartvm.so' } else {
            'libqfli_dart_' + ($relative -replace '[^A-Za-z0-9_]', '_') + '.so'
        }
        if ($names.ContainsKey($name)) { throw "Duplicate Android SDK library name: $name" }
        $names[$name] = $true
        Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $native $name) -Force
        $libraries.Add(@{ path = $relative; library = $name })
    } else {
        $data.Add($file)
    }
    $digests.Add($relative + ':' + (Get-FileHash -LiteralPath $file.FullName).Hash)
}
$id = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($digests -join "`n"))).ToLowerInvariant()
$manifest = @{
    version = 1
    id = "android-$Abi-$id"
    sdkVersion = [IO.File]::ReadAllText((Join-Path $Sdk 'version')).Trim()
    libraries = @($libraries.ToArray())
} | ConvertTo-Json -Depth 5 -Compress
[IO.File]::WriteAllText((Join-Path $assets "dart-sdk-$Abi.json"), $manifest, [Text.UTF8Encoding]::new($false))
$zipPath = Join-Path $assets "dart-sdk-$Abi.zip"
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath }
$zip = [IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in $data) {
        $relative = [IO.Path]::GetRelativePath($Sdk, $file.FullName).Replace('\', '/')
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $relative) | Out-Null
    }
} finally { $zip.Dispose() }
Write-Output "Android Dart SDK: $($libraries.Count) native files, $($data.Count) data files; $zipPath"
