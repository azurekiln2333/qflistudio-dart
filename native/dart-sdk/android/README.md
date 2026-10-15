# Android Dart SDK

Android runs the upstream Dart 3.13.5 C++ VM and compiles reusable Kernel
programs. The complete Termux SDK is an Android build of the actual Dart engine.
The application never substitutes the portable evaluator on Android.

## Inputs and provenance

`packages.lock.json` pins both package sizes/hashes, the Termux recipe commit,
and the upstream source archive hash. The recipe is
`https://github.com/termux/termux-packages/blob/d0f94da1e578a0c9550a84d408bc8ed0003882ec/packages/dart/build.sh`.
Packages are downloaded from the USTC Termux mirror. SDK licenses and notices
remain in the packaged data; no third-party SDK binary is tracked in Git.

On Linux or WSL, with Python 3, curl, dpkg-deb and GNU tar:

```bash
bash native/dart-sdk/android/prepare_sdk.sh x86_64 /tmp/dart-x64
bash native/dart-sdk/android/prepare_sdk.sh arm64-v8a /tmp/dart-arm64
```

Export each `sdk.tar` to a Windows workspace and extract to its own SDK
directory. The script repairs the SDK's absolute platform-library alias and
dereferences symlinks during export. This preserves the same platform bytes
without requiring Windows symlink privileges.

```powershell
tar.exe -xf sdk-x64.tar -C sdk-x64
tar.exe -xf sdk-arm64.tar -C sdk-arm64
./native/dart-sdk/android/stage.ps1 -Abi x86_64 -Sdk sdk-x64
./native/dart-sdk/android/stage.ps1 -Abi arm64-v8a -Sdk sdk-arm64
flutter build apk --debug --target-platform android-x64
```

Stage all requested ABIs before packaging. Unsupported 32-bit targets and
missing images fail the build. An installed NDK can be selected with the Gradle
property `qfliDartNdkVersion`; otherwise the Flutter default remains in use.

The requested Flutter targets also select the packaged JNI ABIs and SDK data.
For an ARM64 release, use `--target-platform android-arm64`. The resulting APK
must advertise only `arm64-v8a`, with `libflutter.so`, `libapp.so` and
`libqfli_dartvm.so` present, and must omit the x86_64 SDK ZIP/manifest. A combined
ARM64/x64 build must contain all three libraries for both ABIs. Check the APK
itself, because Flutter's build-type filters can override default-config filters.

## Installed layout and execution

Staging validates every ELF's architecture and 16 KiB LOAD compatibility,
including AOT snapshots. Native code is packaged in extracted `jniLibs`; the
full data SDK is a per-ABI asset ZIP. A content manifest maps SDK-native paths
to installed libraries and identifies the exact SDK image.

`qfli_dartwing/sdk` method `prepare` runs installation on a background executor
and returns absolute `home`, `vm`, and `libraryDirectory` paths. The actual VM
ELF determines the ABI. Kotlin extracts the data under `files/dart-sdk` and
links its native paths to `nativeLibraryDir`. Dart caches only a successfully
installed layout whose native version probe identifies Android.

Run invokes `dartvm` with source or `.dill`, drains stdout/stderr and preserves
the program's exit status. `input.txt` feeds stdin; absent input closes the pipe
with EOF. Compile invokes upstream `--snapshot-kind=kernel`; tools persist the
result under `build` and can execute it after deleting the source. Stop kills
the owned process and returns 130. A preparation or compiler error is reported
to the caller; it cannot switch Android to the portable evaluator.

## Verification

`tools/android_sdk_smoke.dart` checks the real in-app VM, self-package imports,
stdin, async file IO, UTF-8, source-free Kernel execution, compiler diagnostics,
native exit codes and cancellation. Its `QFLI_DART_ANDROID_SMOKE` record is the
runtime assertion; shell-only probes do not establish an application pass.
Restore the ordinary `lib/main.dart` target after running the smoke APK.

ARM64 staging is independently checked. Actual ARM64 execution needs a device;
x86_64 emulator results cannot establish that runtime. Native iOS integration
remains unresolved and is not delivered by this Android implementation.
