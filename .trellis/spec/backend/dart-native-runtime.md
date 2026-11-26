# Native Dart Runtime Contract

## 1. Scope / Trigger

Use this contract for Android/desktop run, compilation, SDK discovery or packaging,
and for OHOS native-library architecture filtering.
Android and desktop use the official SDK's C++ VM. iOS/OHOS use the vendored
portable interpreter ([contract](./dart-portable-runtime.md));
native VM integration remains pending there. Compiler front-end code in
the SDK is Dart code hosted by the native VM; do not describe all SDK code as C.

## 2. Signatures

`NativeDartToolchain({String? executable})` owns `resolveExecutable()`,
`run(projectPath, entryFile)` and `compileKernel(projectPath, entryFile)`.
Run returns the existing `ProgramRunResult`; compilation returns `Uint8List`.
`DartTools.compile` selects native Kernel on Android/desktop; `compilePortable` selects
the legacy evaluator explicitly. `CompiledDartProgram.extension` owns the
artifact suffix and the tools page must use it when writing the file.

Android channel `qfli_dartwing/sdk.prepare` returns absolute `home`, `vm` and
`libraryDirectory` paths, or `DART_SDK_PREPARE_FAILED`. `AndroidDartSdk.prepare`
shares concurrent preparation and caches only a successful native version probe.

Android input preparation is `bash native/dart-sdk/android/prepare_sdk.sh <abi>
<output>`. It reads `packages.lock.json` and writes `package.deb`, `sdk.tar` and
`source-url.txt`. Staging is `pwsh -File native/dart-sdk/android/stage.ps1 -Abi
<abi> -Sdk <extracted-sdk>`. Supported ABI values are `arm64-v8a` and `x86_64`.

## 3. Contracts

- SDK discovery: explicit executable, QFLI_DART_SDK, DART_SDK, packaged SDK,
  FLUTTER_ROOT, then native executable/Flutter SDK candidates in PATH.
- Windows/Linux package the complete SDK under `data/dart-sdk/`. macOS uses
  `Contents/Helpers/dart-sdk/{arm64,x64}` selected by the current ABI.
  Keep Mach-O files in Helpers and sign them before the application. Store
  non-Mach-O SDK files under the matching `Contents/Resources/dart-sdk/` tree,
  with relative symlinks at their original SDK paths. Preserve every SDK file
  and relative lookup; do not discard snapshots or sign data through xattrs.
  Move entire pure-data directories, not just their files. Only Mach-O files
  and their ancestor directories may remain as real entries in Helpers; a data
  directory containing a period can otherwise be interpreted as a code bundle.
  Apple TN2206 treats files in Helpers as nested code. Data there can make the
  outer signature fail even when every Mach-O file was signed correctly.
- Run validates canonical project/entry containment, executes the SDK, captures
  stdout and stderr independently, preserves native exit codes and uses 130 for
  cancelled runs. Never switch to a portable interpreter after an Android/desktop SDK failure.
- Android stages the pinned full upstream SDK for arm64-v8a/x86_64. Every ELF,
  including AOT snapshots, lives in extracted nativeLibraryDir and must pass
  ABI/16 KiB LOAD checks. Data ZIPs, licenses and content manifests are assets.
  The actual VM ELF determines the data ABI, and background Kotlin installation
  creates SDK-native symlinks to installed code. Missing inputs fail packaging;
  unsupported 32-bit targets fail rather than packaging an evaluator.
- `.github/workflows/native-android-sdk.yml` packages these two Android SDK
  images on Ubuntu. It publishes per-ABI Actions artifacts for 30 days, with
  `jniLibs/`, `assets/`, provenance and file SHA256 manifests. Restore artifacts
  into `native/build/android/`. This is SDK staging, not a C++ rebuild, APK
  build or device execution check. It requires neither Flutter nor shared core.
