# Dart toolchain design

## Boundaries

`DartProgramRunner` owns source collection and the `ProgramRunResult` contract.
`NativeDartToolchain` executes the official SDK on Android/desktop; portable
compilation and evaluation use `dart_eval` on OHOS/iOS/web. The shared editor
and both terminal surfaces display the same output streams and exit state.

## Data flow

Native: contained project/entry -> SDK/package configuration -> native VM or
Kernel compiler -> source or source-free `.dill` execution -> streamed stdout,
stderr and native exit status -> `ProgramRunResult`.

Portable: project/source map -> compiler worker -> EVC bytes -> runtime worker
-> streamed stdout and stderr -> `ProgramRunResult`. Cancellation terminates the
owned process/worker; Android/desktop SDK errors never fall back to portable
evaluation. Missing libraries and compiler errors are failures.

Both terminals use the profile's `dartTerminalDelegate`, which routes commands
through these services rather than forwarding CLI verbs to Android's raw VM.
Formatting and parser diagnostics share `DartTools`; diagnostics are explicitly
syntax-level. Network package management is disabled for the offline product.

## Compatibility and risk

`dart_eval` 0.8.5 implements a subset of Dart. Only 43/120 curriculum lessons are
verified on it; the other 77 visibly require the official SDK. An unsigned OHOS
HAP build establishes packaging, while signed device execution remains open.
Android's upstream Dart 3.13.5 VM passed the physical ARM64 device smoke gate;
the host SDK is Dart 3.11.5. These are separate capability claims.

The existing `qfli_studio_core` runner interface stays unchanged. Changes needed in the sibling repository require their own repo review, verification, and commit.
