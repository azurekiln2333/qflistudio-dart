# qfli_dart

This Flutter app is an independent Git repository. Check out `qfli_studio_core` next to it before resolving dependencies.

```text
checkout-parent/
  qfli_studio_core/
  qfli_dart/
```

Run `flutter pub get` here, then `flutter run` for the target device. The shared editor patch is provided by `../qfli_studio_core/vendor/re_editor`.

Android packages the complete official Dart SDK. Stage each requested ABI using
`native/dart-sdk/android/stage.ps1` before building:

```powershell
flutter build apk --release --target-platform android-arm64 --no-pub
```

The current Android release configuration uses the debug signing key for local
verification. Configure a store signing key before publishing.

With the OHOS Flutter SDK and HarmonyOS toolchain configured:

```powershell
flutter build hap --release --no-pub --no-codesign
```

The unsigned HAP is written to `build/ohos/hap/entry-default-unsigned.hap`.
Configure a signing identity for `com.azurekiln.qfli.dartwing` locally in DevEco
Studio before installing or publishing; another application's profile cannot
sign this bundle. Machine-specific signing material is not stored in the
project configuration.

OHOS uses the portable `dart_eval` engine. The curriculum contains 120 lessons
and 120 examples; 43 lessons are verified with that engine, and the remaining
77 require the official SDK available on Android and desktop. Each lesson and
example displays its engine requirement.

Run the release checks from this repository:

```powershell
flutter analyze --no-pub
flutter test --no-pub
dart run tool/verify_dart_content.dart
```
