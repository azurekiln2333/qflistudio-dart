# Native Dart Runtime Contract

## 1. Scope / Trigger

Use this contract for Android/desktop run, compilation, SDK discovery or packaging.
Android and desktop use the official SDK's C++ VM. iOS/OHOS retain dart_eval;
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
  cancelled runs. Never switch to dart_eval after an Android/desktop SDK failure.
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

## 7. Wrong vs Correct

Wrong: `return artifact.readAsBytes();` in a try whose finally deletes its parent.
Correct: `return await artifact.readAsBytes();` so cleanup occurs after the read.

Wrong: treat the presence of another product's task as a runtime pass.
Correct: inspect build, packaging, bridge and real engine execution evidence.