- `packages.lock.json` owns package URLs, byte sizes, hashes and upstream
  artifact provenance. The fixed 3.13.5 mirror URLs disappeared. Preserve the
  verified original packages in the `native-sdk-inputs-3.13.5` input release.
  The archive workflow unwraps the official artifact ZIP and its inner TAR,
  verifies the exact package bytes, and refuses to replace different assets.
  Keep this release when removing expired build outputs. Never bypass hashes
  or silently upgrade the SDK to repair an unavailable download.
- `application-build.yml` builds Windows x64, Linux x64 and each Android ABI.
  `apple-build.yml` builds macOS arm64/x64 and an unsigned iOS ARM64 archive.
  Standard-platform CI pins Flutter 3.41.9 and a shared-core revision, checks
  them out as sibling directories, and applies `tool/ci/stock-flutter-core.patch`
  only to the clean disposable core checkout. `prepare_core.py` rejects a dirty
  checkout, a different core commit and an OHOS-enabled Flutter checkout.
  Never apply this patch to the developer's shared core or the OHOS CI build.
- `tool/ci/package_desktop_sdk.py` exports the complete host SDK. Check the Dart
  platform tag, compile real file-IO source to Kernel, remove the source and run
  that Kernel before upload. Upload the native SDK before app compilation, so
  an app failure does not hide a usable SDK. Desktop apps include their SDK.
  Windows archives contain the whole Release directory; Linux archives contain
  the whole bundle; macOS archives contain the whole .app. Unix tar archives
  preserve permissions and symlinks inside the Actions artifact ZIP.
- Android CI APKs use the existing ephemeral debug signing configuration.
  macOS CI apps use ad hoc signing and are not notarized. iOS CI exports an
  unsigned .xcarchive, its matching native frameworks and an unsigned IPA.
  None is device-installable before Apple signing, and none is a standalone
  Dart SDK. Provenance must distinguish compilation, archive checks, SDK smoke
  execution and unverified application/device use.
- `tool/ci/package_installer.py` owns installer creation and verification. Its
  subcommands are `windows`, `linux`, `macos`, `ios` and
  `check-macos-sdk-links`; the last one also checks the restored macOS tar
  archive. Workflows call it after the application artifact upload, write to
  `dist/installer/` and upload a separate `installer-<name>` artifact, so an
  installer failure does not hide a usable application. Each artifact holds the
  installer, `SHA256SUMS`, `SIGNING.txt` and `provenance.json`. Provenance
  copies the job's `dist/app/provenance.json` and adds an `installer` object;
  the version comes from `pubspec.yaml`. Keep one source for toolchain pins.
- Installer formats: Windows x64 is an Inno Setup program built from
  `tool/ci/windows_installer.iss`, installed per user without elevation. Never
  change its `AppId`; it links upgrades and the uninstall entry. Start
  `ISCC.exe` from Python, because Git Bash rewrites `/D` arguments as paths.
  Linux x64 is the Debian package `qfli-dart-wing` with dependencies from
  `dpkg-shlibdeps`. Keep the bundle intact under `/opt/qfli-dart-wing`: the
  SDK is found beside the resolved executable, so `/usr/bin/qfli-dart-wing`
  must be a symlink, not a copy or wrapper in another directory. macOS is a
  UDZO disk image with the ad hoc signed .app and an `/Applications` link.
  iOS is `Payload/Runner.app` zipped with symlinks preserved and labelled
  unsigned. Android and OHOS keep their existing packages.
- Installer builds use only tools shipped on the pinned runner images: Inno
  Setup on `windows-2022`, dpkg-dev on `ubuntu-24.04`, `hdiutil` and `ditto` on
  `macos-15`. Fail clearly when a tool is absent; never download one.
- Installer verification: Windows installs silently, compares the installed
  file list, runs the installed `dart.exe --version` and uninstalls. Linux
  installs through apt, checks the launcher link and shared libraries, runs the
  installed SDK and removes the package. macOS verifies the image, mounts it
  read-only and checks architecture, codesigning and SDK links. Never execute
  the bundled macOS helpers from the mounted image: they carry sandbox
  inheritance entitlements and fail outside the sandboxed application. iOS
  reads the IPA back and rejects a signature or provisioning profile.
  `installVerified` is true only for Windows and Linux. No check starts the
  application window; UI and device runtime remain unverified in provenance.
