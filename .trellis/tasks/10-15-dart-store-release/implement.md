# Execution plan

- [x] Verify repository root, clean baseline and exact Herdr workspace/Pi identities.
- [x] Write requirements, design, execution plan and curated context before activation.
- [x] Dispatch terminal/toolchain, curriculum and offline/core audits to w7:p4/p5/p6, each verified in the Dart workspace.
- [x] Inspect shared core and platform packaging; coordinate shared gates and later core fixes through 8b33443.
- [x] Review and commit scoped repairs after relevant verification.
- [x] Run formatter checks, clean static analysis, 103 Dart tests, 479 core tests, deterministic generation and all 240 curriculum programs.
- [x] Build Android release APK and OHOS HAP; inspect permissions, ABI completeness and bundled SDK bytes.
- [x] Complete Android SDK/terminal device smoke (16 checks), install and launch ordinary main; attempt OHOS installation and record signature rejection.
- [x] Reconcile existing Trellis tasks, update specs, record exact evidence and remaining gates.
- [x] Explicitly track 09-30-dart-toolchain as the existing signed-OHOS runtime gate; retain it in progress until that acceptance passes.
- [x] Audit final APK native ABI and16KiB page compatibility, including all17 Flutter/application/SDK ELF libraries and zipalign.
- [x] Commit verification evidence and record the session journal.
- [ ] Reinstall the final reduced ARM64 APK and repeat a launch/SDK check after the Web/Python/SQL device queue releases it.
- [ ] Restore a matching DartWing OHOS signing identity, sign the current HAP, install and verify portable execution on the OHOS device.

The source audit and builds are complete. This task remains in progress for the
explicit device gates above. Android currently uses a debug signing key; store
signing must be configured before publication. See research/platform-verification.md.

Validation uses the current Flutter SDK and explicit workspace paths. Build/device failures are investigated; a package build never substitutes for runtime verification. Roll back only owned edits if a regression is observed.
