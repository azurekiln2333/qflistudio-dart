# Native Dart SDK

Desktop execution and Kernel compilation use the official Dart SDK. Its VM is
C++; the compiler front end and SDK commands include official Dart code running
on that VM. This integration does not substitute dart_eval for native execution.

## Packaging

Windows/Linux CMake installs the complete SDK, including snapshots, platform
libraries, license and version, into `data/dart-sdk/`. Set `QFLI_DART_SDK` (CMake
cache or environment) to select an SDK; the default is the build Flutter SDK's
`bin/cache/dart-sdk`. Cross-builds are rejected so a host VM is not mispackaged.

macOS embeds SDK trees in `Contents/Helpers/dart-sdk/arm64` and/or `x64` according
to `ARCHS`. The host architecture can use the Flutter SDK; a universal app also
needs the other SDK via `QFLI_DART_SDK_ARM64`/`QFLI_DART_SDK_X64`. Each architecture
is checked, and Mach-O files are signed before the outer application. Executable
helpers inherit the app sandbox and grant the VM JIT permission. Actual macOS
build and application execution require an Apple environment and remain unverified.

## Runtime

`NativeDartToolchain` searches configured SDKs, the app bundle, `FLUTTER_ROOT`,
and the native executable/Flutter SDK in PATH. Desktop Run executes the real VM,
streams stdout/stderr, preserves native exit codes and returns 130 on stop.
Compile invokes the official compiler and returns `.dill` bytes; the artifact can
execute after the source file is removed. Project `package_config.json` is used
when present. Dependency-free self-package imports receive a temporary standard
package configuration; unresolved third-party dependencies report an error.

## Verification

Windows SDK 3.11.5 passed native file IO, async execution, Kernel compilation,
source-independent artifact execution, compiler errors, program exit codes,
imports and cancellation. All 33 product snapshot tests and static analysis
passed. The standalone CMake installation was exercised separately from Flutter.
There is no Visual Studio C++ toolchain for a full Windows UI build. Linux and
Apple native execution are not established by these Windows checks.

The mobile runner still uses the previous portable evaluator. Native Android,
iOS and OHOS Dart VM integration is a remaining requirement, not a completed
native runtime. This desktop patch alone must not close the cross-product goal.