- Android Gradle uses the same `target-platform` list for SDK validation,
  build-type ABI filters and SDK data assets. Flutter supplies build-type ABI
  defaults, so changing only `defaultConfig.ndk.abiFilters` is insufficient.
  Inspect the final APK: every advertised ABI must contain `libflutter.so`,
  `libapp.so` and `libqfli_dartvm.so`; omit unrequested SDK ZIPs/manifests.
- OHOS HAP and APP packages support only `arm64-v8a`. Keep
  `ohos/entry/build-profile.json5`'s
  `buildOption.externalNativeOptions.abiFilters` set to `["arm64-v8a"]`, and use
  `--target-platform ohos-arm64` for Flutter builds. The module filter also
  applies when packaging through DevEco; the Flutter Hvigor plugin otherwise
  defaults to both ARM64 and x86_64.
- `ohos-build.yml` pins Flutter OHOS 3.41.9+ohos-1.0.2 and uses the unpatched
  shared core. `ohos_build.py sanitize` removes signingConfigs and each product's
  signingConfig only in the disposable CI checkout, before any build command.
  Bootstrap reads `tool/ci/ohos-command-line-tools.lock.json`; overrides require
  both `OHOS_COMMAND_LINE_TOOLS_URL` and `OHOS_COMMAND_LINE_TOOLS_SHA256` from the
  same dispatch or repository source. Verify the downloaded bytes before unzip.
  Reject archive path traversal and unexpected SDK API metadata. The locked
  official archive uses `sdk/default/`, `tool/node/`, root `ohpm/` and `hvigor/`,
  with command wrappers in root `bin/`. Select Java 21 from the hosted runner.
  A signed CDN URL may permit GET while rejecting HEAD; do not infer absence
  from HEAD alone. Preserve the project's target API until build evidence
  establishes whether the locked toolchain is compatible. Run 43943142540
  verified complete download hashing, unsigned HAP/APP compilation and package
  inspection with the locked API 26 SDK and authored target API 24.
- OHOS CI builds both unsigned HAP and APP with `--no-codesign`, checks the
  standalone HAP and nested APP HAPs with `inspect_dart_hap.py`, and exports
  matching ARM64 libraries separately. The library artifact is Flutter/app/
  plugin code, not a standalone Dart VM SDK. Report signing and device runtime
  as unverified in provenance. Never upload signing configuration or local keys.
- OHOS store packages use bundle `com.azurekiln.qfli.dart` in
  `ohos/AppScope/app.json5` and the product's `signingConfig: "releaseKey"` in
  `ohos/build-profile.json5`. The local release profile must have `type: "release"`,
  `app-distribution-type: "app_gallery"`, and `bundle-info.bundle-name` equal to
  the packaged bundle; its distribution certificate must match the signer.
  Flutter/OHOS release compilation and release signing are separate checks:
  `debug: false` or a `-signed` filename alone does not prove release signing.
  Keep private keys and passwords local; preserve user-provided signing material.
- Android executes dartvm directly, with `--snapshot-kind=kernel` for compilation.
  Its embedded frontend/platform resources avoid launcher-relative discovery.
  Both platforms feed input.txt to stdin and close with EOF when absent.
- Public Run accepts `.dill` on native platforms. The tools compiled-run button
  executes the saved artifact without saving or recreating its source.
- Use an existing project package_config.json. Dependency-free self-package
  imports may use an owned temporary standard configuration; remove it after
  execution or failure. Unresolved dependencies require SDK package resolution.
- Native compilation emits .dill. Read its bytes before deleting the owned
  compilation directory. A kernel artifact must execute without the source.
- CMake SDK selection uses QFLI_DART_SDK or the build Flutter SDK. Reject
  incomplete SDKs and cross-builds; include snapshots, libraries and license.
