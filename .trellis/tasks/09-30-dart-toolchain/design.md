# Dart toolchain design

## Boundaries

`DartProgramRunner` owns source collection and the `ProgramRunResult` contract. A dedicated service owns `dart_eval` compilation, execution, and reusable bytecode. The existing shared editor continues to display stdout, stderr, and exit code.

## Data flow

Project files -> package/source map -> `dart_eval.Compiler` -> `Program` / EVC bytes -> `dart_eval.Runtime` -> streamed stdout and stderr -> `ProgramRunResult`.

Compile and execute in a worker isolate. The parent isolate owns the output streams and can terminate the worker on cancellation. Source paths and package names must preserve Dart import behavior. A missing or unsupported library must be reported as a compile failure, not as a successful run.

## Compatibility and risk

`dart_eval` parses current Dart using `analyzer` but does not implement every Dart language and library feature. Its published platform list excludes HarmonyOS. The app must not advertise full Dart SDK parity or target support until a real target build and run prove it. The installed Flutter SDK provides Dart 3.11.5; `dart_eval` 0.8.5 accepts Dart >=3.8.0.

The existing `qfli_studio_core` runner interface stays unchanged. Changes needed in the sibling repository require their own repo review, verification, and commit.
