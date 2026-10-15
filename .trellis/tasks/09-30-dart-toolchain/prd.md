# Dart local toolchain

## Requirements
- Use maintained compiler/runtime implementations for local Dart execution.
- Run source and multi-file projects with real output, diagnostics, exit status and cancellation.
- Provide formatting, syntax diagnostics and reusable compilation through tools and both terminal surfaces.
- Keep offline network entry points hidden and describe engine limits accurately.
- Verify supported target builds and representative target execution independently.

## Acceptance and current evidence — 2026-10-15
- [x] Android/desktop run on the official native SDK; OHOS uses dart_eval.
- [x] Source, local/self-package imports, stdin, async file IO, UTF-8 and native exit codes work.
- [x] Native Kernel artifacts run after deleting the source; portable EVC has separate coverage.
- [x] Formatting and scanner/parser diagnostics are available and labeled as syntax checks.
- [x] Both real terminal widgets use the Dart profile hook; cancellation allows subsequent execution.
- [x] Static analysis is clean and all 103 Dart tests pass, including 240 curriculum executions.
- [x] Android release builds and the native VM passes a real ARM64 device smoke gate.
- [x] OHOS release builds as an unsigned HAP with INTERNET and account integration removed.
- [ ] Signed OHOS installation and representative portable-engine execution on device.

## Outstanding target gate
The OHOS device rejected the unsigned package with code 9568320, no signature
file. The previous machine-specific signing paths did not exist; the available
profiles bind other applications and cannot sign com.azurekiln.qfli.dartwing.
A DartWing-specific signing identity is needed before this final criterion can
be completed. Do not mark this task fully complete from a host test or HAP build.

## Engine limits
OHOS dart_eval verifies 43/120 curriculum lessons; 77 lessons visibly require
the official SDK. Syntax diagnostics do not claim project-wide semantic
analysis. The final contracts are in backend/dart-native-runtime.md and
frontend/dart-terminal.md. The release task's research/platform-verification.md
records exact commands, artifacts and device results.