- macOS architecture SDKs use QFLI_DART_SDK_ARM64/QFLI_DART_SDK_X64. Check each
  binary architecture, sign Mach-O files before the outer application, and grant
  executable helpers sandbox inheritance and JIT rights. Apple execution is
  unverified until an Apple application build and runtime check pass.
  Invoke the architecture check as `lipo <binary> -verify_arch <architecture>`.
  Putting the binary after `-verify_arch` makes lipo parse it as an architecture.
  Keep command argument arrays nonempty when expanding them under `set -u`:
  macOS Bash 3.2 rejects an empty array. Initialize signing arguments with
  `--force --sign <identity>` and append optional flags per Mach-O file.

## 4. Validation & Error Matrix

| Condition | Result |
| --- | --- |
| Missing explicit executable or SDK | Specific file/state error; no evaluator fallback |
| Canonical entry outside project | ArgumentError before starting a process |
| Missing entry | FileSystemException |
| Dependencies without package configuration | Dependency resolution error |
| Invalid source | Native compiler stderr and nonzero status |
| Program failure | Native stderr and native nonzero exit code |
| Active run stopped | VM terminates; exit 130; owned temporary files removed |
| Native Kernel compile fails | StateError; no successful artifact |
| SDK missing core library or VM | Packaging fails |
| macOS SDK of wrong architecture | Architecture check fails |
| macOS SDK data stored as loose files under Helpers | Outer application signing can reject unsigned nested code |
| macOS SDK resource link is broken or escapes the application | Packaging validation fails |
| Android SDK layout/probe fails | Report platform/format/native error; no fallback |
| Android unsupported ABI or incomplete image | Build fails with staging instructions |
| SDK download missing or package size/SHA256 differs | Preparation fails; no uploaded SDK artifact |
| Archived input already exists with different bytes | Archive workflow fails without replacing it |
| Standard-platform core checkout is dirty or has a different revision | Compatibility helper fails before patching |
| Standard-platform helper sees OHOS Flutter | Compatibility helper refuses the patch |
| Desktop SDK platform tag differs from the requested artifact | SDK packaging fails before upload |
| Installer tool is absent from the runner image | Installer step fails; the application artifact is already uploaded |
| Installed Windows file list differs from the Release directory | Installer verification fails before upload |
| Debian package launcher resolves outside `/opt/qfli-dart-wing` | Installer verification fails before upload |
| Unsigned IPA contains a signature or provisioning profile | Installer verification fails before upload |
| Only one OHOS toolchain override is supplied | Bootstrap fails instead of mixing sources |
| OHOS download hash or locked API metadata differs | Bootstrap fails before application compilation |
| OHOS profile authorizes a different bundle | Resolve the bundle/profile mismatch before signing |
| OHOS release build uses a debug profile | Release runtime only; not a store-signed artifact |
| Signed APP contains an unsigned nested HAP | Verify the outer APP signature; inspect nested bundle/ABI separately |

## 5. Good / Base / Bad Cases

Good: dart:io writes and rereads a real file; a compiled .dill runs after its
source is deleted; self-package imports resolve offline; stop ends an infinite
program. Base: a single-file template prints its actual output. Bad: call EVC
native Kernel, silently use dart_eval on desktop, or return a byte-read Future
while the finally block deletes the artifact.

For CI, good is a verified source package plus downloadable artifacts from both
ABI jobs. A base case stages one requested ABI. Bad is treating a green archive
job as proof of SDK staging or Android runtime execution.

## 6. Tests Required

