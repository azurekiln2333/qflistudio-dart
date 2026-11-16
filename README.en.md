# qfli_dart

[简体中文](README.md) · [繁體中文](README.zh-Hant.md) · [English](README.en.md)

This repository is a standalone Flutter app.
Its product name is QFLIDartWing.
It bundles a Dart editor, a tools tab, a terminal and the curriculum.
The app works offline.
It does not open external web pages.
The main Android manifest requests no network permission.
The debug and profile manifests request network permission.
The OHOS manifest requests only clipboard read permission.
The editor, terminal and file tree come from the sibling `qfli_studio_core`
package.

## Runtime backends

Android and desktop use the official Dart SDK.
Android bundles the official SDK for arm64-v8a and x86_64.
The OHOS HAP does not carry the official SDK.
OHOS uses a built-in portable interpreter.
The portable interpreter is `vendor/tom_d4rt`.
Its version is `1.229.0+qfli.1`.
It keeps the upstream MIT license.
`dart_eval` 0.8.5 remains only for the legacy EVC compile action.
The portable interpreter is not the complete Dart VM.
It supports a subset of the language and libraries.
It refuses networking, native processes, standard input and symlink traversal.
It reads preloaded project sources only.
It allows file reads and writes under the project and scratch directories.

## Curriculum content

The shipped assets hold 120 lessons and 120 paired examples.
The curriculum has 14 chapters, numbered 001 to 120.
Each lesson has explanation, objective, code, output and exercises.
A further 180 draft pairs are numbered 121 to 300.
The drafts live in 16 chapter files.
The drafts are not in the shipped assets.
The production aggregate and assets stay at 120/120.
The original OHOS acceptance is a mandatory gate before draft promotion.
The drafts were verified on the host only.
Host verification covers official-SDK runs and portable runs.
The 58 exercises numbered 181 to 238 were rerun on the host.
All passed with both the official SDK and the portable runtime.
The drafts have no OHOS device evidence.

## Evidence boundaries

Host SDK runs, host portable runs, OHOS packaging and device runs are four
separate gates.
Passing host tests does not prove device execution.
The Windows AOT results prove the host only.
They do not prove OHOS.
Dart has no OHOS device acceptance yet.
A shared x64 emulator now exists.
Dart has not received an OHOS device time slot yet.
Dart performed no OHOS app install, start or stop.
The Android native SDK passed nine checks on an API 37 x86_64 emulator.
Those checks used 16 KiB pages.
ARM64 application execution still needs a device.
Select arm64-v8a when building release HAP and APP packages.
A separate x86_64 audit HAP also exists.
`tool/ohos/build_dart_audit.ps1` builds it.
It serves host package inspection only.
It is not a release package.
It is not device evidence.
The native offline guard is verified by the host channel test only.
The existing audit HAP predates the native offline guard.
With no HDC target, device evidence is empty.

## Supported scope and limits

The tools tab offers format, syntax diagnostics, run, compile and source
structure.
Formatting uses `dart_style`.
The tools tab and the terminal `dart analyze` both report syntax diagnostics only.
Syntax diagnostics cover scanning and parsing only.
They do not do type, lint or dependency analysis.
A clean result does not prove type correctness.
A missing input returns an unavailable reason.
It does not return a false clean result.
The OHOS portable target has no official SDK.
The terminal `dart compile kernel` returns an unavailable reason.
Compilation on Android and desktop produces Kernel `.dill`.
The legacy EVC action produces `dart_eval` bytecode.
The terminal supports `dart run`, `format`, `analyze` and `compile kernel`.
The terminal refuses `pub get` and global installs.
The app has no breakpoint debugging.
It has no stepping or variable-inspection API.
Printing logs is not breakpoint debugging.
The app supports no networking or port features.
Unsupported capabilities fail explicitly.

## Sibling repository and dependencies

This repository depends on the sibling `qfli_studio_core` package.
Check it out next to this repository first.

```text
checkout-parent/
  qfli_studio_core/
  qfli_dart/
```

Then run `flutter pub get` in this repository.
The editor patch comes from `../qfli_studio_core/vendor/re_editor`.
`pubspec.yaml` points to it with a path override.

## Development and tests

Generate the content assets.

```powershell
dart run tool/build_dart_content.dart
```

Verify every lesson with the official SDK.

```powershell
dart run tool/verify_dart_content.dart
```

Verify that engine notes are present.

```powershell
dart run tool/audit_compat.dart
```

Verify every lesson with the portable interpreter.

```powershell
dart run tool/verify_portable_content.dart --report portable-report.json
```

Run static analysis and tests.

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

Run the native offline-channel test.
It covers two groups: offline rejection and local capability wiring.

```powershell
node --max-old-space-size=128 --test test/native_entry_ability_test.cjs
```

Check the Chinese documents.

```powershell
python scripts/ste-lint-zh.py README.md README.zh-Hant.md
```

## Builds

See [GitHub builds and downloads](GITHUB_BUILD.zh-CN.md) for cloud artifacts (Chinese).

Stage the SDK before an Android build.
Replace both SDK directory placeholders.

```powershell
./native/dart-sdk/android/stage.ps1 -Abi arm64-v8a -Sdk '<SDK_ARM64_DIR>'
./native/dart-sdk/android/stage.ps1 -Abi x86_64 -Sdk '<SDK_X64_DIR>'
```

Build the arm64 APK.

```powershell
flutter build apk --release --target-platform android-arm64 --no-pub
```

The Android release currently signs with the debug key.
Configure a store signing key before publishing.

Build the OHOS HAP.

```powershell
flutter build hap --release --target-platform ohos-arm64 --no-pub
```

Build the OHOS APP.

```powershell
flutter build app --release --target-platform ohos-arm64 --no-pub
```

The signed HAP is written to `build/ohos/hap/entry-default-signed.hap`.
The signed APP is written to `build/ohos/app/ohos-default-signed.app`.
Add `--no-codesign` when signing material is unavailable.

## Signing and privacy

Keep private keys, certificates and passwords local.
Do not commit them to the repository.
Configure OHOS release signing locally.
Name the local release signing configuration `releaseKey`.
Read the bundle name from `ohos/AppScope/app.json5`.
The signing configuration must authorize that bundle.
The certificate must match the signer.
Verify packaging, signing and device runs separately.
A `-signed` filename does not prove store signing.
Use `hap-sign-tool` to verify the signature and profile.

```powershell
tool/ohos/verify_dart_hap.ps1 -HapPath <hap>
```

## Pending evidence

Original OHOS packaging and device acceptance remain open.
Promotion of the 180 drafts remains open.
Full verification of all 300 content pairs remains open.
The final shared-core revision still needs review.

## License

The code in this repository is licensed under GNU GPL v3.0.
Content with a separate license retains that license.
See [LICENSE](LICENSE) for the full license text.

## Third-party license

The bundled `tom_d4rt` uses MIT.
The license is kept at `vendor/tom_d4rt/LICENSE`.
