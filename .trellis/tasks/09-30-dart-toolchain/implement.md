# Toolchain implementation and release reconciliation

- [x] Inspect and implement Dart source collection, imports and isolate execution.
- [x] Integrate the official native Android/desktop SDK, source and Kernel execution.
- [x] Provide real formatter, parser diagnostics, compile/run/stop tools and file selection.
- [x] Wire local Dart commands into standalone and embedded terminals.
- [x] Test both real terminal surfaces, exit handling, stopping and transcript retention.
- [x] Execute the 120-lesson/120-example curriculum and maintain accurate engine labels.
- [x] Run clean static analysis, formatting, whitespace checks and 103/103 host tests.
- [x] Build Android release and verify the official VM on the physical ARM64 device.
- [x] Build OHOS release unsigned; remove unused network/account/webview packaging.
- [x] Commit validated changes with Conventional Commits.
- [ ] Supply a DartWing-specific OHOS signing profile, install and execute representative
  portable-engine programs. Device currently rejects the unsigned HAP (9568320).

See ../10-15-dart-store-release/research/platform-verification.md for current
evidence. The historical unsigned build and 28-test baseline are superseded by
this release run. The remaining target gate keeps this task in progress.