For native CI changes, parse workflow YAML and embedded Python, run `bash -n`
on preparation scripts, and inspect a real GitHub run. Both ABI jobs must pass
package size/SHA256, ELF ABI and 16 KiB checks. Inspect the artifact inventory,
the version in provenance, and the generated checksum manifest. Flutter-wide
tests do not replace these checks and are unnecessary for CI-only changes.
For standard Flutter compatibility changes, run `tool/ci/test_prepare_core.py`
and the startup tests. Linux CI runs full application analysis and host tests.
Check macOS application and bundled-SDK architectures and verify codesigning.
Before the full Flutter build, embed the same SDK using the same script in a
temporary minimal .app and sign its Mach-O main executable, then its outer
bundle. Verify with `codesign --verify --deep --strict`; never use deep signing
to hide missing nested signatures. This is a packaging preflight only.
Check SDK resource symlinks and verify the application again after extracting
the uploaded inner tar archive. Archive validation must not depend on extended
attributes carrying signatures for non-Mach-O data.
Inspect links in both the Helpers SDK and Resources mirror, because directory
symlinks are not traversed by `Path.rglob`. All links must be relative, resolve
successfully and remain inside the application.
Check the iOS executable, App.framework and Flutter.framework architectures.
After changing the installer helper, run `python tool/ci/test_package_installer.py`.
Inno Setup, `hdiutil` and Apple signing behavior require the real workflows;
record the run that produced each `installer-<name>` artifact.
`bash -n` on Windows checks grammar only. Apple command behavior and Bash 3.2
runtime compatibility require the real Apple workflow; a Git Bash pass is not
that verification. Search both workflow steps and Xcode packaging scripts when
fixing a shared command invocation.

`native_dart_toolchain_test.dart` exercises VM IO, async code, native exit codes,
compile failure, cancellation and source-independent Kernel execution.
`dart_app_test.dart` covers imports, errors, Run dispatch and cancellation.
`dart_tools_page_test.dart` compiles and reloads the actual Kernel artifact and
checks run/stop UI states. Keep explicit portable-EVC coverage separately.
Android requires `QFLI_DART_ANDROID_SMOKE` success for version, imports, stdin,
async file IO, UTF-8, source-free Kernel, diagnostics, exit and cancellation.
Exercise ordinary editor Run, tools compilation/artifact Run and Stop separately.
Record ARM64 packaging and runtime evidence separately when no device exists.
Run `flutter analyze --no-pub` and `flutter test --no-pub`. Validate installed SDK
execution separately from the source SDK. Report absent platform environments
as skips and never infer macOS/Linux execution from Windows tests.

For OHOS packaging changes, build both `flutter build hap --release
--target-platform ohos-arm64 --no-pub` and `flutter build app --release
--target-platform ohos-arm64 --no-pub` using the configured local signing identity
(or `--no-codesign` for unsigned builds). Inspect HAPs and the HAPs nested in APPs:
native libraries must be ARM64 ELF files under `libs/arm64-v8a/`, with no x86_64
payload. A build log alone does not establish the packaged architectures.

For OHOS release signing, run `java -jar <toolchains>/lib/hap-sign-tool.jar
verify-profile -inFile <release.p7b> -outFile <result.json>` and `verify-app
-inFile <signed.hap> -outCertChain <chain.cer> -outProfile <embedded.p7b>`.
Verify the standalone HAP and the outer signed APP with `verify-app`. The APP
build signs the outer container; its nested HAP can be unsigned. Inspect that
nested HAP for bundle, release flag and ABI without requiring a nested signature.
Check each signed artifact's embedded profile type, app distribution, exact
bundle and validity; compare the extracted signer's certificate fingerprint
with the configured release certificate. Inspect packaged `app.debug == false`
and intermediate `app.buildMode == "release"` independently of signature checks.

## 7. Wrong vs Correct

Wrong: assume an upstream Actions ZIP directly contains `.deb` files.
Correct: follow the pinned Termux workflow's ZIP -> TAR -> exact package member
layout, then verify the existing package size and SHA256 before archiving.

Wrong: put SDK snapshots and libraries in Helpers and sign only the Mach-O files.
Correct: keep SDK data in Resources and preserve the SDK lookup paths with
relative symlinks. Apple TN2206's Nested Code and FAQ sections describe this
layout: https://developer.apple.com/library/archive/technotes/tn2206/_index.html.

Wrong: `return artifact.readAsBytes();` in a try whose finally deletes its parent.
Correct: `return await artifact.readAsBytes();` so cleanup occurs after the read.

Wrong: treat the presence of another product's task as a runtime pass.
Correct: inspect build, packaging, bridge and real engine execution evidence.

Wrong: label an OHOS release build as store-signed because its filename is signed.
Correct: verify its signature and embedded release profile against the exact bundle.
