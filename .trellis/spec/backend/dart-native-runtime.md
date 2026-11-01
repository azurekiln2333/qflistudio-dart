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

## 3. Contracts

- SDK discovery: explicit executable, QFLI_DART_SDK, DART_SDK, packaged SDK,
  FLUTTER_ROOT, then native executable/Flutter SDK candidates in PATH.
- Windows/Linux package the complete SDK under `data/dart-sdk/`. macOS uses
  `Contents/Helpers/dart-sdk/{arm64,x64}` selected by the current ABI.
- Run validates canonical project/entry containment, executes the SDK, captures
  stdout and stderr independently, preserves native exit codes and uses 130 for
  cancelled runs. Never switch to a portable interpreter after an Android/desktop SDK failure.
- Android stages the pinned full upstream SDK for arm64-v8a/x86_64. Every ELF,
  including AOT snapshots, lives in extracted nativeLibraryDir and must pass
  ABI/16 KiB LOAD checks. Data ZIPs, licenses and content manifests are assets.
  The actual VM ELF determines the data ABI, and background Kotlin installation
  creates SDK-native symlinks to installed code. Missing inputs fail packaging;
  unsupported 32-bit targets fail rather than packaging an evaluator.
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
| Android SDK layout/probe fails | Report platform/format/native error; no fallback |
| Android unsupported ABI or incomplete image | Build fails with staging instructions |
| OHOS profile authorizes a different bundle | Resolve the bundle/profile mismatch before signing |
| OHOS release build uses a debug profile | Release runtime only; not a store-signed artifact |
| Signed APP contains an unsigned nested HAP | Verify the outer APP signature; inspect nested bundle/ABI separately |

## 5. Good / Base / Bad Cases

Good: dart:io writes and rereads a real file; a compiled .dill runs after its
source is deleted; self-package imports resolve offline; stop ends an infinite
program. Base: a single-file template prints its actual output. Bad: call EVC
native Kernel, silently use dart_eval on desktop, or return a byte-read Future
while the finally block deletes the artifact.

## 6. Tests Required

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

Wrong: `return artifact.readAsBytes();` in a try whose finally deletes its parent.
Correct: `return await artifact.readAsBytes();` so cleanup occurs after the read.

Wrong: treat the presence of another product's task as a runtime pass.
Correct: inspect build, packaging, bridge and real engine execution evidence.

Wrong: label an OHOS release build as store-signed because its filename is signed.
Correct: verify its signature and embedded release profile against the exact bundle.
