# HAP inspector integration check — October 26, 2026

Scope: `tool/ohos/inspect_dart_hap.py`, its Python fixture tests and the package
inspection contract. This batch has no Dart/core/native-source/signing changes.

The inspector checks product identity, ABI/ELF, permissions, exact curriculum
assets, configuration fingerprints and HAP immutability. Root review corrected
two evidence bugs: requesting release validation no longer marks a debug package
as a verified release, and a corrupt ZIP now writes a failure report and exits 1.
The fixtures exercise both regressions.

Actual verification:

- `python tool/ohos/test_inspect_dart_hap.py`: 31 passed, 0 failed.
- Read-only inspection of the preserved x64 HAP with `--topics 120` and the exact
  SHA256 pin passed. `immutableVerified` and `releaseModeVerified` are true.
- HAP SHA256: `700336efe21b71acee178e6f7ad7949e7623f0f7c423fad9d7b930d241307589`.
- Current report: `build/dart-audit/inspector-root-20261026.json`.
- `signatureVerified`, `deviceVerified` and `nativeGuardVerified` remain false.

This is the old artifact. It predates the native URL guard. No SDK, Flutter,
Java, native build or device process was started for this check. Signature
verification remains the separate pre-existing evidence; this inspector does not
refresh it. Current-native-policy rebuild and installed-device acceptance remain
UNRUN.
